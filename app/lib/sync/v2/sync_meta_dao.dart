import 'package:sqflite/sqflite.dart';

/// 负责访问和管理 sync_meta 元数据状态表
class SyncMetaDao {
  static const String tableName = 'sync_meta';
  static const String keyLastSeq = 'last_seq';
  static const String keyLegacyMigrated = 'legacy_migrated';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  ''';

  /// 读取当前同步检查点游标 last_seq，不存在时返回 0
  static Future<int> getLastSeq(DatabaseExecutor db) async {
    final value = await get(db, keyLastSeq);
    if (value == null) return 0;
    return int.tryParse(value) ?? 0;
  }

  /// 更新同步检查点游标 last_seq
  static Future<void> setLastSeq(DatabaseExecutor db, int seq) async {
    await set(db, keyLastSeq, seq.toString());
  }

  /// 读取任意元数据 key
  static Future<String?> get(DatabaseExecutor db, String key) async {
    final rows = await db.query(
      tableName,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  /// 插入或更新元数据
  static Future<void> set(DatabaseExecutor db, String key, String value) async {
    await db.insert(
      tableName,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 判断是否已完成存量数据平滑自愈迁移
  static Future<bool> isLegacyMigrated(DatabaseExecutor db) async {
    final val = await get(db, keyLegacyMigrated);
    return val == 'true';
  }

  /// 标记已完成存量数据平滑迁移
  static Future<void> setLegacyMigrated(DatabaseExecutor db) async {
    await set(db, keyLegacyMigrated, 'true');
  }
}
