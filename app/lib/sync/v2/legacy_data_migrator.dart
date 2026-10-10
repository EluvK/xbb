import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'local_first_db.dart';
import 'outbox_dao.dart';
import 'outbox_item.dart';
import 'sync_meta_dao.dart';
import 'uuid_service.dart';

/// 负责老客户端存量数据的平滑自愈迁移（One-time Bootstrap）
class LegacyDataMigrator {
  /// 老业务表候选名称列表（包含带 c_ 前缀与普通命名）
  static const List<String> defaultLegacyTables = [
    'repo',
    'post',
    'comment',
    'check_list',
    'task',
    'tracker',
    'tracker_record',
    'checkin_event',
    'checkin_record',
    'clipboard_history_entry',
    'chat_assistant',
    'chat_conversation',
    'chat_message',
    // 兼容历史带 c_ 前缀命名
    'c_repo',
    'c_post',
    'c_comment',
    'c_check_list',
    'c_task',
    'c_tracker',
    'c_tracker_record',
    'c_checkin_event',
    'c_checkin_record',
    'c_clipboard_history_entry',
    'c_chat_assistant',
    'c_chat_conversation',
    'c_chat_message',
  ];

  /// 将表名规范化为业务实体标准表名（去除 c_ 前缀并将 task 映射为 check_list 等）
  static String normalizeTableName(String rawName) {
    var name = rawName;
    if (name.startsWith('c_')) {
      name = name.substring(2);
    }
    if (name == 'task') {
      name = 'check_list';
    }
    return name;
  }

  /// 检查指定数据库中是否存在目标表
  static Future<bool> tableExists(DatabaseExecutor db, String tableName) async {
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [tableName],
    );
    return res.isNotEmpty;
  }

  /// 针对单个数据库执行存量数据平滑自愈迁移（若未迁移过）
  ///
  /// 工作流：
  /// 1. 检查 sync_meta.legacy_migrated，若已迁移则直接返回。
  /// 2. 扫描本地所有旧业务表：
  ///    - 将所有 sync_status IN ('pending', 'failed') 的记录转换为 outbox 中的待发 PUT 记录。
  ///    - 已同步/归档记录完整保留在本地表中，不作删除。
  ///    - 将 sync_meta.last_seq 置为 0。
  /// 3. 设置 sync_meta.legacy_migrated = 'true'。
  static Future<int> migrateLegacyClientDataIfNeeded(
    Database db, {
    List<String>? tableCandidates,
  }) async {
    // 确保同步元数据表存在
    await LocalFirstDB.initSyncTables(db);

    final alreadyMigrated = await SyncMetaDao.isLegacyMigrated(db);
    if (alreadyMigrated) {
      return 0;
    }

    var migratedOutboxCount = 0;
    final tables = tableCandidates ?? defaultLegacyTables;

    await db.transaction((txn) async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      for (final rawTable in tables) {
        if (!await tableExists(txn, rawTable)) {
          continue;
        }

        final normalizedTable = normalizeTableName(rawTable);

        // 检查该表是否具备 sync_status 列
        final pragma = await txn.rawQuery('PRAGMA table_info($rawTable)');
        final hasSyncStatus = pragma.any((col) => col['name'] == 'sync_status');
        if (!hasSyncStatus) {
          continue;
        }

        // 扫描 sync_status IN ('pending', 'failed') 的存量未同步/失败记录
        final pendingRows = await txn.rawQuery(
          "SELECT id, body FROM $rawTable WHERE LOWER(sync_status) IN ('pending', 'failed')",
        );

        for (final row in pendingRows) {
          final entityId = row['id'] as String?;
          final bodyData = row['body'] as String?;
          if (entityId == null) continue;

          final outbox = OutboxItem.put(
            id: UuidService.v7(),
            tableName: normalizedTable,
            entityId: entityId,
            data: bodyData,
            baseVersion: 1,
            createdAt: nowMs,
          );

          await OutboxDao.enqueue(txn, outbox);
          migratedOutboxCount++;
        }
      }

      // 将 sync_meta.last_seq 置为 0，确保首次 Pull 能从头对齐日志流
      await SyncMetaDao.setLastSeq(txn, 0);

      // 标记完成首次自愈迁移
      await SyncMetaDao.setLegacyMigrated(txn);
    });

    return migratedOutboxCount;
  }

  /// 扫描旧的多数据库文件（如 notes.db, task.db 等）并将其合并到目标数据库中
  static Future<int> migrateLegacyFilesToTargetDb({
    required Database targetDb,
    required String legacyDirPath,
    DatabaseFactory? customFactory,
  }) async {
    // 确保目标库已建表
    await LocalFirstDB.initSyncTables(targetDb);

    final alreadyMigrated = await SyncMetaDao.isLegacyMigrated(targetDb);
    if (alreadyMigrated) return 0;

    final dir = Directory(legacyDirPath);
    if (!dir.existsSync()) {
      return await migrateLegacyClientDataIfNeeded(targetDb);
    }

    final dbFiles = [
      'notes.db',
      'task.db',
      'tracker.db',
      'checkin.db',
      'clipboard.db',
      'chat.db',
    ];

    var totalOutbox = 0;
    final factory = customFactory ?? databaseFactory;

    await targetDb.transaction((targetTxn) async {
      for (final fileName in dbFiles) {
        final filePath = join(legacyDirPath, fileName);
        if (!File(filePath).existsSync()) continue;

        Database? legacyDb;
        try {
          legacyDb = await factory.openDatabase(
            filePath,
            options: OpenDatabaseOptions(readOnly: true),
          );

          // 遍历老库中的业务表
          for (final rawTable in defaultLegacyTables) {
            if (!await tableExists(legacyDb, rawTable)) continue;

            final normalizedTable = normalizeTableName(rawTable);
            // 确保目标库存在该表
            await targetTxn.execute(LocalFirstDB.buildEntityTableSql(normalizedTable));

            final rows = await legacyDb.query(rawTable);
            for (final row in rows) {
              // 1. 保留所有业务数据入目标库（0 数据丢失）
              final map = Map<String, dynamic>.from(row);
              await targetTxn.insert(
                normalizedTable,
                map,
                conflictAlgorithm: ConflictAlgorithm.ignore,
              );

              // 2. 将 pending 或 failed 记录转入 outbox
              final syncStatus = (map['sync_status'] as String?)?.toLowerCase();
              if (syncStatus == 'pending' || syncStatus == 'failed') {
                final entityId = map['id'] as String;
                final body = map['body'] as String?;
                await OutboxDao.enqueue(
                  targetTxn,
                  OutboxItem.put(
                    tableName: normalizedTable,
                    entityId: entityId,
                    data: body,
                    baseVersion: 1,
                  ),
                );
                totalOutbox++;
              }
            }
          }
        } catch (_) {
          // 容错处理个别无法读取的旧文件
        } finally {
          if (legacyDb != null && legacyDb.isOpen) {
            await legacyDb.close();
          }
        }
      }

      await SyncMetaDao.setLastSeq(targetTxn, 0);
      await SyncMetaDao.setLegacyMigrated(targetTxn);
    });

    return totalOutbox;
  }
}
