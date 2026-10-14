# App Agent Guidelines (Client)

## Overview
跨平台 Flutter 客户端 (`app/lib/main.dart`)，基于 Clean Local-First Architecture 构建 (Riverpod 2 + Drift reactive storage + Adaptive Scaffold + Desktop Manager)。

## Subpackages (`app/packages/*`)
- `sync_annotation`: Freezed 领域的声明式模型注解 (`@Repository`)。
- `sync_generator`: 生成序列化与 Repository 助手的代码生成器。
- `syncstore_client`: REST & Sync 客户端数据模型 (`DataItem<T>`, `ACLMask`, `SyncStatus`, `ColorTag`)。
- `deepseek_client`: 面向 DeepSeek 模型的流式 SSE 对话与推理客户端。

## Code Structure (`app/lib/`)
- `core/*`: App 主题、快捷键 (`AppShortcuts`)、桌面窗口管理 (`DesktopManager`)、路由导航 (`appRouterProvider`)、网络底层 (`ApiClient`)、认证状态。
- `data/*`: Drift 数据库引擎 (`AppDriftEngine`)、数据表定义 (`schema.dart`)、响应式 Local-First Repositories (`repositories/*_repository.dart`)。
- `models/{feature}/*`: Freezed 领域模型 (`model.dart`) 与相关注解。
- `presentation/{feature}/*`: Riverpod 状态管理器/Providers (`*_providers.dart`) 与 Material 3 视图组件 (`modern_*_view.dart`)。
- `sync/v2/*`: SyncWorker 后台守护 (`sync_worker.dart`)、Outbox DAO (`outbox_dao.dart`)、统一 Local-First DB (`local_first_db.dart`) 及数据迁移逻辑。
- `utils/*`: 国际化多语言定义 (`translation.dart`) 与实用工具函数。

## Invariants & Critical Rules
- **Codegen**: 严禁手动修改 `*.g.dart` 或 `*.freezed.dart`。修改 `model.dart` 后必须运行 `dart run build_runner build --delete-conflicting-outputs`。
- **Local-First & Outbox**: 所有本地实体写入操作必须在单一事务中原子性完成，并同步写入 Outbox 队列项 (`LocalFirstDB.saveEntityWithOutbox` / `persistPutRaw`)。
- **Data Isolation**: 已认证用户数据严格隔离写入 `<db_dir>/<user_id>/app_v2.db` (ADR-0001)；未认证访客会话使用内存数据库 (`openInMemory()`)。
- **Clipboard Privacy**: 后台剪贴板监听记录默认 `localOnly=true` (ADR-0002)；未经用户显式操作严禁上传至云端。
- **Check-in Constraints**: 每个打卡事件每天在本地日期维度 (`localDayKey`) 严格限打卡一次 (ADR-0003)；严禁未来日期预打卡。
- **i18n**: 新增翻译词条必须置于 `app/lib/utils/translation.dart` 内各自对应的功能区块中，严禁追加在文件末尾。

## Testing & Verification
- 单元与集成测试：`flutter test`
- 静态分析：`flutter analyze`
