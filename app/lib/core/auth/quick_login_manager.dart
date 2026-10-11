import 'package:get_storage/get_storage.dart';
import 'package:xbb/constant.dart';

/// 快速登录凭据模型
class QuickLoginCredential {
  final String userId;
  final String username;
  final String password;
  final String nickname;
  final String avatar;
  final DateTime lastLoginTime;

  QuickLoginCredential({
    required this.userId,
    required this.username,
    required this.password,
    String? nickname,
    String? avatar,
    DateTime? lastLoginTime,
  })  : nickname = nickname ?? username,
        avatar = avatar ?? 'avatar_1',
        lastLoginTime = lastLoginTime ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'password': password,
        'nickname': nickname,
        'avatar': avatar,
        'lastLoginTime': lastLoginTime.toIso8601String(),
      };

  factory QuickLoginCredential.fromJson(Map<String, dynamic> json) => QuickLoginCredential(
        userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
        username: json['username'] as String? ?? json['user_name'] as String? ?? '',
        password: json['password'] as String? ?? json['user_password'] as String? ?? '',
        nickname: json['nickname'] as String? ?? json['user_name'] as String? ?? '',
        avatar: json['avatar'] as String? ?? json['user_avatar_url'] as String? ?? 'avatar_1',
        lastLoginTime: json['lastLoginTime'] != null
            ? DateTime.tryParse(json['lastLoginTime'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// 快速登录凭据管理器 (QuickLoginManager)
/// 支持在本地安全存储多个已登录账号快照，提供增删查功能
class QuickLoginManager {
  final GetStorage _box;

  QuickLoginManager([GetStorage? box]) : _box = box ?? GetStorage(GET_STORAGE_FILE_KEY);

  List<QuickLoginCredential> getCredentials() {
    final raw = _box.read(STORAGE_SETTING_QUICK_LOGIN_KEY);
    if (raw == null) return [];
    if (raw is Map) {
      final list = <QuickLoginCredential>[];
      raw.forEach((key, val) {
        if (val is Map) {
          try {
            list.add(QuickLoginCredential.fromJson(Map<String, dynamic>.from(val)));
          } catch (_) {}
        }
      });
      list.sort((a, b) => b.lastLoginTime.compareTo(a.lastLoginTime));
      return list;
    }
    return [];
  }

  Future<void> saveCredential(QuickLoginCredential credential) async {
    final raw = _box.read(STORAGE_SETTING_QUICK_LOGIN_KEY);
    final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    map[credential.userId] = credential.toJson();
    await _box.write(STORAGE_SETTING_QUICK_LOGIN_KEY, map);
  }

  Future<void> removeCredential(String userId) async {
    final raw = _box.read(STORAGE_SETTING_QUICK_LOGIN_KEY);
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      map.remove(userId);
      await _box.write(STORAGE_SETTING_QUICK_LOGIN_KEY, map);
    }
  }

  Future<void> clearAll() async {
    await _box.remove(STORAGE_SETTING_QUICK_LOGIN_KEY);
  }
}
