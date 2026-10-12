# Agent Guidelines

## Repo Overview
- **Monorepo Structure**:
  - `app/`: Cross-platform Flutter client (`app/lib/main.dart`) built with Clean Local-First Architecture (Riverpod 2 + Drift reactive storage + Adaptive Scaffold + Desktop Manager).
  - `server/`: High-performance Rust synchronization service (`server/src/main.rs`) built on Salvo + SQLite + sqlx, serving the modern `/sync/v1` change-stream protocol.
  - `app/packages/*`: Internal client packages (`sync_annotation`, `sync_generator`, `syncstore_client`, `deepseek_client`).

## Code Structure (Client `app/lib/`)
- `core/*`: App theme, shortcuts (`AppShortcuts`), desktop manager (`DesktopManager`), router (`appRouterProvider`), network (`ApiClient`), auth.
- `data/*`: Drift database engine (`AppDriftEngine`), table schemas (`schema.dart`), and reactive local-first repositories (`repositories/*_repository.dart`).
- `models/{feature}/*`: Freezed domain models (`model.dart`) & annotations.
- `presentation/{feature}/*`: Riverpod state notifiers/providers (`*_providers.dart`) & Material 3 UI views (`modern_*_view.dart`).
- `sync/v2/*`: SyncWorker background daemon (`sync_worker.dart`), outbox DAO (`outbox_dao.dart`), unified local-first DB (`local_first_db.dart`), and legacy migrator.

## Code Structure (Server `server/src/`)
- `main.rs`, `router.rs`: Salvo HTTP routing, version distribution, legacy 426 deprecation intercepts.
- `sync/*`: `/sync/v1/push` (CAS mutations), `/sync/v1/pull` (sequence changelog stream), and ACL management.
- `storage/*`, `user.rs`, `auth.rs`: SQLite pool management, user identity, JWT auth middleware.

## Invariants & Critical Rules
- **Codegen**: Never edit `*.g.dart` or `*.freezed.dart`. Update `model.dart` and run `dart run build_runner build --delete-conflicting-outputs` in `app/`.
- **Local-First & Outbox**: All local entity writes must execute atomically within a transaction that simultaneously enqueues an Outbox item (`LocalFirstDB.saveEntityWithOutbox` / `persistPutRaw`).
- **Data Isolation**: Authenticated sessions write strictly to `<db_dir>/<user_id>/app_v2.db` (ADR-0001); guest sessions use in-memory SQLite (`openInMemory()`) to prevent disk pollution.
- **Clipboard Privacy**: Background clipboard captures default to `localOnly=true` (ADR-0002); never upload to cloud without explicit user action.
- **Check-in Constraints**: One checkin per event per day keyed on local date `localDayKey` (ADR-0003); pre-checkin on future dates is strictly prohibited.
- **i18n**: Add new translation keys inside their respective feature section in `app/lib/utils/translation.dart`, never at the end of the file.

## 领域知识与架构决策 (Domain Knowledge)
- 业务概念定义、中英别名映射与模块物理代码入口，优先查阅 `GLOSSARY.md`。
- 涉及重要技术选型或架构调整前，先查阅 `docs/adr/README.md` 单行索引，严禁违背既定决策。
- 严格遵守 `GLOSSARY.md` 中的 `_Avoid_` 禁用词约定，防止概念混淆。

## Progressive Disclosure
- 领域词典与物理索引：首选 `GLOSSARY.md`。
- 系统整体架构与技术栈：阅读 `CONTEXT.md`。
- 架构决策记录：阅读 `docs/adr/README.md` 与对应 ADR。
- 子模块详细设计与 Schema：按需阅读 `docs/domain/<feature>.md` (`notes`, `task`, `tracker`, `checkin`, `clipboard`, `chat`, `syncstore_protocol`, `codegen_pipeline`)。
