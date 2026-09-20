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

## Progressive Disclosure
- System concepts & domain glossary: Read `CONTEXT.md`.
- Feature-specific design & schemas: Load only when needed from `docs/domain/<feature>.md` (`notes`, `task`, `tracker`, `checkin`, `clipboard`, `chat`, `syncstore_protocol`, `codegen_pipeline`).
