# SyncStore Protocol & Synchronization Engine

## 1. Overview & Evolution
The synchronization subsystem has evolved from legacy REST endpoints (`/data`, `/batch-data`) into a modern, log-stream synchronization architecture (**Sync v2**). 

The backend is implemented in **Rust** (Salvo + SQLite + sqlx) under `server/`, while the client uses a **Local-First Outbox Engine** managed by `SyncWorker` under `app/lib/sync/v2/`. Legacy client requests to obsolete paths are intercepted and returned with HTTP 426 (`CLIENT_UPGRADE_REQUIRED`).

---

## 2. Client Local-First Architecture

### 2.1 Unified Database & Transactional Outbox (ADR-0004)
- **Database Path**: `<db_dir>/<user_id>/app_v2.db` for authenticated users; in-memory SQLite (`openInMemory()`) for guests.
- **Transactional Outbox**: All local business mutations (create, update, delete) execute within a single atomic SQLite transaction alongside the `outbox` table (`LocalFirstDB.saveEntityWithOutbox` / `persistPutRaw`).
- **Zero Data Loss**: If the app is terminated or offline, pending mutations remain safely persisted in the outbox.

### 2.2 SyncWorker Background Daemon
- **Singleton Lifecycle**: Initialized in `main.dart`; runs a continuous background polling loop (default 15s interval).
- **Instant Wakeups**:
  - `notifyLocalWrite()`: Triggered immediately whenever local UI writes occur.
  - `notifyNetworkRestored()`: Triggered when network connectivity is re-established.
- **Concurrency Control**: Serialized sync cycles protected by a mutual exclusion lock with pending-trigger accumulation (debouncing).

### 2.3 Outbox Coalescing
Before pushing to the server, `SyncWorker` collapses multiple pending mutations for the same `(table, entityId)` pair within a batch:
- Emits only the latest payload state.
- Preserves the batch's initial `baseVersion` to avoid intra-batch CAS version conflicts.

---

## 3. Protocol Endpoints (`/sync/v1`)

All sync endpoints require JWT authentication (`Authorization: Bearer <token>`).

### 3.1 WhoAmI
- **Endpoint**: `GET /sync/v1/whoami`
- **Response**: `{"user_id": "...", "status": "ok"}`

### 3.2 Push Mutations (`/sync/v1/push`)
- **Endpoint**: `POST /sync/v1/push`
- **Request Body (`SyncPushRequest`)**:
  ```json
  {
    "client_id": "uuid-v4",
    "mutations": [
      {
        "table": "post",
        "id": "post-id",
        "op": "put",
        "data": { ... },
        "base_version": 1,
        "client_timestamp": "2026-10-12T00:00:00Z"
      }
    ]
  }
  ```
- **Response Body (`SyncPushResponse`)**:
  ```json
  {
    "applied_ids": ["post-id"],
    "conflicts": [
      {
        "id": "conflicted-id",
        "server_version": 3,
        "current_data": { ... }
      }
    ]
  }
  ```
- **Conflict Resolution**: Optimistic Concurrency Control via CAS (Compare-And-Swap). When `base_version` mismatches the server's record, the server returns the latest authoritative data, which the client applies locally to reconcile.

### 3.3 Pull Remote Changes (`/sync/v1/pull`)
- **Endpoint**: `GET /sync/v1/pull?seq={last_seq}&limit=100`
- **Response Body (`SyncPullResponse`)**:
  ```json
  {
    "changes": [
      {
        "seq": 1042,
        "table": "post",
        "id": "post-id",
        "op": "put",
        "version": 2,
        "data": { ... },
        "timestamp": "2026-10-12T00:00:00Z"
      }
    ],
    "has_more": false,
    "next_seq": 1042
  }
  ```
- **Replay**: Client applies received changes into the local database in a single transaction and advances `sync_meta.last_seq`.

### 3.4 Access Control (`/sync/v1/acl/*`)
- **Grant**: `POST /sync/v1/acl/grant`
- **Revoke**: `POST /sync/v1/acl/revoke`
- Controls access permissions based on 6-bit `ACLMask` flags.

---

## 4. Legacy Data Migration (`LegacyDataMigrator`)

To support existing users smoothly without data loss:
- `LegacyDataMigrator` scans for historical database files (`notes.db`, `task.db`, `tracker.db`, `checkin.db`, `clipboard.db`, `chat.db`) and legacy table prefixes (e.g. `c_*`).
- Extracted records are normalized and imported into `app_v2.db`.

---

## 5. Key Source Paths

- **Client Sync Engine**: `app/lib/sync/v2/`
  - `sync_worker.dart`: Background daemon and sync lifecycle
  - `local_first_db.dart`: Transactional database and table initialization
  - `outbox_dao.dart`: Local Outbox queue persistence
  - `sync_meta_dao.dart`: Sequence cursor tracking (`last_seq`)
  - `legacy_data_migrator.dart`: One-time legacy database migration
- **Server Sync Backend**: `server/src/`
  - `router.rs`: Routing table and 426 legacy interception
  - `sync/service.rs`, `sync/handlers.rs`: Push, Pull, and CAS conflict engine
  - `storage/`: Server SQLite pool and migrations
