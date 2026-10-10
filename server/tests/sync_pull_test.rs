use salvo::http::StatusCode;
use salvo::prelude::*;
use salvo::test::{ResponseExt, TestClient};
use server::auth::{create_jwt_token, AuthMiddleware};
use server::router::create_app_router_with_db;
use server::storage::create_sqlite_pool;
use server::sync::{Mutation, PullResponse, PushRequest, PushResponse};
use tempfile::tempdir;

#[tokio::test]
async fn test_pull_pagination_isolation_and_tombstone() -> anyhow::Result<()> {
    let dir = tempdir()?;
    let db_path = dir.path().join("test_sync_pull.db");
    let pool = create_sqlite_pool(&format!("sqlite://{}", db_path.to_string_lossy())).await?;

    let secret = "test-secret-pull";
    let token_alice = create_jwt_token("user-alice", secret)?;
    let token_bob = create_jwt_token("user-bob", secret)?;

    let router = create_app_router_with_db(pool.clone(), AuthMiddleware::new(secret));
    let service = Service::new(router);

    // 1. Alice 提交 3 篇笔记
    let alice_push = PushRequest {
        client_id: "alice-device".to_string(),
        mutations: vec![
            Mutation {
                table: "post".to_string(),
                id: "post-1".to_string(),
                op: "PUT".to_string(),
                data: Some(serde_json::json!({ "title": "Post 1" })),
                base_version: 0,
                client_timestamp: None,
            },
            Mutation {
                table: "post".to_string(),
                id: "post-2".to_string(),
                op: "PUT".to_string(),
                data: Some(serde_json::json!({ "title": "Post 2" })),
                base_version: 0,
                client_timestamp: None,
            },
            Mutation {
                table: "post".to_string(),
                id: "post-3".to_string(),
                op: "PUT".to_string(),
                data: Some(serde_json::json!({ "title": "Post 3" })),
                base_version: 0,
                client_timestamp: None,
            },
        ],
    };

    let mut res = TestClient::post("http://127.0.0.1/sync/v1/push")
        .add_header("Authorization", format!("Bearer {token_alice}"), true)
        .json(&alice_push)
        .send(&service)
        .await;
    assert_eq!(res.status_code.unwrap(), StatusCode::OK);
    let push_res: PushResponse = res.take_json().await.unwrap();
    assert_eq!(push_res.applied_ids.len(), 3);

    // 2. Bob 提交 1 篇私人笔记
    let bob_push = PushRequest {
        client_id: "bob-device".to_string(),
        mutations: vec![Mutation {
            table: "post".to_string(),
            id: "bob-post-1".to_string(),
            op: "PUT".to_string(),
            data: Some(serde_json::json!({ "title": "Bob Secret" })),
            base_version: 0,
            client_timestamp: None,
        }],
    };

    let res = TestClient::post("http://127.0.0.1/sync/v1/push")
        .add_header("Authorization", format!("Bearer {token_bob}"), true)
        .json(&bob_push)
        .send(&service)
        .await;
    assert_eq!(res.status_code.unwrap(), StatusCode::OK);

    // 3. 测试多用户数据隔离：Bob 拉取变更，只能看到自己的 1 条记录，看不到 Alice 的 3 条记录
    let mut res = TestClient::get("http://127.0.0.1/sync/v1/pull?checkpoint=0&limit=10")
        .add_header("Authorization", format!("Bearer {token_bob}"), true)
        .send(&service)
        .await;
    assert_eq!(res.status_code.unwrap(), StatusCode::OK);
    let bob_pull: PullResponse = res.take_json().await.unwrap();
    assert_eq!(bob_pull.changes.len(), 1);
    assert_eq!(bob_pull.changes[0].id, "bob-post-1");
    assert!(!bob_pull.has_more);

    // 4. 测试增量查询分页：Alice 从 checkpoint=0 拉取，limit=2
    let mut res = TestClient::get("http://127.0.0.1/sync/v1/pull?checkpoint=0&limit=2")
        .add_header("Authorization", format!("Bearer {token_alice}"), true)
        .send(&service)
        .await;
    assert_eq!(res.status_code.unwrap(), StatusCode::OK);
    let page1: PullResponse = res.take_json().await.unwrap();
    assert_eq!(page1.changes.len(), 2);
    assert!(page1.has_more);
    assert_eq!(page1.changes[0].id, "post-1");
    assert_eq!(page1.changes[1].id, "post-2");
    let checkpoint_1 = page1.checkpoint;

    // 拉取第二页：从 checkpoint_1 继续拉取 limit=2
    let mut res = TestClient::get(format!("http://127.0.0.1/sync/v1/pull?checkpoint={checkpoint_1}&limit=2"))
        .add_header("Authorization", format!("Bearer {token_alice}"), true)
        .send(&service)
        .await;
    assert_eq!(res.status_code.unwrap(), StatusCode::OK);
    let page2: PullResponse = res.take_json().await.unwrap();
    assert_eq!(page2.changes.len(), 1);
    assert_eq!(page2.changes[0].id, "post-3");
    assert!(!page2.has_more);
    let checkpoint_2 = page2.checkpoint;

    // 5. 测试软删除墓碑记录下发：Alice 删除 post-2
    let delete_push = PushRequest {
        client_id: "alice-device".to_string(),
        mutations: vec![Mutation {
            table: "post".to_string(),
            id: "post-2".to_string(),
            op: "DELETE".to_string(),
            data: None,
            base_version: 1,
            client_timestamp: None,
        }],
    };

    let res = TestClient::post("http://127.0.0.1/sync/v1/push")
        .add_header("Authorization", format!("Bearer {token_alice}"), true)
        .json(&delete_push)
        .send(&service)
        .await;
    assert_eq!(res.status_code.unwrap(), StatusCode::OK);

    // Alice 从 checkpoint_2 增量拉取最新变更
    let mut res = TestClient::get(format!("http://127.0.0.1/sync/v1/pull?checkpoint={checkpoint_2}"))
        .add_header("Authorization", format!("Bearer {token_alice}"), true)
        .send(&service)
        .await;
    assert_eq!(res.status_code.unwrap(), StatusCode::OK);
    let delete_pull: PullResponse = res.take_json().await.unwrap();
    assert_eq!(delete_pull.changes.len(), 1);
    assert_eq!(delete_pull.changes[0].id, "post-2");
    assert_eq!(delete_pull.changes[0].op, "DELETE");
    assert!(delete_pull.changes[0].data.is_none());
    assert_eq!(delete_pull.changes[0].version, 2);

    Ok(())
}
