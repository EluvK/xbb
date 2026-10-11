import 'package:dio/dio.dart';
import 'package:xbb/core/network/api_client.dart';

class UserAuthInfo {
  final String id;
  final String username;
  final String nickname;
  final String avatar;

  UserAuthInfo({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatar,
  });

  factory UserAuthInfo.fromJson(Map<String, dynamic> json) {
    return UserAuthInfo(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      nickname: json['nickname'] as String? ?? (json['username'] as String? ?? ''),
      avatar: json['avatar'] as String? ?? 'avatar_1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nickname': nickname,
      'avatar': avatar,
    };
  }
}

class AuthResult {
  final String token;
  final UserAuthInfo user;

  AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String? ?? '',
      user: UserAuthInfo.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class AuthService {
  final Dio _dio;

  AuthService([Dio? dio]) : _dio = dio ?? ApiClient.instance.dio;

  Future<AuthResult> login(String username, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: {
          'username': username.trim(),
          'password': password.trim(),
        },
      );
      if (response.data == null) {
        throw Exception('服务端返回空数据');
      }
      return AuthResult.fromJson(response.data!);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  Future<AuthResult> register(
    String username,
    String password, {
    String? nickname,
    String? avatar,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/register',
        data: {
          'username': username.trim(),
          'password': password.trim(),
          if (nickname != null && nickname.isNotEmpty) 'nickname': nickname.trim(),
          if (avatar != null && avatar.isNotEmpty) 'avatar': avatar.trim(),
        },
      );
      if (response.data == null) {
        throw Exception('服务端返回空数据');
      }
      return AuthResult.fromJson(response.data!);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  Future<UserAuthInfo> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/auth/me');
      final data = response.data;
      if (data == null || data['user'] == null) {
        throw Exception('获取个人资料失败');
      }
      return UserAuthInfo.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  Future<UserAuthInfo> updateProfile({String? nickname, String? avatar}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/profile',
        data: {
          if (nickname != null) 'nickname': nickname.trim(),
          if (avatar != null) 'avatar': avatar.trim(),
        },
      );
      final data = response.data;
      if (data == null || data['user'] == null) {
        throw Exception('更新个人资料失败');
      }
      return UserAuthInfo.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/password',
        data: {
          'old_password': oldPassword.trim(),
          'new_password': newPassword.trim(),
        },
      );
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  Future<List<UserAuthInfo>> listUsers() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/auth/users');
      final data = response.data;
      if (data == null || data['users'] == null) {
        return [];
      }
      final list = data['users'] as List<dynamic>;
      return list.map((e) => UserAuthInfo.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  String _extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      final map = e.response!.data as Map;
      if (map['message'] != null) {
        return map['message'].toString();
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return '网络连接超时，请检查服务器状态';
    }
    if (e.type == DioExceptionType.connectionError) {
      return '无法连接到服务器，请检查网络或服务器地址';
    }
    if (e.response?.statusCode == 401) {
      return '用户名或密码错误';
    }
    if (e.response?.statusCode == 409) {
      return '用户名已被占用';
    }
    return e.message ?? '网络请求失败';
  }
}
