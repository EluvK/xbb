import 'dart:ui';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:xbb/core/core.dart';
import 'package:syncstore_client/syncstore_client.dart' show ApiError, ApiException;
import 'package:xbb/controller/app_launch.dart';
import 'package:xbb/controller/clipboard_tray.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/syncstore.dart';
import 'package:xbb/pages/home.dart';
import 'package:xbb/pages/login.dart';
import 'package:xbb/pages/chat/chat_page.dart';
import 'package:xbb/pages/notes/editor_pages.dart';
import 'package:xbb/pages/notes/view_post.dart';
import 'package:xbb/pages/profile.dart';
import 'package:xbb/pages/task/task_page.dart';
import 'package:xbb/pages/trackers/edit_tracker.dart';
import 'package:xbb/pages/trackers/view_tracker.dart';
import 'package:xbb/pages/checkin/edit_event_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:xbb/utils/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(GET_STORAGE_FILE_KEY);

  await Get.putAsync(() async {
    final controller = SettingController();
    return controller;
  });
  final settingController = Get.find<SettingController>();
  await settingController.ensureInitialization();
  await initializeDateFormatting(settingController.locale.languageCode);

  await Get.putAsync(() async {
    final controller = AppLaunchController();
    await controller.ensureInitialization();
    return controller;
  }, permanent: true);

  await Get.putAsync(() async {
    final controller = ClipboardTrayController();
    await controller.ensureInitialization();
    return controller;
  }, permanent: true);

  await reInitSyncStoreController();
  PlatformDispatcher.instance.onError = (error, stack) {
    if (error is ApiException && error.error == ApiError.loginRequired) {
      print('[Handle ERROR] Login required, redirecting to login page.');
      Get.offAllNamed('/login');
      flushBar(FlushLevel.INFO, "Token 过期", "需要重新登录");
      return true;
    }
    if (error is ApiException) {
      print('[API ERROR] ${error.error}: ${error.message}');
      flushBar(FlushLevel.WARNING, "API 错误", "${error.error}: ${error.message}");
      return true;
    }
    flushBar(FlushLevel.WARNING, "未知错误", "$error");
    print(stack);
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingController = Get.find<SettingController>();
    bool first = initFirstTime();
    String initialRoute = first ? '/login' : '/';

    ThemeMode themeMode = settingController.themeMode;
    print('load themeMode: $themeMode');
    var locale = settingController.locale;
    double fontScale = settingController.fontScale;
    print('load fontScale: $fontScale');
    final mediaQueryData = MediaQuery.of(context);
    final scale = mediaQueryData.textScaler.clamp(minScaleFactor: fontScale, maxScaleFactor: fontScale + 0.1);

    var app = MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      initialRoute: initialRoute,
      locale: locale,
      routes: {
        '/': (context) => const HomePageWrapper(),
        '/login': (context) => const LoginPage(),
        '/profile': (context) => const ProfilePage(),
        '/notes/view-post': (context) => const ViewPostPage(),
        '/notes/edit-post': (context) => const EditPostPage(),
        '/notes/edit-repo': (context) => const EditRepoPage(),
        '/tracker/edit-tracker': (context) => const EditTrackerPage(),
        '/tracker/view-tracker': (context) => const ViewTrackerDetailPage(),
        '/task': (context) => const TaskPage(),
        '/checkin/edit-event': (context) => const EditCheckinEventPage(),
        '/chat': (context) => const ChatPage(),
      },
      debugShowCheckedModeBanner: true,
      themeMode: themeMode,
      theme: FlexThemeData.light(
        scheme: FlexScheme.blumineBlue,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          useMaterial3Typography: true,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
        ),
        keyColors: const FlexKeyColors(useSecondary: true),
        tones: FlexTones.material(Brightness.light).onMainsUseBW(),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
        fontFamily: 'lxgw',
      ),
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.blumineBlue,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 14,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useMaterial3Typography: true,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
        ),
        keyColors: const FlexKeyColors(useSecondary: true),
        tones: FlexTones.material(Brightness.dark).onMainsUseBW(),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
        fontFamily: 'lxgw',
      ),
    );

    return MediaQuery(
      data: mediaQueryData.copyWith(textScaler: scale),
      child: app,
    );
  }
}
