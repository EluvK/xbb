use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use salvo::http::StatusCode;
use salvo::prelude::*;
use serde::{Deserialize, Serialize};

pub const DEFAULT_JWT_SECRET: &str = "xbb-sync-secret-key-2026";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: Option<String>,
    pub user_id: Option<String>,
    pub exp: Option<usize>,
}

impl Claims {
    pub fn new(user_id: impl Into<String>) -> Self {
        let uid = user_id.into();
        Self {
            sub: Some(uid.clone()),
            user_id: Some(uid),
            exp: Some(
                chrono::Utc::now()
                    .checked_add_signed(chrono::Duration::days(365))
                    .unwrap()
                    .timestamp() as usize,
            ),
        }
    }

    pub fn get_user_id(&self) -> Option<&str> {
        self.user_id.as_deref().or(self.sub.as_deref())
    }
}

pub fn create_jwt_token(user_id: &str, secret: &str) -> Result<String, jsonwebtoken::errors::Error> {
    let claims = Claims::new(user_id);
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
}

#[derive(Clone)]
pub struct AuthMiddleware {
    pub secret: String,
}

impl AuthMiddleware {
    pub fn new(secret: impl Into<String>) -> Self {
        Self {
            secret: secret.into(),
        }
    }
}

impl Default for AuthMiddleware {
    fn default() -> Self {
        let secret = std::env::var("JWT_SECRET").unwrap_or_else(|_| DEFAULT_JWT_SECRET.to_string());
        Self::new(secret)
    }
}

#[handler]
impl AuthMiddleware {
    async fn handle(&self, req: &mut Request, depot: &mut Depot, res: &mut Response, ctrl: &mut FlowCtrl) {
        let auth_header = req
            .headers()
            .get("Authorization")
            .and_then(|v| v.to_str().ok());

        let token = match auth_header {
            Some(header) if header.starts_with("Bearer ") => &header[7..],
            _ => {
                res.status_code(StatusCode::UNAUTHORIZED);
                res.render(Json(serde_json::json!({
                    "code": "UNAUTHORIZED",
                    "message": "Missing or invalid Bearer token"
                })));
                ctrl.skip_rest();
                return;
            }
        };

        let mut validation = Validation::default();
        validation.validate_exp = false; // 宽松过期验证以保证离线或长效客户端测试
        match decode::<Claims>(
            token,
            &DecodingKey::from_secret(self.secret.as_bytes()),
            &validation,
        ) {
            Ok(token_data) => {
                if let Some(user_id) = token_data.claims.get_user_id() {
                    depot.insert("user_id", user_id.to_string());
                    ctrl.call_next(req, depot, res).await;
                } else {
                    res.status_code(StatusCode::UNAUTHORIZED);
                    res.render(Json(serde_json::json!({
                        "code": "UNAUTHORIZED",
                        "message": "Invalid claims: user_id missing"
                    })));
                    ctrl.skip_rest();
                }
            }
            Err(e) => {
                tracing::warn!("JWT verification failed: {:?}", e);
                res.status_code(StatusCode::UNAUTHORIZED);
                res.render(Json(serde_json::json!({
                    "code": "UNAUTHORIZED",
                    "message": "Token verification failed"
                })));
                ctrl.skip_rest();
            }
        }
    }
}
