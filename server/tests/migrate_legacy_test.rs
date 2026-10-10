use server::migrate::migrate_legacy_db;
use server::storage::{create_raw_pool, create_sqlite_pool, AclRecord, ChangeLogRecord, EntityRecord};
use tempfile::tempdir;

#[tokio::test]
async fn test_migrate_legacy_database_end_to_end() -> anyhow::Result<()> {
    let dir = tempdir()?;
    let legacy_db_path = dir.path().join("legacy.db");
    let new_db_path = dir.path().join("migrated_new.db");

    // 1. 初始化并填充老版数据库结构
    let legacy_pool =
        create_raw_pool(&format!("sqlite://{}", legacy_db_path.to_string_lossy())).await?;

    sqlx::raw_sql(
        r#"
        CREATE TABLE IF NOT EXISTS c_post (
            id TEXT PRIMARY KEY,
            body TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            owner TEXT NOT NULL,
            uniq TEXT,
            parent_id TEXT
        );

        CREATE TABLE IF NOT EXISTS c_tracker (
            id TEXT PRIMARY KEY,
            body TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            owner TEXT NOT NULL,
            uniq TEXT,
            parent_id TEXT
        );

        CREATE TABLE IF NOT EXISTS __acls (
            id TEXT PRIMARY KEY,
            data_collection TEXT NOT NULL,
            data_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            permission TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            owner TEXT NOT NULL
        );
        "#,
    )
    .execute(&legacy_pool)
    .await?;

    // 插入老数据（故意用不同格式的时间戳和时间顺序测试排序）
    sqlx::query(
        "INSERT INTO c_post (id, body, created_at, updated_at, owner) VALUES (?, ?, ?, ?, ?)"
    )
    .bind("post-old-2")
    .bind(r#"{"title":"Second Post"}"#)
    .bind("2025-01-02T12:00:00Z")
    .bind("2025-01-02T12:00:00Z")
    .bind("user-alice")
    .execute(&legacy_pool)
    .await?;

    sqlx::query(
        "INSERT INTO c_post (id, body, created_at, updated_at, owner) VALUES (?, ?, ?, ?, ?)"
    )
    .bind("post-old-1")
    .bind(r#"{"title":"First Post"}"#)
    .bind("2025-01-01T10:00:00Z")
    .bind("2025-01-01T10:00:00Z")
    .bind("user-alice")
    .execute(&legacy_pool)
    .await?;

    sqlx::query(
        "INSERT INTO c_tracker (id, body, created_at, updated_at, owner) VALUES (?, ?, ?, ?, ?)"
    )
    .bind("trk-1")
    .bind(r#"{"name":"Workout Tracker"}"#)
    .bind("1735730000000") // 毫秒时间戳
    .bind("1735730000000")
    .bind("user-bob")
    .execute(&legacy_pool)
    .await?;

    sqlx::query(
        "INSERT INTO __acls (id, data_collection, data_id, user_id, permission, created_at, updated_at, owner) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
    )
    .bind("acl-1")
    .bind("post")
    .bind("post-old-1")
    .bind("user-bob")
    .bind("READ")
    .bind("2025-01-01T11:00:00Z")
    .bind("2025-01-01T11:00:00Z")
    .bind("user-alice")
    .execute(&legacy_pool)
    .await?;

    // 2. 执行数据迁移
    let new_pool =
        create_sqlite_pool(&format!("sqlite://{}", new_db_path.to_string_lossy())).await?;

    let report = migrate_legacy_db(&legacy_pool, &new_pool).await?;

    assert_eq!(report.entities_count, 3);
    assert_eq!(report.change_logs_count, 3);
    assert_eq!(report.acls_count, 1);
    assert!(report.collections.contains(&"post".to_string()));
    assert!(report.collections.contains(&"tracker".to_string()));

    // 3. 验证新库 entities 完整性与快照
    let entities = sqlx::query_as::<_, EntityRecord>(
        "SELECT * FROM entities ORDER BY table_name, id"
    )
    .fetch_all(&new_pool)
    .await?;

    assert_eq!(entities.len(), 3);
    assert_eq!(entities[0].table_name, "post");
    assert_eq!(entities[0].id, "post-old-1");
    assert_eq!(entities[0].owner_id, "user-alice");
    assert_eq!(entities[0].version, 1);
    assert_eq!(entities[0].data, r#"{"title":"First Post"}"#);

    assert_eq!(entities[1].table_name, "post");
    assert_eq!(entities[1].id, "post-old-2");

    assert_eq!(entities[2].table_name, "tracker");
    assert_eq!(entities[2].id, "trk-1");
    assert_eq!(entities[2].owner_id, "user-bob");

    // 4. 验证 change_log 连续自增 seq (1..N)
    let logs = sqlx::query_as::<_, ChangeLogRecord>(
        "SELECT * FROM change_log ORDER BY seq ASC"
    )
    .fetch_all(&new_pool)
    .await?;

    assert_eq!(logs.len(), 3);
    assert_eq!(logs[0].seq, 1);
    assert_eq!(logs[1].seq, 2);
    assert_eq!(logs[2].seq, 3);

    for log in &logs {
        assert_eq!(log.op, "PUT");
        assert_eq!(log.version, 1);
        assert!(log.data.is_some());
    }

    // 5. 验证 acls 授权表完整性
    let acls = sqlx::query_as::<_, AclRecord>(
        "SELECT * FROM acls"
    )
    .fetch_all(&new_pool)
    .await?;

    assert_eq!(acls.len(), 1);
    assert_eq!(acls[0].table_name, "post");
    assert_eq!(acls[0].entity_id, "post-old-1");
    assert_eq!(acls[0].user_id, "user-bob");
    assert_eq!(acls[0].permission, "READ");

    Ok(())
}
