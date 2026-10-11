use std::str::FromStr;
use std::time::Duration;
use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use sqlx::sqlite::{SqliteConnectOptions, SqliteJournalMode, SqlitePool, SqlitePoolOptions, SqliteSynchronous};
use sqlx::FromRow;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, FromRow)]
pub struct EntityRecord {
    pub table_name: String,
    pub id: String,
    pub owner_id: String,
    pub data: String,
    pub version: i64,
    pub updated_at: i64,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, FromRow)]
pub struct ChangeLogRecord {
    pub seq: i64,
    pub table_name: String,
    pub entity_id: String,
    pub owner_id: String,
    pub op: String,
    pub data: Option<String>,
    pub version: i64,
    pub created_at: i64,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, FromRow)]
pub struct AclRecord {
    pub table_name: String,
    pub entity_id: String,
    pub user_id: String,
    pub permission: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, FromRow)]
pub struct UserRecord {
    pub id: String,
    pub username: String,
    pub password_hash: String,
    pub nickname: Option<String>,
    pub avatar: Option<String>,
    pub created_at: i64,
    pub updated_at: i64,
}

pub const SCHEMA_SQL: &str = r#"
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

CREATE TABLE IF NOT EXISTS entities (
    table_name TEXT NOT NULL,
    id TEXT NOT NULL,
    owner_id TEXT NOT NULL,
    data TEXT NOT NULL,
    version INTEGER NOT NULL DEFAULT 1,
    updated_at INTEGER NOT NULL,
    PRIMARY KEY (table_name, id)
);

CREATE INDEX IF NOT EXISTS idx_entities_owner ON entities (owner_id);

CREATE TABLE IF NOT EXISTS change_log (
    seq INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    owner_id TEXT NOT NULL,
    op TEXT NOT NULL,
    data TEXT,
    version INTEGER NOT NULL,
    created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_change_log_seq_owner ON change_log (seq, owner_id);

CREATE TABLE IF NOT EXISTS acls (
    table_name TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    permission TEXT NOT NULL,
    PRIMARY KEY (table_name, entity_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_acls_user ON acls (user_id, table_name, entity_id);

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    nickname TEXT,
    avatar TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users (username);
"#;

pub async fn create_raw_pool(database_url: &str) -> Result<SqlitePool> {
    let connect_opts = SqliteConnectOptions::from_str(database_url)?
        .create_if_missing(true)
        .journal_mode(SqliteJournalMode::Wal)
        .synchronous(SqliteSynchronous::Normal)
        .busy_timeout(Duration::from_secs(30));

    let pool = SqlitePoolOptions::new()
        .max_connections(50)
        .acquire_timeout(Duration::from_secs(10))
        .connect_with(connect_opts)
        .await
        .with_context(|| format!("Failed to connect to SQLite at {database_url}"))?;

    Ok(pool)
}

pub async fn create_sqlite_pool(database_url: &str) -> Result<SqlitePool> {
    let pool = create_raw_pool(database_url).await?;
    init_schema(&pool).await?;
    Ok(pool)
}

pub async fn init_schema(pool: &SqlitePool) -> Result<()> {
    sqlx::raw_sql(SCHEMA_SQL)
        .execute(pool)
        .await
        .context("Failed to execute storage schema initialization")?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Arc;
    use tempfile::tempdir;

    #[tokio::test]
    async fn test_schema_init_and_crud() -> Result<()> {
        let dir = tempdir()?;
        let db_path = dir.path().join("test_sync.db");
        let db_url = format!("sqlite://{}", db_path.to_string_lossy());

        let pool = create_sqlite_pool(&db_url).await?;

        // 验证三张表建表成功并且能插入查询
        sqlx::query(
            "INSERT INTO entities (table_name, id, owner_id, data, version, updated_at) VALUES (?, ?, ?, ?, ?, ?)"
        )
        .bind("post")
        .bind("p-1")
        .bind("user-1")
        .bind(r#"{"title":"Hello"}"#)
        .bind(1)
        .bind(1000)
        .execute(&pool)
        .await?;

        let entity = sqlx::query_as::<_, EntityRecord>(
            "SELECT * FROM entities WHERE table_name = ? AND id = ?"
        )
        .bind("post")
        .bind("p-1")
        .fetch_one(&pool)
        .await?;

        assert_eq!(entity.id, "p-1");
        assert_eq!(entity.owner_id, "user-1");
        assert_eq!(entity.version, 1);

        sqlx::query(
            "INSERT INTO change_log (table_name, entity_id, owner_id, op, data, version, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)"
        )
        .bind("post")
        .bind("p-1")
        .bind("user-1")
        .bind("PUT")
        .bind(r#"{"title":"Hello"}"#)
        .bind(1)
        .bind(1000)
        .execute(&pool)
        .await?;

        let log = sqlx::query_as::<_, ChangeLogRecord>(
            "SELECT * FROM change_log WHERE entity_id = ?"
        )
        .bind("p-1")
        .fetch_one(&pool)
        .await?;

        assert_eq!(log.seq, 1);
        assert_eq!(log.op, "PUT");

        sqlx::query(
            "INSERT INTO acls (table_name, entity_id, user_id, permission) VALUES (?, ?, ?, ?)"
        )
        .bind("post")
        .bind("p-1")
        .bind("user-2")
        .bind("READ")
        .execute(&pool)
        .await?;

        let acl = sqlx::query_as::<_, AclRecord>(
            "SELECT * FROM acls WHERE table_name = ? AND entity_id = ? AND user_id = ?"
        )
        .bind("post")
        .bind("p-1")
        .bind("user-2")
        .fetch_one(&pool)
        .await?;

        assert_eq!(acl.permission, "READ");
        Ok(())
    }

    #[tokio::test]
    async fn test_high_concurrency_read_write() -> Result<()> {
        let dir = tempdir()?;
        let db_path = dir.path().join("test_concurrent.db");
        let db_url = format!("sqlite://{}", db_path.to_string_lossy());

        let pool = Arc::new(create_sqlite_pool(&db_url).await?);

        let mut handles = Vec::new();
        let total_tasks = 20;
        let ops_per_task = 50;

        for task_idx in 0..total_tasks {
            let pool = Arc::clone(&pool);
            let handle = tokio::spawn(async move {
                for i in 0..ops_per_task {
                    let entity_id = format!("e-{task_idx}-{i}");
                    let user_id = format!("u-{task_idx}");
                    sqlx::query(
                        "INSERT INTO entities (table_name, id, owner_id, data, version, updated_at) VALUES (?, ?, ?, ?, ?, ?)"
                    )
                    .bind("item")
                    .bind(&entity_id)
                    .bind(&user_id)
                    .bind("{}")
                    .bind(1)
                    .bind(100)
                    .execute(&*pool)
                    .await
                    .unwrap();

                    sqlx::query(
                        "INSERT INTO change_log (table_name, entity_id, owner_id, op, data, version, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)"
                    )
                    .bind("item")
                    .bind(&entity_id)
                    .bind(&user_id)
                    .bind("PUT")
                    .bind("{}")
                    .bind(1)
                    .bind(100)
                    .execute(&*pool)
                    .await
                    .unwrap();
                }
            });
            handles.push(handle);
        }

        for h in handles {
            h.await.unwrap();
        }

        let total_entities: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM entities")
            .fetch_one(&*pool)
            .await?;
        assert_eq!(total_entities.0, (total_tasks * ops_per_task) as i64);

        let total_logs: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM change_log")
            .fetch_one(&*pool)
            .await?;
        assert_eq!(total_logs.0, (total_tasks * ops_per_task) as i64);

        Ok(())
    }
}
