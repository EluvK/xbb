import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/ss_client/token_storage.dart';

// ignore: constant_identifier_names
const String NOTES_NAMESPACE = 'xbb';
// ignore: constant_identifier_names
const String REPO_COLLECTION = 'repo';
typedef RepoItem = DataItem<Repo>;

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

  // --- Repo APIs ---
  Future<List<RepoItem>> listRepos() async {
    try {
      final list = await client.list<Repo>(NOTES_NAMESPACE, REPO_COLLECTION, fromJson: Repo.fromJson, limit: 100);
      return list.items;
    } on ApiException catch (e) {
      print('Error listing repos: ${e.message}');
      rethrow;
    }
  }

  Future<RepoItem> getRepo(String id) async {
    try {
      final repoItem = await client.get<Repo>(NOTES_NAMESPACE, REPO_COLLECTION, id, Repo.fromJson);
      return repoItem;
    } on ApiException catch (e) {
      print('Error getting repo $id: ${e.message}');
      rethrow;
    }
  }

  Future<String> createRepo(Repo repo) async {
    try {
      final newId = await client.create(NOTES_NAMESPACE, REPO_COLLECTION, repo.toJson());
      return newId;
    } on ApiException catch (e) {
      print('Error creating repo: ${e.message}');
      rethrow;
    }
  }

  Future<String> updateRepo(String id, Repo repo) async {
    try {
      final updatedId = await client.update(NOTES_NAMESPACE, REPO_COLLECTION, id, repo.toJson());
      return updatedId;
    } on ApiException catch (e) {
      print('Error updating repo $id: ${e.message}');
      rethrow;
    }
  }

  Future<void> deleteRepo(String id) async {
    try {
      await client.delete(NOTES_NAMESPACE, REPO_COLLECTION, id);
    } on ApiException catch (e) {
      print('Error deleting repo $id: ${e.message}');
      rethrow;
    }
  }
}
