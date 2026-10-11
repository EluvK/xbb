import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:xbb/core/core.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/sync/v2/sync_v2.dart';
import 'package:get_storage/get_storage.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/task_widget.dart';
import 'package:xbb/controller/user.dart' show reInitUserManagerController;
import 'package:xbb/models/clipboard/model.dart' show reInitClipboardSync, ClipboardHistoryEntryController;
import 'package:xbb/models/notes/model.dart' show reInitNotesSync, RepoController, PostController, CommentController;
import 'package:xbb/models/task/model.dart' show reInitTaskSync, CheckListController;
import 'package:xbb/models/tracker/model.dart' show reInitTrackerSync, TrackerController, TrackerRecordController;
import 'package:xbb/models/checkin/model.dart' show reInitCheckinSync, CheckinEventController, CheckinRecordController;
import 'package:xbb/models/chat/model.dart' show ChatAssistantController, ChatConversationController, ChatMessageController;
import 'package:xbb/utils/utils.dart' show FlushLevel, flushBar, successSimpleFlushBar;

void refreshAllLocalControllers() {
  if (Get.isRegistered<RepoController>()) unawaited(Get.find<RepoController>().rebuildLocal());
  if (Get.isRegistered<PostController>()) unawaited(Get.find<PostController>().rebuildLocal());
  if (Get.isRegistered<CommentController>()) unawaited(Get.find<CommentController>().rebuildLocal());
  if (Get.isRegistered<CheckListController>()) unawaited(Get.find<CheckListController>().rebuildLocal());
  if (Get.isRegistered<CheckinEventController>()) unawaited(Get.find<CheckinEventController>().rebuildLocal());
  if (Get.isRegistered<CheckinRecordController>()) unawaited(Get.find<CheckinRecordController>().rebuildLocal());
  if (Get.isRegistered<TrackerController>()) unawaited(Get.find<TrackerController>().rebuildLocal());
  if (Get.isRegistered<TrackerRecordController>()) unawaited(Get.find<TrackerRecordController>().rebuildLocal());
  if (Get.isRegistered<ChatAssistantController>()) unawaited(Get.find<ChatAssistantController>().rebuildLocal());
  if (Get.isRegistered<ChatConversationController>()) unawaited(Get.find<ChatConversationController>().rebuildLocal());
  if (Get.isRegistered<ChatMessageController>()) unawaited(Get.find<ChatMessageController>().rebuildLocal());
  if (Get.isRegistered<ClipboardHistoryEntryController>()) unawaited(Get.find<ClipboardHistoryEntryController>().rebuildLocal());
}

/// ALERT: any page that call this should make sure use the new created controller.
Future<void> reInitSyncStoreController() async {
  if (Get.isRegistered<SyncStoreControl>()) {
    await Get.delete<SyncStoreControl>(force: true);
  }
  await Get.putAsync<SyncStoreControl>(() async {
    final ctrl = SyncStoreControl();
    await ctrl.ensureInitialization();
    return ctrl;
  }, permanent: true);
  await reInitUserManagerController();
  final syncStoreClient = Get.find<SyncStoreControl>().syncStoreClient;
  await reInitNotesSync(syncStoreClient);
  await reInitTrackerSync(syncStoreClient);
  await reInitTaskSync(syncStoreClient);
  await reInitClipboardSync(syncStoreClient);
  await reInitCheckinSync(syncStoreClient);
  unawaited(onReadySyncStartup());
}

Future<void> onReadySyncStartup() async {
  final SyncStoreClient ssClient = Get.find<SyncStoreControl>().syncStoreClient;
  final latency = await ssClient.pingLatencyMs();
  if (latency < 0) {
    print('SyncStore health check failed, skipping startup sync.');
    _showStartupToast(() {
      flushBar(FlushLevel.WARNING, "同步服务异常", "无法连接到同步服务，启动同步已跳过");
    });
    return;
  }

  try {
    await SyncWorker.instance.triggerSync();
    refreshAllLocalControllers();
    _showStartupToast(() {
      successSimpleFlushBar("启动同步完成");
    });
  } catch (e) {
    print('Error during startup sync: $e');
    _showStartupToast(() {
      flushBar(FlushLevel.WARNING, "同步错误", "启动同步过程中发生错误: $e");
    });
  }
}

void _showStartupToast(void Function() showToast) {
  if (Get.context != null) {
    showToast();
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (Get.context != null) {
      showToast();
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (Get.context != null) {
        showToast();
      }
    });
  });
}

class SyncStoreControl extends GetxController {
  final GetStorageTokenStorage tokenStorage;
  final SettingController settingController = Get.find<SettingController>();

  final Rx<SyncStoreClient?> client = Rx<SyncStoreClient?>(null);

  SyncStoreControl() : tokenStorage = GetStorageTokenStorage() {
    client.value = SyncStoreClient(
      baseUrl: settingController.syncStoreUrl,
      tokenStorage: tokenStorage,
    );
  }

  get syncStoreClient => client.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    final userId = settingController.userId;
    if (userId.isNotEmpty && client.value != null) {
      try {
        final db = await LocalFirstDB.getDb(userId: userId);
        try {
          final basePath = await databaseFactory.getDatabasesPath();
          final legacyDirPath = join(basePath, userId);
          final migratedCount = await LegacyDataMigrator.migrateLegacyFilesToTargetDb(
            targetDb: db,
            legacyDirPath: legacyDirPath,
          );
          if (migratedCount > 0) {
            print('[LegacyDataMigrator] Migrated $migratedCount legacy items to outbox.');
          }
        } catch (migErr) {
          print('[LegacyDataMigrator] Migration warning: $migErr');
        }

        SyncWorker.configure(
          dio: client.value!.dio,
          db: db,
          onUpgradeRequired: (msg) {
            _showUpgradeDialog(msg);
          },
        );
        SyncWorker.instance.onPullCompleted = (resp) {
          if (resp.changes.isNotEmpty) {
            refreshAllLocalControllers();
          }
        };
        SyncWorker.instance.start();
      } catch (e) {
        print('Failed to start SyncWorker: $e');
      }
    }
    _initialized = true;
  }

  void _showUpgradeDialog(String msg) {
    if (Get.context != null) {
      Get.defaultDialog(
        title: '版本升级提示',
        middleText: msg,
        textConfirm: '知道了',
        onConfirm: () {
          Get.back();
        },
      );
    }
  }

  @override
  void onClose() {
    SyncWorker.instance.stop();
    super.onClose();
  }

  bool _initialized = false;
  @override
  Future<void> ensureInitialization() async {
    while (!_initialized) {
      await onInit();
    }
    return;
  }

  Future<UserProfile> login(String username, String password) async {
    try {
      return client.value!.login(username, password);
    } on ApiException catch (e) {
      print('Error during login: ${e.message}');
      rethrow;
    }
  }

  Future<int> pingLatencyMs() async {
    try {
      return client.value!.pingLatencyMs();
    } catch (e) {
      print('Error during ping test: $e');
      return -1;
    }
  }

  Future<String> fetchVersionInfo(String appName) async {
    try {
      final res = await client.value!.download('/fs/public/$appName/version', isPublic: true);
      return utf8.decode(res);
    } on ApiException catch (e) {
      print('Error during fetching version info: ${e.message}');
      rethrow;
    }
  }

  Future<String> fetchReleaseNotes(String appName) async {
    try {
      final res = await client.value!.download('/fs/public/$appName/CHANGELOG', isPublic: true);
      return utf8.decode(res);
    } on ApiException catch (e) {
      print('Error during fetching release notes: ${e.message}');
      rethrow;
    }
  }
}

// todo maybe rename this and the key name.
class AppCacheManager {
  static CacheManager? _instance;

  static CacheManager instance(SyncStoreClient client) {
    _instance ??= CacheManager(
      Config(
        'auth_image_cache', // 缓存对应的 key
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 200,
        fileService: SyncStoreFileService(client), // 注入你的 Dio 服务
      ),
    );
    return _instance!;
  }
}

class SyncStoreFileService extends FileService {
  final SyncStoreClient syncStoreClient;

  SyncStoreFileService(this.syncStoreClient);

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    final bytes = await syncStoreClient.download(url);
    return _SyncStoreFileServiceResponse(url: url, bytes: bytes, statusCode: 200);
  }
}

class _SyncStoreFileServiceResponse extends FileServiceResponse {
  final String url;
  final Uint8List bytes;
  final int _statusCode;

  _SyncStoreFileServiceResponse({required this.url, required this.bytes, required int statusCode})
    : _statusCode = statusCode;

  @override
  Stream<List<int>> get content => Stream.value(bytes);

  @override
  int? get contentLength => bytes.length;

  @override
  int get statusCode => _statusCode;

  // 这里的参数可以根据需要调整缓存策略
  @override
  DateTime get validTill => DateTime.now().add(const Duration(days: 7));

  @override
  String? get eTag => null;

  @override
  String get fileExtension => url.split('.').last;
}

class GetStorageTokenStorage implements TokenStorage {
  final box = GetStorage(GET_STORAGE_FILE_KEY);
  final SettingController settingController = Get.find<SettingController>();

  //  override TokenStorage
  @override
  Future<void> clear() {
    TaskWidgetBridge.scheduleLoggedOutState();
    return Future.wait([box.remove(TOKEN_ACCESS_KEY), box.remove(TOKEN_REFRESH_KEY)]);
  }

  @override
  Future<String?> getAccessToken() {
    return Future.value(box.read<String?>(TOKEN_ACCESS_KEY));
  }

  @override
  Future<String?> getRefreshToken() {
    return Future.value(box.read<String?>(TOKEN_REFRESH_KEY));
  }

  @override
  Future<void> setAccessToken(String token, {DateTime? expiry}) {
    return box.write(TOKEN_ACCESS_KEY, token);
  }

  @override
  Future<void> setRefreshToken(String token, {DateTime? expiry}) {
    return box.write(TOKEN_REFRESH_KEY, token);
  }

  @override
  void setUserId(String userId) {
    settingController.updateUserInfo(userId: userId);
  }

  @override
  String? getUserId() {
    return settingController.userId;
  }
}
