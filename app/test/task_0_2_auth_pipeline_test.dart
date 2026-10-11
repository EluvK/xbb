import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/core/network/api_client.dart';
import 'package:xbb/core/network/auth_service.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

class _AuthMockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  _AuthMockAdapter(this.handler);

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
    tempDir = Directory.systemTemp.createTempSync('xbb_auth_test_');

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

  group('TASK-0.2: 重构真实的账号认证体系与本地持久化 (Auth Pipeline)', () {
    late GetStorage box;
    late DatabaseChangeNotifier dbChangeNotifier;
    late Dio mockDio;

    setUp(() async {
      await GetStorage.init('TestAuthStorage');
      box = GetStorage('TestAuthStorage');
      await box.erase();
      dbChangeNotifier = DatabaseChangeNotifier();
      mockDio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:10101'));
    });

    tearDown(() async {
      await box.erase();
      SyncWorker.instance.stop();
    });

    test('AuthService 真实请求序列化与响应解析', () async {
      mockDio.httpClientAdapter = _AuthMockAdapter((options) async {
        if (options.path.endsWith('/api/v1/auth/login')) {
          final data = options.data as Map;
          if (data['username'] == 'alice' && data['password'] == 'pwd123') {
            return ResponseBody.fromString(
              jsonEncode({
                'status': 'ok',
                'token': 'jwt-alice-token-valid',
                'user': {
                  'id': 'user-alice-1',
                  'username': 'alice',
                  'nickname': 'Alice Liddell',
                  'avatar': 'avatar_3',
                }
              }),
              200,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          } else {
            return ResponseBody.fromString(
              jsonEncode({'code': 'INVALID_CREDENTIALS', 'message': '用户名或密码错误'}),
              401,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          }
        }
        throw Exception('Unhandled path: ${options.path}');
      });

      final service = AuthService(mockDio);
      final result = await service.login('alice', 'pwd123');
      expect(result.token, equals('jwt-alice-token-valid'));
      expect(result.user.id, equals('user-alice-1'));
      expect(result.user.nickname, equals('Alice Liddell'));

      // 密码错误测试
      expect(
        () => service.login('alice', 'wrong'),
        throwsA(predicate((e) => e.toString().contains('用户名或密码错误'))),
      );
    });

    test('AuthNotifier 登录成功后写入 GetStorage 并动态初始化用户专属 DB 与 Token', () async {
      mockDio.httpClientAdapter = _AuthMockAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({
            'status': 'ok',
            'token': 'jwt-bob-token-valid',
            'user': {
              'id': 'user-bob-99',
              'username': 'bob',
              'nickname': 'Builder Bob',
              'avatar': 'avatar_5',
            }
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      final authService = AuthService(mockDio);
      final notifier = AuthNotifier(box, dbChangeNotifier, authService);

      expect(notifier.state.isLoggedIn, isFalse);
      expect(box.read(STORAGE_SETTING_USER_INFO_KEY), isNull);

      await notifier.loginWithCredentials('bob', 'secretBob');

      // 1. 验证内存状态更新
      expect(notifier.state.isLoggedIn, isTrue);
      expect(notifier.state.userId, equals('user-bob-99'));
      expect(notifier.state.username, equals('bob'));
      expect(notifier.state.nickname, equals('Builder Bob'));
      expect(notifier.state.token, equals('jwt-bob-token-valid'));

      // 2. 验证本地持久化已写入 GetStorage (验收标准：冷启动不会丢失)
      final storedUser = box.read<Map<dynamic, dynamic>>(STORAGE_SETTING_USER_INFO_KEY);
      expect(storedUser, isNotNull);
      expect(storedUser?['id'], equals('user-bob-99'));
      expect(box.read<String>(TOKEN_ACCESS_KEY), equals('jwt-bob-token-valid'));

      // 3. 验证网络层 Token 同步更新
      expect(ApiClient.instance.token, equals('jwt-bob-token-valid'));
    });

    test('模拟 App 冷启动：从 GetStorage 正确恢复认证状态与网络鉴权头', () async {
      // 预先写入存储模拟已登录
      await box.write(STORAGE_SETTING_USER_INFO_KEY, {
        'id': 'user-persisted-123',
        'username': 'charlie',
        'nickname': 'Charlie Brown',
        'avatar': 'avatar_2',
      });
      await box.write(TOKEN_ACCESS_KEY, 'persisted-jwt-token-777');

      // 创建全新的 AuthNotifier 模拟冷启动
      final restoredNotifier = AuthNotifier(box, dbChangeNotifier);

      expect(restoredNotifier.state.isLoggedIn, isTrue);
      expect(restoredNotifier.state.userId, equals('user-persisted-123'));
      expect(restoredNotifier.state.username, equals('charlie'));
      expect(restoredNotifier.state.nickname, equals('Charlie Brown'));
      expect(restoredNotifier.state.token, equals('persisted-jwt-token-777'));
      expect(ApiClient.instance.token, equals('persisted-jwt-token-777'));
    });

    test('完整登出逻辑：销毁敏感 Token、重置网络头、切回本地访客模式', () async {
      await box.write(STORAGE_SETTING_USER_INFO_KEY, {
        'id': 'user-to-logout',
        'username': 'dave',
      });
      await box.write(TOKEN_ACCESS_KEY, 'token-to-delete');
      ApiClient.instance.updateToken('token-to-delete');

      final notifier = AuthNotifier(box, dbChangeNotifier);
      expect(notifier.state.isLoggedIn, isTrue);

      await notifier.logout();

      // 1. 验证状态已恢复为离线默认
      expect(notifier.state.isLoggedIn, isFalse);
      expect(notifier.state.userId, equals('default'));
      expect(notifier.state.token, isEmpty);

      // 2. 验证 Storage 中敏感信息已完全销毁 (验收标准：Token 正确销毁)
      expect(box.read(STORAGE_SETTING_USER_INFO_KEY), isNull);
      expect(box.read(TOKEN_ACCESS_KEY), isNull);
      expect(box.read('user_token'), isNull);

      // 3. 验证 ApiClient 中的鉴权头已清理
      expect(ApiClient.instance.token, isNull);
    });
  });
}
