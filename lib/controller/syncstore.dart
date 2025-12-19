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
