# Server Agent Guidelines (Sync Service)

## Overview
基于 Rust 构建的高性能同步服务 (`server/src/main.rs`)，采用 Salvo HTTP 框架 + SQLite (sqlx) + tokio 异步运行时，提供 `/sync/v1` 变更流协议服务。

## Code Structure (`server/src/`)
- `main.rs`: 服务入口、配置加载、HTTP 服务监听启动。
- `router.rs`: Salvo 路由挂载、版本分发、接口拦截。
- `sync/*`:
  - `handlers.rs`: `/sync/v1/push` (CAS 乐观锁变更提交) 与 `/sync/v1/pull` (序列号 changelog 流式拉取) 请求处理。
  - `service.rs`: 核心同步事务逻辑、ACL 鉴权与变更序列推进。
  - `models.rs`: 同步请求/响应协议结构体定义。
- `storage/*`: SQLite 连接池管理与数据库初始化迁移。
- `auth.rs`: JWT 认证中间件与 Token 编解码。
- `user.rs`: 用户身份体系与密码哈希处理。

## Invariants & Critical Rules
- **CAS Mutations**: 接收客户端 push 变更时，必须通过 CAS 检查进行乐观并发控制，防止数据覆盖。
- **Monotonic Sequence**: changelog 必须严格按自增序列号 (`seq`) 递增分配并提供增量拉取支持。
- **Database Pool & Transactions**: 数据库写操作与变更记录必须置于单一事务中，使用 sqlx SQLite 连接池（WAL 模式）。
- **Authentication**: 受保护的端点必须经过 JWT 认证中间件校验，严格隔离用户权限与租户数据。

## Testing & Verification
- 单元与集成测试：`cargo test`
- 编译与静态检查：`cargo check` / `cargo clippy`
