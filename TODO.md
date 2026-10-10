# xbb Monorepo & 新一代通用同步架构演进执行蓝图 (TODO.md)

本文档是整个系统重构的权威执行规范。目标是将当前仓库改造为 Monorepo、从零构建业务无关的新一代 Rust 同步服务端（基于 ChangeLog 变更流）、并在客户端全面重构为 Local-First 架构（彻底解耦业务关系、淘汰 GetX、平滑数据迁移）。

---

## 第一部分：原子化执行任务清单（Agent 任务分派序列）

每个任务项均设计为自包含任务，可独立派发给 Subagent 执行，请严格按先后依赖顺序推进。

### 阶段一：Monorepo 目录划分与环境重组

- [x] **TASK-1.1: 仓库根目录重构与 Flutter App 迁移**
  - **依赖**: 无
  - **工作内容**:
    1. 在根目录下新建 `app/` 目录。
    2. 将除 `TODO.md`、`.git/`、`.gitignore` 外的所有客户端相关文件/目录（包括 `lib/`, `packages/`, `android/`, `macos/`, `windows/`, `assets/`, `pubspec.*`, `analysis_options.yaml` 等）迁移到 `app/` 目录下。
    3. 修复 `app/` 内部相对路径依赖（检查 `pubspec.yaml` 中各内部 package 引用）。
  - **验收标准**: 在 `app/` 目录下执行 `flutter pub get` 与 `flutter test`（若有）通过，无文件丢失。

- [x] **TASK-1.2: 初始化全新 Rust 服务端工程**
  - **依赖**: TASK-1.1
  - **工作内容**:
    1. 在根目录下新建 `server/` 目录，初始化 Cargo 项目（使用 Salvo 或 Axum，推荐 Salvo 与现有技术栈对齐，集成 tokio, sqlx/rusqlite, serde, tracing, jsonwebtoken）。
    2. 配置根目录 `.gitignore`，纳入 `server/target/` 及 `server/data/`。
  - **验收标准**: 在 `server/` 目录下执行 `cargo check` 无错误。

---

### 阶段二：全新 Rust 服务端核心实现（业务无关变更流引擎）

- [x] **TASK-2.1: 存储层表结构与基础数据库连接**
  - **依赖**: TASK-1.2
  - **工作内容**:
    1. 在 `server/src/storage/` 建立 SQLite 连接池（启用 WAL 模式）。
    2. 初始化三张核心数据表：
       - `entities`: 存储当前业务实体最新快照 (`table_name`, `id`, `owner_id`, `data`, `version`, `updated_at`)。
       - `change_log`: 单调自增变更流水 (`seq AUTOINCREMENT`, `table_name`, `entity_id`, `owner_id`, `op`, `data`, `created_at`)。
       - `acls`: 细粒度实体授权 (`table_name`, `entity_id`, `user_id`, `permission`)。
  - **验收标准**: 单元测试验证表自动建表成功，支持高并发读写。

- [x] **TASK-2.2: 基础鉴权与旧版更新通道兼容路由**
  - **依赖**: TASK-2.1
  - **工作内容**:
    1. 实现极简标准的 Bearer JWT 认证中间件，提取 `user_id`（移除 HPKE）。
    2. **旧版客户端升级通道保持兼容**：挂载 `/fs/public/{app}/version` 与 `/fs/public/{app}/CHANGELOG` 静态文件服务。
    3. **老接口优雅拦截**：对所有匹配 `/data/*`、`/batch-data/*` 的旧路径，一律返回 HTTP 426 (Upgrade Required)，附带清晰 JSON 升级提示。
  - **验收标准**: curl 测试 `/fs/public/...` 正常返回，访问 `/data/...` 返回 426。

- [x] **TASK-2.3: 实现提交变更接口 `POST /sync/v1/push`**
  - **依赖**: TASK-2.1, TASK-2.2
  - **工作内容**:
    1. 解析 `PushRequest`（包含 `client_id`, `mutations: [{ table, id, op, data, base_version }]`）。
    2. 实现**写策略守卫（Policy Guard）**拦截管线：校验用户对目标资源的写入权限。
    3. 实现**乐观锁版本仲裁（CAS）**：
       - 若 `base_version` 与服务端当前 `version` 一致：更新 `entities`（`version + 1`），并在同一事务写入 `change_log`，生成单调递增 `seq`。
       - 若版本不一致：标记为 `CONFLICT`，返回服务端当前最新快照。
  - **验收标准**: 编写集成测试，覆盖单次提交、批量提交、并发版本冲突（CAS 拦截）场景。

- [x] **TASK-2.4: 实现增量拉取接口 `GET /sync/v1/pull`**
  - **依赖**: TASK-2.3
  - **工作内容**:
    1. 接收 `checkpoint`（即 `since_seq`）与 `limit`（默认 200，上限 1000）。
    2. 实现**读投影过滤（Projection Filter）**：在数据库层面高效过滤：
       `seq > checkpoint AND (owner_id = user_id OR EXISTS(SELECT 1 FROM acls ...))`。
    3. 原生支持下发软删除（`op = DELETE`）墓碑记录。
  - **验收标准**: 集成测试验证增量查询分页、多用户数据隔离、删除记录正常下发。

- [x] **TASK-2.5: 实现动态 ACL 授权转化为变更事件机制**
  - **依赖**: TASK-2.4
  - **工作内容**:
    1. 实现 ACL 变更接口（`POST /sync/v1/acl/grant` 和 `revoke`）。
    2. **晚期授权解决机制**：在授权给新用户时，事务内往 `acls` 插入记录的同时，向 `change_log` 追加一条带有实体最新快照的全新 `PUT` 事件（生成当前最新 `seq`）。
    3. 撤权时追加一条 `DELETE` 投影事件。
  - **验收标准**: 单元测试模拟“用户 B 先同步完、A 之后授权 B、B 再次增量 Pull 能够无缝拉到历史数据”。

- [ ] **TASK-2.6: 编写存量数据迁移工具（`migrate_legacy`）**
  - **依赖**: TASK-2.5
  - **工作内容**:
    1. 在 `server/src/bin/migrate_legacy.rs` 编写离线数据迁移 CLI。
    2. 读取老版本各个 SQLite 数据库中的 `c_{collection}` 与 `__acls`。
    3. 转换并批量插入到新库的 `entities`，并按时间生成连续自增的初始 `change_log`（`seq = 1..N`）。
  - **验收标准**: 跑测试数据库迁移，迁移后验证 `entities` 和 `change_log` 完整且一致。

---

### 阶段三：客户端 Local-First 核心与平滑迁移层

- [ ] **TASK-3.1: 客户端彻底清理老旧网络与生成器依赖**
  - **依赖**: TASK-1.1
  - **工作内容**:
    1. 移除 `packages/syncstore_client` 中的 `HpkeInterceptor` 与 `ConcurrentChunkInterceptor`。
    2. 移除客户端对 RFC 9180 HPKE 手写实现的依赖。
    3. 简化网络客户端为标准 Dio，只挂载标准 Bearer JWT 拦截器。
  - **验收标准**: `app/` 编译成功，无 HPKE 及分片相关残留。

- [ ] **TASK-3.2: 建立本地 Local-First 数据库与 Outbox 表结构**
  - **依赖**: TASK-3.1
  - **工作内容**:
    1. 引入/确认本地 SQLite 支持（推荐使用 Drift 或继续扩展 sqflite 体系）。
    2. 建立本地 `outbox` 待发变更队列表：
       `id, table_name, entity_id, op, data, base_version, created_at`。
    3. 建立本地元数据状态表 `sync_meta`：记录 `last_seq`（同步检查点游标）。
    4. 引入纯 Dart 的 `uuid` v7 生成器，客户端新增数据本地直接生成权威 UUIDv7。
  - **验收标准**: 本地写入测试：事务内同时插入业务表与 `outbox`。

- [ ] **TASK-3.3: 实现老客户端数据自愈平滑迁移（One-time Bootstrap）**
  - **依赖**: TASK-3.2
  - **工作内容**:
    1. 编写客户端首次升级检测逻辑（通过版本号或 DB flag 判定）。
    2. 扫描本地所有旧业务表：
       - 将所有 `sync_status IN ('pending', 'failed')` 的记录转换为 `outbox` 中的待发 `PUT` 记录。
       - 已同步/归档记录完整保留在本地表中，不作删除。
       - 将 `sync_meta.last_seq` 置为 0。
  - **验收标准**: 单元测试模拟存量 `failed` 数据在升级后成功进入 `outbox`，且本地业务数据 0 丢失。

- [ ] **TASK-3.4: 实现全局单例 `SyncWorker`**
  - **依赖**: TASK-3.2, TASK-2.4
  - **工作内容**:
    1. 编写后台守护 `SyncWorker`（支持定时轮询、网络恢复唤醒、本地写入唤醒）：
       - Push 流程：读取 `outbox`，调用 `/sync/v1/push`，成功后从 `outbox` 批量清除已确认 ID。
       - Pull 流程：带上 `last_seq` 调用 `/sync/v1/pull`，本地事务内批量回放 `changes` 到本地业务表，并推进 `last_seq`。
    2. 优雅处理 `426 Upgrade Required` 响应（弹窗引导用户升级）。
  - **验收标准**: 端到端测试客户端离线写入出队、连网后 Push 成功、Pull 拉回其他端变更。

---

### 阶段四：业务解耦与彻底剥离 GetX

- [ ] **TASK-4.1: 解除父子关系对网络层的依赖**
  - **依赖**: TASK-3.2
  - **工作内容**:
    1. 改造笔记（Repo/Post/Comment）、聊天（Conversation/Message）的查询逻辑。
    2. 将原有的 `syncChildren`、`by_parent_ids` 网络请求彻底删除，改为纯本地 SQL 查询：
       `SELECT * FROM post WHERE repo_id = ? ORDER BY created_at DESC`。
  - **验收标准**: 断网状态下，在笔记本之间切换，笔记列表依旧瞬间渲染呈现。

- [ ] **TASK-4.2: 废除 `sync_generator` 中越界的 Controller 代码生成**
  - **依赖**: TASK-4.1
  - **工作内容**:
    1. 移除 `sync_generator` 中生成 `GetxController`、`_SyncEngine` 以及 ACL 同步扩展的代码。
    2. 移除对业务模型上 `withAcls` 等特化注解参数的依赖。
  - **验收标准**: 运行 build_runner 仅生成纯净的模型映射与数据表定义。

- [ ] **TASK-4.3: 逐模块重构与彻底淘汰 GetX**
  - **依赖**: TASK-4.2
  - **工作内容**:
    将各业务模块的 Controller 改造为轻量状态管理（推荐统一的无侵入方案，例如 Riverpod / 响应式 SQLite Query Stream）：
    1. 重构 Task 模块。
    2. 重构 Checkin 模块。
    3. 重构 Notes 模块。
    4. 重构 Tracker & Clipboard 模块。
    5. 重构 Chat 模块。
    6. 彻底移除 `Get.put`, `Get.find`, `GetxController` 依赖，从 `pubspec.yaml` 中彻底卸载 `get` 库。
  - **验收标准**: 全局搜索代码库，零 `import 'package:get/...'` 引用，全模块运行正常。

---

## 第二部分：技术落地实现标准规范（Implementation Guide）

### 1. 协议规范定义 (Protocol Spec)

所有的请求均携带标准 HTTP Header: `Authorization: Bearer <jwt_token>`。

#### (1) `POST /sync/v1/push`
* **Request**:
  ```json
  {
    "client_id": "device-uuid-xxxx",
    "mutations": [
      {
        "table": "post",
        "id": "018f2d50-xxxx-7xxx-axxx-xxxxxxxxxxxx",
        "op": "PUT",
        "data": { "repo_id": "r-01", "title": "标题", "content": "内容" },
        "base_version": 1,
        "client_timestamp": 1728550000000
      },
      {
        "table": "post",
        "id": "018f2d50-yyyy-7xxx-bxxx-xxxxxxxxxxxx",
        "op": "DELETE",
        "base_version": 3,
        "client_timestamp": 1728550001000
      }
    ]
  }
  ```
* **Response (200 OK)**:
  ```json
  {
    "applied_ids": ["018f2d50-xxxx-7xxx-axxx-xxxxxxxxxxxx"],
    "conflicts": [
      {
        "id": "018f2d50-yyyy-7xxx-bxxx-xxxxxxxxxxxx",
        "reason": "VERSION_MISMATCH",
        "server_version": 4,
        "current_data": { "repo_id": "r-01", "title": "远程更新后的标题" }
      }
    ]
  }
  ```

#### (2) `GET /sync/v1/pull?checkpoint=100&limit=200`
* **Response (200 OK)**:
  ```json
  {
    "checkpoint": 105,
    "has_more": false,
    "changes": [
      {
        "seq": 101,
        "table": "post",
        "id": "018f2d50-xxxx-7xxx-axxx-xxxxxxxxxxxx",
        "op": "PUT",
        "data": { "repo_id": "r-01", "title": "标题", "content": "内容" },
        "version": 2
      },
      {
        "seq": 102,
        "table": "post",
        "id": "018f2d50-zzzz-7xxx-cxxx-xxxxxxxxxxxx",
        "op": "DELETE",
        "version": 4
      }
    ]
  }
  ```

---

### 2. 服务端核心 SQL DDL 规范

```sql
-- 开启 WAL 模式以提升并发写日志性能
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

-- 实体主数据（当前版本快照）
CREATE TABLE IF NOT EXISTS entities (
    table_name TEXT NOT NULL,
    id TEXT NOT NULL,
    owner_id TEXT NOT NULL,
    data TEXT NOT NULL,           -- JSON 字符串
    version INTEGER NOT NULL DEFAULT 1,
    updated_at INTEGER NOT NULL,
    PRIMARY KEY (table_name, id)
);

CREATE INDEX IF NOT EXISTS idx_entities_owner ON entities (owner_id);

-- 单调自增变更流日志
CREATE TABLE IF NOT EXISTS change_log (
    seq INTEGER PRIMARY KEY AUTOINCREMENT,
    table_name TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    owner_id TEXT NOT NULL,
    op TEXT NOT NULL,              -- 'PUT' | 'DELETE'
    data TEXT,                    -- op = 'DELETE' 时为空
    version INTEGER NOT NULL,
    created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_change_log_seq_owner ON change_log (seq, owner_id);

-- 细粒度权限表
CREATE TABLE IF NOT EXISTS acls (
    table_name TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    permission TEXT NOT NULL,     -- 'READ' | 'WRITE'
    PRIMARY KEY (table_name, entity_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_acls_user ON acls (user_id, table_name, entity_id);
```

---

### 3. 动态 ACL 晚期授权处理规范

当用户 A 将某一实体（如 `post-1`）授权给用户 B 时，服务端处理逻辑严格如下：

```rust
pub async fn grant_permission(
    tx: &mut Transaction,
    table_name: &str,
    entity_id: &str,
    grantee_id: &str,
    perm: &str,
) -> Result<()> {
    // 1. 插入 acls 授权表
    sqlx::query("INSERT OR REPLACE INTO acls (table_name, entity_id, user_id, permission) VALUES (?, ?, ?, ?)")
        .bind(table_name).bind(entity_id).bind(grantee_id).bind(perm)
        .execute(&mut **tx).await?;

    // 2. 获取当前实体最新快照
    let entity = sqlx::query_as::<_, EntityRow>("SELECT * FROM entities WHERE table_name = ? AND id = ?")
        .bind(table_name).bind(entity_id)
        .fetch_one(&mut **tx).await?;

    // 3. 核心：在 change_log 末尾追加一条全新带快照的 PUT 事件！
    // 这保证了即便被授权者 checkpoint 已经很高，该新增事件的 seq 一定更大，下次 pull 必定能被拉取到。
    sqlx::query(
        "INSERT INTO change_log (table_name, entity_id, owner_id, op, data, version, created_at) \
         VALUES (?, ?, ?, 'PUT', ?, ?, ?)"
    )
    .bind(table_name)
    .bind(entity_id)
    .bind(&entity.owner_id)
    .bind(&entity.data)
    .bind(entity.version)
    .bind(chrono::Utc::now().timestamp_millis())
    .execute(&mut **tx).await?;

    Ok(())
}
```

---

### 4. 客户端数据自愈与 Outbox 模式规范

#### 本地 Outbox 表结构
```sql
CREATE TABLE IF NOT EXISTS outbox (
    id TEXT PRIMARY KEY,          -- 本地变更事件 UUID
    table_name TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    op TEXT NOT NULL,             -- 'PUT' | 'DELETE'
    data TEXT,
    base_version INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS sync_meta (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
-- 存一条 ('last_seq', '0')
```

#### 升级自愈迁移逻辑伪代码 (Dart)
```dart
Future<void> migrateLegacyClientDataIfNeeded(Database db) async {
  final hasMigrated = await db.rawQuery("SELECT value FROM sync_meta WHERE key = 'legacy_migrated'");
  if (hasMigrated.isNotEmpty) return;

  await db.transaction((txn) async {
    // 遍历所有老业务表 (例如 notes, posts, tasks, trackers 等)
    for (final table in ['c_repo', 'c_post', 'c_comment', 'c_task', 'c_tracker']) {
      final rows = await txn.rawQuery("SELECT * FROM $table WHERE sync_status IN ('pending', 'failed')");
      for (final row in rows) {
        await txn.insert('outbox', {
          'id': const Uuid().v4(),
          'table_name': table.replaceFirst('c_', ''),
          'entity_id': row['id'],
          'op': 'PUT',
          'data': row['body'],
          'base_version': 1,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    }
    await txn.insert('sync_meta', {'key': 'last_seq', 'value': '0'});
    await txn.insert('sync_meta', {'key': 'legacy_migrated', 'value': 'true'});
  });
}
```

---

### 5. 旧版本兼容与割接路由规范

新 Rust 服务端路由组织规范：

```rust
pub fn create_app_router() -> Router {
    Router::new()
        // 1. 公开的 App 更新通道（与老客户端完全一致，保证老 App 能检测更新并下载）
        .push(Router::with_path("fs/public/{app}/version").get(handlers::app_version))
        .push(Router::with_path("fs/public/{app}/CHANGELOG").get(handlers::app_changelog))
        .push(Router::with_path("fs/public/{app}/download").get(handlers::app_download))

        // 2. 新一代日志流同步接口
        .push(
            Router::with_path("sync/v1")
                .hoop(auth_middleware)
                .push(Router::with_path("push").post(handlers::sync_push))
                .push(Router::with_path("pull").get(handlers::sync_pull))
                .push(Router::with_path("acl/grant").post(handlers::acl_grant))
                .push(Router::with_path("acl/revoke").post(handlers::acl_revoke))
        )

        // 3. 针对旧客户端同步接口的统一优雅拦截 (返回 426)
        .push(Router::with_path("data/{**rest}").get(deprecated_handler).post(deprecated_handler).delete(deprecated_handler))
        .push(Router::with_path("batch-data/{**rest}").post(deprecated_handler))
}

async fn deprecated_handler(res: &mut Response) {
    res.status_code(StatusCode::UPGRADE_REQUIRED);
    res.render(Json(serde_json::json!({
        "code": "CLIENT_UPGRADE_REQUIRED",
        "message": "当前客户端同步协议已废弃，请升级到最新应用版本。"
    })));
}
```
