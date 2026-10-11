// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Tracker _$TrackerFromJson(Map<String, dynamic> json) => _Tracker(
  name: json['name'] as String,
  description: json['description'] as String,
  category: json['category'] as String,
  type: json['type'] as String,
  config: TrackerConfig.fromJson(json['config'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TrackerToJson(_Tracker instance) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'category': instance.category,
  'type': instance.type,
  'config': instance.config,
};

EventTrackerConfig _$EventTrackerConfigFromJson(Map<String, dynamic> json) =>
    EventTrackerConfig(
      periodDays: (json['period_days'] as num).toInt(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$EventTrackerConfigToJson(EventTrackerConfig instance) =>
    <String, dynamic>{
      'period_days': instance.periodDays,
      'type': instance.$type,
    };

MilestoneTrackerConfig _$MilestoneTrackerConfigFromJson(
  Map<String, dynamic> json,
) => MilestoneTrackerConfig(
  goalType: json['goal_type'] as String,
  targetValue: json['target_value'] as String,
  progressMode: json['progress_mode'] as String? ?? 'accumulate',
  $type: json['type'] as String?,
);

Map<String, dynamic> _$MilestoneTrackerConfigToJson(
  MilestoneTrackerConfig instance,
) => <String, dynamic>{
  'goal_type': instance.goalType,
  'target_value': instance.targetValue,
  'progress_mode': instance.progressMode,
  'type': instance.$type,
};

AnniversaryTrackerConfig _$AnniversaryTrackerConfigFromJson(
  Map<String, dynamic> json,
) => AnniversaryTrackerConfig(
  baseDate: DateTime.parse(json['base_date'] as String),
  isLunar: json['is_lunar'] as bool,
  remindType: json['remind_type'] as String,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$AnniversaryTrackerConfigToJson(
  AnniversaryTrackerConfig instance,
) => <String, dynamic>{
  'base_date': instance.baseDate.toIso8601String(),
  'is_lunar': instance.isLunar,
  'remind_type': instance.remindType,
  'type': instance.$type,
};

_TrackerRecord _$TrackerRecordFromJson(Map<String, dynamic> json) =>
    _TrackerRecord(
      trackerId: json['tracker_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      value: json['value'] as String?,
      content: json['content'] as String?,
    );

Map<String, dynamic> _$TrackerRecordToJson(_TrackerRecord instance) =>
    <String, dynamic>{
      'tracker_id': instance.trackerId,
      'timestamp': instance.timestamp.toIso8601String(),
      'value': instance.value,
      'content': instance.content,
    };

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

extension LocalStoreTracker on Tracker {
  static String get tableName => 'tracker';

  static String get onCreateTableTrackerSQL =>
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
    return await TrackerDB().getDb();
  }
}

typedef TrackerDataItem = DataItem<Tracker>;

class TrackerRepository {
  Future<void> addToLocalDb(TrackerDataItem item) async {
    final db = await LocalStoreTracker.getDb();
    await db.insert(
      LocalStoreTracker.tableName,
      item.toJson((r) => json.encode(r.toJson())),
    );
  }

  Future<TrackerDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreTracker.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreTracker.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<Tracker>.fromJson(
        maps.first,
        (jsonStr) => Tracker.fromJson(json.decode(jsonStr as String)),
      );
    }
    return null;
  }

  Future<List<TrackerDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStoreTracker.getDb();
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
      LocalStoreTracker.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return maps
        .map(
          (map) => DataItem<Tracker>.fromJson(
            map,
            (jsonStr) => Tracker.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<List<TrackerDataItem>> listByParentIdFromLocalDb(
    String parentId, {
    bool desc = true,
  }) async {
    final db = await LocalStoreTracker.getDb();
    final order = desc ? 'DESC' : 'ASC';
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM ${LocalStoreTracker.tableName} WHERE parent_id = ? ORDER BY created_at $order',
      [parentId],
    );
    return maps
        .map(
          (map) => DataItem<Tracker>.fromJson(
            map,
            (jsonStr) => Tracker.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreTracker.getDb();
    await db.delete(
      LocalStoreTracker.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateToLocalDb(TrackerDataItem item) async {
    final db = await LocalStoreTracker.getDb();
    await db.update(
      LocalStoreTracker.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(TrackerDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}

extension LocalStoreTrackerRecord on TrackerRecord {
  static String get tableName => 'tracker_record';

  static String get onCreateTableTrackerRecordSQL =>
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
    return await TrackerDB().getDb();
  }
}

typedef TrackerRecordDataItem = DataItem<TrackerRecord>;

class TrackerRecordRepository {
  Future<void> addToLocalDb(TrackerRecordDataItem item) async {
    final db = await LocalStoreTrackerRecord.getDb();
    await db.insert(
      LocalStoreTrackerRecord.tableName,
      item.toJson((r) => json.encode(r.toJson())),
    );
  }

  Future<TrackerRecordDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreTrackerRecord.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreTrackerRecord.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<TrackerRecord>.fromJson(
        maps.first,
        (jsonStr) => TrackerRecord.fromJson(json.decode(jsonStr as String)),
      );
    }
    return null;
  }

  Future<List<TrackerRecordDataItem>> listFromLocalDb({
    String? parentId,
  }) async {
    final db = await LocalStoreTrackerRecord.getDb();
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
      LocalStoreTrackerRecord.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return maps
        .map(
          (map) => DataItem<TrackerRecord>.fromJson(
            map,
            (jsonStr) => TrackerRecord.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<List<TrackerRecordDataItem>> listByParentIdFromLocalDb(
    String parentId, {
    bool desc = true,
  }) async {
    final db = await LocalStoreTrackerRecord.getDb();
    final order = desc ? 'DESC' : 'ASC';
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM ${LocalStoreTrackerRecord.tableName} WHERE parent_id = ? ORDER BY created_at $order',
      [parentId],
    );
    return maps
        .map(
          (map) => DataItem<TrackerRecord>.fromJson(
            map,
            (jsonStr) => TrackerRecord.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreTrackerRecord.getDb();
    await db.delete(
      LocalStoreTrackerRecord.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateToLocalDb(TrackerRecordDataItem item) async {
    final db = await LocalStoreTrackerRecord.getDb();
    await db.update(
      LocalStoreTrackerRecord.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(TrackerRecordDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}
