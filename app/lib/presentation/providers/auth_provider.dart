import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

class AuthState {
  final String userId;
  final String username;
  final String token;
  final bool isLoggedIn;

  const AuthState({
    this.userId = 'default',
    this.username = '',
    this.token = '',
    this.isLoggedIn = false,
  });

  AuthState copyWith({
    String? userId,
    String? username,
    String? token,
    bool? isLoggedIn,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      token: token ?? this.token,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final GetStorage box;
  final DatabaseChangeNotifier dbChangeNotifier;

  AuthNotifier(this.box, this.dbChangeNotifier) : super(const AuthState()) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final user = box.read<Map<String, dynamic>?>(STORAGE_SETTING_USER_INFO_KEY);
    if (user != null) {
      final id = user['id'] as String? ?? 'default';
      final name = user['username'] as String? ?? '';
      final token = box.read<String>('user_token') ?? '';
      state = AuthState(
        userId: id,
        username: name,
        token: token,
        isLoggedIn: id.isNotEmpty && id != 'default',
      );
    }
  }

  void setLogin({required String userId, required String username, required String token}) {
    state = AuthState(
      userId: userId,
      username: username,
      token: token,
      isLoggedIn: true,
    );
  }

  void logout() {
    state = const AuthState(userId: 'default', isLoggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final box = GetStorage(GET_STORAGE_FILE_KEY);
  final notifier = ref.watch(dbChangeNotifierProvider);
  return AuthNotifier(box, notifier);
});
