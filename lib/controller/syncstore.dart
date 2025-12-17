import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:get_storage/get_storage.dart';
import 'package:xbb/constant.dart';

class SyncStoreControl {
  final String baseUrl;
  final GetStorageTokenStorage tokenStorage;
  late final SyncStoreClient client;

  SyncStoreControl({required this.baseUrl, required this.tokenStorage}) {
    client = SyncStoreClient(baseUrl: baseUrl, tokenStorage: tokenStorage);
    Get.put<SyncStoreClient>(client);
  }

  Future<UserProfile> login(String username, String password) async {
    try {
      return client.login(username, password);
    } on ApiException catch (e) {
      print('Error during login: ${e.message}');
      rethrow;
    }
  }

  Future<bool> checkHealth() async {
    try {
      return client.checkHealth();
    } on ApiException catch (e) {
      print('Error during health check: ${e.message}');
      rethrow;
    }
  }
}

class GetStorageTokenStorage implements TokenStorage {
  final box = GetStorage(GET_STORAGE_FILE_KEY);

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
    box.write(STORAGE_USER_ID_KEY, userId);
  }

  @override
  String? getUserId() {
    return box.read<String?>(STORAGE_USER_ID_KEY);
  }

  String getUserName() {
    return box.read<String?>(STORAGE_USER_NAME_KEY) ?? '';
  }

  void setUserName(String name) {
    box.write(STORAGE_USER_NAME_KEY, name);
  }
}
