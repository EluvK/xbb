import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/core/network/auth_service.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/providers/friends_provider.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

class _ProfileMockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  _ProfileMockAdapter(this.handler);

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
    tempDir = Directory.systemTemp.createTempSync('xbb_profile_test_');

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

  group('TASK-0.4: 重构个人资料管理 (Profile: 昵称、密码、头像与好友列表)', () {
    late GetStorage box;
    late DatabaseChangeNotifier dbChangeNotifier;
    late Dio testDio;

    setUp(() async {
      await GetStorage.init('TestProfileStorage');
      box = GetStorage('TestProfileStorage');
      await box.erase();
      dbChangeNotifier = DatabaseChangeNotifier();
      testDio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:10101'));
    });

    tearDown(() async {
      await box.erase();
      SyncWorker.instance.stop();
    });

    test('updateProfile 提交云端持久化并实时更新本地 Storage 与 AuthState', () async {
      // 预先写入登录用户
      await box.write(STORAGE_SETTING_USER_INFO_KEY, {
        'id': 'user-alice-123',
        'username': 'alice',
        'nickname': 'Alice Old',
        'avatar': 'preset_avatar_1',
      });
      await box.write(TOKEN_ACCESS_KEY, 'alice-valid-token');

      Map<String, dynamic>? requestedBody;
      testDio.httpClientAdapter = _ProfileMockAdapter((options) async {
        if (options.path.endsWith('/api/v1/auth/profile')) {
          requestedBody = options.data as Map<String, dynamic>;
          return ResponseBody.fromString(
            jsonEncode({
              'status': 'ok',
              'user': {
                'id': 'user-alice-123',
                'username': 'alice',
                'nickname': requestedBody?['nickname'] ?? 'Alice Old',
                'avatar': requestedBody?['avatar'] ?? 'preset_avatar_1',
              }
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        throw Exception('Unhandled path: ${options.path}');
      });

      final authService = AuthService(testDio);
      final notifier = AuthNotifier(box, dbChangeNotifier, authService);

      expect(notifier.state.nickname, equals('Alice Old'));
      expect(notifier.state.avatar, equals('preset_avatar_1'));

      // 修改昵称和头像
      await notifier.updateProfile(
        nickname: 'Alice Wonderland',
        avatar: 'preset_avatar_4',
      );

      // 1. 验证网络请求载荷
      expect(requestedBody?['nickname'], equals('Alice Wonderland'));
      expect(requestedBody?['avatar'], equals('preset_avatar_4'));

      // 2. 验证响应式状态实时刷新 (验收标准：顶栏头像和用户名称立即刷新)
      expect(notifier.state.nickname, equals('Alice Wonderland'));
      expect(notifier.state.avatar, equals('preset_avatar_4'));

      // 3. 验证本地持久化 GetStorage 已同步落盘
      final stored = box.read<Map<dynamic, dynamic>>(STORAGE_SETTING_USER_INFO_KEY);
      expect(stored?['nickname'], equals('Alice Wonderland'));
      expect(stored?['avatar'], equals('preset_avatar_4'));
    });

    test('AuthService.updatePassword 正确提交修改密码请求', () async {
      Map<String, dynamic>? requestedBody;
      testDio.httpClientAdapter = _ProfileMockAdapter((options) async {
        if (options.path.endsWith('/api/v1/auth/password')) {
          requestedBody = options.data as Map<String, dynamic>;
          return ResponseBody.fromString(
            jsonEncode({'status': 'ok', 'message': 'Password updated successfully'}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        throw Exception('Unhandled path: ${options.path}');
      });

      final authService = AuthService(testDio);
      await authService.updatePassword('oldPass123', 'newPass456');

      expect(requestedBody?['old_password'], equals('oldPass123'));
      expect(requestedBody?['new_password'], equals('newPass456'));
    });

    test('FriendsNotifier 读取好友/协同成员列表并进行本地持久化缓存', () async {
      testDio.httpClientAdapter = _ProfileMockAdapter((options) async {
        if (options.path.endsWith('/api/v1/auth/users')) {
          return ResponseBody.fromString(
            jsonEncode({
              'status': 'ok',
              'users': [
                {
                  'id': 'user-collab-1',
                  'username': 'bob',
                  'nickname': 'Bob Builder',
                  'avatar': 'preset_avatar_2',
                },
                {
                  'id': 'user-collab-2',
                  'username': 'charlie',
                  'nickname': 'Charlie C',
                  'avatar': 'preset_avatar_3',
                },
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        throw Exception('Unhandled path: ${options.path}');
      });

      final authService = AuthService(testDio);
      final notifier = FriendsNotifier(authService, box);

      await notifier.loadFriends();

      expect(notifier.state.hasValue, isTrue);
      final list = notifier.state.value!;
      expect(list.length, equals(2));
      expect(list.first.username, equals('bob'));
      expect(list.last.username, equals('charlie'));

      // 验证写入 Storage 缓存
      final cached = box.read<List<dynamic>>(GET_STORAGE_FRIENDS_KEY);
      expect(cached, isNotNull);
      expect(cached?.length, equals(2));
    });
  });
}
