import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/core/auth/quick_login_manager.dart';
import 'package:xbb/core/network/api_client.dart';
import 'package:xbb/presentation/providers/server_health_provider.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

class _HealthMockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  _HealthMockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('xbb_quick_health_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall call) async {
      return tempDir.path;
    });
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('TASK-0.3: 恢复多账号快速登录与服务可用性探测', () {
    late GetStorage box;
    late Dio testDio;

    setUp(() async {
      await GetStorage.init('TestQuickLoginStorage');
      box = GetStorage('TestQuickLoginStorage');
      await box.erase();
      testDio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:10101'));
    });

    tearDown(() async {
      await box.erase();
      SyncWorker.instance.stop();
    });

    test('QuickLoginManager 多账号凭据存储、排序与删除', () async {
      final manager = QuickLoginManager(box);
      expect(manager.getCredentials(), isEmpty);

      // 1. 保存两个用户快照
      final cred1 = QuickLoginCredential(
        userId: 'user-1',
        username: 'alice',
        password: 'password1',
        nickname: 'Alice',
        lastLoginTime: DateTime.now().subtract(const Duration(minutes: 10)),
      );
      final cred2 = QuickLoginCredential(
        userId: 'user-2',
        username: 'bob',
        password: 'password2',
        nickname: 'Bob',
        lastLoginTime: DateTime.now(),
      );

      await manager.saveCredential(cred1);
      await manager.saveCredential(cred2);

      // 2. 验证多账号列表获取且按时间排序 (bob 应该在前面)
      final list = manager.getCredentials();
      expect(list.length, equals(2));
      expect(list.first.userId, equals('user-2'));
      expect(list.last.userId, equals('user-1'));

      // 3. 删除其中一个账号
      await manager.removeCredential('user-1');
      final afterRemove = manager.getCredentials();
      expect(afterRemove.length, equals(1));
      expect(afterRemove.first.userId, equals('user-2'));

      // 4. 清空所有
      await manager.clearAll();
      expect(manager.getCredentials(), isEmpty);
    });

    test('ServerHealthNotifier 正常连网探测与 Ping 延迟测速', () async {
      testDio.httpClientAdapter = _HealthMockAdapter((options) async {
        if (options.path.endsWith('/health')) {
          return ResponseBody.fromString(
            jsonEncode({'status': 'ok'}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        throw Exception('Unhandled path: ${options.path}');
      });

      final notifier = ServerHealthNotifier(testDio, box);
      await notifier.checkHealth();

      expect(notifier.state.state, equals(ServerHealthState.available));
      expect(notifier.state.latencyMs, greaterThanOrEqualTo(0));
      expect(notifier.state.errorMessage, isNull);
      notifier.dispose();
    });

    test('ServerHealthNotifier 离线/异常时正确标记服务不可用', () async {
      testDio.httpClientAdapter = _HealthMockAdapter((options) async {
        throw DioException(
          requestOptions: options,
          error: 'Connection refused',
          type: DioExceptionType.connectionError,
        );
      });

      final notifier = ServerHealthNotifier(testDio, box);
      await notifier.checkHealth();

      expect(notifier.state.state, equals(ServerHealthState.unavailable));
      expect(notifier.state.latencyMs, equals(-1));
      expect(notifier.state.errorMessage, isNotNull);
      notifier.dispose();
    });

    test('updateServerUrl 动态修改服务器地址并触发重测与持久化', () async {
      testDio.httpClientAdapter = _HealthMockAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({'status': 'ok'}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      final notifier = ServerHealthNotifier(testDio, box);
      await notifier.updateServerUrl('http://192.168.1.100:10101/api/');

      // 验证 BaseURL 规范化并持久化到 Storage
      expect(ApiClient.instance.baseUrl, equals('http://192.168.1.100:10101'));
      final setting = box.read<Map<dynamic, dynamic>>(STORAGE_SETTING_SYNCSTORE_SETTINGS_KEY);
      expect(setting?['base_url'], equals('http://192.168.1.100:10101'));
      expect(notifier.state.state, equals(ServerHealthState.available));
      notifier.dispose();
    });
  });
}
