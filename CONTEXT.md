# XBB Context

XBB is a cross-platform Flutter personal productivity workspace with a local-first architecture, SQLite data isolation, and cloud synchronization via the `syncstore` protocol.

- Domain Glossary: [GLOSSARY.md](GLOSSARY.md)
- Architecture Decisions: [docs/adr/README.md](docs/adr/README.md)

---

## 1. Architecture Stack

- App Framework: Flutter + GetX (reactive state management, tab routing, dependency injection).
- Storage:
  - `GetStorage`: App settings, feature toggles, UI cache, auth tokens.
  - `SQLite`: User-isolated relational storage (`<db_dir>/<user_id>/<feature>.db`) via `sqflite` / `sqflite_common_ffi`.
- Packages (`packages/`):
  - `syncstore_client`: REST client for SyncStore protocol (Token refresh, HPKE encryption, chunking).
  - `sync_annotation`: Declarative model annotations (`@Repository`) for persistence and sync.
  - `sync_generator`: Code generator (`source_gen`) producing stores, repos, controllers, sync engines.
  - `deepseek_client`: Streaming API client for DeepSeek chat and reasoning models.

---

## 2. Domains & Concepts

### SyncStore & Codegen ([syncstore_protocol.md](docs/domain/syncstore_protocol.md), [codegen_pipeline.md](docs/domain/codegen_pipeline.md))
- SyncServer: Central sync backend coordinating multi-client data consistency, ACLs, and storage.
- SyncStore Protocol: Unified REST synchronization contract using generic DataItem envelopes.
- DataItem&lt;T&gt;: Universal envelope wrapping model T with id, owner, parentId, syncStatus, and timestamps.
- ACLMask: 6-bit permission mask for read, update, delete, and 3-tier downward append rights.
- @Repository: Codegen annotation generating SQLite stores, repositories, controllers, and sync engines.
- LocalStore: Generated SQLite data access object handling schema DDL, CRUD, and status indexing.

### Notes ([notes.md](docs/domain/notes.md))
- Repo: Top-level notebook collection with ACL sharing support.
- Post: Article entity under a Repo (parentId = repoId) with markdown content.
- Comment: Discussion entry on a Post, supporting nested replies and paragraph anchoring.
- Paragraph Anchor: Links a Comment to a specific post paragraph via paragraphIndex and paragraphHash.

### Task ([task.md](docs/domain/task.md))
- CheckList: Checklist workspace container for the active document or historical archives.
- TaskItem: Discrete todo entry carrying completion status (done/doneAt) and sort order.
- TaskWidgetBridge: Android MethodChannel bridge pushing pending task snapshots to home widget.

### Tracker ([tracker.md](docs/domain/tracker.md))
- Tracker: Subject entity configured as Event, Milestone, or Anniversary.
- Event Tracker: Habit tracker defined by recurrence interval (periodDays).
- Milestone Tracker: Goal tracker with target values (time, number, boolean) and progress modes.
- Anniversary Tracker: Milestone date monitor supporting Gregorian/Lunar calendars and reminders.
- TrackerRecord: Timestamped progress log entry recorded against a Tracker.

### Check-in ([checkin.md](docs/domain/checkin.md))
- CheckinEvent: User-defined habit event with an associated ARGB color.
- CheckinRecord: Daily completion log entry for a specific calendar date.
- localDayKey: Local ISO date string (yyyy-MM-dd) enforcing at most 1 check-in per event per day.
- CheckinWidgetBridge: Android native bridge driving 3-size home widget with midnight reset.

### Clipboard ([clipboard.md](docs/domain/clipboard.md))
- ClipboardHistoryEntry: Captured clipboard text record with capture time and cloud state.
- localOnly: Privacy flag (default true); copied text never uploads without manual confirmation.
- ClipboardTrayController: Windows Win32 clipboard hook and tray minimization controller.

### Chat ([chat.md](docs/domain/chat.md))
- ChatAssistant: Configured AI persona defined by prompt and model hyperparameters.
- ChatConversation: Dialogue thread associated with a specific ChatAssistant.
- ChatMessage: Message carrying role, text, token usage, and chain-of-thought reasoning content.
- Reasoning Text: First-class token stream from reasoning models (e.g. DeepSeek-R1).

---

## 3. Engineering Invariants

- Codegen: Never edit `*.g.dart` or `*.freezed.dart`. Regenerate via `dart run build_runner build --delete-conflicting-outputs`.
- Resilience: Guard sync calls with `client.pingLatencyMs()` (< 0 means offline).
- Multi-Account: SQLite DBs are isolated by `<db_dir>/<user_id>/<feature>.db`.
- i18n: Append new keys inside their respective feature block in `lib/utils/translation.dart`.
