## About This Repo
- A flutter app named XBB. Root(`lib/main.dart`)
- GetStorage for local cache + SQLite for user data + syncstore protocol to sync with server.
- With submodules : `sync_annotation` + `sync_generator` (model annotation && codegen for sync engines), `syncstore_client` (syncstore protocol client), `deepseek_client` (DeepSeek protocol client).

## High-value commands
- Analyze: `flutter analyze`.

## App feature list
- Notes
- Task
- Tracker
- Chat
- Clipboard

Each feature has its own data models, local DB, sync engine, and UI components. Load further details ONLY if needed(.agents/features/*.md)

## Code Architecture
- lib/components/{feature}/*: UI components for each feature.
- lib/controllers/{feature}/*: State management and business logic for each feature or app settings.
- lib/models/{feature}/*: Data models for each feature, with annotations for codegen.
- lib/pages/*: App pages/screens, composed of components and controllers.

## Codegen rules (critical)
- Do not hand-edit generated files: `lib/models/**/model.g.dart` and `lib/models/**/model.freezed.dart`. Use annotations in `model.dart` and run `dart run build_runner build --delete-conflicting-outputs` to regenerate.
