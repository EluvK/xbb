// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CheckinEvent _$CheckinEventFromJson(Map<String, dynamic> json) =>
    _CheckinEvent(
      name: json['name'] as String,
      description: json['description'] as String,
      colorValue: (json['color_value'] as num).toInt(),
    );

Map<String, dynamic> _$CheckinEventToJson(_CheckinEvent instance) =>
    <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'color_value': instance.colorValue,
    };

_CheckinRecord _$CheckinRecordFromJson(Map<String, dynamic> json) =>
    _CheckinRecord(
      eventId: json['event_id'] as String,
      createdAtUtc: DateTime.parse(json['created_at_utc'] as String),
      localDayKey: json['local_day_key'] as String,
      timezoneOffsetMinutes:
          (json['timezone_offset_minutes'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$CheckinRecordToJson(_CheckinRecord instance) =>
    <String, dynamic>{
      'event_id': instance.eventId,
      'created_at_utc': instance.createdAtUtc.toIso8601String(),
      'local_day_key': instance.localDayKey,
      'timezone_offset_minutes': instance.timezoneOffsetMinutes,
      'note': instance.note,
    };

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

extension LocalStoreCheckinEvent on CheckinEvent {
  static String get tableName => 'event';

  static String get onCreateTableCheckinEventSQL =>
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
    return await CheckinDB().getDb();
  }
}

typedef CheckinEventDataItem = DataItem<CheckinEvent>;

class CheckinEventRepository {
  Future<void> addToLocalDb(CheckinEventDataItem item) async {
    final db = await LocalStoreCheckinEvent.getDb();
    await db.insert(
      LocalStoreCheckinEvent.tableName,
      item.toJson((r) => json.encode(r.toJson())),
    );
  }

  Future<CheckinEventDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreCheckinEvent.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreCheckinEvent.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<CheckinEvent>.fromJson(
        maps.first,
        (jsonStr) => CheckinEvent.fromJson(json.decode(jsonStr as String)),
      );
    }
    return null;
  }

  Future<List<CheckinEventDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStoreCheckinEvent.getDb();
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
      LocalStoreCheckinEvent.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return maps
        .map(
          (map) => DataItem<CheckinEvent>.fromJson(
            map,
            (jsonStr) => CheckinEvent.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<List<CheckinEventDataItem>> listByParentIdFromLocalDb(
    String parentId, {
    bool desc = true,
  }) async {
    final db = await LocalStoreCheckinEvent.getDb();
    final order = desc ? 'DESC' : 'ASC';
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM ${LocalStoreCheckinEvent.tableName} WHERE parent_id = ? ORDER BY created_at $order',
      [parentId],
    );
    return maps
        .map(
          (map) => DataItem<CheckinEvent>.fromJson(
            map,
            (jsonStr) => CheckinEvent.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreCheckinEvent.getDb();
    await db.delete(
      LocalStoreCheckinEvent.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateToLocalDb(CheckinEventDataItem item) async {
    final db = await LocalStoreCheckinEvent.getDb();
    await db.update(
      LocalStoreCheckinEvent.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(CheckinEventDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}

extension LocalStoreCheckinRecord on CheckinRecord {
  static String get tableName => 'record';

  static String get onCreateTableCheckinRecordSQL =>
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
    return await CheckinDB().getDb();
  }
}

typedef CheckinRecordDataItem = DataItem<CheckinRecord>;

class CheckinRecordRepository {
  Future<void> addToLocalDb(CheckinRecordDataItem item) async {
    final db = await LocalStoreCheckinRecord.getDb();
    await db.insert(
      LocalStoreCheckinRecord.tableName,
      item.toJson((r) => json.encode(r.toJson())),
    );
  }

  Future<CheckinRecordDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreCheckinRecord.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreCheckinRecord.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<CheckinRecord>.fromJson(
        maps.first,
        (jsonStr) => CheckinRecord.fromJson(json.decode(jsonStr as String)),
      );
    }
    return null;
  }

  Future<List<CheckinRecordDataItem>> listFromLocalDb({
    String? parentId,
  }) async {
    final db = await LocalStoreCheckinRecord.getDb();
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
      LocalStoreCheckinRecord.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return maps
        .map(
          (map) => DataItem<CheckinRecord>.fromJson(
            map,
            (jsonStr) => CheckinRecord.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<List<CheckinRecordDataItem>> listByParentIdFromLocalDb(
    String parentId, {
    bool desc = true,
  }) async {
    final db = await LocalStoreCheckinRecord.getDb();
    final order = desc ? 'DESC' : 'ASC';
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM ${LocalStoreCheckinRecord.tableName} WHERE parent_id = ? ORDER BY created_at $order',
      [parentId],
    );
    return maps
        .map(
          (map) => DataItem<CheckinRecord>.fromJson(
            map,
            (jsonStr) => CheckinRecord.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreCheckinRecord.getDb();
    await db.delete(
      LocalStoreCheckinRecord.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateToLocalDb(CheckinRecordDataItem item) async {
    final db = await LocalStoreCheckinRecord.getDb();
    await db.update(
      LocalStoreCheckinRecord.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(CheckinRecordDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}
