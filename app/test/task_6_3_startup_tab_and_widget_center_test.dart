import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/presentation/checkin/modern_checkin_view.dart';
import 'package:xbb/presentation/home/modern_home_shell.dart';
import 'package:xbb/presentation/providers/settings_provider.dart';
import 'package:xbb/presentation/settings/modern_settings_view.dart';
import 'package:xbb/presentation/task/modern_task_view.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/utils/translation.dart';

void main() {
  late Directory tempDir;
  late Database db;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    tempDir = Directory.systemTemp.createTempSync('xbb_task_6_3_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall call) async {
      return tempDir.path;
    });

    await GetStorage.init(GET_STORAGE_FILE_KEY);
    db = await LocalFirstDB.getDb(userId: 'test_user_6_3');
  });

  tearDownAll(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('TASK-6.3: 恢复默认启动页配置与桌面插件添加中心', () {
    test('SettingsNotifier 能够设置并持久化 startupTabIndex', () {
      final box = GetStorage(GET_STORAGE_FILE_KEY);
      final notifier = AppSettingsNotifier(box);

      notifier.setStartupTabIndex(AppHomeStartupTabIndex.task);
      expect(notifier.state.startupTabIndex, equals(AppHomeStartupTabIndex.task));

      final saved = box.read<Map<String, dynamic>?>(STORAGE_SETTING_APP_FEATURES_MANAGEMENT_KEY);
      expect(saved, isNotNull);
      expect(saved!['home_startup_tab_index'], equals(AppHomeStartupTabIndex.task));

      notifier.setStartupTabIndex(AppHomeStartupTabIndex.checkin);
      expect(notifier.state.startupTabIndex, equals(AppHomeStartupTabIndex.checkin));
    });

    testWidgets('ModernHomeShell 冷启动时依据 startupTabIndex 激活指定功能 Tab', (tester) async {
      Translation.setLocale('zh_CN');
      final box = GetStorage(GET_STORAGE_FILE_KEY);
      final features = Map<String, dynamic>.from(
        box.read<Map<String, dynamic>?>(STORAGE_SETTING_APP_FEATURES_MANAGEMENT_KEY) ?? {},
      );
      features['home_startup_tab_index'] = AppHomeStartupTabIndex.task;
      await box.write(STORAGE_SETTING_APP_FEATURES_MANAGEMENT_KEY, features);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      // 验证配置为待办任务 Tab
      expect(container.read(appSettingsProvider).startupTabIndex, equals(AppHomeStartupTabIndex.task));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ModernHomeShell(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证页面展示的是待办事项视图
      expect(find.byType(ModernTaskView), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      container.dispose();
    });

    testWidgets('ModernSettingsView 展示桌面插件中心与待办/打卡快捷添加操作', (tester) async {
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

      // 滚动到底部找到桌面插件中心
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pump();

      expect(find.text('桌面小部件 (Home Widget)'), findsOneWidget);
      expect(find.text('任务桌面插件'), findsOneWidget);
      expect(find.text('打卡桌面插件'), findsOneWidget);
      expect(find.text('默认启动页面'), findsOneWidget);

      // 验证待办插件按钮与打卡插件按钮均存在
      expect(find.text('添加到桌面小部件'), findsOneWidget);
      expect(find.text('添加打卡插件'), findsOneWidget);

      // 点击待办插件添加
      final taskAddBtn = find.text('添加到桌面小部件');
      await tester.tap(taskAddBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 弹出添加指引弹窗
      expect(find.text('添加桌面小部件指引'), findsOneWidget);
      await tester.tap(find.text('我知道了'));
      await tester.pumpAndSettle();

      // 向上滚动让打卡插件按钮完全可见
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump();

      // 点击打卡插件添加
      final checkinAddBtn = find.text('添加打卡插件');
      await tester.tap(checkinAddBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 弹出添加打卡插件指引弹窗
      expect(find.text('添加打卡插件'), findsWidgets);
      await tester.tap(find.text('我知道了').last);
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      container.dispose();
    });
  });
}
