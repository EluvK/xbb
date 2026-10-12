# Code Generation Pipeline

## 1. Overview
XBB relies on internal code generation packages (`sync_annotation`, `sync_generator`) combined with Flutter ecosystem generators (`build_runner`, `freezed`, `json_serializable`, `riverpod_generator`) to generate immutable domain entities, serialization methods, and reactive state notifiers.

---

## 2. The `@Repository` Annotation

Defined in `app/packages/sync_annotation/lib/sync_annotation.dart`:

```dart
@Repository(
  collectionName: 'xbb',                   // Remote SyncStore collection namespace
  tableName: 'post',                       // Local SQLite / Drift table name
  db: NotesDB,                             // Database provider type reference
  withAcls: false,                         // Whether to generate ACL permission hooks
  parentIdField: 'repoId',                 // Binds model field to parent entity ID
  toSyncJsonMethod: 'toSyncJson',          // Custom serialization method (defaults to toJson)
  fromRemoteJsonFactory: 'fromRemoteJson', // Custom deserializer (defaults to fromJson)
)
@freezed
abstract class Post with _$Post { ... }
```

---

## 3. Codegen Layers & Ecosystem Integration

Running `dart run build_runner build --delete-conflicting-outputs` inside `app/` drives multiple generator passes:

1. **Freezed & JSON Serialization (`freezed`, `json_serializable`)**:
   - Generates immutable dataclasses with deep `copyWith`, equality comparisons, and JSON serialization (`*.freezed.dart`, `*.g.dart`).
2. **Repository Model Annotations (`sync_generator`)**:
   - Inspects `@Repository` markers and validates parent-child hierarchy definitions and sync configurations.
3. **Reactive State Providers (`riverpod_annotation`)**:
   - Generates strongly-typed Riverpod Notifiers and auto-disposing Providers, decoupling presentation state from UI rendering.
4. **Relational Storage Schema (`drift`)**:
   - Drift tables (`app/lib/data/drift/schema.dart`) define compile-time safe database schemas aligned with `SyncStoreEntityTable`.

---

## 4. Development Workflow & Rules

- **Do Not Hand-Edit**: Never edit `*.g.dart` or `*.freezed.dart` files manually.
- **Model Evolution Workflow**:
  1. Update entity definition in `app/lib/models/<feature>/model.dart`.
  2. Run `dart run build_runner build --delete-conflicting-outputs` from `app/`.
  3. Ensure the entity's table is registered in `LocalFirstDB.coreEntityTables` (`app/lib/sync/v2/local_first_db.dart`) and Drift schema (`app/lib/data/drift/schema.dart`).
  4. Implement or update repository queries in `app/lib/data/repositories/<feature>_repository.dart`.
