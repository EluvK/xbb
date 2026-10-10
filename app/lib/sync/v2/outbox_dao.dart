import 'package:sqflite/sqflite.dart';
import 'outbox_item.dart';

/// 负责访问和管理 outbox 待发变更队列表
class OutboxDao {
  static const String tableName = 'outbox';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      id TEXT PRIMARY KEY,
      table_name TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      op TEXT NOT NULL,
      data TEXT,
      base_version INTEGER NOT NULL DEFAULT 1,
      created_at INTEGER NOT NULL
    );
  ''';

  static const String createIndexSql = '''
    CREATE INDEX IF NOT EXISTS idx_outbox_created_at ON $tableName (created_at);
  ''';

  /// 向 outbox 表中入队一条待发变更
  static Future<void> enqueue(DatabaseExecutor db, OutboxItem item) async {
    await db.insert(
      tableName,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 批量入队多条变更
  static Future<void> enqueueBatch(DatabaseExecutor db, List<OutboxItem> items) async {
    if (items.isEmpty) return;
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        tableName,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// 获取待发送变更队列列表（默认按创建时间自增排序）
  static Future<List<OutboxItem>> getPending(
    DatabaseExecutor db, {
    int limit = 100,
  }) async {
    final rows = await db.query(
      tableName,
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return rows.map((r) => OutboxItem.fromMap(r)).toList();
  }

  /// 批量清除已确认的变更 ID
  static Future<int> deleteByIds(DatabaseExecutor db, List<String> ids) async {
    if (ids.isEmpty) return 0;
    // 使用占位符批量删除
    final placeholders = List.filled(ids.length, '?').join(',');
    return await db.delete(
      tableName,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// 清除单条变更 ID
  static Future<int> deleteById(DatabaseExecutor db, String id) async {
    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取当前队列长度
  static Future<int> count(DatabaseExecutor db) async {
    final rows = await db.rawQuery('SELECT COUNT(*) as count FROM $tableName');
    if (rows.isEmpty) return 0;
    return (rows.first['count'] as num?)?.toInt() ?? 0;
  }
}
