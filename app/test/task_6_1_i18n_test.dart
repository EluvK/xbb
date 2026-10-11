import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/presentation/home/modern_home_shell.dart';
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
    tempDir = Directory.systemTemp.createTempSync('xbb_task_6_1_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall call) async {
      return tempDir.path;
    });

    await GetStorage.init(GET_STORAGE_FILE_KEY);
    db = await LocalFirstDB.getDb(userId: 'test_user_6_1');
  });

  tearDownAll(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('TASK-6.1: 恢复多语言国际化支持 (i18n)', () {
    test('Translation 能够在 zh_CN 与 en_US 之间实时切换翻译字典', () {
      Translation.setLocale('zh_CN');
      expect('settings_center'.tr, equals('设置中心'));
      expect('home_bar_title_notes'.tr, equals('笔记'));
      expect('home_bar_title_task'.tr, equals('任务'));
      expect('home_bar_title_checkin'.tr, equals('打卡'));
      expect('home_bar_title_tracker'.tr, equals('追踪'));
      expect('home_bar_title_clipboard'.tr, equals('剪贴板'));
      expect('task_active_list'.tr, equals('待办事项'));

      Translation.setLocale('en_US');
      expect('settings_center'.tr, equals('Settings'));
      expect('home_bar_title_notes'.tr, equals('Notes'));
      expect('home_bar_title_task'.tr, equals('Tasks'));
      expect('home_bar_title_checkin'.tr, equals('Check-in'));
      expect('home_bar_title_tracker'.tr, equals('Tracker'));
      expect('home_bar_title_clipboard'.tr, equals('Clipboard'));
      expect('task_active_list'.tr, equals('Tasks'));

      // 切回中文
      Translation.setLocale('zh_CN');
      expect('settings_center'.tr, equals('设置中心'));
    });

    test('AppSettingsNotifier 设置语言时同步更新 Translation 并落盘存储', () {
      final box = GetStorage(GET_STORAGE_FILE_KEY);
      final notifier = AppSettingsNotifier(box);

      notifier.setLanguageCode('en');
      expect(notifier.state.languageCode, equals('en'));
      expect(notifier.state.locale, equals(const Locale('en', 'US')));
      expect(Translation.currentLocale, equals('en_US'));

      final saved = box.read<Map<String, dynamic>?>(STORAGE_SETTING_APP_SETTINGS_KEY);
      expect(saved, isNotNull);
      expect(saved!['locale'], equals('en'));

      notifier.setLanguageCode('zh');
      expect(notifier.state.languageCode, equals('zh'));
      expect(notifier.state.locale, equals(const Locale('zh', 'CN')));
      expect(Translation.currentLocale, equals('zh_CN'));
    });

    testWidgets('ModernSettingsView 与 ModernHomeShell 切换语言即时生效全局文案', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      // 显式设置为中文环境
      container.read(appSettingsProvider.notifier).setLanguageCode('zh');

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

      // 中文环境下
      expect(find.text('设置中心'), findsOneWidget);
      expect(find.text('外观与排版'), findsOneWidget);
      expect(find.text('语言设置'), findsOneWidget);

      // 通过 Notifier 切换为英文
      container.read(appSettingsProvider.notifier).setLanguageCode('en');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证瞬间切为英文
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance & Typography'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);

      // 测试 ModernHomeShell 英文渲染
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

      expect(find.text('Notes'), findsWidgets);
      expect(find.text('Tasks'), findsWidgets);
      expect(find.text('Check-in'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 11));

      container.dispose();
    });
  });
}
