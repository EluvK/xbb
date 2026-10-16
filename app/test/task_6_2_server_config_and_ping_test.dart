import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/components/common/ping_latency_inline.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/core/network/api_client.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/presentation/providers/settings_provider.dart';
import 'package:xbb/presentation/settings/modern_settings_view.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/utils/translation.dart';

void main() {
  late Directory tempDir;
  late Database db;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('xbb_task_6_2_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall call) async {
      return tempDir.path;
    });

    await GetStorage.init(GET_STORAGE_FILE_KEY);
    db = await LocalFirstDB.getDb(userId: 'test_user_6_2');
  });

  tearDownAll(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('TASK-6.2: 恢复服务器配置与网络实时 Ping 测速', () {
    test('多平台默认服务器地址判断', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(ApiClient.defaultDevServerUrl, equals('http://10.0.2.2:10101'));

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(ApiClient.defaultDevServerUrl, equals('http://127.0.0.1:10101'));

      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(ApiClient.defaultDevServerUrl, equals('http://127.0.0.1:10101'));

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(ApiClient.defaultDevServerUrl, equals('http://127.0.0.1:10101'));

      debugDefaultTargetPlatformOverride = null;
    });

    test('SettingsNotifier 能够规范化保存 syncStoreUrl 与历史记录并落盘', () async {
      final box = GetStorage(GET_STORAGE_FILE_KEY);
      await box.erase();
      final notifier = AppSettingsNotifier(box);

      expect(notifier.state.syncStoreUrl, equals(ApiClient.defaultDevServerUrl));

      // 输入带多余斜杠的自定义地址
      await notifier.updateSyncStoreUrl('http://192.168.1.88:9090/');
      expect(notifier.state.syncStoreUrl, equals('http://192.168.1.88:9090'));
      expect(notifier.state.syncStoreUrlHistory.first, equals('http://192.168.1.88:9090'));
      expect(ApiClient.instance.baseUrl, equals('http://192.168.1.88:9090'));

      // 验证本地存储写入
      final saved = box.read<Map<String, dynamic>?>(STORAGE_SETTING_SYNCSTORE_SETTINGS_KEY);
      expect(saved, isNotNull);
      expect(saved!['base_url'], equals('http://192.168.1.88:9090'));

      // 重置为默认
      await notifier.resetDefaultSyncStoreUrl();
      expect(notifier.state.syncStoreUrl, equals(ApiClient.defaultDevServerUrl));
      expect(ApiClient.instance.baseUrl, equals(ApiClient.defaultDevServerUrl));
    });

    testWidgets('PingLatencyInline 正确呈现时延 ms、离线状态与加载中动画', (tester) async {
      Translation.setLocale('zh_CN');

      // 1. 正常延迟
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PingLatencyInline(
              isLoading: false,
              latencyMs: 42,
              onRefresh: () {},
            ),
          ),
        ),
      );
      expect(find.text('42 ms'), findsOneWidget);

      // 2. 离线/测速失败 (-1)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PingLatencyInline(
              isLoading: false,
              latencyMs: -1,
              onRefresh: () {},
            ),
          ),
        ),
      );
      expect(find.text('-- ms'), findsOneWidget);

      // 3. 加载中
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PingLatencyInline(
              isLoading: true,
              latencyMs: null,
              onRefresh: () {},
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('ModernSettingsView 展示服务器卡片、地址修改与一键重置', (tester) async {
      final box = GetStorage(GET_STORAGE_FILE_KEY);
      await box.erase();
      Translation.setLocale('zh_CN');

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ModernSettingsView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('SyncStore 同步服务器'), findsOneWidget);
      expect(find.text('重置默认'), findsOneWidget);

      // 在输入框中填入新服务器地址
      final textFieldFinder = find.byType(TextField).first;
      expect(textFieldFinder, findsOneWidget);

      await tester.enterText(textFieldFinder, 'http://example.sync.com:8080');
      await tester.pump();

      // 点击保存
      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 状态已更新为新地址
      expect(container.read(appSettingsProvider).syncStoreUrl, equals('http://example.sync.com:8080'));

      // 点击一键重置默认
      await tester.tap(find.text('重置默认'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(appSettingsProvider).syncStoreUrl, equals(ApiClient.defaultDevServerUrl));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      container.dispose();
    });
  });
}
