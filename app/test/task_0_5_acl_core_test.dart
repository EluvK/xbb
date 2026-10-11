import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/core/acl/acl_repository.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

class _AclMockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  _AclMockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-0.5: 重构细粒度权限控制核心 (ACL Core & AclEditor 组件)', () {
    late Database db;
    late DatabaseChangeNotifier dbChangeNotifier;
    late Dio testDio;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
      dbChangeNotifier = DatabaseChangeNotifier();
      testDio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:10101'));
    });

    tearDown(() async {
      await db.close();
      SyncWorker.instance.stop();
    });

    test('EntityAclRole 权限矩阵映射', () {
      expect(EntityAclRole.spy.serverPermission, equals('READ'));
      expect(EntityAclRole.subscribe.serverPermission, equals('READ'));
      expect(EntityAclRole.share.serverPermission, equals('WRITE'));
      expect(EntityAclRole.fullAccess.serverPermission, equals('WRITE'));
    });

    test('grantPermission 在本地落盘并向远端发起 /sync/v1/acl/grant', () async {
      Map<String, dynamic>? grantPayload;
      testDio.httpClientAdapter = _AclMockAdapter((options) async {
        if (options.path.endsWith('/sync/v1/acl/grant')) {
          grantPayload = options.data as Map<String, dynamic>;
          return ResponseBody.fromString(
            jsonEncode({'status': 'ok'}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        throw Exception('Unhandled path: ${options.path}');
      });

      final repo = AclRepository(dbChangeNotifier, testDio);

      final entry = EntityAclEntry(
        userId: 'user-collaborator-1',
        username: 'collab1',
        nickname: 'Collab One',
        avatar: 'preset_avatar_2',
        role: EntityAclRole.share,
      );

      await repo.grantPermission(
        db: db,
        table: 'repo',
        entityId: 'repo-100',
        entry: entry,
      );

      // 1. 验证本地 SQLite 落盘
      final acls = await repo.getAcls(db, table: 'repo', entityId: 'repo-100');
      expect(acls.length, equals(1));
      expect(acls.first.userId, equals('user-collaborator-1'));
      expect(acls.first.role, equals(EntityAclRole.share));

      // 2. 验证远端 API 载荷 (验收标准：生成合法权限变更事件)
      expect(grantPayload?['table'], equals('repo'));
      expect(grantPayload?['entity_id'], equals('repo-100'));
      expect(grantPayload?['grantee_id'], equals('user-collaborator-1'));
      expect(grantPayload?['permission'], equals('WRITE'));
    });

    test('revokePermission 从本地移除并向远端发起 /sync/v1/acl/revoke', () async {
      Map<String, dynamic>? revokePayload;
      testDio.httpClientAdapter = _AclMockAdapter((options) async {
        if (options.path.endsWith('/sync/v1/acl/grant')) {
          return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
        }
        if (options.path.endsWith('/sync/v1/acl/revoke')) {
          revokePayload = options.data as Map<String, dynamic>;
          return ResponseBody.fromString(
            jsonEncode({'status': 'ok'}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        throw Exception('Unhandled path: ${options.path}');
      });

      final repo = AclRepository(dbChangeNotifier, testDio);

      // 先添加两个协作者
      await repo.grantPermission(
        db: db,
        table: 'tracker',
        entityId: 'tracker-200',
        entry: EntityAclEntry(
          userId: 'user-a',
          username: 'a',
          nickname: 'User A',
          avatar: 'avatar_1',
          role: EntityAclRole.spy,
        ),
      );
      await repo.grantPermission(
        db: db,
        table: 'tracker',
        entityId: 'tracker-200',
        entry: EntityAclEntry(
          userId: 'user-b',
          username: 'b',
          nickname: 'User B',
          avatar: 'avatar_2',
          role: EntityAclRole.fullAccess,
        ),
      );

      expect((await repo.getAcls(db, table: 'tracker', entityId: 'tracker-200')).length, equals(2));

      // 撤销 user-a
      await repo.revokePermission(
        db: db,
        table: 'tracker',
        entityId: 'tracker-200',
        granteeId: 'user-a',
      );

      final after = await repo.getAcls(db, table: 'tracker', entityId: 'tracker-200');
      expect(after.length, equals(1));
      expect(after.first.userId, equals('user-b'));

      expect(revokePayload?['table'], equals('tracker'));
      expect(revokePayload?['entity_id'], equals('tracker-200'));
      expect(revokePayload?['grantee_id'], equals('user-a'));
    });

    test('watchAcls 响应式 Stream 测试', () async {
      final repo = AclRepository(dbChangeNotifier, testDio);

      testDio.httpClientAdapter = _AclMockAdapter((options) async {
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      });

      final stream = repo.watchAcls(db, table: 'repo', entityId: 'repo-stream-test');

      final emitted = <List<EntityAclEntry>>[];
      final sub = stream.listen((data) => emitted.add(data));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitted.length, equals(1)); // 初始空列表

      // 授权一次
      await repo.grantPermission(
        db: db,
        table: 'repo',
        entityId: 'repo-stream-test',
        entry: EntityAclEntry(
          userId: 'user-stream',
          username: 's',
          nickname: 'Stream User',
          avatar: 'avatar_1',
          role: EntityAclRole.subscribe,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(emitted.length, equals(2));
      expect(emitted.last.first.userId, equals('user-stream'));

      await sub.cancel();
    });
  });
}
