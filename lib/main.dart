import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/controller/repo.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/sync.dart';
import 'package:xbb/pages/edit_post.dart';
import 'package:xbb/pages/edit_repo.dart';
import 'package:xbb/pages/home.dart';
import 'package:xbb/pages/register.dart';
import 'package:xbb/pages/view_post.dart';

void main() async {
  await GetStorage.init('XbbGetStorage');

  if (!Platform.isAndroid && !Platform.isIOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await Get.putAsync(() async {
    final controller = SettingController();
    return controller;
  });
  // should init before app start
  final settingController = Get.find<SettingController>();
  await settingController.ensureInitialization();
  await Get.putAsync(() async {
    final controller = AsyncController();
    return controller;
  });
  await Get.putAsync(() async {
    final controller = PostController();
    return controller;
  });

  await Get.putAsync(() async {
    final controller = RepoController();
    return controller;
  });

  await initCacheSetting();
  await initRepoPost();
  runApp(const MyApp());
}

Future<void> initRepoPost() async {
  final settingController = Get.find<SettingController>();
  final postController = Get.find<PostController>();
  await postController.loadPost(settingController.currentRepoId.value);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    String initialRoute = initFirstTime() ? '/login' : '/';
    var app = GetMaterialApp(
      scrollBehavior: const MaterialScrollBehavior()
          .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/', page: () => HomePage()),
        GetPage(name: '/login', page: () => const RegisterPage()),
        GetPage(name: '/view-post', page: () => const ViewPostPage()),
        GetPage(name: '/edit-post', page: () => const EditPostPage()),
        GetPage(name: '/edit-repo', page: () => const EditRepoPage()),
      ],
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
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
        keyColors: const FlexKeyColors(
          useSecondary: true,
        ),
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
        keyColors: const FlexKeyColors(
          useSecondary: true,
        ),
        tones: FlexTones.material(Brightness.dark).onMainsUseBW(),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
        fontFamily: 'lxgw',
      ),
    );
    return app;
  }
}
