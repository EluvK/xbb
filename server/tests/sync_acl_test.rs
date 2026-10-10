use salvo::http::StatusCode;
use salvo::prelude::*;
use salvo::test::{ResponseExt, TestClient};
use server::auth::{create_jwt_token, AuthMiddleware};
use server::router::create_app_router_with_db;
use server::storage::create_sqlite_pool;
use server::sync::{AclGrantRequest, AclRevokeRequest, Mutation, PullResponse, PushRequest};
use tempfile::tempdir;

#[tokio::test]
async fn test_late_acl_grant_and_revoke_event_stream() -> anyhow::Result<()> {
    let dir = tempdir()?;
    let db_path = dir.path().join("test_sync_acl.db");
    let pool = create_sqlite_pool(&format!("sqlite://{}", db_path.to_string_lossy())).await?;

    let secret = "test-secret-acl";
    let token_alice = create_jwt_token("user-alice", secret)?;
    let token_bob = create_jwt_token("user-bob", secret)?;

    let router = create_app_router_with_db(pool.clone(), AuthMiddleware::new(secret));
    let service = Service::new(router);

    // 1. Alice 提交历史笔记 post-shared (生成 seq = 1)
    let alice_push = PushRequest {
        client_id: "alice-device".to_string(),
        mutations: vec![Mutation {
            table: "post".to_string(),
            id: "post-shared".to_string(),
            op: "PUT".to_string(),
            data: Some(serde_json::json!({ "title": "Confidential Project" })),
            base_version: 0,
            client_timestamp: None,
        }],
    };

    let res = TestClient::post("http://127.0.0.1/sync/v1/push")
        .add_header("Authorization", format!("Bearer {token_alice}"), true)
        .json(&alice_push)
        .send(&service)
        .await;
    assert_eq!(res.status_code.unwrap(), StatusCode::OK);

    // 2. Bob 提交自己的笔记 (生成 seq = 2)
    let bob_push = PushRequest {
        client_id: "bob-device".to_string(),
        mutations: vec![Mutation {
            table: "post".to_string(),
            id: "bob-note".to_string(),
            op: "PUT".to_string(),
            data: Some(serde_json::json!({ "title": "Bob Daily" })),
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

    // 3. Bob 先同步完自身数据：拉取到 seq = 2，checkpoint 推进至 2（已越过 Alice 的 seq = 1）
    let mut res = TestClient::get("http://127.0.0.1/sync/v1/pull?checkpoint=0")
        .add_header("Authorization", format!("Bearer {token_bob}"), true)
        .send(&service)
        .await;
    assert_eq!(res.status_code.unwrap(), StatusCode::OK);
    let bob_pull_1: PullResponse = res.take_json().await.unwrap();
    assert_eq!(bob_pull_1.changes.len(), 1);
    assert_eq!(bob_pull_1.changes[0].id, "bob-note");
    let bob_checkpoint = bob_pull_1.checkpoint;
    assert_eq!(bob_checkpoint, 2);

    // 4. 用户 A (Alice) 之后进行晚期授权：POST /sync/v1/acl/grant 将 post-shared 授权给 Bob
    let grant_body = AclGrantRequest {
        table: "post".to_string(),
        entity_id: "post-shared".to_string(),
        grantee_id: "user-bob".to_string(),
        permission: "READ".to_string(),
    };

    let res = TestClient::post("http://127.0.0.1/sync/v1/acl/grant")
        .add_header("Authorization", format!("Bearer {token_alice}"), true)
        .json(&grant_body)
        .send(&service)
        .await;
    assert_eq!(res.status_code.unwrap(), StatusCode::OK);

    // 5. 用户 B 再次增量 Pull (从 checkpoint = 2 开始)：
    // 晚期授权解决机制生效：服务端追加了新事件(seq = 3 > 2)，B 能够无缝拉到历史数据！
    let mut res = TestClient::get(format!("http://127.0.0.1/sync/v1/pull?checkpoint={bob_checkpoint}"))
        .add_header("Authorization", format!("Bearer {token_bob}"), true)
        .send(&service)
        .await;
    assert_eq!(res.status_code.unwrap(), StatusCode::OK);
    let bob_pull_2: PullResponse = res.take_json().await.unwrap();
    assert_eq!(bob_pull_2.changes.len(), 1);
    assert_eq!(bob_pull_2.changes[0].id, "post-shared");
    assert_eq!(bob_pull_2.changes[0].op, "PUT");
    assert_eq!(
        bob_pull_2.changes[0].data,
        Some(serde_json::json!({ "title": "Confidential Project" }))
    );
    let bob_checkpoint_after_grant = bob_pull_2.checkpoint;
    assert!(bob_checkpoint_after_grant > bob_checkpoint);

    // 6. 用户 A 撤权: POST /sync/v1/acl/revoke
    let revoke_body = AclRevokeRequest {
        table: "post".to_string(),
        entity_id: "post-shared".to_string(),
        grantee_id: "user-bob".to_string(),
    };

    let res = TestClient::post("http://127.0.0.1/sync/v1/acl/revoke")
        .add_header("Authorization", format!("Bearer {token_alice}"), true)
        .json(&revoke_body)
        .send(&service)
        .await;
    assert_eq!(res.status_code.unwrap(), StatusCode::OK);

    // 7. 用户 B 再次增量 Pull：接收到针对自己的 DELETE 墓碑事件，触发本地缓存清除！
    let mut res = TestClient::get(format!(
        "http://127.0.0.1/sync/v1/pull?checkpoint={bob_checkpoint_after_grant}"
    ))
    .add_header("Authorization", format!("Bearer {token_bob}"), true)
    .send(&service)
    .await;
    assert_eq!(res.status_code.unwrap(), StatusCode::OK);
    let bob_pull_3: PullResponse = res.take_json().await.unwrap();
    assert_eq!(bob_pull_3.changes.len(), 1);
    assert_eq!(bob_pull_3.changes[0].id, "post-shared");
    assert_eq!(bob_pull_3.changes[0].op, "DELETE");
    assert!(bob_pull_3.changes[0].data.is_none());

    Ok(())
}
