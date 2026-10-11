import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/core/network/auth_service.dart';

class FriendsNotifier extends StateNotifier<AsyncValue<List<UserAuthInfo>>> {
  final AuthService _authService;
  final GetStorage _box;

  FriendsNotifier(this._authService, this._box) : super(const AsyncValue.loading()) {
    loadFriends();
  }

  Future<void> loadFriends() async {
    // 1. 先尝试从本地 Storage 加载缓存 (避免断网白屏)
    final cached = _box.read<List<dynamic>?>(GET_STORAGE_FRIENDS_KEY);
    if (cached != null && cached.isNotEmpty) {
      final list = cached
          .map((e) => UserAuthInfo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      state = AsyncValue.data(list);
    }

    // 2. 异步请求远端最新协同用户列表
    try {
      final remoteList = await _authService.listUsers();
      // 持久化缓存
      await _box.write(
        GET_STORAGE_FRIENDS_KEY,
        remoteList.map((e) => e.toJson()).toList(),
      );
      state = AsyncValue.data(remoteList);
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() => loadFriends();
}

final friendsProvider = StateNotifierProvider<FriendsNotifier, AsyncValue<List<UserAuthInfo>>>((ref) {
  final authService = AuthService();
  final box = GetStorage(GET_STORAGE_FILE_KEY);
  return FriendsNotifier(authService, box);
});
