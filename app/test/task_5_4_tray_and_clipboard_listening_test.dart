import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/controller/clipboard_tray.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/repositories/clipboard_repository.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/providers/settings_provider.dart';
import 'package:xbb/presentation/settings/modern_settings_view.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

class _MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _MockAuthNotifier() : super(const AuthState(userId: 'test-user', isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tempDir;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('xbb_clip_test_');

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

  group('TASK-5.4: 重新打通桌面平台后台监听与系统托盘驻留', () {
    late Database db;
    late DatabaseChangeNotifier dbChangeNotifier;
    late ClipboardRepository clipboardRepo;
    late GetStorage testBox;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
      dbChangeNotifier = DatabaseChangeNotifier();
      clipboardRepo = ClipboardRepository(db: db, changeNotifier: dbChangeNotifier);
      ClipboardTrayService.instance.configure(repository: clipboardRepo, userId: 'test-user');
      await ClipboardTrayService.instance.init(featureEnabled: true, listeningEnabled: false);

      await GetStorage.init('TestClipboardStorage');
      testBox = GetStorage('TestClipboardStorage');
      await testBox.erase();
    });

    tearDown(() async {
      await ClipboardTrayService.instance.setListeningEnabled(false);
      await testBox.erase();
      await db.close();
      SyncWorker.instance.stop();
    });

    test('后台剪贴板监听开关受控：关闭时不捕获，开启后捕获且严格遵循 ADR-0002 仅本地存储', () async {
      final service = ClipboardTrayService.instance;

      // 1. 默认处于关闭态
      expect(service.isListeningActive, isFalse);

      // 在关闭态下模拟系统复制文本
      final capturedWhenDisabled = await service.handleCollectedText('关闭态下复制的秘密文本');
      expect(capturedWhenDisabled, isFalse);

      // 验证数据库无任何记录
      final rows1 = await db.query('clipboard_history_entry');
      expect(rows1, isEmpty);

      // 2. 开启后台剪贴板监听
      await service.setListeningEnabled(true);
      expect(service.isListeningActive, isTrue);

      // 在开启态下模拟系统复制文本
      final capturedWhenEnabled = await service.handleCollectedText('开启态下捕获的系统文本');
      expect(capturedWhenEnabled, isTrue);

      // 验证本地数据库已新增该记录
      final rows2 = await db.query('clipboard_history_entry');
      expect(rows2.length, 1);
      final body = jsonDecode(rows2.first['body'] as String);
      expect(body['data'], '开启态下捕获的系统文本');
      // 验证 ADR-0002: 强制 localOnly = true
      expect(body['local_only'], isTrue);

      // 验证 ADR-0002: 严禁自动生成 Outbox 项
      final outboxRows = await db.query('outbox');
      expect(outboxRows, isEmpty);

      // 3. 测试连续重复文本查重
      final duplicateCaptured = await service.handleCollectedText('开启态下捕获的系统文本');
      expect(duplicateCaptured, isFalse);
      final rows3 = await db.query('clipboard_history_entry');
      expect(rows3.length, 1);

      // 4. 关闭监听，再次复制不再捕获
      await service.setListeningEnabled(false);
      expect(service.isListeningActive, isFalse);

      final capturedAfterClose = await service.handleCollectedText('关闭后复制的新内容');
      expect(capturedAfterClose, isFalse);
      final rows4 = await db.query('clipboard_history_entry');
      expect(rows4.length, 1);
    });

    test('AppSettingsNotifier.setClipboardListeningEnabled 正确同步状态并驱动 ClipboardTrayService', () async {
      final notifier = AppSettingsNotifier(testBox);

      expect(notifier.state.clipboardListeningEnabled, isFalse);
      expect(ClipboardTrayService.instance.listeningEnabled, isFalse);

      // 启用监听
      notifier.setClipboardListeningEnabled(true);
      expect(notifier.state.clipboardListeningEnabled, isTrue);
      expect(ClipboardTrayService.instance.listeningEnabled, isTrue);

      // 验证写入 Storage
      final storedFeature = testBox.read<Map<String, dynamic>?>(STORAGE_SETTING_APP_FEATURES_MANAGEMENT_KEY);
      expect(storedFeature?['enable_clipboard_listening'], isTrue);

      // 禁用监听
      notifier.setClipboardListeningEnabled(false);
      expect(notifier.state.clipboardListeningEnabled, isFalse);
      expect(ClipboardTrayService.instance.listeningEnabled, isFalse);
    });

    testWidgets('ModernSettingsView 展示后台剪贴板监听开关并能响应切换', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => _MockAuthNotifier()),
            appSettingsProvider.overrideWith((ref) => AppSettingsNotifier(testBox)),
          ],
          child: const MaterialApp(
            home: ModernSettingsView(),
          ),
        ),
      );

      expect(find.text('桌面系统托盘与剪贴板'), findsOneWidget);
      expect(find.text('启用后台剪贴板监听'), findsOneWidget);
      expect(find.text('已暂停'), findsOneWidget);

      // 点击 Switch 开启后台监听
      final switchFinder = find.widgetWithText(SwitchListTile, '启用后台剪贴板监听');
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pump();

      expect(find.text('正在监听'), findsOneWidget);
    });
  });
}
