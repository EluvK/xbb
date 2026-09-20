# Code Generation Pipeline

## 1. Overview
XBB relies on internal packages (`sync_annotation` and `sync_generator`) and `build_runner` to automatically bridge in-memory domain models, local SQLite tables, GetX reactive controllers, and bidirectional sync engines.

---

## 2. The `@Repository` Annotation

Defined in `packages/sync_annotation/lib/sync_annotation.dart`:

```dart
@Repository(
  collectionName: 'xbb',              // Remote SyncStore collection name
  tableName: 'post',                  // Local SQLite table name
  db: NotesDB,                        // Database provider class (returns Future<Database>)
  withAcls: false,                    // Whether to generate ACL permission hooks
  parentIdField: 'repoId',            // Binds model field to DataItem.parentId for local creation
  toSyncJsonMethod: 'toSyncJson',     // Custom serialization method (defaults to toJson)
  fromRemoteJsonFactory: 'fromRemoteJson', // Custom deserializer (defaults to fromJson)
)
@freezed
abstract class Post with _$Post { ... }
```

---

## 3. Generated Layers (`*.g.dart`)

Running `dart run build_runner build --delete-conflicting-outputs` generates four synchronized layers per entity:

1. LocalStore (`LocalStore<Entity>`):
   - `onCreateTable<Entity>SQL`: DDL including indexes and primary key (`data_id`).
   - SQLite CRUD: insert, batch insert, update, soft delete, hard delete, and query by `parentId` or status.
2. Repository (`<Entity>Repository`):
   - Manages memory caches (`RxList<EntityDataItem>`).
   - Encapsulates transaction queries and mapping between raw SQLite rows and `DataItem<Entity>`.
3. Controller (`<Entity>Controller`):
   - GetX controller managing UI-facing observables.
   - Provides optimistic UI mutations (e.g. `addData`, `updateData`, `deleteData`) that write locally with `SyncStatus.pending` before kicking off sync tasks.
4. Sync Engine (`<Entity>SyncEngine`):
   - Bidirectional reconciliation:
     - Push: Queries local items where `syncStatus == SyncStatus.pending`, batches POST requests to SyncStore, and marks them `SyncStatus.synced`.
     - Pull: Queries remote updates with `marker` pagination, reconciles timestamps, writes to local SQLite, and triggers `rebuildLocal()`.

---

## 4. Development Workflow & Rules

- Do Not Hand-Edit: Never modify `*.g.dart` or `*.freezed.dart` manually.
- Model Evolution:
  1. Modify `lib/models/<feature>/model.dart`.
  2. Run `dart run build_runner build --delete-conflicting-outputs`.
  3. Ensure `lib/models/<feature>/db.dart` includes table creation DDL in `onCreate`.
  4. Ensure `reInit<Feature>Sync` is registered in `lib/controller/syncstore.dart`.
