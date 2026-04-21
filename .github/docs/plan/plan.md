# Task Feature Plan (V1)

## Goal

- Provide a lightweight task workflow that feels like a continuous checklist document.
- Default focus on active tasks, while keeping archived history reviewable.
- Keep sync behavior non-blocking and UI responsive under frequent edits.

## Scope

### In Scope (V1)

- Single active checklist and multiple archived checklists.
- Task add/edit/toggle done/delete.
- Archive current workspace into history and create a fresh active workspace.
- Local-first rendering with async sync backfill.

### Out of Scope (V1)

- Multi-user collaborative editing semantics.
- Per-task server-side partial update API (still segment-level writeback).
- Advanced conflict resolution UI.

## Data Model

### CheckList

- `tasks: String` (JSON serialized `TaskItem[]`)
- `archived: bool`
- `archivedAt: DateTime?`

### TaskItem

- `id: String`
- `content: String`
- `done: bool`
- `doneAt: DateTime?`
- `lastModifiedAt: DateTime`

### Invariants

- `archived == true` implies `archivedAt != null`
- `archived == false` implies `archivedAt == null`
- `done == true` implies `doneAt != null`
- `done == false` implies `doneAt == null`

## Display Rules

- Active checklist is shown in workspace area.
- Archived checklists are shown in history area with incremental loading.
- Task ordering:
  - undone first, done later
  - undone by `lastModifiedAt` ascending
  - done by `doneAt` ascending, tie-break by `lastModifiedAt` ascending

## Sync and UX Strategy

- Startup sync remains non-blocking (`onReadySyncTask` async trigger).
- Task page subscribes to local reactive checklist list; UI auto-refreshes on local rebuild after sync.
- Rapid operations use 1s debounce batching before persistence to reduce flicker and request churn.
- New task starts as local draft:
  - empty draft on blur is dropped
  - only non-empty content is persisted/synced
- Saving indicator (`task_saving`) is shown beside workspace title during real syncing stage.

## Delivery Status

- [x] Module 1: Routes + models scaffold
- [x] Module 2: Local DB and repository integration
- [x] Module 3: Core task operations
- [x] Module 4: Task page interactions and history UI
- [x] Module 5: Async sync integration + reactive local refresh
- [ ] Module 6: Regression tests and edge-case hardening

## Current Verification Focus

- High-latency network with rapid checkbox toggles
- Draft create/edit/empty-drop flows
- Archive immediately followed by add/edit actions
- Archived-history delete with pagination window consistency
- Multi-client overwrite behavior on same checklist

## Next Steps

1. Add task interaction regression tests for debounce and draft behavior.
2. Add targeted sync-state tests for local reactive refresh after `syncAll`.
3. Run manual scenario checklist under latency-injected environment.
