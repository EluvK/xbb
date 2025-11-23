import 'package:get_storage/get_storage.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/constant.dart';

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

  String getUserName() {
    return box.read<String?>(STORAGE_USER_NAME_KEY) ?? '';
  }

  void setUserName(String name) {
    box.write(STORAGE_USER_NAME_KEY, name);
  }
}
