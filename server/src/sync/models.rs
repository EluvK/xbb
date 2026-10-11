use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Mutation {
    pub table: String,
    pub id: String,
    pub op: String, // "PUT" | "DELETE"
    #[serde(default)]
    pub data: Option<serde_json::Value>,
    #[serde(default)]
    pub base_version: i64,
    #[serde(default)]
    pub client_timestamp: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PushRequest {
    pub client_id: String,
    pub mutations: Vec<Mutation>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ConflictItem {
    pub id: String,
    pub reason: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub server_version: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub current_data: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct PushResponse {
    pub applied_ids: Vec<String>,
    pub conflicts: Vec<ConflictItem>,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct PullQuery {
    #[serde(default)]
    pub checkpoint: Option<i64>,
    #[serde(default)]
    pub limit: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ChangeItem {
    pub seq: i64,
    pub table: String,
    pub id: String,
    pub op: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<serde_json::Value>,
    pub version: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub owner_id: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub created_at: Option<i64>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct PullResponse {
    pub checkpoint: i64,
    pub has_more: bool,
    pub changes: Vec<ChangeItem>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AclGrantRequest {
    pub table: String,
    pub entity_id: String,
    pub grantee_id: String,
    pub permission: String, // "READ" | "WRITE"
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AclRevokeRequest {
    pub table: String,
    pub entity_id: String,
    pub grantee_id: String,
}
