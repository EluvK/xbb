import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/core/router/app_router.dart';
import 'package:xbb/core/theme/app_theme.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/presentation/providers/settings_provider.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init(GET_STORAGE_FILE_KEY);

  // 初始化多用户物理隔离 SQLite 数据库 (ADR-0001)
  final box = GetStorage(GET_STORAGE_FILE_KEY);
  final userInfo = box.read<Map<String, dynamic>?>(STORAGE_SETTING_USER_INFO_KEY);
  final userId = userInfo != null ? (userInfo['id'] as String? ?? 'default') : 'default';
  final db = await LocalFirstDB.getDb(userId: userId);

  // 初始化后台单例 SyncWorker 守护进程
  SyncWorker.instance.start();

  await initializeDateFormatting('zh');

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
        final scale = mediaQueryData.textScaler.clamp(
          minScaleFactor: settings.fontScale,
          maxScaleFactor: settings.fontScale + 0.1,
        );
        return MediaQuery(
          data: mediaQueryData.copyWith(textScaler: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
