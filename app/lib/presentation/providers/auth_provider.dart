import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/core/network/api_client.dart';
import 'package:xbb/core/network/auth_service.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

class AuthState {
  final String userId;
  final String username;
  final String nickname;
  final String avatar;
  final String token;
  final bool isLoggedIn;

  const AuthState({
    this.userId = 'default',
    this.username = '',
    this.nickname = '',
    this.avatar = 'avatar_1',
    this.token = '',
    this.isLoggedIn = false,
  });

  AuthState copyWith({
    String? userId,
    String? username,
    String? nickname,
    String? avatar,
    String? token,
    bool? isLoggedIn,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      token: token ?? this.token,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final GetStorage box;
  final DatabaseChangeNotifier dbChangeNotifier;
  final AuthService authService;
  final Ref? ref;

  AuthNotifier(this.box, this.dbChangeNotifier, [AuthService? service, this.ref])
      : authService = service ?? AuthService(),
        super(const AuthState()) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final user = box.read<Map<String, dynamic>?>(STORAGE_SETTING_USER_INFO_KEY);
    final token = box.read<String>(TOKEN_ACCESS_KEY) ?? box.read<String>('user_token') ?? '';

    if (user != null) {
      final id = user['id'] as String? ?? 'default';
      final name = user['username'] as String? ?? '';
      final nick = user['nickname'] as String? ?? name;
      final avt = user['avatar'] as String? ?? 'avatar_1';

      if (id.isNotEmpty && id != 'default') {
        if (token.isNotEmpty) {
          ApiClient.instance.updateToken(token);
        }
        state = AuthState(
          userId: id,
          username: name,
          nickname: nick,
          avatar: avt,
          token: token,
          isLoggedIn: true,
        );
      }
    }
  }

  /// 使用账号密码向 Rust 服务端发起登录
  Future<void> loginWithCredentials(String username, String password) async {
    final result = await authService.login(username, password);
    await _applyAuthSuccess(result.user, result.token);
  }

  /// 向 Rust 服务端发起新账号注册
  Future<void> registerWithCredentials(
    String username,
    String password, {
    String? nickname,
    String? avatar,
  }) async {
    final result = await authService.register(
      username,
      password,
      nickname: nickname,
      avatar: avatar,
    );
    await _applyAuthSuccess(result.user, result.token);
  }

  /// 本地写入鉴权信息并动态切换数据库与同步配置
  Future<void> setLogin({
    required String userId,
    required String username,
    String? nickname,
    String? avatar,
    required String token,
  }) async {
    final user = UserAuthInfo(
      id: userId,
      username: username,
      nickname: nickname ?? username,
      avatar: avatar ?? 'avatar_1',
    );
    await _applyAuthSuccess(user, token);
  }

  Future<void> _applyAuthSuccess(UserAuthInfo user, String token) async {
    // 1. 持久化用户信息与权威 Token
    await box.write(STORAGE_SETTING_USER_INFO_KEY, user.toJson());
    await box.write(TOKEN_ACCESS_KEY, token);
    await box.write('user_token', token);

    // 2. 更新网络层 Bearer JWT 拦截器
    ApiClient.instance.updateToken(token);

    // 3. 动态初始化该用户专属的 SQLite 数据库并绑定到 SyncWorker 及 Riverpod DatabaseProvider
    final db = await LocalFirstDB.getDb(userId: user.id);
    setActiveDatabase(db);
    SyncWorker.instance.updateDependencies(db: db);
    SyncWorker.instance.start();
    SyncWorker.instance.triggerSync();
    if (ref != null) {
      ref!.read(activeDatabaseStateProvider.notifier).state = db;
    }

    // 4. 广播所有本地业务表刷新
    dbChangeNotifier.notifyAll(LocalFirstDB.coreEntityTables);

    // 5. 更新响应式状态
    state = AuthState(
      userId: user.id,
      username: user.username,
      nickname: user.nickname,
      avatar: user.avatar,
      token: token,
      isLoggedIn: true,
    );
  }

  /// 完整登出：清理敏感 Token、停止同步守护进程、重置状态
  Future<void> logout() async {
    // 1. 清除本地持久化 Token 与用户信息
    await box.remove(STORAGE_SETTING_USER_INFO_KEY);
    await box.remove(TOKEN_ACCESS_KEY);
    await box.remove('user_token');

    // 2. 清除网络层 Token
    ApiClient.instance.updateToken(null);

    // 3. 停止同步守护并切回纯内存隔离数据库（访客模式）
    SyncWorker.instance.stop();
    SyncWorker.instance.updateDependencies(db: null);
    final guestDb = await LocalFirstDB.openInMemory();
    setActiveDatabase(guestDb);
    if (ref != null) {
      ref!.read(activeDatabaseStateProvider.notifier).state = guestDb;
    }

    // 4. 广播业务表刷新
    dbChangeNotifier.notifyAll(LocalFirstDB.coreEntityTables);

    // 5. 更新状态
    state = const AuthState();
  }

  /// 更新用户个人资料并持久化
  Future<void> updateProfile({String? nickname, String? avatar}) async {
    final updated = await authService.updateProfile(nickname: nickname, avatar: avatar);
    final current = box.read<Map<String, dynamic>?>(STORAGE_SETTING_USER_INFO_KEY) ?? {};
    final newMap = Map<String, dynamic>.from(current)
      ..['nickname'] = updated.nickname
      ..['avatar'] = updated.avatar;
    await box.write(STORAGE_SETTING_USER_INFO_KEY, newMap);

    state = state.copyWith(
      nickname: updated.nickname,
      avatar: updated.avatar,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final box = GetStorage(GET_STORAGE_FILE_KEY);
  final notifier = ref.watch(dbChangeNotifierProvider);
  return AuthNotifier(box, notifier, null, ref);
});
