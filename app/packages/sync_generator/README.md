# sync_generator

`sync_generator` 是一个基于 `source_gen` 的代码生成器，用于给带 `@Repository(...)` 注解的数据模型生成：

- 数据模型 DDL 扩展（`LocalStore<Entity>`）
- 本地仓储（`<Entity>Repository`）
- 通用数据信封别名（`<Entity>DataItem = DataItem<Entity>`）

生成代码会写入 `*.g.dart`（通过 `source_gen|combining_builder` 合并输出）。

## 快速使用

在模型文件中使用 `@Repository` 注解：

```dart
@Repository(
  collectionName: 'xbb',
  tableName: 'comment',
  db: NotesDB,
)
@freezed
abstract class Comment with _$Comment {
  const factory Comment({
    required String content,
    required String postId,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}
```

然后执行：

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Repository 注解参数

`Repository` 目前支持以下参数：

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `collectionName` | `String` | 是 | - | SyncStore 集合名 |
| `tableName` | `String` | 是 | - | 本地 SQLite 表名 |
| `db` | `Type` | 是 | - | 数据库管理类类型 |
| `withAcls` | `bool` | 否 | `false` | 是否启用 ACL 权限 |
| `parentIdField` | `String?` | 否 | `null` | 绑定父级实体 ID 的字段名 |
| `toSyncJsonMethod` | `String?` | 否 | `null` | 自定义序列化方法名 |
| `fromRemoteJsonFactory` | `String?` | 否 | `null` | 自定义反序列化构造方法名 |
