import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/base_repository.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/models/tracker/model.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';
import 'package:xbb/sync/v2/uuid_service.dart';

class TrackerRepository {
  final Database db;
  final DatabaseChangeNotifier changeNotifier;

  TrackerRepository({
    required this.db,
    required this.changeNotifier,
  });

  /// 监听所有追踪器 (Tracker)
  Stream<List<DataItem<Tracker>>> watchTrackers() {
    return changeNotifier.watchTable('tracker').asyncMap((_) async {
      final rows = await db.query('tracker', orderBy: 'created_at DESC');
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final tracker = Tracker.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        return DataItem<Tracker>(
          r['id'] as String,
          DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
          DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now(),
          r['owner'] as String? ?? 'default',
          null,
          null,
          body: tracker,
          syncStatus: SyncStatus.synced,
        );
      }).toList();
    });
  }

  /// 监听某追踪器的全部记录 (TrackerRecord)
  Stream<List<DataItem<TrackerRecord>>> watchRecordsByTracker(String? trackerId) {
    return changeNotifier.watchTable('tracker_record').asyncMap((_) async {
      if (trackerId == null || trackerId.isEmpty) return <DataItem<TrackerRecord>>[];
      final rows = await db.query(
        'tracker_record',
        where: 'parent_id = ?',
        whereArgs: [trackerId],
        orderBy: 'created_at DESC',
      );
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final record = TrackerRecord.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        return DataItem<TrackerRecord>(
          r['id'] as String,
          DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
          DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now(),
          r['owner'] as String? ?? 'default',
          trackerId,
          null,
          body: record,
          syncStatus: SyncStatus.synced,
        );
      }).toList();
    });
  }

  /// 保存追踪器
  Future<void> saveTracker(DataItem<Tracker> item) async {
    final nowIso = DateTime.now().toIso8601String();
    final row = <String, dynamic>{
      'id': item.id,
      'created_at': nowIso,
      'updated_at': nowIso,
      'owner': item.owner,
      'parent_id': null,
      'sync_status': 'pending',
      'color_tag': 'default',
      'body': jsonEncode(item.body.toJson()),
    };
    await LocalFirstDB.persistPutRaw(
      db: db,
      tableName: 'tracker',
      entityId: item.id,
      entityRow: row,
    );
    changeNotifier.notify('tracker');
    SyncWorker.instance.notifyLocalWrite();
  }

  /// 删除追踪器
  Future<void> deleteTracker(String id) async {
    await LocalFirstDB.persistDeleteRaw(
      db: db,
      tableName: 'tracker',
      entityId: id,
    );
    changeNotifier.notify('tracker');
    SyncWorker.instance.notifyLocalWrite();
  }

  /// 添加追踪记录
  Future<void> addRecord({
    required String trackerId,
    required String? value,
    required String? content,
    required String currentUserId,
  }) async {
    final newId = UuidService.v7();
    final record = TrackerRecord(
      trackerId: trackerId,
      timestamp: DateTime.now(),
      value: value,
      content: content,
    );
    final nowIso = DateTime.now().toIso8601String();
    final row = <String, dynamic>{
      'id': newId,
      'created_at': nowIso,
      'updated_at': nowIso,
      'owner': currentUserId,
      'parent_id': trackerId,
      'sync_status': 'pending',
      'color_tag': 'default',
      'body': jsonEncode(record.toJson()),
    };
    await LocalFirstDB.persistPutRaw(
      db: db,
      tableName: 'tracker_record',
      entityId: newId,
      entityRow: row,
    );
    changeNotifier.notify('tracker_record');
    SyncWorker.instance.notifyLocalWrite();
  }
}
