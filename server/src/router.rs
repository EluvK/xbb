use std::path::{Path, PathBuf};
use salvo::http::StatusCode;
use salvo::prelude::*;
use sqlx::SqlitePool;
use crate::auth::AuthMiddleware;
use crate::user::{
    auth_login, auth_me, auth_register, health_check, list_users, update_password, update_profile,
};

#[derive(Clone)]
pub struct DbMiddleware(pub SqlitePool);

#[handler]
impl DbMiddleware {
    async fn handle(&self, depot: &mut Depot) {
        depot.insert("pool", self.0.clone());
    }
}

#[handler]
pub async fn app_version(req: &mut Request, res: &mut Response) {
    let app = req.param::<String>("app").unwrap_or_default();
    let candidate_paths = [
        format!("data/public/{app}/version"),
        format!("public/{app}/version"),
        format!("../{app}/version"),
    ];

    for path in &candidate_paths {
        if Path::new(path).is_file() {
            if let Ok(content) = tokio::fs::read_to_string(path).await {
                res.render(content);
                return;
            }
        }
    }

    res.render("0.2.5+283");
}

#[handler]
pub async fn app_changelog(req: &mut Request, res: &mut Response) {
    let app = req.param::<String>("app").unwrap_or_default();
    let candidate_paths = [
        format!("data/public/{app}/CHANGELOG"),
        format!("public/{app}/CHANGELOG"),
        "../CHANGELOG".to_string(),
        "CHANGELOG".to_string(),
    ];

    for path in &candidate_paths {
        if Path::new(path).is_file() {
            if let Ok(content) = tokio::fs::read_to_string(path).await {
                res.render(content);
                return;
            }
        }
    }

    res.render("# Changelog\n\nLatest update available.");
}

#[handler]
pub async fn app_download(req: &mut Request, res: &mut Response) {
    let app = req.param::<String>("app").unwrap_or_default();
    let file_path = PathBuf::from(format!("data/public/{app}/download.bin"));
    if file_path.is_file() {
        res.send_file(file_path, req.headers()).await;
    } else {
        res.status_code(StatusCode::NOT_FOUND);
        res.render("File not found");
    }
}

#[handler]
pub async fn deprecated_handler(res: &mut Response) {
    res.status_code(StatusCode::UPGRADE_REQUIRED);
    res.render(Json(serde_json::json!({
        "code": "CLIENT_UPGRADE_REQUIRED",
        "message": "当前客户端同步协议已废弃，请升级到最新应用版本。"
    })));
}

#[handler]
pub async fn sync_whoami(depot: &mut Depot, res: &mut Response) {
    let user_id = depot.get::<String>("user_id").cloned().unwrap_or_default();
    res.render(Json(serde_json::json!({
        "user_id": user_id,
        "status": "ok"
    })));
}

fn deprecated_router(path: &str) -> Router {
    Router::with_path(path)
        .get(deprecated_handler)
        .post(deprecated_handler)
        .put(deprecated_handler)
        .delete(deprecated_handler)
        .patch(deprecated_handler)
}

pub fn create_app_router() -> Router {
    create_app_router_with_auth(AuthMiddleware::default())
}

pub fn create_app_router_with_auth(auth: AuthMiddleware) -> Router {
    Router::new()
        // 1. 公开的 App 更新通道（与老客户端完全一致，保证老 App 能检测更新并下载）
        .push(Router::with_path("fs/public/{app}/version").get(app_version))
        .push(Router::with_path("fs/public/{app}/CHANGELOG").get(app_changelog))
        .push(Router::with_path("fs/public/{app}/download").get(app_download))
        // 2. 新一代日志流同步接口 (挂载 JWT 认证中间件)
        .push(
            Router::with_path("sync/v1")
                .hoop(auth)
                .push(Router::with_path("whoami").get(sync_whoami))
                .push(Router::with_path("push").post(crate::sync::sync_push))
                .push(Router::with_path("pull").get(crate::sync::sync_pull))
                .push(Router::with_path("acl/grant").post(crate::sync::acl_grant))
                .push(Router::with_path("acl/revoke").post(crate::sync::acl_revoke))
        )
        // 3. 针对旧客户端同步接口的统一优雅拦截 (返回 426)
        .push(deprecated_router("data"))
        .push(deprecated_router("data/{**rest}"))
        .push(deprecated_router("batch-data"))
        .push(deprecated_router("batch-data/{**rest}"))
}

pub fn create_app_router_with_db(pool: SqlitePool, auth: AuthMiddleware) -> Router {
    Router::new()
        .hoop(DbMiddleware(pool))
        .push(Router::with_path("health").get(health_check))
        .push(Router::with_path("api/v1/health").get(health_check))
        .push(Router::with_path("api/v1/auth/register").post(auth_register))
        .push(Router::with_path("api/v1/auth/login").post(auth_login))
        .push(
            Router::with_path("api/v1/auth")
                .hoop(auth.clone())
                .push(Router::with_path("me").get(auth_me))
                .push(Router::with_path("profile").put(update_profile).post(update_profile))
                .push(Router::with_path("password").post(update_password))
                .push(Router::with_path("users").get(list_users))
                .push(Router::with_path("friends").get(list_users)),
        )
        .push(Router::with_path("fs/public/{app}/version").get(app_version))
        .push(Router::with_path("fs/public/{app}/CHANGELOG").get(app_changelog))
        .push(Router::with_path("fs/public/{app}/download").get(app_download))
        .push(
            Router::with_path("sync/v1")
                .hoop(auth)
                .push(Router::with_path("whoami").get(sync_whoami))
                .push(Router::with_path("push").post(crate::sync::sync_push))
                .push(Router::with_path("pull").get(crate::sync::sync_pull))
                .push(Router::with_path("acl/grant").post(crate::sync::acl_grant))
                .push(Router::with_path("acl/revoke").post(crate::sync::acl_revoke))
        )
        .push(deprecated_router("data"))
        .push(deprecated_router("data/{**rest}"))
        .push(deprecated_router("batch-data"))
        .push(deprecated_router("batch-data/{**rest}"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::auth::create_jwt_token;
    use salvo::test::{ResponseExt, TestClient};

    #[tokio::test]
    async fn test_version_and_changelog_routes() {
        let router = create_app_router();
        let service = Service::new(router);

        let mut res = TestClient::get("http://127.0.0.1/fs/public/xbb/version")
            .send(&service)
            .await;
        assert_eq!(res.status_code.unwrap(), StatusCode::OK);
        let body = res.take_string().await.unwrap();
        assert!(!body.is_empty());

        let mut res = TestClient::get("http://127.0.0.1/fs/public/xbb/CHANGELOG")
            .send(&service)
            .await;
        assert_eq!(res.status_code.unwrap(), StatusCode::OK);
        let body = res.take_string().await.unwrap();
        assert!(body.contains("Changelog") || body.contains("CHANGELOG"));
    }

    #[tokio::test]
    async fn test_deprecated_endpoints_return_426() {
        let router = create_app_router();
        let service = Service::new(router);

        let endpoints = [
            ("GET", "http://127.0.0.1/data/posts"),
            ("POST", "http://127.0.0.1/data/posts/1"),
            ("DELETE", "http://127.0.0.1/data/notes/sub/doc"),
            ("POST", "http://127.0.0.1/batch-data/push"),
        ];

        for (method, url) in endpoints {
            let client = match method {
                "GET" => TestClient::get(url),
                "POST" => TestClient::post(url),
                "DELETE" => TestClient::delete(url),
                _ => unreachable!(),
            };
            let mut res = client.send(&service).await;
            assert_eq!(res.status_code.unwrap(), StatusCode::UPGRADE_REQUIRED);
            let json: serde_json::Value = res.take_json().await.unwrap();
            assert_eq!(json["code"], "CLIENT_UPGRADE_REQUIRED");
        }
    }

    #[tokio::test]
    async fn test_jwt_auth_middleware() {
        let auth = AuthMiddleware::new("test-secret-2026");
        let router = create_app_router_with_auth(auth);
        let service = Service::new(router);

        // 1. 无 token -> 401
        let res = TestClient::get("http://127.0.0.1/sync/v1/whoami")
            .send(&service)
            .await;
        assert_eq!(res.status_code.unwrap(), StatusCode::UNAUTHORIZED);

        // 2. 伪造/错误 token -> 401
        let res = TestClient::get("http://127.0.0.1/sync/v1/whoami")
            .add_header("Authorization", "Bearer invalid-token", true)
            .send(&service)
            .await;
        assert_eq!(res.status_code.unwrap(), StatusCode::UNAUTHORIZED);

        // 3. 有效 token -> 200 并且成功提取 user_id
        let token = create_jwt_token("user-tester-42", "test-secret-2026").unwrap();
        let mut res = TestClient::get("http://127.0.0.1/sync/v1/whoami")
            .add_header("Authorization", format!("Bearer {token}"), true)
            .send(&service)
            .await;
        assert_eq!(res.status_code.unwrap(), StatusCode::OK);
        let json: serde_json::Value = res.take_json().await.unwrap();
        assert_eq!(json["user_id"], "user-tester-42");
    }

    #[tokio::test]
    async fn test_auth_register_login_profile_pipeline() {
        let pool = crate::storage::create_raw_pool("sqlite::memory:").await.unwrap();
        crate::storage::init_schema(&pool).await.unwrap();
        let auth = AuthMiddleware::default();
        let router = create_app_router_with_db(pool, auth);
        let service = Service::new(router);

        // 1. 注册新用户
        let register_body = serde_json::json!({
            "username": "alice",
            "password": "secretPassword123",
            "nickname": "Alice In Wonder",
            "avatar": "avatar_2"
        });
        let mut res = TestClient::post("http://127.0.0.1/api/v1/auth/register")
            .json(&register_body)
            .send(&service)
            .await;
        assert_eq!(res.status_code.unwrap(), StatusCode::CREATED);
        let json: serde_json::Value = res.take_json().await.unwrap();
        assert_eq!(json["status"], "ok");
        let token = json["token"].as_str().unwrap().to_string();
        let user_id = json["user"]["id"].as_str().unwrap().to_string();
        assert_eq!(json["user"]["username"], "alice");

        // 2. 使用刚才注册的账号登录
        let login_body = serde_json::json!({
            "username": "alice",
            "password": "secretPassword123"
        });
        let mut res = TestClient::post("http://127.0.0.1/api/v1/auth/login")
            .json(&login_body)
            .send(&service)
            .await;
        assert_eq!(res.status_code.unwrap(), StatusCode::OK);
        let login_json: serde_json::Value = res.take_json().await.unwrap();
        assert_eq!(login_json["user"]["id"], user_id);

        // 3. 错误密码 -> 401
        let bad_login = serde_json::json!({
            "username": "alice",
            "password": "wrongPassword"
        });
        let res = TestClient::post("http://127.0.0.1/api/v1/auth/login")
            .json(&bad_login)
            .send(&service)
            .await;
        assert_eq!(res.status_code.unwrap(), StatusCode::UNAUTHORIZED);

        // 4. 使用 token 访问 /api/v1/auth/me
        let mut res = TestClient::get("http://127.0.0.1/api/v1/auth/me")
            .add_header("Authorization", format!("Bearer {token}"), true)
            .send(&service)
            .await;
        assert_eq!(res.status_code.unwrap(), StatusCode::OK);
        let me_json: serde_json::Value = res.take_json().await.unwrap();
        assert_eq!(me_json["user"]["username"], "alice");

        // 5. 修改个人资料
        let update_profile_body = serde_json::json!({
            "nickname": "Alice Updated",
            "avatar": "avatar_3"
        });
        let mut res = TestClient::post("http://127.0.0.1/api/v1/auth/profile")
            .add_header("Authorization", format!("Bearer {token}"), true)
            .json(&update_profile_body)
            .send(&service)
            .await;
        assert_eq!(res.status_code.unwrap(), StatusCode::OK);
        let prof_json: serde_json::Value = res.take_json().await.unwrap();
        assert_eq!(prof_json["user"]["nickname"], "Alice Updated");
        assert_eq!(prof_json["user"]["avatar"], "avatar_3");

        // 6. 检查 health 接口
        let mut res = TestClient::get("http://127.0.0.1/health")
            .send(&service)
            .await;
        assert_eq!(res.status_code.unwrap(), StatusCode::OK);
        let health_json: serde_json::Value = res.take_json().await.unwrap();
        assert_eq!(health_json["status"], "ok");
    }
}
