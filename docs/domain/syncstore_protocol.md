# SyncStore Protocol

## 1. Overview
SyncServer is the central server responsible for cloud synchronization, multi-client consistency, and data persistence. The client and server communicate via the SyncStore protocol, which abstracts heterogeneous schema types behind unified data envelopes and REST-like CRUD operations.

---

## 2. Generic Envelope: `DataItem<T>`

Every synchronized business object is wrapped in a `DataItem<T>` envelope:

| Field | Type | Description |
|---|---|---|
| `id` | `String` (UUID v4) | Unique entity identifier across client and server. |
| `owner` | `String` | User ID of the owner. |
| `parentId` | `String?` | Optional parent entity ID establishing a tree hierarchy (e.g., Post -> Repo, Comment -> Post). |
| `unique` | `String?` | Domain uniqueness or idempotency token. |
| `createdAt` | `DateTime` (UTC) | Creation timestamp. |
| `updatedAt` | `DateTime` (UTC) | Last modified timestamp on the server. |
| `syncStatus` | `SyncStatus` | Local sync lifecycle state (`pending`, `syncing`, `synced`, `failed`, `deleted`, `hidden`, `archived`). |
| `colorTag` | `ColorTag` | Client-side categorization tag (`none`, `red`, `orange`, `yellow`, `green`, `blue`, `gray`). |
| `body` | `T` | The typed business payload. |

---

## 3. Protocol Endpoints

All data operations are keyed by `/{namespace}/{collection}`:

- Create: `POST /data/{namespace}/{collection}` -> Returns created entity ID (`String`).
- Get: `GET /data/{namespace}/{collection}/{id}` -> Returns `DataItem<T>`.
- Batch Get: `POST /batch-data/{namespace}/{collection}/by_ids` (`{"ids": [...]}`) -> Returns `BatchGetResponse<T>`.
- List: `GET /data/{namespace}/{collection}?parent_id=...&marker=...&limit=...` -> Returns `ListResponse` containing `DataItemSummary` list and `PageInfo` (with `nextMarker`).
- Batch List Children: `POST /batch-data/{namespace}/{collection}/by_parent_ids` (`{"ids": [...]}`) -> Returns `ListResponse`.
- Update: `POST /data/{namespace}/{collection}/{id}` -> Overwrites remote body.
- Delete: `DELETE /data/{namespace}/{collection}/{id}` -> Remote deletion.

---

## 4. Access Control List (ACL)

A 6-bit mask representation controls access permissions:

| Access Level | Mask | Value | Semantics |
|---|---|---|---|
| `read` | `readOnly` | `0x01` | Read the entity. |
| `update` | `readOnly \| updateOnly` | `0x03` | Read and edit the entity. |
| `append3Below` | `readOnly \| append3Below` | `0x09` | Append sub-items up to 3 tiers down. |
| `append2Below` | `readOnly \| append2Below` | `0x19` | Append sub-items up to 2 tiers down. |
| `append1Below` | `readOnly \| append1Below` | `0x39` | Append immediate children. |
| `write` | `read \| update \| append1Below` | `0x3B` | Edit entity and append immediate children. |
| `fullAccess` | `fullAccess` | `0x3F` | Total control (delete, permission delegation). |

Local persistence creates an `acl` table:
```sql
CREATE TABLE IF NOT EXISTS acl (
  data_id TEXT PRIMARY KEY,
  data_collection TEXT NOT NULL,
  permissions TEXT NOT NULL
);
```

Server endpoints:
- `GET /acl/{namespace}/{collection}/{id}`
- `POST /acl/{namespace}/{collection}/{id}` (`{"permissions": [...]}`)
- `DELETE /acl/{namespace}/{collection}/{id}`

---

## 5. Security & Transport Interceptors

- AuthInterceptor: Injects `Authorization: Bearer <token>`. Intercepts 401 status, executes a single-flight mutex to call `/auth/refresh`, updates `TokenStorage`, and replays failed requests.
- HpkeInterceptor: Transparent hybrid public key encryption (RFC 9180) based on user public keys fetched at `/user/profile/{userId}`.
- ConcurrentChunkInterceptor: Chunks large encrypted binary payloads for reliable concurrent transfers.
- Health Check & Ping: Health checks ping `/health` via `pingLatencyMs()`. If ping fails (`< 0`), local-first features gracefully skip network sync.
