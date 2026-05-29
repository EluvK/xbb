# sync_generator

`sync_generator` 是一个基于 `source_gen` 的代码生成器，用于给带 `@Repository(...)` 注解的数据模型生成：

- 本地仓储（Repository）
- 控制器（GetX Controller）
- 同步引擎（Sync Engine）

生成代码会写入 `*.g.dart`（通过 `source_gen|combining_builder` 合并输出）。

## Quick Start

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

- `collectionName`：服务端集合名
- `tableName`：服务端表名
- `db`：本地数据库类型
- `withAcls`：是否生成 ACL 相关扩展（默认 `false`）
- `parentIdField`：`addData` 本地创建时映射到 `DataItem.parentId` 的字段名
- `toSyncJsonMethod`：同步请求体序列化方法名（默认使用 `toJson`）
- `fromRemoteJsonFactory`：服务端返回反序列化工厂名（默认使用 `fromJson`）

## 高级配置示例

### 1) parentId 映射（立即可见的本地新增）

当你的列表订阅依赖 `ParentIdFilter(...)` 时，建议配置 `parentIdField`：

```dart
@Repository(
  collectionName: 'xbb',
  tableName: 'comment',
  db: NotesDB,
  parentIdField: 'postId',
)
```

这样生成的 `addData` 会自动变成：

```dart
final newItem = CommentDataItem.localNew(owner, newData, parentId: newData.postId);
```

### 2) 自定义同步序列化/反序列化（如 clipboard 特例）

当模型需要“上传字段”和“远端解析”与默认 `toJson/fromJson` 不一致时：

```dart
@Repository(
  collectionName: 'clipboard_history',
  tableName: 'entry',
  db: ClipboardDB,
  toSyncJsonMethod: 'toSyncJson',
  fromRemoteJsonFactory: 'fromRemoteJson',
)
```

生成器会在 Sync Engine 中自动使用：

- `local.body.toSyncJson()` 作为 create/update 请求体
- `Model.fromRemoteJson` 作为 get/batchGet 的解析函数

## 注意事项

- `*.g.dart` 为生成文件，不要手改；应修改注解或生成器后重新生成。
- 若你在 workspace 中开发本包，确保根项目 `pubspec.yaml` 已包含 `sync_generator` 的 `path` 依赖与 `build_runner`。
