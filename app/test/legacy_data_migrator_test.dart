import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/sync/v2/sync_v2.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-3.3: 老客户端数据自愈平滑迁移 (One-time Bootstrap) 测试', () {
    late Database db;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
    });

    tearDown(() async {
      await db.close();
    });

    test('验收标准：模拟存量 failed 与 pending 数据升级后进入 outbox，本地业务数据 0 丢失', () async {
      // 1. 在本地表中构造存量历史数据
      // 包含多种状态：synced (已同步), archived (已归档), pending (待同步), failed (历史失败)
      final postSynced = {
        'id': 'post-synced-1',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'owner': 'user-1',
        'parent_id': 'repo-1',
        'unique': null,
        'sync_status': 'synced',
        'color_tag': 'none',
        'body': jsonEncode({'title': 'Synced Note'}),
      };

      final postFailed = {
        'id': 'post-failed-1',
        'created_at': '2026-01-02T00:00:00Z',
        'updated_at': '2026-01-02T00:00:00Z',
        'owner': 'user-1',
        'parent_id': 'repo-1',
        'unique': null,
        'sync_status': 'failed',
        'color_tag': 'red',
        'body': jsonEncode({'title': 'Failed Note Need Retry'}),
      };

      final postPending = {
        'id': 'post-pending-1',
        'created_at': '2026-01-03T00:00:00Z',
        'updated_at': '2026-01-03T00:00:00Z',
        'owner': 'user-1',
        'parent_id': 'repo-1',
        'unique': null,
        'sync_status': 'pending',
        'color_tag': 'yellow',
        'body': jsonEncode({'title': 'Pending Offline Note'}),
      };

      final taskArchived = {
        'id': 'task-archived-1',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'owner': 'user-1',
        'parent_id': null,
        'unique': null,
        'sync_status': 'archived',
        'color_tag': 'gray',
        'body': jsonEncode({'name': 'Archived Task'}),
      };

      final taskFailed = {
        'id': 'task-failed-1',
        'created_at': '2026-01-04T00:00:00Z',
        'updated_at': '2026-01-04T00:00:00Z',
        'owner': 'user-1',
        'parent_id': null,
        'unique': null,
        'sync_status': 'failed',
        'color_tag': 'blue',
        'body': jsonEncode({'name': 'Failed Task'}),
      };

      // 模拟旧库历史，甚至包含带 c_ 前缀的旧业务表 c_tracker
      await db.execute(LocalFirstDB.buildEntityTableSql('c_tracker'));
      final trackerPending = {
        'id': 'tracker-pending-1',
        'created_at': '2026-01-05T00:00:00Z',
        'updated_at': '2026-01-05T00:00:00Z',
        'owner': 'user-1',
        'parent_id': null,
        'unique': null,
        'sync_status': 'pending',
        'color_tag': 'green',
        'body': jsonEncode({'habit': 'Read Books'}),
      };

      await db.insert('post', postSynced);
      await db.insert('post', postFailed);
      await db.insert('post', postPending);
      await db.insert('check_list', taskArchived);
      await db.insert('check_list', taskFailed);
      await db.insert('c_tracker', trackerPending);

      // 验证初始状态下，outbox 为空
      expect(await OutboxDao.count(db), equals(0));

      // 2. 执行老客户端自愈平滑迁移
      final count = await LegacyDataMigrator.migrateLegacyClientDataIfNeeded(db);
      // 应该迁移 3 条记录：postFailed, postPending, taskFailed, trackerPending -> 共 4 条
      expect(count, equals(4));

      // 3. 验证 Outbox 表中的生成内容
      final outboxItems = await OutboxDao.getPending(db, limit: 100);
      expect(outboxItems.length, equals(4));

      final outboxEntityIds = outboxItems.map((e) => e.entityId).toSet();
      expect(outboxEntityIds.contains('post-failed-1'), isTrue);
      expect(outboxEntityIds.contains('post-pending-1'), isTrue);
      expect(outboxEntityIds.contains('task-failed-1'), isTrue);
      expect(outboxEntityIds.contains('tracker-pending-1'), isTrue);
      // 已同步和归档的不应进入 outbox
      expect(outboxEntityIds.contains('post-synced-1'), isFalse);
      expect(outboxEntityIds.contains('task-archived-1'), isFalse);

      // 验证表名标准化（c_tracker 去除了 c_ 前缀）
      final trackerOutbox = outboxItems.firstWhere((e) => e.entityId == 'tracker-pending-1');
      expect(trackerOutbox.tableName, equals('tracker'));
      expect(trackerOutbox.op, equals('PUT'));

      // 4. 验证验收标准：本地业务数据 0 丢失！
      final postsInDb = await db.query('post');
      expect(postsInDb.length, equals(3));
      final tasksInDb = await db.query('check_list');
      expect(tasksInDb.length, equals(2));
      final trackersInDb = await db.query('c_tracker');
      expect(trackersInDb.length, equals(1));

      // 5. 验证 sync_meta 状态
      final lastSeq = await SyncMetaDao.getLastSeq(db);
      expect(lastSeq, equals(0));
      final isMigrated = await SyncMetaDao.isLegacyMigrated(db);
      expect(isMigrated, isTrue);

      // 6. 验证幂等性：再次执行迁移，不会重复入队
      final reRunCount = await LegacyDataMigrator.migrateLegacyClientDataIfNeeded(db);
      expect(reRunCount, equals(0));
      expect(await OutboxDao.count(db), equals(4));
    });

    test('跨多旧库文件（如 notes.db）合并迁移到统一目标数据库测试', () async {
      final tempDir = await Directory.systemTemp.createTemp('legacy_dbs_');
      try {
        final notesDbPath = p.join(tempDir.path, 'notes.db');
        final oldNotesDb = await databaseFactoryFfi.openDatabase(notesDbPath);
        await oldNotesDb.execute(LocalFirstDB.buildEntityTableSql('repo'));
        await oldNotesDb.execute(LocalFirstDB.buildEntityTableSql('post'));

        // 插入旧数据
        await oldNotesDb.insert('repo', {
          'id': 'repo-old-1',
          'created_at': '2025-01-01T00:00:00Z',
          'updated_at': '2025-01-01T00:00:00Z',
          'owner': 'user-1',
          'parent_id': null,
          'unique': null,
          'sync_status': 'synced',
          'color_tag': 'none',
          'body': jsonEncode({'name': 'Old Notebook'}),
        });
        await oldNotesDb.insert('post', {
          'id': 'post-old-failed-1',
          'created_at': '2025-01-01T00:00:00Z',
          'updated_at': '2025-01-01T00:00:00Z',
          'owner': 'user-1',
          'parent_id': 'repo-old-1',
          'unique': null,
          'sync_status': 'failed',
          'color_tag': 'red',
          'body': jsonEncode({'title': 'Old Failed Note'}),
        });
        await oldNotesDb.close();

        // 目标新库执行迁移
        final targetDb = await LocalFirstDB.openInMemory();
        final migratedCount = await LegacyDataMigrator.migrateLegacyFilesToTargetDb(
          targetDb: targetDb,
          legacyDirPath: tempDir.path,
        );

        expect(migratedCount, equals(1));
        // 目标库中存量 repo 和 post 均完整保留
        final repos = await targetDb.query('repo');
        expect(repos.length, equals(1));
        expect(repos.first['id'], equals('repo-old-1'));

        final posts = await targetDb.query('post');
        expect(posts.length, equals(1));
        expect(posts.first['id'], equals('post-old-failed-1'));

        // outbox 中有 1 条 PUT
        final outbox = await OutboxDao.getPending(targetDb);
        expect(outbox.length, equals(1));
        expect(outbox.first.entityId, equals('post-old-failed-1'));
        expect(outbox.first.op, equals('PUT'));

        await targetDb.close();
      } finally {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
