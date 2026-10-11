// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClipboardHistoryEntry _$ClipboardHistoryEntryFromJson(
  Map<String, dynamic> json,
) => _ClipboardHistoryEntry(
  data: json['data'] as String,
  capturedAt: json['captured_at'] == null
      ? null
      : DateTime.parse(json['captured_at'] as String),
  localOnly: json['local_only'] as bool? ?? true,
);

Map<String, dynamic> _$ClipboardHistoryEntryToJson(
  _ClipboardHistoryEntry instance,
) => <String, dynamic>{
  'data': instance.data,
  'captured_at': instance.capturedAt?.toIso8601String(),
  'local_only': instance.localOnly,
};

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

extension LocalStoreClipboardHistoryEntry on ClipboardHistoryEntry {
  static String get tableName => 'clipboard_history_entry';

  static String get onCreateTableClipboardHistoryEntrySQL =>
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
    return await ClipboardDB().getDb();
  }
}

typedef ClipboardHistoryEntryDataItem = DataItem<ClipboardHistoryEntry>;

class ClipboardHistoryEntryRepository {
  Future<void> addToLocalDb(ClipboardHistoryEntryDataItem item) async {
    final db = await LocalStoreClipboardHistoryEntry.getDb();
    await db.insert(
      LocalStoreClipboardHistoryEntry.tableName,
      item.toJson((r) => json.encode(r.toJson())),
    );
  }

  Future<ClipboardHistoryEntryDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreClipboardHistoryEntry.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreClipboardHistoryEntry.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<ClipboardHistoryEntry>.fromJson(
        maps.first,
        (jsonStr) =>
            ClipboardHistoryEntry.fromJson(json.decode(jsonStr as String)),
      );
    }
    return null;
  }

  Future<List<ClipboardHistoryEntryDataItem>> listFromLocalDb({
    String? parentId,
  }) async {
    final db = await LocalStoreClipboardHistoryEntry.getDb();
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
      LocalStoreClipboardHistoryEntry.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return maps
        .map(
          (map) => DataItem<ClipboardHistoryEntry>.fromJson(
            map,
            (jsonStr) =>
                ClipboardHistoryEntry.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<List<ClipboardHistoryEntryDataItem>> listByParentIdFromLocalDb(
    String parentId, {
    bool desc = true,
  }) async {
    final db = await LocalStoreClipboardHistoryEntry.getDb();
    final order = desc ? 'DESC' : 'ASC';
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM ${LocalStoreClipboardHistoryEntry.tableName} WHERE parent_id = ? ORDER BY created_at $order',
      [parentId],
    );
    return maps
        .map(
          (map) => DataItem<ClipboardHistoryEntry>.fromJson(
            map,
            (jsonStr) =>
                ClipboardHistoryEntry.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreClipboardHistoryEntry.getDb();
    await db.delete(
      LocalStoreClipboardHistoryEntry.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateToLocalDb(ClipboardHistoryEntryDataItem item) async {
    final db = await LocalStoreClipboardHistoryEntry.getDb();
    await db.update(
      LocalStoreClipboardHistoryEntry.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(ClipboardHistoryEntryDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}
