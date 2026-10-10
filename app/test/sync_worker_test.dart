import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/sync/v2/sync_v2.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-3.4: 全局单例 SyncWorker 守护与端到端同步测试', () {
    late Database db;
    late Dio dio;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
      dio = Dio();
    });

    tearDown(() async {
      await db.close();
      SyncWorker.instance.stop();
    });

    test('验收标准 1: 客户端离线写入出队、连网后 Push 成功并清除 outbox', () async {
      final postId = UuidService.v7();
      final postData = {'title': 'Offline Draft', 'content': 'Waiting for sync'};
      final postDataStr = jsonEncode(postData);

      // 1. 离线写入：事务内写入业务表与 outbox
      await LocalFirstDB.saveEntityWithOutbox(
        db: db,
        tableName: 'post',
        entityRow: {
          'id': postId,
          'created_at': '2026-03-01T10:00:00Z',
          'updated_at': '2026-03-01T10:00:00Z',
          'owner': 'user-1',
          'parent_id': null,
          'unique': null,
          'sync_status': 'pending',
          'color_tag': 'none',
          'body': postDataStr,
        },
        outboxItem: OutboxItem.put(
          tableName: 'post',
          entityId: postId,
          data: postData,
          baseVersion: 1,
        ),
      );

      expect(await OutboxDao.count(db), equals(1));

      // 2. Mock Dio Adapter 响应 /sync/v1/push
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        if (options.path.endsWith('/sync/v1/push')) {
          final body = options.data as Map<String, dynamic>;
          final mutations = body['mutations'] as List<dynamic>;
          expect(mutations.length, equals(1));
          expect(mutations.first['id'], equals(postId));
          expect(mutations.first['table'], equals('post'));
          expect(mutations.first['op'], equals('PUT'));

          return ResponseBody.fromString(
            jsonEncode({
              'applied_ids': [postId],
              'conflicts': [],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        if (options.path.endsWith('/sync/v1/pull')) {
          return ResponseBody.fromString(
            jsonEncode({
              'checkpoint': 0,
              'has_more': false,
              'changes': [],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        throw Exception('Unhandled mock path: ${options.path}');
      });

      // 3. 触发 SyncWorker 连网同步
      final worker = SyncWorker(
        dio: dio,
        db: db,
        clientId: 'device-test-1',
      );

      await worker.triggerSync();

      // 4. 验证 outbox 中已确认变更被成功删除（出队）
      expect(await OutboxDao.count(db), equals(0));
    });

    test('验收标准 2: 连网后 Pull 拉回远程变更并在本地事务内批量回放，推进 last_seq', () async {
      expect(await SyncMetaDao.getLastSeq(db), equals(0));

      // 先在本地准备一条待删除的 task
      await db.insert('check_list', {
        'id': 'task-to-delete-1',
        'created_at': '2026-03-01T00:00:00Z',
        'updated_at': '2026-03-01T00:00:00Z',
        'owner': 'remote',
        'parent_id': null,
        'unique': null,
        'sync_status': 'synced',
        'color_tag': 'none',
        'body': jsonEncode({'title': 'Old Task'}),
      });

      final remotePostId = UuidService.v7();
      final remotePostData = {'title': 'Remote New Post', 'author': 'Bob'};

      // Mock 服务端响应 Pull 请求下发的 PUT 与 DELETE 变更流
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        if (options.path.endsWith('/sync/v1/pull')) {
          expect(options.queryParameters['checkpoint'], equals(0));

          return ResponseBody.fromString(
            jsonEncode({
              'checkpoint': 102,
              'has_more': false,
              'changes': [
                {
                  'seq': 101,
                  'table': 'post',
                  'id': remotePostId,
                  'op': 'PUT',
                  'data': remotePostData,
                  'version': 2,
                },
                {
                  'seq': 102,
                  'table': 'check_list',
                  'id': 'task-to-delete-1',
                  'op': 'DELETE',
                  'version': 3,
                },
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        throw Exception('Unexpected path: ${options.path}');
      });

      final worker = SyncWorker(
        dio: dio,
        db: db,
        clientId: 'device-test-2',
      );

      await worker.triggerSync();

      // 验证本地业务表数据回放生效
      // 1) 远程新增的 post 已插入本地
      final postRows = await db.query('post', where: 'id = ?', whereArgs: [remotePostId]);
      expect(postRows.length, equals(1));
      expect(jsonDecode(postRows.first['body'] as String), equals(remotePostData));
      expect(postRows.first['sync_status'], equals('synced'));

      // 2) 远程删除的 task 已从本地删除
      final taskRows = await db.query('check_list', where: 'id = ?', whereArgs: ['task-to-delete-1']);
      expect(taskRows.isEmpty, isTrue);

      // 3) 检查点游标已推进到 102
      expect(await SyncMetaDao.getLastSeq(db), equals(102));
    });

    test('验收标准 3: 端到端双向同步：离线写入出队、Push 成功、Pull 拉回其他端变更', () async {
      final localEntityId = UuidService.v7();
      final remoteEntityId = UuidService.v7();

      // 离线写入本地
      await OutboxDao.enqueue(
        db,
        OutboxItem.put(
          tableName: 'tracker',
          entityId: localEntityId,
          data: const {'habit': 'Morning Run'},
        ),
      );
      expect(await OutboxDao.count(db), equals(1));

      // Mock push 和 pull 服务
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        if (options.path.endsWith('/sync/v1/push')) {
          return ResponseBody.fromString(
            jsonEncode({
              'applied_ids': [localEntityId],
              'conflicts': [],
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }

        if (options.path.endsWith('/sync/v1/pull')) {
          return ResponseBody.fromString(
            jsonEncode({
              'checkpoint': 200,
              'has_more': false,
              'changes': [
                {
                  'seq': 200,
                  'table': 'tracker',
                  'id': remoteEntityId,
                  'op': 'PUT',
                  'data': {'habit': 'Evening Yoga'},
                  'version': 1,
                }
              ],
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }

        throw Exception('Unknown: ${options.path}');
      });

      final worker = SyncWorker(dio: dio, db: db, clientId: 'client-e2e');
      await worker.triggerSync();

      // 验证 Push 出队
      expect(await OutboxDao.count(db), equals(0));

      // 验证 Pull 拉回数据
      final trackerRows = await db.query('tracker', where: 'id = ?', whereArgs: [remoteEntityId]);
      expect(trackerRows.length, equals(1));
      expect(await SyncMetaDao.getLastSeq(db), equals(200));
    });

    test('优雅处理 426 Upgrade Required 响应并触发回调，停止轮询', () async {
      String? upgradeMessage;
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({
            'code': 'CLIENT_UPGRADE_REQUIRED',
            'message': '当前客户端同步协议已废弃，请升级到最新应用版本。',
          }),
          426,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final worker = SyncWorker(
        dio: dio,
        db: db,
        onUpgradeRequired: (msg) {
          upgradeMessage = msg;
        },
      );

      worker.start();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(worker.isUpgradeRequired, isTrue);
      expect(worker.isRunning, isFalse); // 轮询自动停止
      expect(upgradeMessage, contains('当前客户端同步协议已废弃，请升级到最新应用版本。'));
    });

    test('本地写操作与网络恢复唤醒机制触发测试', () async {
      var syncCount = 0;
      dio.httpClientAdapter = _MockHttpClientAdapter((options) async {
        syncCount++;
        return ResponseBody.fromString(
          jsonEncode({
            'checkpoint': 1,
            'has_more': false,
            'changes': [],
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      final worker = SyncWorker(dio: dio, db: db);

      // 本地写入唤醒
      worker.notifyLocalWrite();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(syncCount, greaterThanOrEqualTo(1));

      // 网络恢复唤醒
      worker.notifyNetworkRestored();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(syncCount, greaterThanOrEqualTo(2));
    });
  });
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  _MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
