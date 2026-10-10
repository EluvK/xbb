use salvo::http::StatusCode;
use salvo::prelude::*;
use sqlx::SqlitePool;
use super::models::PushRequest;
use super::service;

#[handler]
pub async fn sync_push(req: &mut Request, depot: &mut Depot, res: &mut Response) {
    let pool = match depot.get::<SqlitePool>("pool") {
        Ok(pool) => pool.clone(),
        Err(_) => {
            res.status_code(StatusCode::INTERNAL_SERVER_ERROR);
            res.render(Json(serde_json::json!({
                "code": "DB_POOL_ERROR",
                "message": "Database pool missing in request context"
            })));
            return;
        }
    };

    let user_id = match depot.get::<String>("user_id") {
        Ok(uid) => uid.clone(),
        Err(_) => {
            res.status_code(StatusCode::UNAUTHORIZED);
            return;
        }
    };

    let push_req: PushRequest = match req.parse_json().await {
        Ok(body) => body,
        Err(e) => {
            res.status_code(StatusCode::BAD_REQUEST);
            res.render(Json(serde_json::json!({
                "code": "BAD_REQUEST",
                "message": format!("Invalid JSON payload: {e}")
            })));
            return;
        }
    };

    match service::handle_push(&pool, &user_id, push_req).await {
        Ok(push_res) => {
            res.render(Json(push_res));
        }
        Err(e) => {
            tracing::error!("Failed to process push: {:?}", e);
            res.status_code(StatusCode::INTERNAL_SERVER_ERROR);
            res.render(Json(serde_json::json!({
                "code": "INTERNAL_ERROR",
                "message": e.to_string()
            })));
        }
    }
}

#[handler]
pub async fn sync_pull(req: &mut Request, depot: &mut Depot, res: &mut Response) {
    let pool = match depot.get::<SqlitePool>("pool") {
        Ok(pool) => pool.clone(),
        Err(_) => {
            res.status_code(StatusCode::INTERNAL_SERVER_ERROR);
            res.render(Json(serde_json::json!({
                "code": "DB_POOL_ERROR",
                "message": "Database pool missing in request context"
            })));
            return;
        }
    };

    let user_id = match depot.get::<String>("user_id") {
        Ok(uid) => uid.clone(),
        Err(_) => {
            res.status_code(StatusCode::UNAUTHORIZED);
            return;
        }
    };

    let checkpoint = req.query::<i64>("checkpoint").unwrap_or(0);
    let limit = req.query::<i64>("limit").unwrap_or(200);

    match service::handle_pull(&pool, &user_id, checkpoint, limit).await {
        Ok(pull_res) => {
            res.render(Json(pull_res));
        }
        Err(e) => {
            tracing::error!("Failed to process pull: {:?}", e);
            res.status_code(StatusCode::INTERNAL_SERVER_ERROR);
            res.render(Json(serde_json::json!({
                "code": "INTERNAL_ERROR",
                "message": e.to_string()
            })));
        }
    }
}
