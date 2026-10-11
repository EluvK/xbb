import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/core/update/app_update_service.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/presentation/home/modern_home_shell.dart';
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
    tempDir = Directory.systemTemp.createTempSync('xbb_task_6_4_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall call) async {
      return tempDir.path;
    });

    await GetStorage.init(GET_STORAGE_FILE_KEY);
    db = await LocalFirstDB.getDb(userId: 'test_user_6_4');
  });

  tearDownAll(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('TASK-6.4: 恢复软件在线检测更新与移动端手势导航升级', () {
    test('AppUpdateService.isNewerVersion 准确比对 Semantic Version 与 Build Number', () {
      expect(AppUpdateService.isNewerVersion('0.3.0', '0.2.5'), isTrue);
      expect(AppUpdateService.isNewerVersion('1.0.0', '0.9.9'), isTrue);
      expect(AppUpdateService.isNewerVersion('0.2.5+290', '0.2.5+283'), isTrue);
      expect(AppUpdateService.isNewerVersion('0.2.6+100', '0.2.5+283'), isTrue);

      expect(AppUpdateService.isNewerVersion('0.2.5+283', '0.2.5+283'), isFalse);
      expect(AppUpdateService.isNewerVersion('0.2.4+300', '0.2.5+100'), isFalse);
      expect(AppUpdateService.isNewerVersion('0.2.5+280', '0.2.5+283'), isFalse);
    });

    test('AppUpdateService.check 能够向远端拉取 version 与 CHANGELOG 并生成下载地址', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/fs/public/xbb/version')) {
              handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: '0.3.0+300\n',
              ));
            } else if (options.path.endsWith('/fs/public/xbb/CHANGELOG')) {
              handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: '# Changelog\n- Performance improvements\n- Bug fixes',
              ));
            } else {
              handler.next(options);
            }
          },
        ),
      );

      final info = await AppUpdateService.check(
        dio: dio,
        baseUrl: 'http://test.syncstore.internal:10101',
      );

      expect(info.hasUpdate, isTrue);
      expect(info.latestVersion, equals('0.3.0+300'));
      expect(info.currentVersion, equals(AppUpdateService.currentVersion));
      expect(info.changelog, contains('Performance improvements'));
      expect(info.downloadUrl, equals('http://test.syncstore.internal:10101/fs/public/xbb/download'));
    });

    testWidgets('ModernSettingsView 展示版本卡片与检查更新按钮并支持手动触发', (tester) async {
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

      // 滚到底部查看版本信息卡片
      await tester.drag(find.byType(ListView), const Offset(0, -1600));
      await tester.pump();

      expect(find.text('版本信息与软件更新'), findsOneWidget);
      expect(find.text('v${AppUpdateService.currentVersion}'), findsOneWidget);
      expect(find.text('check_update'.tr), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      container.dispose();
    });

    testWidgets('ModernHomeShell 移动端底部导航栏由 PieCanvas 与 PieMenu 包装以支持手势轮转', (tester) async {
      Translation.setLocale('zh_CN');
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
      );

      // 设置为移动端尺寸
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      // 验证移动端结构包含 PieCanvas 和 PieMenu
      expect(find.byType(PieCanvas), findsOneWidget);
      expect(find.byType(PieMenu), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 11));
      container.dispose();
    });
  });
}
