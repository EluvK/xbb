# XBB Context

XBB is a cross-platform personal productivity workspace with a Local-First architecture, user-isolated Drift storage, and cloud synchronization via the modern SyncStore changelog protocol.

- Domain Glossary: [GLOSSARY.md](GLOSSARY.md)
- Architecture Decisions: [docs/adr/README.md](docs/adr/README.md)

---

## 1. Architecture Stack

### Client (`app/`)
- **App Framework**: Flutter 3.10+ with Clean Local-First Architecture.
- **State Management**: `flutter_riverpod` + `riverpod_annotation` (reactive Notifiers, automatic disposal, type safety).
- **Navigation**: `go_router` with reactive auth guard (`appRouterProvider`).
- **Data & Local Storage**:
  - `Drift`: Strongly-typed relational schema (`SyncStoreEntityTable`, `OutboxTable`) with reactive Stream queries (`watchQuery`) and atomic transactions.
  - User Isolation: Authenticated sessions use `<db_dir>/<user_id>/app_v2.db` (ADR-0001); unauthenticated sessions use in-memory SQLite (`openInMemory()`).
  - Cache & Preferences: `GetStorage` for app tokens, feature switches, and UI settings.
- **Desktop & Cross-Platform**:
  - `window_manager` + `tray_manager`: Borderless customizable window, drag regions, double-click maximize, and hide-to-tray minimization (ADR-0006).
  - `flutter_adaptive_scaffold`: Smoothly transitions between mobile navigation (NavigationBar + stack routing) and desktop workspace (NavigationRail + Master-Detail multi-pane).
  - Global Shortcuts: Flutter native `Shortcuts` & `Actions` (`Cmd/Ctrl+K` command palette, `Cmd/Ctrl+N` new item, `ESC` exit/pop).
- **Internal Packages (`app/packages/`)**:
  - `syncstore_client`: REST & Sync client models (`DataItem<T>`, `ACLMask`, `SyncStatus`, `ColorTag`).
  - `sync_annotation`: Declarative model annotations (`@Repository`) for Freezed models.
  - `sync_generator`: Code generator producing serialization and repository helpers.
  - `deepseek_client`: Streaming SSE client for DeepSeek chat & reasoning models.

### Server (`server/`)
- **Framework**: Rust 2024 edition built on Salvo HTTP framework + tokio async runtime.
- **Database**: SQLite with `sqlx` (connection pool, migrations, WAL mode).
- **Security**: JWT authentication middleware (`auth.rs`), Argon2/SHA password hashing.
- **Sync Protocol (`/sync/v1`)**:
  - Push (`POST /sync/v1/push`): Batch CAS mutations with optimistic conflict resolution.
  - Pull (`GET /sync/v1/pull`): Sequence-based incremental changelog stream (`seq` cursor).
  - Deprecation: Returns HTTP 426 (`CLIENT_UPGRADE_REQUIRED`) for legacy `/data` and `/batch-data` endpoints.
  - App Distribution: Serves version checks, CHANGELOG, and application binaries (`/fs/public/{app}/*`).

---

## 2. Domains & Concepts

### SyncStore & Local-First Engine ([syncstore_protocol.md](docs/domain/syncstore_protocol.md), [codegen_pipeline.md](docs/domain/codegen_pipeline.md))
- **SyncWorker**: Background singleton sync daemon managing periodic polling, write notifications, debounce mutex, and push/pull lifecycles.
- **Outbox Queue**: Durable local outbox table (`outbox`) capturing pending mutations atomically with business writes (ADR-0004).
- **Sequence Stream**: Server-assigned monotonic sequence numbers (`seq`) driving incremental client synchronization.
- **DataItem&lt;T&gt;**: Canonical client envelope wrapping entity body with ID, owner, timestamps, color tag, and sync status.
- **ACLMask**: 6-bit permission mask for fine-grained read, update, delete, and multi-tier append permissions.

### Notes Knowledge Base ([notes.md](docs/domain/notes.md))
- **Repo**: Top-level notebook collection with ACL sharing and subscription support.
- **Post**: Markdown article entity belonging to a Repo (`parentId = repoId`).
- **Comment**: Discussion entry on a Post supporting nested tree replies and paragraph anchoring.
- **Block-Level Comments**: Stable paragraph/block-level annotation system resilient against content edits (ADR-0007).
- **Workspace Navigation**: Adaptive Master-Detail layout with category unread dots, mark-all-as-read, and preview cards.

### Task Management ([task.md](docs/domain/task.md))
- **CheckList**: Container entity storing active items (`tasks` payload) or historic archive segments.
- **TaskItem**: Discrete todo entry with status, completion timestamp, and drag-and-drop sort order.
- **Reorderable Flow**: `ReorderableListView` with focus-locking state machine (`_frozenOrderIds`) preventing cursor jump during edits.
- **TaskWidgetBridge**: System widget bridge streaming pending task snapshots to Android desktop widgets.

### Goal Tracker ([tracker.md](docs/domain/tracker.md))
- **Tracker**: Polymorphic configuration entity for `event` (recurring habit), `milestone` (numeric/time/boolean goal), and `anniversary` (date countdown/milestone).
- **TrackerRecord**: Timestamped progress log entry recorded against a Tracker.
- **ViewTrackerBrief & Detail**: Macro category summary dashboard and dedicated full-screen time-series analysis page (`ViewTrackerDetailPage`).

### Check-in Habits ([checkin.md](docs/domain/checkin.md))
- **CheckinEvent**: Habit theme entity with customizable ARGB color and description.
- **CheckinRecord**: Daily completion log entry constrained by local date string `localDayKey` (ADR-0003).
- **Validation Rules**: Strictly at most 1 completion per event per day; allows past backfills; strictly forbids future pre-checkins.

### Clipboard History ([clipboard.md](docs/domain/clipboard.md))
- **ClipboardHistoryEntry**: Local desktop clipboard capture record.
- **Local-First Privacy**: Background capture defaults to `localOnly = true`; cloud upload requires explicit user action (ADR-0002).
- **Desktop Tray Integration**: System tray integration (`tray_manager`) with double-click restore and pause/resume toggling.

### AI Chat ([chat.md](docs/domain/chat.md))
- **ChatAssistant**: Configured AI persona defining system prompt, temperature, and model hyperparameters.
- **ChatConversation**: Dialogue thread bound to a specific ChatAssistant.
- **ChatMessage**: Message entity carrying role, text, token usage, and chain-of-thought `reasoningText` stream.

---

## 3. Engineering Invariants

- **Codegen**: Never edit `*.g.dart` or `*.freezed.dart`. Regenerate via `dart run build_runner build --delete-conflicting-outputs` in `app/`.
- **Atomic Mutations**: Business table modifications and Outbox records must always be wrapped in a single database transaction.
- **User Isolation**: Never mix multi-user data in a single SQLite database file; strictly isolate via `<user_id>/app_v2.db`.
- **Network Resilience**: Skip cloud sync when offline; handle HTTP 426 by prompting application updates.
