import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/controller/checkin_widget.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/models/checkin/model.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';
import 'package:xbb/sync/v2/uuid_service.dart';

class CheckinRepository {
  final Database db;
  final DatabaseChangeNotifier changeNotifier;

  CheckinRepository({
    required this.db,
    required this.changeNotifier,
  });

  /// 格式化本地日期为 ISO localDayKey: yyyy-MM-dd
  static String formatLocalDayKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// 监听所有打卡事件 (CheckinEvent)
  Stream<List<DataItem<CheckinEvent>>> watchEvents() {
    return changeNotifier.watchTable('checkin_event').asyncMap((_) async {
      final rows = await db.query('checkin_event', orderBy: 'created_at ASC');
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final event = CheckinEvent.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        final now = DateTime.now();
        return DataItem<CheckinEvent>(
          r['id'] as String,
          DateTime.tryParse(r['created_at'] as String? ?? '') ?? now,
          DateTime.tryParse(r['updated_at'] as String? ?? '') ?? now,
          r['owner'] as String? ?? 'default',
          null,
          null,
          body: event,
          syncStatus: SyncStatus.synced,
        );
      }).toList();
    });
  }

  /// 监听所有打卡记录 (CheckinRecord)
  Stream<List<DataItem<CheckinRecord>>> watchRecords() {
    return changeNotifier.watchTable('checkin_record').asyncMap((_) async {
      final rows = await db.query('checkin_record', orderBy: 'created_at DESC');
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final record = CheckinRecord.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        final now = DateTime.now();
        return DataItem<CheckinRecord>(
          r['id'] as String,
          DateTime.tryParse(r['created_at'] as String? ?? '') ?? now,
          DateTime.tryParse(r['updated_at'] as String? ?? '') ?? now,
          r['owner'] as String? ?? 'default',
          record.eventId,
          null,
          body: record,
          syncStatus: SyncStatus.synced,
        );
      }).toList();
    });
  }

  /// 查询指定年月的打卡记录统计（每个事件完成次数）
  Future<Map<String, int>> getMonthlyCheckinCounts(int year, int month) async {
    final monthPrefix = '$year-${month.toString().padLeft(2, '0')}';
    final rows = await db.query(
      'checkin_record',
      columns: ['parent_id', 'body'],
      where: "body LIKE ?",
      whereArgs: ['%"local_day_key":"$monthPrefix%'],
    );
    final counts = <String, int>{};
    for (final r in rows) {
      String? eventId = r['parent_id'] as String?;
      if (eventId == null || eventId.isEmpty) {
        try {
          final bodyStr = r['body'] as String? ?? '{}';
          final map = jsonDecode(bodyStr) as Map<String, dynamic>;
          eventId = map['event_id'] as String?;
        } catch (_) {}
      }
      if (eventId != null && eventId.isNotEmpty) {
        counts[eventId] = (counts[eventId] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// 响应式监听指定年月的打卡统计
  Stream<Map<String, int>> watchMonthlyCheckinCounts(int year, int month) {
    return changeNotifier.watchTable('checkin_record').asyncMap((_) => getMonthlyCheckinCounts(year, month));
  }

  /// 创建打卡事件
  Future<void> createEvent({
    required String name,
    required String description,
    required int colorValue,
    required String currentUserId,
    DateTime? createdAt,
  }) async {
    final newId = UuidService.v7();
    final event = CheckinEvent(name: name, description: description, colorValue: colorValue);
    final eventTime = createdAt ?? DateTime.now();
    final row = <String, dynamic>{
      'id': newId,
      'created_at': eventTime.toIso8601String(),
      'updated_at': eventTime.toIso8601String(),
      'owner': currentUserId,
      'parent_id': null,
      'sync_status': 'pending',
      'color_tag': 'default',
      'body': jsonEncode(event.toJson()),
    };
    await LocalFirstDB.persistPutRaw(
      db: db,
      tableName: 'checkin_event',
      entityId: newId,
      entityRow: row,
    );
    changeNotifier.notify('checkin_event');
    SyncWorker.instance.notifyLocalWrite();
    CheckinWidgetBridge.scheduleRefresh();
  }

  /// 修改已有打卡事件
  Future<void> updateEvent({
    required String eventId,
    required String name,
    required String description,
    required int colorValue,
    required String currentUserId,
  }) async {
    final rows = await db.query('checkin_event', where: 'id = ?', whereArgs: [eventId]);
    if (rows.isEmpty) return;
    final row = rows.first;
    final now = DateTime.now().toIso8601String();
    final event = CheckinEvent(name: name, description: description, colorValue: colorValue);
    final updatedRow = Map<String, dynamic>.from(row);
    updatedRow['updated_at'] = now;
    updatedRow['body'] = jsonEncode(event.toJson());

    await LocalFirstDB.persistPutRaw(
      db: db,
      tableName: 'checkin_event',
      entityId: eventId,
      entityRow: updatedRow,
    );
    changeNotifier.notify('checkin_event');
    SyncWorker.instance.notifyLocalWrite();
    CheckinWidgetBridge.scheduleRefresh();
  }

  /// 删除打卡事件（级联删除所有关联的 CheckinRecord，并在 Outbox 产生对应的 DELETE 记录）
  Future<void> deleteEvent(String id) async {
    // 1. 级联删除关联的所有 records
    final records = await db.query(
      'checkin_record',
      columns: ['id'],
      where: 'parent_id = ? OR body LIKE ?',
      whereArgs: [id, '%"event_id":"$id"%'],
    );
    for (final r in records) {
      final recId = r['id'] as String;
      await LocalFirstDB.persistDeleteRaw(
        db: db,
        tableName: 'checkin_record',
        entityId: recId,
      );
    }

    // 2. 删除事件本身
    await LocalFirstDB.persistDeleteRaw(
      db: db,
      tableName: 'checkin_event',
      entityId: id,
    );
    changeNotifier.notify('checkin_record');
    changeNotifier.notify('checkin_event');
    SyncWorker.instance.notifyLocalWrite();
    CheckinWidgetBridge.scheduleRefresh();
  }

  /// 打卡（执行 ADR-0003 校验：禁止未来打卡，限制单日单次）
  Future<bool> checkin({
    required String eventId,
    required DateTime targetDate,
    required String currentUserId,
    String? note,
    DateTime? recordTime,
  }) async {
    final today = DateTime.now();
    final todayKey = formatLocalDayKey(today);
    final targetDayKey = formatLocalDayKey(targetDate);

    // ADR-0003: 严禁未来预打卡
    if (targetDayKey.compareTo(todayKey) > 0) {
      throw ArgumentError('严禁未来预打卡 (ADR-0003)');
    }

    // 严格校验：禁止补打事件创建日期之前的历史日期（除非显式指定了 recordTime 自定义发生时间）
    final eventRows = await db.query(
      'checkin_event',
      columns: ['created_at'],
      where: 'id = ?',
      whereArgs: [eventId],
    );
    if (eventRows.isNotEmpty) {
      final createdAtStr = eventRows.first['created_at'] as String?;
      if (createdAtStr != null && createdAtStr.isNotEmpty) {
        final eventCreatedDate = DateTime.tryParse(createdAtStr)?.toLocal();
        if (eventCreatedDate != null) {
          final eventCreatedDayKey = formatLocalDayKey(eventCreatedDate);
          if (recordTime == null && targetDayKey.compareTo(eventCreatedDayKey) < 0) {
            throw ArgumentError('不能补打事件创建前的日期 (checkin_past_date_forbidden)');
          }
        }
      }
    }

    // 检查是否已在该日期打卡（结合 parent_id 与精准 JSON 解析，消除键序漂移影响）
    final existing = await db.query(
      'checkin_record',
      where: "(parent_id = ? OR body LIKE ?) AND body LIKE ?",
      whereArgs: [eventId, '%"event_id":"$eventId"%', '%"local_day_key":"$targetDayKey"%'],
    );
    bool alreadyChecked = false;
    for (final r in existing) {
      try {
        final bodyStr = r['body'] as String? ?? '{}';
        final map = jsonDecode(bodyStr) as Map<String, dynamic>;
        final rec = CheckinRecord.fromJson(map);
        if (rec.eventId == eventId && rec.localDayKey == targetDayKey) {
          alreadyChecked = true;
          break;
        }
      } catch (_) {}
    }
    if (alreadyChecked) {
      return false; // 当日已存在记录
    }

    final newId = UuidService.v7();
    final actualTime = recordTime ?? DateTime.now();
    final record = CheckinRecord(
      eventId: eventId,
      createdAtUtc: actualTime.toUtc(),
      localDayKey: targetDayKey,
      timezoneOffsetMinutes: actualTime.timeZoneOffset.inMinutes,
      note: note,
    );

    final row = <String, dynamic>{
      'id': newId,
      'created_at': actualTime.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'owner': currentUserId,
      'parent_id': eventId,
      'sync_status': 'pending',
      'color_tag': 'default',
      'body': jsonEncode(record.toJson()),
    };

    await LocalFirstDB.persistPutRaw(
      db: db,
      tableName: 'checkin_record',
      entityId: newId,
      entityRow: row,
    );
    changeNotifier.notify('checkin_record');
    SyncWorker.instance.notifyLocalWrite();
    CheckinWidgetBridge.scheduleRefresh();
    return true;
  }

  /// 修改已有打卡记录的发生时间与备注
  Future<void> updateRecordDetails({
    required String recordId,
    required DateTime recordTime,
    String? note,
  }) async {
    final rows = await db.query('checkin_record', where: 'id = ?', whereArgs: [recordId]);
    if (rows.isEmpty) return;
    final row = rows.first;
    final bodyStr = row['body'] as String? ?? '{}';
    final oldRecord = CheckinRecord.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
    final updatedRecord = oldRecord.copyWith(
      createdAtUtc: recordTime.toUtc(),
      timezoneOffsetMinutes: recordTime.timeZoneOffset.inMinutes,
      note: note,
    );
    final updatedRow = Map<String, dynamic>.from(row);
    updatedRow['updated_at'] = DateTime.now().toIso8601String();
    updatedRow['created_at'] = recordTime.toIso8601String();
    updatedRow['body'] = jsonEncode(updatedRecord.toJson());

    await LocalFirstDB.persistPutRaw(
      db: db,
      tableName: 'checkin_record',
      entityId: recordId,
      entityRow: updatedRow,
    );
    changeNotifier.notify('checkin_record');
    SyncWorker.instance.notifyLocalWrite();
    CheckinWidgetBridge.scheduleRefresh();
  }

  /// 撤销打卡记录（精准匹配 parent_id 与 local_day_key）
  Future<void> undoCheckin({
    required String eventId,
    required String dayKey,
  }) async {
    final existing = await db.query(
      'checkin_record',
      where: "(parent_id = ? OR body LIKE ?) AND body LIKE ?",
      whereArgs: [eventId, '%"event_id":"$eventId"%', '%"local_day_key":"$dayKey"%'],
    );
    for (final r in existing) {
      try {
        final bodyStr = r['body'] as String? ?? '{}';
        final map = jsonDecode(bodyStr) as Map<String, dynamic>;
        final rec = CheckinRecord.fromJson(map);
        if (rec.eventId == eventId && rec.localDayKey == dayKey) {
          final id = r['id'] as String;
          await LocalFirstDB.persistDeleteRaw(
            db: db,
            tableName: 'checkin_record',
            entityId: id,
          );
        }
      } catch (_) {}
    }
    changeNotifier.notify('checkin_record');
    SyncWorker.instance.notifyLocalWrite();
    CheckinWidgetBridge.scheduleRefresh();
  }
}
