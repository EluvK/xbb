# 架构决策索引 (ADRs)

本项目重要技术选型、架构形态与反直觉约束索引。新功能设计前请先查阅，严禁无意识违背既有决策。

---

- [ADR-0001: SQLite 按用户 ID 物理目录隔离](./0001-user-isolated-sqlite.md) — 采用 `<db_dir>/<user_id>/app_v2.db` 保证多账号隔离与单事务原子落盘，未登录使用纯内存库。
- [ADR-0002: 剪贴板本地优先与绝对隐私同步](./0002-clipboard-local-first-privacy.md) — 桌面后台全局捕获默认 `localOnly=true`，完全禁止自动双写，必须由用户显式确认上云。
- [ADR-0003: 打卡本地时区单次判定与禁止预打卡](./0003-checkin-local-day-boundary.md) — 以设备本地日期 `localDayKey` 限制单日单次，允许补打卡但严禁未来预打卡。
- [ADR-0004: Drift 响应式存储与单事务 Outbox 日志流持久化](./0004-drift-outbox-storage.md) — 采用 Drift 强类型 Schema 与单事务同时写入业务表与 Outbox 队列，实现 Local-First 零数据丢失。
- [ADR-0005: 采用 Riverpod 替代 GetX 作为全局状态管理底座](./0005-riverpod-state-management.md) — 彻底废弃 GetX，采用 Riverpod 注解驱动与依赖注入，保证生命周期安全与单测隔离。
- [ADR-0006: 桌面系统集成全面采用成熟生态库替代手写原生 C++](./0006-standard-desktop-integration.md) — 引入 `tray_manager` 与 `window_manager`，跨平台赋能 Windows/macOS/Linux 无边框窗口与托盘驻留。
- [ADR-0007: 基于稳定块标识的树状批注系统](./0007-stable-block-comments.md) — 基于稳定段落/块唯一标识绑定批注树，彻底消除纯文本 Hash 失效导致的孤儿评论。
