# Agent Guidelines

## Repo Overview
- XBB: Cross-platform Flutter app (`lib/main.dart`) with local-first SQLite + GetStorage cache, synced via SyncStore protocol.
- Packages (`packages/`): `sync_annotation` + `sync_generator` (codegen), `syncstore_client` (sync client), `deepseek_client` (LLM client).

## Code Structure
- `lib/components/{feature}/*`: UI widgets.
- `lib/controller/*`: App & feature state controllers (GetX).
- `lib/models/{feature}/*`: Domain models (`model.dart`) & SQLite providers (`db.dart`).
- `lib/pages/*`: Route screens.

## Invariants & Critical Rules
- Codegen: Never edit `*.g.dart` or `*.freezed.dart`. Modify `model.dart` and run `dart run build_runner build --delete-conflicting-outputs`.
- i18n: Add new translation keys inside their respective feature section in `lib/utils/translation.dart`, never at the end of the file.

## 领域知识与架构决策 (Domain Knowledge)
- 业务概念定义、中英别名映射与模块物理代码入口，优先查阅 `GLOSSARY.md`。
- 涉及重要技术选型或架构调整前，先查阅 `docs/adr/README.md` 单行索引，严禁违背既定决策。
- 严格遵守 `GLOSSARY.md` 中的 `_Avoid_` 禁用词约定，防止概念混淆。

## Progressive Disclosure
- 领域词典与物理索引：首选 `GLOSSARY.md`。
- 系统整体架构与技术栈：阅读 `CONTEXT.md`。
- 子模块详细设计与 Schema：按需阅读 `docs/domain/<feature>.md` (`notes`, `task`, `tracker`, `checkin`, `clipboard`, `chat`, `syncstore_protocol`, `codegen_pipeline`)。
