use std::sync::LazyLock;
use anyhow::Result;
use sqlx::SqlitePool;
use tokio::sync::Mutex;
use crate::storage::EntityRecord;
use super::models::{ConflictItem, PushRequest, PushResponse};

static SYNC_WRITE_LOCK: LazyLock<Mutex<()>> = LazyLock::new(|| Mutex::new(()));

pub async fn handle_push(
    pool: &SqlitePool,
    user_id: &str,
    req: PushRequest,
) -> Result<PushResponse> {
    // 保护 SQLite 写入的串行化事务，消除 SQLITE_BUSY_SNAPSHOT 死锁，确保严谨 CAS
    let _guard = SYNC_WRITE_LOCK.lock().await;

    let mut tx = pool.begin().await?;
    let mut applied_ids = Vec::new();
    let mut conflicts = Vec::new();

    for mutation in req.mutations {
        let existing = sqlx::query_as::<_, EntityRecord>(
            "SELECT * FROM entities WHERE table_name = ? AND id = ?"
        )
        .bind(&mutation.table)
        .bind(&mutation.id)
        .fetch_optional(&mut *tx)
        .await?;

        match existing {
            None => {
                if mutation.op == "DELETE" {
                    applied_ids.push(mutation.id);
                    continue;
                }

                let version = 1;
                let now = chrono::Utc::now().timestamp_millis();
                let data_str = mutation
                    .data
                    .as_ref()
                    .map(|d| d.to_string())
                    .unwrap_or_else(|| "{}".to_string());

                sqlx::query(
                    "INSERT INTO entities (table_name, id, owner_id, data, version, updated_at) VALUES (?, ?, ?, ?, ?, ?)"
                )
                .bind(&mutation.table)
                .bind(&mutation.id)
                .bind(user_id)
                .bind(&data_str)
                .bind(version)
                .bind(now)
                .execute(&mut *tx)
                .await?;

                sqlx::query(
                    "INSERT INTO change_log (table_name, entity_id, owner_id, op, data, version, created_at) VALUES (?, ?, ?, 'PUT', ?, ?, ?)"
                )
                .bind(&mutation.table)
                .bind(&mutation.id)
                .bind(user_id)
                .bind(&data_str)
                .bind(version)
                .bind(now)
                .execute(&mut *tx)
                .await?;

                applied_ids.push(mutation.id);
            }
            Some(entity) => {
                let is_owner = entity.owner_id == user_id;
                let mut has_write_perm = is_owner;

                if !has_write_perm {
                    let acl: Option<(String,)> = sqlx::query_as(
                        "SELECT permission FROM acls WHERE table_name = ? AND entity_id = ? AND user_id = ?"
                    )
                    .bind(&mutation.table)
                    .bind(&mutation.id)
                    .bind(user_id)
                    .fetch_optional(&mut *tx)
                    .await?;

                    if let Some((perm,)) = acl {
                        if perm == "WRITE" {
                            has_write_perm = true;
                        }
                    }
                }

                if !has_write_perm {
                    let cur_data = serde_json::from_str(&entity.data).ok();
                    conflicts.push(ConflictItem {
                        id: mutation.id,
                        reason: "PERMISSION_DENIED".to_string(),
                        server_version: Some(entity.version),
                        current_data: cur_data,
                    });
                    continue;
                }

                if mutation.base_version != entity.version {
                    let cur_data = serde_json::from_str(&entity.data).ok();
                    conflicts.push(ConflictItem {
                        id: mutation.id,
                        reason: "VERSION_MISMATCH".to_string(),
                        server_version: Some(entity.version),
                        current_data: cur_data,
                    });
                    continue;
                }

                let new_version = entity.version + 1;
                let now = chrono::Utc::now().timestamp_millis();

                if mutation.op == "DELETE" {
                    sqlx::query("DELETE FROM entities WHERE table_name = ? AND id = ?")
                        .bind(&mutation.table)
                        .bind(&mutation.id)
                        .execute(&mut *tx)
                        .await?;

                    sqlx::query(
                        "INSERT INTO change_log (table_name, entity_id, owner_id, op, data, version, created_at) VALUES (?, ?, ?, 'DELETE', NULL, ?, ?)"
                    )
                    .bind(&mutation.table)
                    .bind(&mutation.id)
                    .bind(&entity.owner_id)
                    .bind(new_version)
                    .bind(now)
                    .execute(&mut *tx)
                    .await?;
                } else {
                    let data_str = mutation
                        .data
                        .as_ref()
                        .map(|d| d.to_string())
                        .unwrap_or_else(|| "{}".to_string());

                    sqlx::query(
                        "UPDATE entities SET data = ?, version = ?, updated_at = ? WHERE table_name = ? AND id = ?"
                    )
                    .bind(&data_str)
                    .bind(new_version)
                    .bind(now)
                    .bind(&mutation.table)
                    .bind(&mutation.id)
                    .execute(&mut *tx)
                    .await?;

                    sqlx::query(
                        "INSERT INTO change_log (table_name, entity_id, owner_id, op, data, version, created_at) VALUES (?, ?, ?, 'PUT', ?, ?, ?)"
                    )
                    .bind(&mutation.table)
                    .bind(&mutation.id)
                    .bind(&entity.owner_id)
                    .bind(&data_str)
                    .bind(new_version)
                    .bind(now)
                    .execute(&mut *tx)
                    .await?;
                }

                applied_ids.push(mutation.id);
            }
        }
    }

    tx.commit().await?;

    Ok(PushResponse {
        applied_ids,
        conflicts,
    })
}
