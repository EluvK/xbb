# Task Feature Domain

## 1. Domain Concept
The Task module offers a document-like checklist experience that seamlessly unifies an active workspace with an expandable history of archived checklist segments.

---

## 2. Core Entities & Schema

### 2.1 CheckList (检查单)
- **Definition**: Container entity representing an active todo document or an archived segment.
- **Model**: `CheckList { String tasks, bool archived, DateTime? archivedAt }`
- **Drift Table**: `CheckListTable` -> table `check_list` in `app_v2.db`.
- **Invariants**:
  - `isCheckListStateValid`:
    - `archived == true` <==> `archivedAt != null`
    - `archived == false` <==> `archivedAt == null`

### 2.2 TaskItem (待办项)
- **Definition**: Discrete checklist entry serialized within the `tasks` JSON payload of a `CheckList`.
- **Model**:
  ```dart
  TaskItem {
    String id,
    String content,
    bool done,
    DateTime? doneAt,
    DateTime lastModifiedAt,
    int sortOrder,
  }
  ```
- **Serialization**: Helper methods `decodeTaskItems` and `encodeTaskItems` manage JSON marshalling and default order backfilling.

---

## 3. Key Capabilities & Interaction Rules

1. **Reorderable Drag & Drop**:
   - Tasks render in an enhanced `ReorderableListView`.
   - In non-editing state, drag handles allow users to reorder priorities directly, updating `sortOrder` weights.
2. **Focus-Locking Inline Editing (`_frozenOrderIds`)**:
   - Clicking task text enters in-place editing immediately.
   - While editing, the list order is frozen to eliminate focus loss or cursor jumps triggered by background sync or concurrent sort re-evaluations.
3. **Archiving Workflow**:
   - Users can archive completed tasks from the active checklist.
   - Completed items are moved into an archived `CheckList` segment (`archived = true`, `archivedAt = now()`), keeping the active list clean.
4. **Android Home Widget Integration**:
   - `TaskWidgetBridge` communicates over `MethodChannel('com.eluvk.xbb/task_widget')`.
   - Pushes snapshots containing unfinished count and top pending tasks; handles deep-linking into the Task tab.

---

## 4. Key Source Paths

- **Domain Model**: `app/lib/models/task/model.dart`
- **Data Repository**: `app/lib/data/repositories/task_repository.dart` (`TaskRepository`)
- **State Management**: `app/lib/presentation/task/task_providers.dart` (Riverpod Notifiers & StateProviders)
- **Presentation Views**:
  - Main Checklist: `app/lib/presentation/task/modern_task_view.dart` (`ModernTaskView`)
  - Archive History: `app/lib/presentation/task/task_history_view.dart` (`TaskHistoryView`)
  - Progress Card: `app/lib/presentation/task/task_overview_card.dart` (`TaskOverviewCard`)
- **Widget Bridge**: `app/lib/controller/task_widget.dart` (`TaskWidgetBridge`)
- **Route Screen**: `app/lib/pages/task/task_page.dart`
