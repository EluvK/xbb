# 架构决策索引 (ADRs)

本项目重要技术选型、架构形态与反直觉约束索引。新功能设计前请先查阅，严禁无意识违背既有决策。

---

- [ADR-0001: SQLite 按用户 ID 物理分库隔离](./0001-user-isolated-sqlite.md) — 采用 `<db_dir>/<user_id>/<feature>.db` 彻底消除多账号串扰并支持原子级注销清理。
- [ADR-0002: 剪贴板本地优先与绝对隐私同步](./0002-clipboard-local-first-privacy.md) — Windows 全局捕获默认 `localOnly=true`，完全禁止自动双写，必须由用户显式确认上云。
- [ADR-0003: 打卡本地时区单次判定与禁止预打卡](./0003-checkin-local-day-boundary.md) — 以设备本地日期 `localDayKey` 限制单日单次，允许补打卡但严禁未来预打卡。
