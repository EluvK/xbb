import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:get_storage/get_storage.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/controller/setting.dart';

class SyncStoreControl extends GetxController {
  // todo should allow change baseUrl for different server in future
  final String baseUrl;
  final GetStorageTokenStorage tokenStorage;

  final Rx<SyncStoreClient?> client = Rx<SyncStoreClient?>(null);

  SyncStoreControl({required this.baseUrl, required this.tokenStorage}) {
    client.value = SyncStoreClient(baseUrl: baseUrl, tokenStorage: tokenStorage);
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

  Future<bool> checkHealth() async {
    try {
      return client.value!.checkHealth();
    } on ApiException catch (e) {
      print('Error during health check: ${e.message}');
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
  final NewSettingController settingController = Get.find<NewSettingController>();

  //  override TokenStorage
  @override
  Future<void> clear() {
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
