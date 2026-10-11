use salvo::http::StatusCode;
use salvo::prelude::*;
use serde::{Deserialize, Serialize};
use sqlx::SqlitePool;
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use crate::auth::{create_jwt_token, DEFAULT_JWT_SECRET};
use crate::storage::UserRecord;

pub fn hash_password(password: &str) -> String {
    let mut hasher = DefaultHasher::new();
    format!("xbb-secure-salt-2026-{}", password).hash(&mut hasher);
    format!("{:016x}", hasher.finish())
}

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub username: String,
    pub password: String,
    pub nickname: Option<String>,
    pub avatar: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub username: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct UpdateProfileRequest {
    pub nickname: Option<String>,
    pub avatar: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct UpdatePasswordRequest {
    pub old_password: String,
    pub new_password: String,
}

#[derive(Debug, Serialize)]
pub struct UserPublicDto {
    pub id: String,
    pub username: String,
    pub nickname: String,
    pub avatar: String,
}

impl From<UserRecord> for UserPublicDto {
    fn from(r: UserRecord) -> Self {
        let nickname = r.nickname.unwrap_or_else(|| r.username.clone());
        let avatar = r.avatar.unwrap_or_else(|| "avatar_1".to_string());
        Self {
            id: r.id,
            username: r.username,
            nickname,
            avatar,
        }
    }
}

#[handler]
pub async fn health_check(res: &mut Response) {
    res.render(Json(serde_json::json!({
        "status": "ok",
        "timestamp": chrono::Utc::now().timestamp_millis()
    })));
}

#[handler]
pub async fn auth_register(req: &mut Request, depot: &mut Depot, res: &mut Response) {
    let pool = match depot.get::<SqlitePool>("pool") {
        Ok(p) => p.clone(),
        Err(_) => {
            res.status_code(StatusCode::INTERNAL_SERVER_ERROR);
            res.render(Json(serde_json::json!({"code": "DB_UNAVAILABLE", "message": "Database pool not found"})));
            return;
        }
    };

    let body = match req.parse_json::<RegisterRequest>().await {
        Ok(b) => b,
        Err(e) => {
            res.status_code(StatusCode::BAD_REQUEST);
            res.render(Json(serde_json::json!({"code": "INVALID_BODY", "message": format!("Invalid JSON: {e}")})));
            return;
        }
    };

    let username = body.username.trim();
    let password = body.password.trim();
    if username.is_empty() || password.is_empty() {
        res.status_code(StatusCode::BAD_REQUEST);
        res.render(Json(serde_json::json!({"code": "INVALID_CREDENTIALS", "message": "Username and password cannot be empty"})));
        return;
    }

    // 检查用户名冲突
    let existing: Option<(String,)> = sqlx::query_as("SELECT id FROM users WHERE username = ?")
        .bind(username)
        .fetch_optional(&pool)
        .await
        .unwrap_or(None);

    if existing.is_some() {
        res.status_code(StatusCode::CONFLICT);
        res.render(Json(serde_json::json!({"code": "USERNAME_TAKEN", "message": "Username is already taken"})));
        return;
    }

    let user_id = format!("user-{}", uuid::Uuid::new_v4());
    let password_hash = hash_password(password);
    let nickname = body.nickname.as_deref().unwrap_or(username);
    let avatar = body.avatar.as_deref().unwrap_or("avatar_1");
    let now = chrono::Utc::now().timestamp();

    let result = sqlx::query(
        "INSERT INTO users (id, username, password_hash, nickname, avatar, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)"
    )
    .bind(&user_id)
    .bind(username)
    .bind(&password_hash)
    .bind(nickname)
    .bind(avatar)
    .bind(now)
    .bind(now)
    .execute(&pool)
    .await;

    if let Err(e) = result {
        res.status_code(StatusCode::INTERNAL_SERVER_ERROR);
        res.render(Json(serde_json::json!({"code": "INTERNAL_ERROR", "message": e.to_string()})));
        return;
    }

    let secret = std::env::var("JWT_SECRET").unwrap_or_else(|_| DEFAULT_JWT_SECRET.to_string());
    let token = match create_jwt_token(&user_id, &secret) {
        Ok(t) => t,
        Err(e) => {
            res.status_code(StatusCode::INTERNAL_SERVER_ERROR);
            res.render(Json(serde_json::json!({"code": "TOKEN_ERROR", "message": e.to_string()})));
            return;
        }
    };

    res.status_code(StatusCode::CREATED);
    res.render(Json(serde_json::json!({
        "status": "ok",
        "token": token,
        "user": {
            "id": user_id,
            "username": username,
            "nickname": nickname,
            "avatar": avatar,
        }
    })));
}

#[handler]
pub async fn auth_login(req: &mut Request, depot: &mut Depot, res: &mut Response) {
    let pool = match depot.get::<SqlitePool>("pool") {
        Ok(p) => p.clone(),
        Err(_) => {
            res.status_code(StatusCode::INTERNAL_SERVER_ERROR);
            res.render(Json(serde_json::json!({"code": "DB_UNAVAILABLE", "message": "Database pool not found"})));
            return;
        }
    };

    let body = match req.parse_json::<LoginRequest>().await {
        Ok(b) => b,
        Err(e) => {
            res.status_code(StatusCode::BAD_REQUEST);
            res.render(Json(serde_json::json!({"code": "INVALID_BODY", "message": format!("Invalid JSON: {e}")})));
            return;
        }
    };

    let username = body.username.trim();
    let password = body.password.trim();

    let user: Option<UserRecord> = sqlx::query_as("SELECT * FROM users WHERE username = ?")
        .bind(username)
        .fetch_optional(&pool)
        .await
        .unwrap_or(None);

    let user = match user {
        Some(u) => u,
        None => {
            res.status_code(StatusCode::UNAUTHORIZED);
            res.render(Json(serde_json::json!({"code": "INVALID_CREDENTIALS", "message": "Invalid username or password"})));
            return;
        }
    };

    let target_hash = hash_password(password);
    if user.password_hash != target_hash {
        res.status_code(StatusCode::UNAUTHORIZED);
        res.render(Json(serde_json::json!({"code": "INVALID_CREDENTIALS", "message": "Invalid username or password"})));
        return;
    }

    let secret = std::env::var("JWT_SECRET").unwrap_or_else(|_| DEFAULT_JWT_SECRET.to_string());
    let token = match create_jwt_token(&user.id, &secret) {
        Ok(t) => t,
        Err(e) => {
            res.status_code(StatusCode::INTERNAL_SERVER_ERROR);
            res.render(Json(serde_json::json!({"code": "TOKEN_ERROR", "message": e.to_string()})));
            return;
        }
    };

    let public_user: UserPublicDto = user.into();
    res.render(Json(serde_json::json!({
        "status": "ok",
        "token": token,
        "user": public_user
    })));
}

#[handler]
pub async fn auth_me(depot: &mut Depot, res: &mut Response) {
    let pool = match depot.get::<SqlitePool>("pool") {
        Ok(p) => p.clone(),
        Err(_) => {
            res.status_code(StatusCode::INTERNAL_SERVER_ERROR);
            res.render(Json(serde_json::json!({"code": "DB_UNAVAILABLE", "message": "Database pool not found"})));
            return;
        }
    };

    let user_id = match depot.get::<String>("user_id") {
        Ok(u) => u.clone(),
        Err(_) => {
            res.status_code(StatusCode::UNAUTHORIZED);
            return;
        }
    };
    let user: Option<UserRecord> = sqlx::query_as("SELECT * FROM users WHERE id = ?")
        .bind(&user_id)
        .fetch_optional(&pool)
        .await
        .unwrap_or(None);

    match user {
        Some(u) => {
            let dto: UserPublicDto = u.into();
            res.render(Json(serde_json::json!({
                "status": "ok",
                "user": dto
            })));
        }
        None => {
            res.status_code(StatusCode::NOT_FOUND);
            res.render(Json(serde_json::json!({"code": "USER_NOT_FOUND", "message": "User not found"})));
        }
    }
}

#[handler]
pub async fn update_profile(req: &mut Request, depot: &mut Depot, res: &mut Response) {
    let pool = match depot.get::<SqlitePool>("pool") {
        Ok(p) => p.clone(),
        Err(_) => {
            res.status_code(StatusCode::INTERNAL_SERVER_ERROR);
            res.render(Json(serde_json::json!({"code": "DB_UNAVAILABLE", "message": "Database pool not found"})));
            return;
        }
    };

    let user_id = match depot.get::<String>("user_id") {
        Ok(u) => u.clone(),
        Err(_) => {
            res.status_code(StatusCode::UNAUTHORIZED);
            return;
        }
    };
    let body = match req.parse_json::<UpdateProfileRequest>().await {
        Ok(b) => b,
        Err(e) => {
            res.status_code(StatusCode::BAD_REQUEST);
            res.render(Json(serde_json::json!({"code": "INVALID_BODY", "message": format!("Invalid JSON: {e}")})));
            return;
        }
    };

    let now = chrono::Utc::now().timestamp();
    let current_user: Option<UserRecord> = sqlx::query_as("SELECT * FROM users WHERE id = ?")
        .bind(&user_id)
        .fetch_optional(&pool)
        .await
        .unwrap_or(None);

    let current = match current_user {
        Some(u) => u,
        None => {
            res.status_code(StatusCode::NOT_FOUND);
            res.render(Json(serde_json::json!({"code": "USER_NOT_FOUND", "message": "User not found"})));
            return;
        }
    };

    let new_nickname = body.nickname.or(current.nickname);
    let new_avatar = body.avatar.or(current.avatar);

    let _ = sqlx::query("UPDATE users SET nickname = ?, avatar = ?, updated_at = ? WHERE id = ?")
        .bind(&new_nickname)
        .bind(&new_avatar)
        .bind(now)
        .bind(&user_id)
        .execute(&pool)
        .await;

    res.render(Json(serde_json::json!({
        "status": "ok",
        "user": {
            "id": user_id,
            "username": current.username,
            "nickname": new_nickname.unwrap_or_default(),
            "avatar": new_avatar.unwrap_or_default(),
        }
    })));
}

#[handler]
pub async fn update_password(req: &mut Request, depot: &mut Depot, res: &mut Response) {
    let pool = match depot.get::<SqlitePool>("pool") {
        Ok(p) => p.clone(),
        Err(_) => {
            res.status_code(StatusCode::INTERNAL_SERVER_ERROR);
            res.render(Json(serde_json::json!({"code": "DB_UNAVAILABLE", "message": "Database pool not found"})));
            return;
        }
    };

    let user_id = match depot.get::<String>("user_id") {
        Ok(u) => u.clone(),
        Err(_) => {
            res.status_code(StatusCode::UNAUTHORIZED);
            return;
        }
    };
    let body = match req.parse_json::<UpdatePasswordRequest>().await {
        Ok(b) => b,
        Err(e) => {
            res.status_code(StatusCode::BAD_REQUEST);
            res.render(Json(serde_json::json!({"code": "INVALID_BODY", "message": format!("Invalid JSON: {e}")})));
            return;
        }
    };

    let user: Option<UserRecord> = sqlx::query_as("SELECT * FROM users WHERE id = ?")
        .bind(&user_id)
        .fetch_optional(&pool)
        .await
        .unwrap_or(None);

    let user = match user {
        Some(u) => u,
        None => {
            res.status_code(StatusCode::NOT_FOUND);
            res.render(Json(serde_json::json!({"code": "USER_NOT_FOUND", "message": "User not found"})));
            return;
        }
    };

    if user.password_hash != hash_password(&body.old_password) {
        res.status_code(StatusCode::UNAUTHORIZED);
        res.render(Json(serde_json::json!({"code": "WRONG_PASSWORD", "message": "Old password is incorrect"})));
        return;
    }

    let new_hash = hash_password(&body.new_password);
    let now = chrono::Utc::now().timestamp();
    let _ = sqlx::query("UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?")
        .bind(&new_hash)
        .bind(now)
        .bind(&user_id)
        .execute(&pool)
        .await;

    res.render(Json(serde_json::json!({
        "status": "ok",
        "message": "Password updated successfully"
    })));
}

#[handler]
pub async fn list_users(depot: &mut Depot, res: &mut Response) {
    let pool = match depot.get::<SqlitePool>("pool") {
        Ok(p) => p.clone(),
        Err(_) => {
            res.status_code(StatusCode::INTERNAL_SERVER_ERROR);
            res.render(Json(serde_json::json!({"code": "DB_UNAVAILABLE", "message": "Database pool not found"})));
            return;
        }
    };

    let records: Vec<UserRecord> = sqlx::query_as("SELECT * FROM users ORDER BY created_at ASC")
        .fetch_all(&pool)
        .await
        .unwrap_or_default();

    let dtos: Vec<UserPublicDto> = records.into_iter().map(|r| r.into()).collect();
    res.render(Json(serde_json::json!({
        "status": "ok",
        "users": dtos
    })));
}
