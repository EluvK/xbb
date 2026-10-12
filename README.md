# XBB Workspace

Cross-platform personal productivity workspace built with Flutter and Rust, featuring Clean Local-First Architecture, Drift reactive storage, and seamless cloud synchronization.

---

## 架构总览 (Architecture Overview)

本项目采用 **Monorepo** 组织：

- **`app/` (Flutter Client)**:
  - **Framework & UI**: Flutter 3.10+ (Material 3), `flutter_adaptive_scaffold` 自适应多端工作区。
  - **State Management**: `flutter_riverpod` + `riverpod_annotation`（全面废弃 GetX）。
  - **Local-First & Storage**: Drift 强类型 Schema + 响应式数据流 (`watchQuery`)，单事务写入 Outbox 队列，本地数据零丢失。
  - **Desktop Integration**: `window_manager` + `tray_manager` 跨平台沉浸式无边框窗口与托盘驻留，支持原生全局快捷键 (`shortcuts` + `actions`)。
  - **Data Isolation**: 登录用户使用 `<db_dir>/<user_id>/app_v2.db`（物理目录隔离，ADR-0001）；未登录使用纯内存隔离数据库。
  - **Packages (`app/packages/`)**: `syncstore_client`, `sync_annotation`, `sync_generator`, `deepseek_client`。
- **`server/` (Rust Sync Backend)**:
  - 基于 Salvo + SQLite + sqlx 构建的高性能日志流同步服务。
  - 核心接口：`/sync/v1/push`（CAS 乐观并发控制）、`/sync/v1/pull`（增量 Sequence 变更流）、`/sync/v1/whoami`、`/sync/v1/acl/*`。
  - 统一拦截旧协议接口并返回 HTTP 426 (`CLIENT_UPGRADE_REQUIRED`)，提供应用安装包与版本发布服务。

---

## 核心业务模块 (Core Domains)

1. **笔记知识库 (Notes)**: 树状知识结构（Repo -> Post -> Comment），稳定段落/块唯一标识（Block UUID）批注讨论系统，分类未读红点与批量归档，ACL 协作共享。
2. **待办清单 (Task)**: 连续文档工作区，`ReorderableListView` 拖拽排序，编辑态防失焦锁定机制，归档段落分页流，系统桌面小部件联动。
3. **目标追踪 (Tracker)**: 习惯周期 (Event)、目标里程碑 (Milestone) 与重要纪念日 (Anniversary) 三类多态追踪，宏观分类简报看板与独立时序深度分析页。
4. **习惯打卡 (Checkin)**: 每日自然日本地时区判定（`localDayKey`），严格禁止预打未来日期，多色日历点阵与事件过滤栏，防误触二次确认。
5. **剪贴板管理 (Clipboard)**: 桌面后台全局监听，本地优先隐私保护（默认 `localOnly=true`，上云必须用户显式确认），按日期自动分组与多选批量管理。
6. **AI 对话助手 (Chat)**: 配置化 AI 人格模板，集成 DeepSeek 原生思考链（Chain-of-Thought `reasoningText`）实时流式渲染与展开。

---

## 快速开始 (Getting Started)

### 客户端 (Client)
```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### 服务端 (Server)
```bash
cd server
cargo run --bin server
```

---

## 文档索引 (Documentation)

- **开发守则与指导**: [AGENTS.md](AGENTS.md)
- **系统上下文与技术栈**: [CONTEXT.md](CONTEXT.md)
- **领域词典与物理入口**: [GLOSSARY.md](GLOSSARY.md)
- **架构决策记录**: [docs/adr/README.md](docs/adr/README.md)
- **领域详细设计**: `docs/domain/*.md`
