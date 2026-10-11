import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'outbox_dao.dart';
import 'outbox_item.dart';
import 'sync_meta_dao.dart';
import 'uuid_service.dart';

/// Local-First 统一数据库管理器与事务封装
class LocalFirstDB {
  static final Map<String, Database> _dbCache = {};
  static Database? mockDb;
  static void setMockDb(Database? db) => mockDb = db;

  /// 核心业务表清单
  static const List<String> coreEntityTables = [
    'repo',
    'post',
    'comment',
    'check_list',
    'tracker',
    'tracker_record',
    'checkin_event',
    'checkin_record',
    'clipboard_history_entry',
    'chat_assistant',
    'chat_conversation',
    'chat_message',
  ];

  /// 生成通用业务实体表 SQL
  static String buildEntityTableSql(String tableName) {
    return '''
      CREATE TABLE IF NOT EXISTS $tableName (
        id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        owner TEXT NOT NULL,
        parent_id TEXT,
        "unique" TEXT,
        sync_status TEXT NOT NULL,
        color_tag TEXT NOT NULL,
        body TEXT NOT NULL
      );
    ''';
  }

  /// 初始化同步表（outbox, sync_meta）及核心实体表
  static Future<void> initSyncTables(DatabaseExecutor db) async {
    // 1. 创建 outbox 表及其索引
    await db.execute(OutboxDao.createTableSql);
    await db.execute(OutboxDao.createIndexSql);

    // 2. 创建 sync_meta 表
    await db.execute(SyncMetaDao.createTableSql);

    // 3. 确保 sync_meta 中至少有初始游标 last_seq = 0
    final existingSeq = await SyncMetaDao.getLastSeq(db);
    if (existingSeq == 0) {
      final current = await SyncMetaDao.get(db, SyncMetaDao.keyLastSeq);
      if (current == null) {
        await SyncMetaDao.setLastSeq(db, 0);
      }
    }

    // 4. 创建已知核心业务实体表
    for (final table in coreEntityTables) {
      await db.execute(buildEntityTableSql(table));
    }

    // 5. 创建 ACL 权限表
    await db.execute('''
      CREATE TABLE IF NOT EXISTS acl (
        data_id TEXT PRIMARY KEY,
        data_collection TEXT NOT NULL,
        permissions TEXT NOT NULL
      );
    ''');
  }

  /// 针对特定用户打开或复用本地 Local-First 数据库
  static Future<Database> getDb({
    required String userId,
    DatabaseFactory? customFactory,
    String? customPath,
  }) async {
    if (mockDb != null) {
      return mockDb!;
    }
    if (_dbCache.containsKey(userId)) {
      final cached = _dbCache[userId]!;
      if (cached.isOpen) return cached;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final factory = customFactory ?? databaseFactory;
    String dbPath;
    if (customPath != null) {
      dbPath = customPath;
    } else {
      final basePath = await factory.getDatabasesPath();
      dbPath = join(basePath, userId, 'app_v2.db');
    }

    final db = await factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await initSyncTables(db);
        },
        onOpen: (Database db) async {
          await initSyncTables(db);
        },
      ),
    );

    _dbCache[userId] = db;
    return db;
  }

  /// 打开一个内存测试数据库（包含所有同步表与核心业务表）
  static Future<Database> openInMemory({DatabaseFactory? customFactory}) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
    }
    final factory = customFactory ?? databaseFactoryFfi;
    final db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await initSyncTables(db);
        },
      ),
    );
    return db;
  }

  /// 在同一个事务内原子性地写入业务实体与 Outbox 变更项
  /// 如果任何一步失败，整个事务将原子回滚
  static Future<void> saveEntityWithOutbox({
    required Database db,
    required String tableName,
    required Map<String, dynamic> entityRow,
    required OutboxItem outboxItem,
  }) async {
    await db.transaction((txn) async {
      // 1. 插入或更新业务表
      await txn.insert(
        tableName,
        entityRow,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. 插入 Outbox 待发变更
      await OutboxDao.enqueue(txn, outboxItem);
    });
  }

  /// 在同一个事务内原子性地删除业务实体与入队 Outbox DELETE 变更
  static Future<void> deleteEntityWithOutbox({
    required Database db,
    required String tableName,
    required String entityId,
    required OutboxItem outboxItem,
  }) async {
    await db.transaction((txn) async {
      // 1. 本地逻辑删除或物理删除
      await txn.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [entityId],
      );

      // 2. 插入 Outbox DELETE 变更
      await OutboxDao.enqueue(txn, outboxItem);
    });
  }

  /// 通用辅助：将本地业务行实体保存并入队 Outbox PUT 变更
  static Future<void> persistPutRaw({
    required Database db,
    required String tableName,
    required String entityId,
    required Map<String, dynamic> entityRow,
  }) async {
    final bodyStr = entityRow['body'] as String? ?? '{}';
    final outbox = OutboxItem.put(
      id: UuidService.v7(),
      tableName: tableName,
      entityId: entityId,
      data: bodyStr,
      baseVersion: 1,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await saveEntityWithOutbox(
      db: db,
      tableName: tableName,
      entityRow: entityRow,
      outboxItem: outbox,
    );
  }

  /// 通用辅助：从本地删除业务实体并入队 Outbox DELETE 变更
  static Future<void> persistDeleteRaw({
    required Database db,
    required String tableName,
    required String entityId,
  }) async {
    final outbox = OutboxItem.delete(
      id: UuidService.v7(),
      tableName: tableName,
      entityId: entityId,
      baseVersion: 1,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await deleteEntityWithOutbox(
      db: db,
      tableName: tableName,
      entityId: entityId,
      outboxItem: outbox,
    );
  }

  /// 关闭指定或全部数据库连接（常用于测试或登出）
  static Future<void> closeAll() async {
    for (final db in _dbCache.values) {
      if (db.isOpen) {
        await db.close();
      }
    }
    _dbCache.clear();
  }
}
