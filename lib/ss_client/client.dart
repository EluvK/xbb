import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/ss_client/token_storage.dart';

class SSClient {
  final String baseUrl;
  final GetStorageTokenStorage tokenStorage;
  late final SyncStoreClient client;

  SSClient({required this.baseUrl, required this.tokenStorage}) {
    client = SyncStoreClient(baseUrl: baseUrl, tokenStorage: tokenStorage);
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
