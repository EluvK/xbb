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
