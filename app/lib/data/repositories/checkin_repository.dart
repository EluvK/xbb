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
  }) async {
    final newId = UuidService.v7();
    final event = CheckinEvent(name: name, description: description, colorValue: colorValue);
    final row = <String, dynamic>{
      'id': newId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
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

  /// 删除打卡事件
  Future<void> deleteEvent(String id) async {
    await LocalFirstDB.persistDeleteRaw(
      db: db,
      tableName: 'checkin_event',
      entityId: id,
    );
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
  }) async {
    final today = DateTime.now();
    final todayKey = formatLocalDayKey(today);
    final targetDayKey = formatLocalDayKey(targetDate);

    // ADR-0003: 严禁未来预打卡
    if (targetDayKey.compareTo(todayKey) > 0) {
      throw ArgumentError('严禁未来预打卡 (ADR-0003)');
    }

    // 检查是否已在该日期打卡
    final existing = await db.query(
      'checkin_record',
      where: "body LIKE ?",
      whereArgs: ['%"event_id":"$eventId"%"local_day_key":"$targetDayKey"%'],
    );
    if (existing.isNotEmpty) {
      return false; // 当日已存在记录
    }

    final newId = UuidService.v7();
    final record = CheckinRecord(
      eventId: eventId,
      createdAtUtc: DateTime.now().toUtc(),
      localDayKey: targetDayKey,
      timezoneOffsetMinutes: targetDate.timeZoneOffset.inMinutes,
      note: note,
    );

    final row = <String, dynamic>{
      'id': newId,
      'created_at': DateTime.now().toIso8601String(),
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

  /// 撤销打卡记录
  Future<void> undoCheckin({
    required String eventId,
    required String dayKey,
  }) async {
    final existing = await db.query(
      'checkin_record',
      where: "body LIKE ?",
      whereArgs: ['%"event_id":"$eventId"%"local_day_key":"$dayKey"%'],
    );
    for (final r in existing) {
      final id = r['id'] as String;
      await LocalFirstDB.persistDeleteRaw(
        db: db,
        tableName: 'checkin_record',
        entityId: id,
      );
    }
    changeNotifier.notify('checkin_record');
    SyncWorker.instance.notifyLocalWrite();
    CheckinWidgetBridge.scheduleRefresh();
  }
}
