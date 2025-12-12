import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/constant.dart';
// import 'package:xbb/controller/comment.dart';
// import 'package:xbb/controller/post.dart';
// import 'package:xbb/controller/repo.dart';
import 'package:xbb/controller/setting.dart';
// import 'package:xbb/controller/sync.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/models/notes/model.dart';
// import 'package:xbb/pages/edit_post.dart';
// import 'package:xbb/pages/edit_repo.dart';
import 'package:xbb/pages/home.dart';
import 'package:xbb/pages/login.dart';
// import 'package:xbb/pages/register.dart';
import 'package:xbb/pages/setting.dart';
import 'package:xbb/pages/notes/editor_pages.dart';
import 'package:xbb/pages/notes/view_post.dart';
import 'package:xbb/ss_client/client.dart';
import 'package:xbb/ss_client/token_storage.dart';
import 'package:xbb/utils/translation.dart';

void main() async {
  await GetStorage.init(GET_STORAGE_FILE_KEY);

  await Get.putAsync(() async {
    final controller = SettingController();
    return controller;
  });
  // should init before app start
  final settingController = Get.find<SettingController>();
  await settingController.ensureInitialization();

  await Get.putAsync(() async {
    final controller = UserController();
    return controller;
  });
  // await Get.putAsync(() async {
  //   final controller = AsyncController();
  //   return controller;
  // });
  // await Get.putAsync(() async {
  //   final controller = PostController();
  //   return controller;
  // });
  // await Get.putAsync(() async {
  //   final controller = CommentController();
  //   return controller;
  // });

  // await Get.putAsync(() async {
  //   final controller = RepoController();
  //   return controller;
  // });

  await Get.putAsync(() async {
    final ssClient = SSClient(baseUrl: APP_API_URI, tokenStorage: GetStorageTokenStorage());
    return ssClient;
  });
  await reInitNotesSync(Get.find<SyncStoreClient>());

  await initCacheSetting();
  // await initRepoPost();
  runApp(const MyApp());
}

// Future<void> initRepoPost() async {
//   final settingController = Get.find<SettingController>();
//   final postController = Get.find<PostController>();
//   await postController.loadPost(settingController.currentRepoId.value);
// }

// Future<void> initUpdatePosts() async {
//   final settingController = Get.find<SettingController>();
//   final repoController = Get.find<RepoController>();
//   if (settingController.autoSyncSelfRepo.value) {
//     await repoController.pullRepos();
//   }
//   if (settingController.autoSyncSubscribeRepo.value) {
//     await repoController.pullSubscribeRepos();
//   }
// }

Future<void> checkIfUpdate() async {
  final settingController = Get.find<SettingController>();
  await settingController.checkIfUpdate();
}

void autoLoadAtStart() {
  // checkIfUpdate();
  // initUpdatePosts();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingController = Get.find<SettingController>();

    print(settingController.lastAutoLoadTimestamp);
    bool inMinimumUpdateInterval = DateTime.now()
        .subtract(const Duration(minutes: 1))
        .isBefore(settingController.lastAutoLoadTimestamp.value);
    bool first = initFirstTime();
    String initialRoute = first ? '/login' : '/';
    if (!first && !settingController.quickReloadMode.value && !inMinimumUpdateInterval) {
      settingController.lastAutoLoadTimestamp.value = DateTime.now();
      autoLoadAtStart();
    }

    ThemeMode themeMode = settingController.themeMode.value;
    print('load themeMode: $themeMode');
    var locale = settingController.locale.value;
    double fontScale = settingController.fontScale.value;
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
        GetPage(name: '/setting', page: () => const SettingPage()),
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
