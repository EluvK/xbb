import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/core/network/api_client.dart';
import 'package:xbb/presentation/providers/sync_provider.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

class _TestMockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  _TestMockAdapter(this.handler);

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

  group('TASK-0.1: 修复 SyncWorker 真实依赖装配与网络连接管道', () {
    late Database db;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
    });

    tearDown(() async {
      await db.close();
      SyncWorker.instance.stop();
    });

    test('ApiClient 规范化 BaseURL 与 Bearer Token 注入', () async {
      final client = ApiClient.instance;
      expect(ApiClient.normalizeBaseUrl('http://127.0.0.1:10101/api/'), equals('http://127.0.0.1:10101'));
      expect(ApiClient.normalizeBaseUrl('http://example.com:8080/api'), equals('http://example.com:8080'));
      expect(ApiClient.normalizeBaseUrl('http://localhost:3000/'), equals('http://localhost:3000'));

      client.configure(baseUrl: 'http://127.0.0.1:10101/api', token: 'jwt-token-abc');

      Map<String, dynamic>? interceptedHeaders;
      client.dio.httpClientAdapter = _TestMockAdapter((options) async {
        interceptedHeaders = options.headers;
        return ResponseBody.fromString('{"ok": true}', 200, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
      });

      final resp = await client.dio.get<Map<String, dynamic>>('/test');
      expect(resp.data?['ok'], isTrue);
      expect(interceptedHeaders?['Authorization'], equals('Bearer jwt-token-abc'));

      // 动态更新 token
      client.updateToken('new-jwt-token-xyz');
      await client.dio.get<Map<String, dynamic>>('/test2');
      expect(interceptedHeaders?['Authorization'], equals('Bearer new-jwt-token-xyz'));

      // 动态清除 token
      client.updateToken(null);
      await client.dio.get<Map<String, dynamic>>('/test3');
      expect(interceptedHeaders?['Authorization'], isNull);
    });

    test('SyncWorker.configure 注入真实 Dio 与 DB，状态正确转换为 syncing -> idle', () async {
      final testDio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:10101'));
      bool pushCalled = false;
      bool pullCalled = false;

      testDio.httpClientAdapter = _TestMockAdapter((options) async {
        if (options.path.endsWith('/sync/v1/push')) {
          pushCalled = true;
          return ResponseBody.fromString(
            jsonEncode({'applied_ids': [], 'conflicts': []}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.endsWith('/sync/v1/pull')) {
          pullCalled = true;
          return ResponseBody.fromString(
            jsonEncode({'checkpoint': 0, 'has_more': false, 'changes': []}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        throw Exception('Unhandled path: ${options.path}');
      });

      final worker = SyncWorker.configure(
        dio: testDio,
        db: db,
        clientId: 'client-unit-test-1',
      );

      final stateHistory = <SyncWorkerState>[];
      worker.onStateChanged = (state, {error}) {
        stateHistory.add(state);
      };

      await worker.triggerSync();

      expect(pullCalled, isTrue);
      expect(stateHistory, containsAllInOrder([SyncWorkerState.syncing, SyncWorkerState.idle]));
      expect(worker.state, equals(SyncWorkerState.idle));
    });

    test('断网或网络异常时 SyncWorker 状态能够正确转换为 error', () async {
      final testDio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:10101'));
      testDio.httpClientAdapter = _TestMockAdapter((options) async {
        throw DioException(
          requestOptions: options,
          error: 'Connection refused',
          type: DioExceptionType.connectionError,
        );
      });

      final worker = SyncWorker.configure(
        dio: testDio,
        db: db,
        clientId: 'client-unit-test-error',
      );

      final stateHistory = <SyncWorkerState>[];
      Object? caughtError;
      worker.onStateChanged = (state, {error}) {
        stateHistory.add(state);
        if (error != null) caughtError = error;
      };

      await worker.triggerSync();

      expect(stateHistory, containsAllInOrder([SyncWorkerState.syncing, SyncWorkerState.error]));
      expect(worker.state, equals(SyncWorkerState.error));
      expect(caughtError, isNotNull);
    });

    test('updateDependencies 机制支持动态热更新 Dio、DB 与 ClientId', () async {
      final dio1 = Dio();
      final worker = SyncWorker.configure(
        dio: dio1,
        db: db,
        clientId: 'initial-client',
      );
      expect(worker.clientId, equals('initial-client'));

      final dio2 = Dio();
      worker.updateDependencies(dio: dio2, clientId: 'updated-client');
      expect(worker.clientId, equals('updated-client'));
    });

    test('SyncNotifier 与 SyncWorker 联动状态响应式验证', () async {
      final testDio = Dio();
      testDio.httpClientAdapter = _TestMockAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({'checkpoint': 0, 'has_more': false, 'changes': []}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      SyncWorker.configure(
        dio: testDio,
        db: db,
        clientId: 'client-notifier-test',
      );

      final notifier = SyncNotifier();
      expect(notifier.state.state, equals(SyncRunningState.idle));

      await notifier.triggerSync();
      expect(notifier.state.state, equals(SyncRunningState.idle));
      expect(notifier.state.lastSyncTime, isNotNull);
    });
  });
}
