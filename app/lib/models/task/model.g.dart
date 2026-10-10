// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CheckList _$CheckListFromJson(Map<String, dynamic> json) => _CheckList(
  tasks: json['tasks'] as String,
  archived: json['archived'] as bool,
  archivedAt: json['archived_at'] == null
      ? null
      : DateTime.parse(json['archived_at'] as String),
);

Map<String, dynamic> _$CheckListToJson(_CheckList instance) =>
    <String, dynamic>{
      'tasks': instance.tasks,
      'archived': instance.archived,
      'archived_at': instance.archivedAt?.toIso8601String(),
    };

_TaskItem _$TaskItemFromJson(Map<String, dynamic> json) => _TaskItem(
  id: json['id'] as String,
  content: json['content'] as String,
  done: json['done'] as bool,
  doneAt: json['done_at'] == null
      ? null
      : DateTime.parse(json['done_at'] as String),
  lastModifiedAt: DateTime.parse(json['last_modified_at'] as String),
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TaskItemToJson(_TaskItem instance) => <String, dynamic>{
  'id': instance.id,
  'content': instance.content,
  'done': instance.done,
  'done_at': instance.doneAt?.toIso8601String(),
  'last_modified_at': instance.lastModifiedAt.toIso8601String(),
  'sort_order': instance.sortOrder,
};

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

extension LocalStoreCheckList on CheckList {
  static String get tableName => 'check_list';

  static String get onCreateTableCheckListSQL =>
      """
        CREATE TABLE $tableName (
          id TEXT PRIMARY KEY,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          owner TEXT NOT NULL,
          parent_id TEXT,
          "unique" TEXT,
          sync_status TEXT NOT NULL,
          color_tag TEXT NOT NULL,
          body TEXT NOT NULL
        )
      """;

  static Future<Database> getDb() async {
    return await TaskDB().getDb();
  }
}

typedef CheckListDataItem = DataItem<CheckList>;

class CheckListRepository {
  Future<void> addToLocalDb(CheckListDataItem item) async {
    final db = await LocalStoreCheckList.getDb();
    await db.insert(
      LocalStoreCheckList.tableName,
      item.toJson((r) => json.encode(r.toJson())),
    );
  }

  Future<CheckListDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreCheckList.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreCheckList.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<CheckList>.fromJson(
        maps.first,
        (jsonStr) => CheckList.fromJson(json.decode(jsonStr as String)),
      );
    }
    return null;
  }

  Future<List<CheckListDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStoreCheckList.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty
        ? whereClauses.join(' AND ')
        : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreCheckList.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return maps
        .map(
          (map) => DataItem<CheckList>.fromJson(
            map,
            (jsonStr) => CheckList.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<List<CheckListDataItem>> listByParentIdFromLocalDb(
    String parentId, {
    bool desc = true,
  }) async {
    final db = await LocalStoreCheckList.getDb();
    final order = desc ? 'DESC' : 'ASC';
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM ${LocalStoreCheckList.tableName} WHERE parent_id = ? ORDER BY created_at $order',
      [parentId],
    );
    return maps
        .map(
          (map) => DataItem<CheckList>.fromJson(
            map,
            (jsonStr) => CheckList.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreCheckList.getDb();
    await db.delete(
      LocalStoreCheckList.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateToLocalDb(CheckListDataItem item) async {
    final db = await LocalStoreCheckList.getDb();
    await db.update(
      LocalStoreCheckList.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(CheckListDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}
