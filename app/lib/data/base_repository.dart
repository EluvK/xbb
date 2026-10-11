import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

/// 通用 Local-First 响应式仓储基类
abstract class BaseLocalFirstRepository<T> {
  final Database db;
  final DatabaseChangeNotifier changeNotifier;
  final String tableName;

  BaseLocalFirstRepository({
    required this.db,
    required this.changeNotifier,
    required this.tableName,
  });

  /// 实体序列化为 JSON 字符串
  String serialize(T entity);

  /// JSON Map 反序列化为实体
  T deserialize(Map<String, dynamic> json);

  /// 获取实体主键 ID
  String getId(T entity);

  /// 获取实体的父级 ID（若有）
  String? getParentId(T entity) => null;

  /// 获取实体拥有者 ID
  String getOwner(T entity);

  /// 监听当前表全部记录的响应式 Stream（按 created_at 倒序）
  Stream<List<T>> watchAll({String orderBy = 'created_at DESC'}) {
    return changeNotifier.watchTable(tableName).asyncMap((_) async {
      final rows = await db.query(tableName, orderBy: orderBy);
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        return deserialize(jsonDecode(bodyStr) as Map<String, dynamic>);
      }).toList();
    });
  }

  /// 监听带条件的响应式 Stream
  Stream<List<T>> watchWhere({
    String? where,
    List<Object?>? whereArgs,
    String orderBy = 'created_at DESC',
  }) {
    return changeNotifier.watchTable(tableName).asyncMap((_) async {
      final rows = await db.query(
        tableName,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
      );
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        return deserialize(jsonDecode(bodyStr) as Map<String, dynamic>);
      }).toList();
    });
  }

  /// 根据 ID 监听单个实体
  Stream<T?> watchById(String id) {
    return changeNotifier.watchTable(tableName).asyncMap((_) async {
      final rows = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final bodyStr = rows.first['body'] as String? ?? '{}';
      return deserialize(jsonDecode(bodyStr) as Map<String, dynamic>);
    });
  }

  /// 原子保存（更新业务表 + 入队 Outbox PUT + 广播变更 + 唤醒 SyncWorker）
  Future<void> save(T entity, {String? colorTag = 'default', String? syncStatus = 'pending'}) async {
    final entityId = getId(entity);
    final nowIso = DateTime.now().toIso8601String();
    final bodyJsonStr = serialize(entity);

    final row = <String, dynamic>{
      'id': entityId,
      'created_at': nowIso,
      'updated_at': nowIso,
      'owner': getOwner(entity),
      'parent_id': getParentId(entity),
      'sync_status': syncStatus ?? 'pending',
      'color_tag': colorTag ?? 'default',
      'body': bodyJsonStr,
    };

    await LocalFirstDB.persistPutRaw(
      db: db,
      tableName: tableName,
      entityId: entityId,
      entityRow: row,
    );

    changeNotifier.notify(tableName);
    SyncWorker.instance.notifyLocalWrite();
  }

  /// 原子删除（清理本地业务表 + 入队 Outbox DELETE + 广播变更 + 唤醒 SyncWorker）
  Future<void> delete(String id) async {
    await LocalFirstDB.persistDeleteRaw(
      db: db,
      tableName: tableName,
      entityId: id,
    );

    changeNotifier.notify(tableName);
    SyncWorker.instance.notifyLocalWrite();
  }
}
