# Task Feature Domain

## 1. Domain Concept
The Task module offers a lightweight checklist experience designed to behave like a continuous document. It separates an active workspace from an expandable history of archived checklists.

---

## 2. Core Entities & Invariants

### 2.1 CheckList
- Definition: A container representing a checklist instance.
- Model: `CheckList { String tasks, bool archived, DateTime? archivedAt }`
- Serialization: `tasks` is a JSON-encoded string of `List<TaskItem>`.
- Invariants:
  - `archived == true` <==> `archivedAt != null`
  - `archived == false` <==> `archivedAt == null`

### 2.2 TaskItem
- Definition: A discrete checklist entry inside a checklist container.
- Model: `TaskItem { String id, String content, bool done, DateTime? doneAt, DateTime lastModifiedAt, int sortOrder }`
- Invariants:
  - `done == true` <==> `doneAt != null`
  - `done == false` <==> `doneAt == null`

### 2.3 Ordering Rules
Active and archived lists are sorted via `sortTaskItems`:
1. Undone tasks come first, completed tasks later.
2. Undone tasks sort by `sortOrder` ascending, tie-breaking by `lastModifiedAt` ascending.
3. Done tasks sort by `doneAt` ascending, tie-breaking by `lastModifiedAt` ascending.

---

## 3. Interaction & Sync Behaviors

- Debounced Writes: Fast toggling and typing are debounced by 1 second before writing to SQLite and triggering cloud sync to minimize churn.
- Draft Workflow: New tasks begin as local in-memory drafts. If the user blurs an empty input field, the draft is silently dropped without saving.
- Archive Action: Users can archive completed tasks from the active checklist. This extracts all completed items (`done == true`) into a new historical checklist segment (`archived = true`, `archivedAt = now()`), while preserving unfinished tasks in the active workspace. The archive button is enabled only when completed tasks exist.

---

## 4. Android Home Screen Widget

- Managed via `TaskWidgetBridge` through `MethodChannel('com.eluvk.xbb/task_widget')`.
- Pushes JSON snapshots (`TaskWidgetSnapshot`) with `state` (`ready`, `empty`, `requires_login`), `totalCount`, `unfinishedCount`, and list of pending items.
- Tapping the widget opens the app and deep links to `HomeTabIndex.task` via `AppLaunchController`.

---

## 5. Key Source Paths

- Models & Codegen: `lib/models/task/model.dart`
- Database Provider: `lib/models/task/db.dart`
- Widget Bridge: `lib/controller/task_widget.dart`
- Page & Components: `lib/pages/task/task_page.dart`, `lib/components/task/view_tasks.dart`, `lib/components/task/view_task_overview.dart`
