import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'auth_interceptor.dart';
import 'chunk_interceptor.dart';
import 'hpke_interceptor.dart';
import 'token_storage.dart';
import 'models.dart';
import 'errors.dart';

class SyncStoreClient {
  final Dio _dio;
  final TokenStorage tokenStorage;
  final AuthService authService;
  final bool enableHpke;

  SyncStoreClient._(this._dio, this.tokenStorage, this.authService, this.enableHpke);

  factory SyncStoreClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
    required bool enableHpke,
    Dio? dio,
  }) {
    final client = dio ?? Dio(BaseOptions(baseUrl: baseUrl));
    final authSrv = AuthService(client, tokenStorage);
    client.interceptors.add(AuthInterceptor(tokenStorage, authSrv));
    if (enableHpke) {
      // try to get existing public key from storage
      tokenStorage.getHpkePubKey().then((publicKey) {
        if (publicKey != null) {
          client.interceptors.add(HpkeInterceptor(publicKey));
          client.interceptors.add(ConcurrentChunkInterceptor());
        }
      });
    }
    return SyncStoreClient._(client, tokenStorage, authSrv, enableHpke);
  }

  // helper function to build Options for request
  Options _buildOptions({bool skipAuth = false, bool skipHpke = false, ResponseType responseType = ResponseType.json}) {
    final extra = <String, dynamic>{};
    if (skipAuth) {
      extra['skipAuthInterceptor'] = true;
    }
    if (enableHpke && !skipHpke && _dio.interceptors.any((element) => element is HpkeInterceptor)) {
      extra['secureHpke'] = true;
      extra['isChunked'] = true; // 只有启用HPKE才启用分片上传
      responseType = ResponseType.bytes;
    }
    return Options(extra: extra, responseType: responseType);
  }

  Future<Uint8List> download(String url, {bool isPublic = false}) {
    return perform(() async {
      // public download does not need auth, enable skip auth.
      // not support hpke for public download for now.
      final options = _buildOptions(skipAuth: isPublic, skipHpke: true, responseType: ResponseType.bytes);
      final resp = await _dio.get<List<int>>(url, options: options);
      return Uint8List.fromList(resp.data!);
    });
  }

  Future<UserProfile> login(String username, String password) {
    return perform(() async {
      final userId = await authService.login(username, password);
      tokenStorage.setUserId(userId);
      return getProfile(userId);
    });
  }

  Future<bool> logout() async {
    // Just clear tokens, todo might need to call server logout endpoint in future
    await tokenStorage.clear();
    return true;
  }

  String currentUserId() {
    final String? userId = tokenStorage.getUserId();
    if (userId == null) {
      throw ApiException(ApiError.loginRequired);
    }
    return userId;
  }

  Future<int> pingLatencyMs() async {
    try {
      final stopwatch = Stopwatch()..start();
      await _dio.get('/health', options: _buildOptions(skipAuth: true, skipHpke: true));
      stopwatch.stop();
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      // Use -1 to represent unreachable/failed health request.
      return -1;
    }
  }

  Future<UserProfile> getProfile(String userId) {
    return perform(() async {
      // in case of first time login, we need to skip hpke to get public key?
      // this api can be no harm called without hpke.
      final resp = await _dio.get('/user/profile/$userId', options: _buildOptions(skipHpke: true));
      final data = resp.data as Map<String, dynamic>;
      final userProfile = UserProfile.fromJson(data);
      tokenStorage.setHpkePubKey(userProfile.publicKey);
      // update HpkeInterceptor with new public key if needed
      final publicKey = await tokenStorage.getHpkePubKey();
      if (publicKey == null) return userProfile;
      _dio.interceptors.removeWhere((element) => element is HpkeInterceptor);
      _dio.interceptors.add(HpkeInterceptor(publicKey));
      return userProfile;
    });
  }

  Future<UserProfile> updateProfile(String userId, UpdateUserProfileRequest newProfile) {
    return perform(() async {
      final resp = await _dio.post('/user/profile/$userId', data: newProfile.toJson(), options: _buildOptions());
      final data = resp.data as Map<String, dynamic>;
      return UserProfile.fromJson(data);
    });
  }

  Future<void> addFriend(String friendUserId) {
    return perform(() async {
      await _dio.post('/user/friends', data: {'friend_id': friendUserId}, options: _buildOptions());
      return;
    });
  }

  Future<List<UserProfile>> getFriends() {
    return perform(() async {
      final resp = await _dio.get('/user/friends', options: _buildOptions());
      final data = resp.data as Map<String, dynamic>;
      final friends = data['friends'] as List<dynamic>;
      return friends.map((e) => UserProfile.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// --- Data APIs ---

  /// create new data, returns meta id
  Future<String> create(String namespace, String collection, Map<String, dynamic> body) {
    return perform(() async {
      final resp = await _dio.post('/data/$namespace/$collection', data: body, options: _buildOptions());
      return resp.data as String;
    });
  }

  Future<BatchGetResponse<T>> batchGet<T extends Object>(
    String namespace,
    String collection,
    List<String> ids,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return perform(() async {
      final resp = await _dio.post(
        '/batch-data/$namespace/$collection/by_ids',
        data: {'ids': ids},
        options: _buildOptions(),
      );
      final data = resp.data as Map<String, dynamic>;
      return BatchGetResponse.fromJson(data, (json) => fromJson(json as Map<String, dynamic>));
    });
  }

  Future<ListResponse> batchListChildren(
    String namespace,
    String collection,
    List<String> parentIds, {
    String? marker,
  }) {
    return perform(() async {
      final query = <String, dynamic>{if (marker != null) 'marker': marker};
      final resp = await _dio.post(
        '/batch-data/$namespace/$collection/by_parent_ids',
        data: {'ids': parentIds},
        queryParameters: query,
        options: _buildOptions(),
      );
      final data = resp.data as Map<String, dynamic>;
      return ListResponse.fromJson(data);
    });
  }

  /// get data by id
  Future<DataItem<T>> get<T extends Object>(
    String namespace,
    String collection,
    String id,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return perform(() async {
      final resp = await _dio.get('/data/$namespace/$collection/$id', options: _buildOptions());
      final fromJsonT = (Object? json) => fromJson(json as Map<String, dynamic>);
      return DataItem<T>.fromJson(resp.data, fromJsonT);
    });
  }

  /// update data by id
  Future<String> update(String namespace, String collection, String id, Map<String, dynamic> body) {
    return perform(() async {
      final resp = await _dio.post('/data/$namespace/$collection/$id', data: body, options: _buildOptions());
      return resp.data as String;
    });
  }

  /// delete data by id
  Future<void> delete(String namespace, String collection, String id) {
    return perform(() async {
      await _dio.delete('/data/$namespace/$collection/$id', options: _buildOptions(skipHpke: true));
    });
  }

  /// list with optional parentId, marker, limit
  Future<ListResponse> list(
    String namespace,
    String collection, {
    String? parentId,
    String? marker,
    bool withPermission = false,
    int limit = 50,
  }) {
    return perform(() async {
      final query = <String, dynamic>{
        if (parentId != null) 'parent_id': parentId,
        if (marker != null) 'marker': marker,
        if (withPermission) 'permission': true,
        'limit': limit,
      };
      final resp = await _dio.get('/data/$namespace/$collection', queryParameters: query, options: _buildOptions());
      final data = resp.data as Map<String, dynamic>;
      return ListResponse.fromJson(data);
    });
  }

  /// --- ACL APIs ---
  Future<List<Permission>> getAcls(String namespace, String collection, String id) {
    return perform(() async {
      final resp = await _dio.get('/acl/$namespace/$collection/$id', options: _buildOptions());
      final data = resp.data as Map<String, dynamic>;
      final acls = data['permissions'] as List<dynamic>;
      return acls.map((e) => Permission.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  Future<void> updateAcls(String namespace, String collection, String id, List<Permission> permissions) {
    return perform(() async {
      final aclData = {
        'permissions': permissions.where((p) => p.accessLevel != AccessLevel.none).map((p) => p.toJson()).toList(),
      };
      await _dio.post('/acl/$namespace/$collection/$id', data: aclData, options: _buildOptions());
    });
  }

  Future<void> deleteAcls(String namespace, String collection, String id) {
    return perform(() async {
      await _dio.delete('/acl/$namespace/$collection/$id', options: _buildOptions(skipHpke: true));
    });
  }
}

class AuthService {
  final Dio dio;
  final TokenStorage _storage;

  AuthService(this.dio, this._storage);

  Future<String> login(String username, String password) {
    return perform(() async {
      final resp = await dio.post(
        '/auth/name-login',
        data: {'username': username, 'password': password},
        options: Options(extra: {'skipAuthInterceptor': true, 'skipHpke': true}),
      );
      final data = _normalizeResp(resp);
      _persistTokens(data);
      final user_id = data['user_id'] as String;
      return user_id;
    });
  }

  Future<bool> refresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      throw ApiException(ApiError.loginRequired);
    }

    return perform(() async {
      final resp = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuthInterceptor': true, 'skipHpke': true}),
      );
      final data = _normalizeResp(resp);
      _persistTokens(data);
      return true;
    });
  }

  void _persistTokens(Map<String, dynamic> data) {
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;

    if (access != null) _storage.setAccessToken(access);
    if (refresh != null) _storage.setRefreshToken(refresh);
  }

  Map<String, dynamic> _normalizeResp(Response resp) {
    if (resp.data is Map<String, dynamic>) {
      return resp.data as Map<String, dynamic>;
    }
    return {'raw': resp.data};
  }
}

ApiException _wrapDioException(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return ApiException(ApiError.networkError);
  }
  if (e.type == DioExceptionType.unknown && e.error is ApiError) {
    return ApiException(e.error as ApiError);
  }
  if (e.response != null) {
    final status = e.response!.statusCode ?? 0;
    final data = try_decode_data(e.response!.data);
    print('Error with response data: $data');
    print('Error with response status: $status');
    if (status == 401) return ApiException(ApiError.loginRequired, data);
    if (status == 403) return ApiException(ApiError.permissionDenied, data);
    if (status == 400) return ApiException(ApiError.validationError, data);
    if (status == 404) return ApiException(ApiError.notFound, data);
  }
  return ApiException(ApiError.unknown);
}

/// Universal wrapper
Future<T> perform<T>(Future<T> Function() f) async {
  try {
    return await f();
  } on DioException catch (e) {
    throw _wrapDioException(e);
  }
}

String try_decode_data(dynamic data) {
  if (data is String) {
    return data;
  } else if (data is List<int>) {
    return String.fromCharCodes(data);
  } else {
    return data.toString();
  }
}
