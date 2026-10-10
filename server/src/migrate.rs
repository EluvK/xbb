use anyhow::{Context, Result};
use sqlx::sqlite::SqlitePool;
use crate::storage::init_schema;

#[derive(Debug, Default, Clone, PartialEq, Eq)]
pub struct MigrationReport {
    pub collections: Vec<String>,
    pub entities_count: usize,
    pub acls_count: usize,
    pub change_logs_count: usize,
}

#[derive(Debug)]
struct RawLegacyEntity {
    table_name: String,
    id: String,
    owner_id: String,
    data: String,
    created_at: i64,
    updated_at: i64,
}

#[derive(Debug)]
struct RawLegacyAcl {
    table_name: String,
    entity_id: String,
    user_id: String,
    permission: String,
}

pub fn parse_timestamp(val: &str) -> i64 {
    if let Ok(num) = val.parse::<i64>() {
        return num;
    }
    if let Ok(dt) = chrono::DateTime::parse_from_rfc3339(val) {
        return dt.timestamp_millis();
    }
    chrono::Utc::now().timestamp_millis()
}

pub async fn migrate_legacy_db(
    source_pool: &SqlitePool,
    target_pool: &SqlitePool,
) -> Result<MigrationReport> {
    init_schema(target_pool).await?;

    // 1. 查找所有以 c_ 开头的存量集合表 (排除系统表如 change_log 等)
    let table_rows: Vec<(String,)> = sqlx::query_as(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name LIKE 'c_%' AND name NOT IN ('change_log', 'entities', 'acls') ORDER BY name ASC"
    )
    .fetch_all(source_pool)
    .await
    .context("Failed to query legacy table names")?;

    let mut legacy_entities = Vec::new();
    let mut collections = Vec::new();

    for (raw_table,) in table_rows {
        let collection = raw_table.trim_start_matches("c_").to_string();
        collections.push(collection.clone());

        let query = format!(
            "SELECT id, body, created_at, updated_at, owner FROM \"{raw_table}\""
        );

        let rows: Vec<(String, String, String, String, String)> = sqlx::query_as(&query)
            .fetch_all(source_pool)
            .await
            .with_context(|| format!("Failed to read legacy table {raw_table}"))?;

        for (id, body, created_at_raw, updated_at_raw, owner) in rows {
            let created_at = parse_timestamp(&created_at_raw);
            let updated_at = parse_timestamp(&updated_at_raw);
            legacy_entities.push(RawLegacyEntity {
                table_name: collection.clone(),
                id,
                owner_id: owner,
                data: body,
                created_at,
                updated_at,
            });
        }
    }

    // 2. 检查并读取 __acls 表
    let has_acls_table: Option<(String,)> = sqlx::query_as(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = '__acls'"
    )
    .fetch_optional(source_pool)
    .await?;

    let mut legacy_acls = Vec::new();
    if has_acls_table.is_some() {
        let rows: Vec<(String, String, String, String)> = sqlx::query_as(
            "SELECT data_collection, data_id, user_id, permission FROM __acls"
        )
        .fetch_all(source_pool)
        .await
        .context("Failed to read legacy __acls table")?;

        for (data_collection, data_id, user_id, permission) in rows {
            legacy_acls.push(RawLegacyAcl {
                table_name: data_collection,
                entity_id: data_id,
                user_id,
                permission,
            });
        }
    }

    // 按创建时间升序排列，生成连续时间线的自增 change_log
    legacy_entities.sort_by_key(|e| e.created_at);

    // 3. 开启目标数据库事务批量插入
    let mut tx = target_pool.begin().await?;

    for entity in &legacy_entities {
        sqlx::query(
            "INSERT OR REPLACE INTO entities (table_name, id, owner_id, data, version, updated_at) VALUES (?, ?, ?, ?, ?, ?)"
        )
        .bind(&entity.table_name)
        .bind(&entity.id)
        .bind(&entity.owner_id)
        .bind(&entity.data)
        .bind(1)
        .bind(entity.updated_at)
        .execute(&mut *tx)
        .await?;

        sqlx::query(
            "INSERT INTO change_log (table_name, entity_id, owner_id, op, data, version, created_at) VALUES (?, ?, ?, 'PUT', ?, ?, ?)"
        )
        .bind(&entity.table_name)
        .bind(&entity.id)
        .bind(&entity.owner_id)
        .bind(&entity.data)
        .bind(1)
        .bind(entity.created_at)
        .execute(&mut *tx)
        .await?;
    }

    for acl in &legacy_acls {
        sqlx::query(
            "INSERT OR REPLACE INTO acls (table_name, entity_id, user_id, permission) VALUES (?, ?, ?, ?)"
        )
        .bind(&acl.table_name)
        .bind(&acl.entity_id)
        .bind(&acl.user_id)
        .bind(&acl.permission)
        .execute(&mut *tx)
        .await?;
    }

    tx.commit().await?;

    let entities_count = legacy_entities.len();
    let change_logs_count = entities_count;
    let acls_count = legacy_acls.len();

    Ok(MigrationReport {
        collections,
        entities_count,
        acls_count,
        change_logs_count,
    })
}
