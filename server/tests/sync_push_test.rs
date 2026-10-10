use std::sync::Arc;
use salvo::http::StatusCode;
use salvo::prelude::*;
use salvo::test::{ResponseExt, TestClient};
use server::auth::{create_jwt_token, AuthMiddleware};
use server::router::create_app_router_with_db;
use server::storage::{create_sqlite_pool, ChangeLogRecord, EntityRecord};
use server::sync::{Mutation, PushRequest, PushResponse};
use tempfile::tempdir;

#[tokio::test]
async fn test_push_single_mutation() -> anyhow::Result<()> {
    let dir = tempdir()?;
    let db_path = dir.path().join("test_push_single.db");
    let pool = create_sqlite_pool(&format!("sqlite://{}", db_path.to_string_lossy())).await?;

    let secret = "test-secret-push-1";
    let token = create_jwt_token("user-alice", secret)?;
    let router = create_app_router_with_db(pool.clone(), AuthMiddleware::new(secret));
    let service = Service::new(router);

    let push_body = PushRequest {
        client_id: "client-a".to_string(),
        mutations: vec![Mutation {
            table: "post".to_string(),
            id: "post-1".to_string(),
            op: "PUT".to_string(),
            data: Some(serde_json::json!({
                "title": "First Post",
                "content": "Hello World"
            })),
            base_version: 0,
            client_timestamp: Some(1728550000000),
        }],
    };

    let mut res = TestClient::post("http://127.0.0.1/sync/v1/push")
        .add_header("Authorization", format!("Bearer {token}"), true)
        .json(&push_body)
        .send(&service)
        .await;

    assert_eq!(res.status_code.unwrap(), StatusCode::OK);
    let resp: PushResponse = res.take_json().await.unwrap();
    assert_eq!(resp.applied_ids, vec!["post-1"]);
    assert!(resp.conflicts.is_empty());

    // 验证 entities
    let entity = sqlx::query_as::<_, EntityRecord>(
        "SELECT * FROM entities WHERE table_name = ? AND id = ?"
    )
    .bind("post")
    .bind("post-1")
    .fetch_one(&pool)
    .await?;

    assert_eq!(entity.owner_id, "user-alice");
    assert_eq!(entity.version, 1);

    // 验证 change_log
    let log = sqlx::query_as::<_, ChangeLogRecord>(
        "SELECT * FROM change_log WHERE table_name = ? AND entity_id = ?"
    )
    .bind("post")
    .bind("post-1")
    .fetch_one(&pool)
    .await?;

    assert_eq!(log.seq, 1);
    assert_eq!(log.op, "PUT");
    assert_eq!(log.version, 1);

    Ok(())
}

#[tokio::test]
async fn test_push_batch_and_cas_conflict() -> anyhow::Result<()> {
    let dir = tempdir()?;
    let db_path = dir.path().join("test_push_batch.db");
    let pool = create_sqlite_pool(&format!("sqlite://{}", db_path.to_string_lossy())).await?;

    let secret = "test-secret-push-batch";
    let token_alice = create_jwt_token("user-alice", secret)?;
    let router = create_app_router_with_db(pool.clone(), AuthMiddleware::new(secret));
    let service = Service::new(router);

    // 1. 批量插入两条数据
    let batch_req = PushRequest {
        client_id: "client-a".to_string(),
        mutations: vec![
            Mutation {
                table: "post".to_string(),
                id: "p-batch-1".to_string(),
                op: "PUT".to_string(),
                data: Some(serde_json::json!({ "title": "Batch 1" })),
                base_version: 0,
                client_timestamp: None,
            },
            Mutation {
                table: "post".to_string(),
                id: "p-batch-2".to_string(),
                op: "PUT".to_string(),
                data: Some(serde_json::json!({ "title": "Batch 2" })),
                base_version: 0,
                client_timestamp: None,
            },
        ],
    };

    let mut res = TestClient::post("http://127.0.0.1/sync/v1/push")
        .add_header("Authorization", format!("Bearer {token_alice}"), true)
        .json(&batch_req)
        .send(&service)
        .await;

    assert_eq!(res.status_code.unwrap(), StatusCode::OK);
    let resp: PushResponse = res.take_json().await.unwrap();
    assert_eq!(resp.applied_ids.len(), 2);
    assert!(resp.conflicts.is_empty());

    // 2. 更新 p-batch-1 (base_version = 1)，成功
    let update_req = PushRequest {
        client_id: "client-a".to_string(),
        mutations: vec![Mutation {
            table: "post".to_string(),
            id: "p-batch-1".to_string(),
            op: "PUT".to_string(),
            data: Some(serde_json::json!({ "title": "Batch 1 updated" })),
            base_version: 1,
            client_timestamp: None,
        }],
    };

    let mut res = TestClient::post("http://127.0.0.1/sync/v1/push")
        .add_header("Authorization", format!("Bearer {token_alice}"), true)
        .json(&update_req)
        .send(&service)
        .await;

    assert_eq!(res.status_code.unwrap(), StatusCode::OK);
    let resp: PushResponse = res.take_json().await.unwrap();
    assert_eq!(resp.applied_ids, vec!["p-batch-1"]);

    // 服务端 p-batch-1 当前 version 现在是 2
    // 3. 模拟并发冲突：带有旧的 base_version = 1 再次提交修改
    let conflict_req = PushRequest {
        client_id: "client-b".to_string(),
        mutations: vec![Mutation {
            table: "post".to_string(),
            id: "p-batch-1".to_string(),
            op: "PUT".to_string(),
            data: Some(serde_json::json!({ "title": "Stale update" })),
            base_version: 1, // 服务端已经是 2，应发生 CAS 拦截
            client_timestamp: None,
        }],
    };

    let mut res = TestClient::post("http://127.0.0.1/sync/v1/push")
        .add_header("Authorization", format!("Bearer {token_alice}"), true)
        .json(&conflict_req)
        .send(&service)
        .await;

    assert_eq!(res.status_code.unwrap(), StatusCode::OK);
    let resp: PushResponse = res.take_json().await.unwrap();
    assert!(resp.applied_ids.is_empty());
    assert_eq!(resp.conflicts.len(), 1);
    assert_eq!(resp.conflicts[0].id, "p-batch-1");
    assert_eq!(resp.conflicts[0].reason, "VERSION_MISMATCH");
    assert_eq!(resp.conflicts[0].server_version, Some(2));
    assert_eq!(
        resp.conflicts[0].current_data,
        Some(serde_json::json!({ "title": "Batch 1 updated" }))
    );

    // 4. 写策略守卫：未授权用户 Bob 尝试修改 Alice 的文章
    let token_bob = create_jwt_token("user-bob", secret)?;
    let unauth_req = PushRequest {
        client_id: "client-bob".to_string(),
        mutations: vec![Mutation {
            table: "post".to_string(),
            id: "p-batch-1".to_string(),
            op: "PUT".to_string(),
            data: Some(serde_json::json!({ "title": "Bob malicious update" })),
            base_version: 2,
            client_timestamp: None,
        }],
    };

    let mut res = TestClient::post("http://127.0.0.1/sync/v1/push")
        .add_header("Authorization", format!("Bearer {token_bob}"), true)
        .json(&unauth_req)
        .send(&service)
        .await;

    assert_eq!(res.status_code.unwrap(), StatusCode::OK);
    let resp: PushResponse = res.take_json().await.unwrap();
    assert!(resp.applied_ids.is_empty());
    assert_eq!(resp.conflicts.len(), 1);
    assert_eq!(resp.conflicts[0].reason, "PERMISSION_DENIED");

    Ok(())
}

#[tokio::test]
async fn test_push_concurrent_cas_race() -> anyhow::Result<()> {
    let dir = tempdir()?;
    let db_path = dir.path().join("test_push_concurrent_race.db");
    let pool = create_sqlite_pool(&format!("sqlite://{}", db_path.to_string_lossy())).await?;

    let secret = "test-secret-race";
    let token = create_jwt_token("user-owner", secret)?;
    let router = create_app_router_with_db(pool.clone(), AuthMiddleware::new(secret));
    let service = Arc::new(Service::new(router));

    // 先插入初始实体 (version = 1)
    let init_req = PushRequest {
        client_id: "init".to_string(),
        mutations: vec![Mutation {
            table: "note".to_string(),
            id: "n-1".to_string(),
            op: "PUT".to_string(),
            data: Some(serde_json::json!({ "text": "initial" })),
            base_version: 0,
            client_timestamp: None,
        }],
    };
    let _ = TestClient::post("http://127.0.0.1/sync/v1/push")
        .add_header("Authorization", format!("Bearer {token}"), true)
        .json(&init_req)
        .send(&*service)
        .await;

    // 10 个协程同时尝试以 base_version = 1 更新同一个实体 n-1
    let mut handles = Vec::new();
    for i in 0..10 {
        let service = Arc::clone(&service);
        let token = token.clone();
        let handle = tokio::spawn(async move {
            let req = PushRequest {
                client_id: format!("client-{i}"),
                mutations: vec![Mutation {
                    table: "note".to_string(),
                    id: "n-1".to_string(),
                    op: "PUT".to_string(),
                    data: Some(serde_json::json!({ "text": format!("update from {i}") })),
                    base_version: 1, // 大家都以 1 为基准
                    client_timestamp: None,
                }],
            };

            let mut res = TestClient::post("http://127.0.0.1/sync/v1/push")
                .add_header("Authorization", format!("Bearer {token}"), true)
                .json(&req)
                .send(&*service)
                .await;

            let text = res.take_string().await.unwrap();
            let resp: PushResponse = serde_json::from_str(&text).expect(&format!("Failed to parse response: {}", text));
            resp
        });
        handles.push(handle);
    }

    let mut success_count = 0;
    let mut conflict_count = 0;

    for h in handles {
        let resp = h.await.unwrap();
        if !resp.applied_ids.is_empty() {
            success_count += 1;
        }
        if !resp.conflicts.is_empty() {
            conflict_count += 1;
        }
    }

    // 严格 CAS 仲裁：只有且仅有 1 个请求能成功将 version 从 1 推进到 2，其余 9 个必定冲突！
    assert_eq!(success_count, 1);
    assert_eq!(conflict_count, 9);

    // 最终数据库 version 必须为 2
    let entity = sqlx::query_as::<_, EntityRecord>(
        "SELECT * FROM entities WHERE table_name = ? AND id = ?"
    )
    .bind("note")
    .bind("n-1")
    .fetch_one(&pool)
    .await?;
    assert_eq!(entity.version, 2);

    Ok(())
}
