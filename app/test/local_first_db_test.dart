import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/sync/v2/sync_v2.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-3.2: 纯 Dart UUIDv7 生成器测试', () {
    test('生成的 UUIDv7 格式正确且符合 RFC 9562 规范', () {
      final id1 = UuidService.v7();
      final id2 = UuidService.v7();

      expect(id1, isNotEmpty);
      expect(id1.length, equals(36));
      expect(id1[14], equals('7')); // version 7

      // 验证正则表达式标准 UUID
      final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(uuidRegex.hasMatch(id1), isTrue);
      expect(uuidRegex.hasMatch(id2), isTrue);
      expect(id1 != id2, isTrue);
    });

    test('快速连续生成的 UUIDv7 具有时间单调性', () async {
      final id1 = UuidService.v7();
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final id2 = UuidService.v7();
      expect(id1.compareTo(id2), lessThanOrEqualTo(0));
    });
  });

  group('TASK-3.2: 本地 Local-First 数据库与 Outbox 表结构测试', () {
    late Database db;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
    });

    tearDown(() async {
      await db.close();
    });

    test('数据库初始化时自动建好 outbox 与 sync_meta 表，且 last_seq 默认为 0', () async {
      // 检查 sync_meta 表
      final seq = await SyncMetaDao.getLastSeq(db);
      expect(seq, equals(0));

      // 检查 sync_meta 增删改查
      await SyncMetaDao.setLastSeq(db, 108);
      expect(await SyncMetaDao.getLastSeq(db), equals(108));

      await SyncMetaDao.set(db, 'custom_flag', 'enabled');
      expect(await SyncMetaDao.get(db, 'custom_flag'), equals('enabled'));

      // 检查 outbox 初始为空
      final count = await OutboxDao.count(db);
      expect(count, equals(0));
    });

    test('outbox 支持按时间序列入队与批量删除已确认变更', () async {
      final item1 = OutboxItem.put(
        tableName: 'post',
        entityId: 'post-1',
        data: const {'title': 'Hello World'},
        baseVersion: 1,
        createdAt: 1000,
      );
      final item2 = OutboxItem.delete(
        tableName: 'post',
        entityId: 'post-2',
        baseVersion: 2,
        createdAt: 2000,
      );

      await OutboxDao.enqueue(db, item1);
      await OutboxDao.enqueue(db, item2);

      expect(await OutboxDao.count(db), equals(2));

      final pending = await OutboxDao.getPending(db, limit: 10);
      expect(pending.length, equals(2));
      expect(pending[0].entityId, equals('post-1'));
      expect(pending[0].op, equals('PUT'));
      expect(pending[0].parsedData, equals({'title': 'Hello World'}));
      expect(pending[1].entityId, equals('post-2'));
      expect(pending[1].op, equals('DELETE'));

      // 批量清除已确认变更
      final deleted = await OutboxDao.deleteByIds(db, [item1.id]);
      expect(deleted, equals(1));
      expect(await OutboxDao.count(db), equals(1));
    });

    test('验收标准：本地写入测试——事务内同时插入业务表与 outbox', () async {
      final entityId = UuidService.v7();
      final nowStr = DateTime.now().toUtc().toIso8601String();
      final bodyMap = {
        'repo_id': 'repo-default',
        'title': 'Local-First Post',
        'content': 'Write offline, sync later.',
      };
      final bodyJson = jsonEncode(bodyMap);

      final entityRow = {
        'id': entityId,
        'created_at': nowStr,
        'updated_at': nowStr,
        'owner': 'user-123',
        'parent_id': 'repo-default',
        'unique': null,
        'sync_status': 'pending',
        'color_tag': 'none',
        'body': bodyJson,
      };

      final outboxItem = OutboxItem.put(
        tableName: 'post',
        entityId: entityId,
        data: bodyJson,
        baseVersion: 1,
      );

      // 执行事务写入：同时插入业务表 post 与 outbox
      await LocalFirstDB.saveEntityWithOutbox(
        db: db,
        tableName: 'post',
        entityRow: entityRow,
        outboxItem: outboxItem,
      );

      // 验证业务表 post 已有记录
      final postRows = await db.query('post', where: 'id = ?', whereArgs: [entityId]);
      expect(postRows.length, equals(1));
      expect(postRows.first['id'], equals(entityId));
      expect(postRows.first['body'], equals(bodyJson));

      // 验证 outbox 表已记录该变更
      final outboxRows = await OutboxDao.getPending(db);
      expect(outboxRows.length, equals(1));
      expect(outboxRows.first.entityId, equals(entityId));
      expect(outboxRows.first.tableName, equals('post'));
      expect(outboxRows.first.op, equals('PUT'));
      expect(outboxRows.first.data, equals(bodyJson));
    });

    test('事务写入测试：若事务中途异常，业务表与 outbox 均原子回滚', () async {
      final entityId = UuidService.v7();
      final entityRow = {
        'id': entityId,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'owner': 'user-123',
        'parent_id': null,
        'unique': null,
        'sync_status': 'pending',
        'color_tag': 'none',
        'body': '{}',
      };
      final outboxItem = OutboxItem.put(
        tableName: 'post',
        entityId: entityId,
        data: '{}',
      );

      expect(
        () async {
          await db.transaction((txn) async {
            await txn.insert('post', entityRow);
            await OutboxDao.enqueue(txn, outboxItem);
            throw Exception('Simulated write failure');
          });
        },
        throwsException,
      );

      // 检查回滚结果：业务表和 outbox 均无新增记录
      final postRows = await db.query('post', where: 'id = ?', whereArgs: [entityId]);
      expect(postRows.isEmpty, isTrue);

      final outboxCount = await OutboxDao.count(db);
      expect(outboxCount, equals(0));
    });
  });
}
