# Copilot Instructions for xbb

## Scope and repo layout
- Primary app is `xbb/` (Flutter + GetX + local SQLite sync cache).
- Local workspace package `../syncstore_client/` provides transport, auth refresh, HPKE/chunk upload, and code generators.
- In `xbb/pubspec_overrides.yaml`, `syncstore_client`, `sync_annotation`, and `sync_generator` are overridden to local paths; prefer editing local packages in this workspace, not remote git copies.

## Architecture you must understand first
- App boot order in `lib/main.dart`: initialize `GetStorage` -> init `SettingController` -> `reInitSyncStoreController()` -> register global `ApiException` handling via `PlatformDispatcher.instance.onError`.
- `reInitSyncStoreController()` in `lib/controller/syncstore.dart` is the service boundary reset point: it recreates `SyncStoreControl`, then re-inits `UserManagerController`, then `reInitNotesSync(...)`.
- Notes domain (`Repo`, `Post`, `Comment`) is declared in `lib/models/notes/model.dart` with `@Repository(...)` + `@freezed`; controllers/repositories/sync engines are generated into `model.g.dart`.
- UI reads mostly from local controller state and triggers remote sync explicitly (example: pull-to-refresh flow in `lib/components/notes/view_posts.dart`).

## Generated-code workflow (critical)
- Do not hand-edit generated files: `lib/models/notes/model.g.dart`, `lib/models/notes/model.freezed.dart`.
- When changing model fields/annotations in `model.dart`, regenerate with:
  - `flutter pub run build_runner build --delete-conflicting-outputs`
  - or watch mode: `flutter pub run build_runner watch --delete-conflicting-outputs`
- `sync_generator` behavior is configured in `../syncstore_client/sync_generator/build.yaml`; generated controllers include methods like `syncAll`, `syncChildren`, `addData`, `updateData`, ACL cache helpers.

## State and persistence conventions
- GetX controllers use `ensureInitialization()` loops after `Get.putAsync`; preserve this initialization style when adding controllers.
- Persistent app/user/session settings are in `GetStorage` keys from `lib/constant.dart`; update via `SettingController` APIs rather than direct box writes.
- Notes local DB is per-user (`notes.db` under userId path) in `lib/models/notes/db.dart`; remember user switching implies different local DB cache entry.
- `SyncStatus` is an explicit product concept (see `../syncstore_client/docs/syncstatus.md`), including non-standard states like `archived` and `deleted`.

## Network and security integration points
- All server calls go through `SyncStoreClient` (`../syncstore_client/syncstore_client/lib/src/client.dart`).
- Auth refresh is centralized in `AuthInterceptor` with a single deduplicated refresh flow; avoid adding ad-hoc token refresh logic in feature code.
- HPKE is optional via setting (`enableTunnel` / `syncStoreHpkeEnabled`); if enabled, requests may be encrypted/chunked and response type becomes bytes.
- Public downloads (version/changelog) intentionally skip auth + HPKE (`fetchVersionInfo`, `fetchReleaseNotes` in `SyncStoreControl`).

## Developer workflows in this workspace
- Run app with VS Code tasks in `xbb`:
  - `Flutter-Launch-Desktop`
  - `Flutter-Launch-Android`
  - `Flutter-Launch-All`
- Tests currently live mainly in `xbb/test/` (for example `tracker_model_test.dart`, `text_similarity_test.dart`).
- Analyzer config in `analysis_options.yaml` intentionally allows `print`; do not “clean up” debug prints unless requested.

## Implementation patterns to follow
- For notes feature changes, prefer: update `model.dart` schema/annotations -> regenerate -> wire UI filters/actions via generated controllers.
- Rebuild local lists after sync/update paths when required (pattern used across notes controllers/UI).
- Permission checks should go through `UserManagerController.checkPermission(...)` and `NotesFeatureRequires` in `lib/controller/user.dart`.
- Keep route/navigation style consistent with GetX named routes in `main.dart` (`Get.toNamed`, `Get.offAllNamed`).