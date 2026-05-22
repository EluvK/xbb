import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:get_storage/get_storage.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/task_widget.dart';
import 'package:xbb/controller/user.dart' show reInitUserManagerController;
import 'package:xbb/models/notes/model.dart' show onReadySyncAll, reInitNotesSync;
import 'package:xbb/models/task/model.dart' show onReadySyncTask, reInitTaskSync;
import 'package:xbb/models/tracker/model.dart' show onReadySyncTracker, reInitTrackerSync;
import 'package:xbb/utils/utils.dart' show FlushLevel, flushBar, successSimpleFlushBar;

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
  unawaited(onReadySyncStartup());
}

Future<void> onReadySyncStartup() async {
  final settingController = Get.find<SettingController>();
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
    if (settingController.notesEnabled) {
      await onReadySyncAll(
        showCompletionToast: false,
        skipHealthCheck: true,
        showErrorToast: false,
        rethrowOnError: true,
      );
    }
    if (settingController.trackerEnabled) {
      await onReadySyncTracker(
        showCompletionToast: false,
        skipHealthCheck: true,
        showErrorToast: false,
        rethrowOnError: true,
      );
    }
    if (settingController.taskEnabled) {
      await onReadySyncTask(
        showCompletionToast: false,
        skipHealthCheck: true,
        showErrorToast: false,
        rethrowOnError: true,
      );
    }
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
      enableHpke: settingController.syncStoreHpkeEnabled,
    );
  }

  get syncStoreClient => client.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    _initialized = true;
  }

  bool _initialized = false;
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

  @override
  Future<PublicKey?> getHpkePubKey() {
    final pubKeyB64 = box.read<String?>(TOKEN_HPKE_PUBKEY_KEY);
    if (pubKeyB64 == null) {
      return Future.value(null);
    }
    final pubKeyBytes = base64Decode(pubKeyB64);
    final publicKey = SimplePublicKey(pubKeyBytes, type: KeyPairType.x25519);
    return Future.value(publicKey);
  }

  @override
  Future<void> setHpkePubKey(String pubKeyBase64) {
    return box.write(TOKEN_HPKE_PUBKEY_KEY, pubKeyBase64);
  }
}
