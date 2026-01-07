import 'dart:ui';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart' show ApiError, ApiException;
import 'package:xbb/constant.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/syncstore.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/pages/home.dart';
import 'package:xbb/pages/login.dart';
import 'package:xbb/pages/notes/editor_pages.dart';
import 'package:xbb/pages/notes/view_post.dart';
import 'package:xbb/utils/translation.dart';
import 'package:xbb/utils/utils.dart';

void main() async {
  await GetStorage.init(GET_STORAGE_FILE_KEY);

  await Get.putAsync(() async {
    final controller = NewSettingController();
    return controller;
  });
  final newSettingController = Get.find<NewSettingController>();
  await newSettingController.ensureInitialization();

  await Get.putAsync(() async {
    final ssClient = SyncStoreControl(baseUrl: APP_API_URI, tokenStorage: GetStorageTokenStorage());
    return ssClient;
  });
  final syncStoreControl = Get.find<SyncStoreControl>();
  await syncStoreControl.ensureInitialization();
  await reInitUserManagerController(syncStoreControl.syncStoreClient);
  await reInitNotesSync(syncStoreControl.syncStoreClient);

  WidgetsFlutterBinding.ensureInitialized();
  PlatformDispatcher.instance.onError = (error, stack) {
    // todo handle loginRequired error to redirect to login page
    if (error is ApiException && error.error == ApiError.loginRequired) {
      print('[Handle ERROR] Login required, redirecting to login page.');
      // todo add alert dialog
      Get.offAllNamed('/login');
      flushBar(FlushLevel.INFO, "Token 过期", "需要重新登录");
      return true;
    }
    print('[WARN] Uncaught platform error: $error');
    print(stack);
    return true;
  };

  // await initCacheSetting();
  // await initRepoPost();
  runApp(const MyApp());
}

void autoLoadAtStart() {
  // checkIfUpdate();
  // initUpdatePosts();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingController = Get.find<NewSettingController>();

    // print(settingController.lastAutoLoadTimestamp);
    // bool inMinimumUpdateInterval = DateTime.now()
    //     .subtract(const Duration(minutes: 1))
    //     .isBefore(settingController.lastAutoLoadTimestamp.value);
    bool first = initFirstTime();
    String initialRoute = first ? '/login' : '/';
    // if (!first && !settingController.quickReloadMode.value && !inMinimumUpdateInterval) {
    //   settingController.lastAutoLoadTimestamp.value = DateTime.now();
    //   autoLoadAtStart();
    // }

    ThemeMode themeMode = settingController.themeMode;
    print('load themeMode: $themeMode');
    var locale = settingController.locale;
    double fontScale = settingController.fontScale;
    print('load fontScale: $fontScale');
    final mediaQueryData = MediaQuery.of(context);
    final scale = mediaQueryData.textScaler.clamp(minScaleFactor: fontScale, maxScaleFactor: fontScale + 0.1);

    var app = GetMaterialApp(
      scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      initialRoute: initialRoute,
      translations: Translation(),
      locale: locale,
      getPages: [
        GetPage(name: '/', page: () => const HomePageWrapper()),
        // GetPage(name: '/login', page: () => const RegisterPage()),
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/notes/view-post', page: () => const ViewPostPage()),
        GetPage(name: '/notes/edit-post', page: () => const EditPostPage()),
        // GetPage(name: '/view-post', page: () => const ViewPostPage()),
        // GetPage(name: '/edit-post', page: () => const EditPostPage()),
        GetPage(name: '/notes/edit-repo', page: () => const EditRepoPage()),
        // GetPage(name: '/setting', page: () => const SettingPage()),
      ],
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: FlexThemeData.light(
        scheme: FlexScheme.blumineBlue,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          useTextTheme: true,
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
          useTextTheme: true,
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
