import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/controller/clipboard_tray.dart';
import 'package:xbb/core/desktop/desktop_manager.dart';
import 'package:xbb/core/desktop/desktop_title_bar.dart';
import 'package:xbb/core/network/api_client.dart';
import 'package:xbb/core/router/app_router.dart';
import 'package:xbb/core/theme/app_theme.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/presentation/providers/settings_provider.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';
import 'package:xbb/sync/v2/uuid_service.dart';
import 'package:xbb/utils/translation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(GET_STORAGE_FILE_KEY);

  // 初始化多用户物理隔离 SQLite 数据库 (ADR-0001)
  final box = GetStorage(GET_STORAGE_FILE_KEY);
  final userInfo = box.read<Map<String, dynamic>?>(STORAGE_SETTING_USER_INFO_KEY);
  final rawUserId = userInfo != null ? (userInfo['id'] as String? ?? '') : '';
  final token = box.read<String>(TOKEN_ACCESS_KEY) ?? box.read<String>('user_token');
  final bool isLoggedIn = rawUserId.isNotEmpty && rawUserId != 'default' && token != null && token.isNotEmpty;
  final String userId = isLoggedIn ? rawUserId : '';

  // 已登录加载专属数据库，未登录使用纯内存隔离数据库以彻底杜绝访客磁盘脏数据
  final db = isLoggedIn
      ? await LocalFirstDB.getDb(userId: userId)
      : await LocalFirstDB.openInMemory();
  setActiveDatabase(db);

  // 初始化 ApiClient 与配置后台单例 SyncWorker 守护进程 (TASK-0.1)
  final syncSetting = box.read<Map<String, dynamic>?>(STORAGE_SETTING_SYNCSTORE_SETTINGS_KEY);
  final syncStoreUrl = syncSetting != null
      ? (syncSetting['base_url'] as String? ?? 'http://127.0.0.1:10101')
      : 'http://127.0.0.1:10101';
  var clientId = box.read<String>('device_client_id');
  if (clientId == null || clientId.isEmpty) {
    clientId = UuidService.v4();
    box.write('device_client_id', clientId);
  }

  ApiClient.instance.configure(
    baseUrl: syncStoreUrl,
    token: isLoggedIn ? token : null,
  );

  SyncWorker.configure(
    dio: ApiClient.instance.dio,
    db: db,
    clientId: clientId,
  );
  if (isLoggedIn) {
    SyncWorker.instance.start();
  }

  if (isLoggedIn) {
    ClipboardTrayService.instance.configure(userId: userId);
  }

  await initializeDateFormatting('zh');
  await initializeDateFormatting('en');

  // 初始化当前多语言环境
  final savedAppSettings = box.read<Map<String, dynamic>?>(STORAGE_SETTING_APP_SETTINGS_KEY);
  final savedLang = savedAppSettings != null ? savedAppSettings['locale'] as String? : null;
  if (savedLang == 'en') {
    Translation.setLocale('en_US');
  } else if (savedLang == 'zh') {
    Translation.setLocale('zh_CN');
  } else {
    final sys = PlatformDispatcher.instance.locale;
    Translation.setLocale(sys.languageCode == 'en' ? 'en_US' : 'zh_CN');
  }

  // 初始化桌面端无边框窗口与系统托盘管理 (window_manager + tray_manager)
  await DesktopManager.instance.init(minimizeToTrayOnClose: true);

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const ModernXbbApp(),
    ),
  );
}

class ModernXbbApp extends ConsumerWidget {
  const ModernXbbApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'XBB Workspace',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      themeMode: settings.themeMode,
      theme: AppTheme.light(scheme: settings.scheme),
      darkTheme: AppTheme.dark(scheme: settings.scheme),
      locale: settings.locale,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: PointerDeviceKind.values.toSet(),
      ),
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(textScaler: TextScaler.linear(settings.fontScale)),
          child: Column(
            children: [
              const DesktopTitleBar(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }
}
