import 'dart:async';
import 'package:dio/dio.dart';
import 'token_storage.dart';
import 'client.dart';
import 'errors.dart';

/// AuthInterceptor automatically attaches Authorization header and
/// retries requests when access token expired by running refresh once.
///
/// Usage:
///  final dio = Dio(BaseOptions(baseUrl: 'http://.../api'));
///  final storage = InMemoryTokenStorage();
///  final authService = AuthService(dio, storage);
///  dio.interceptors.add(AuthInterceptor(storage, authService));
class AuthInterceptor extends Interceptor {
  final TokenStorage _storage;
  final AuthService _authService;

  // Single refresh completer to deduplicate concurrent refresh requests.
  Completer<bool>? _refreshCompleter;

  AuthInterceptor(this._storage, this._authService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['skipAuthInterceptor'] == true) {
      // skip adding auth header
      handler.next(options);
      return;
    }

    final String? token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    } else {
      // no access token available, should cancel the request
      handler.reject(DioException(requestOptions: options, error: ApiError.loginRequired));
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // auth request should not trigger refresh
    if (err.requestOptions.extra['skipAuthInterceptor'] == true) {
      handler.next(err);
      return;
    }

    final status = err.response?.statusCode;
    // only attempt refresh on 401 and for non-retried requests
    final requestOptions = err.requestOptions;
    final alreadyRetried = requestOptions.extra['__retried'] == true;

    if (status == 401 && !alreadyRetried) {
      try {
        final didRefresh = await _runRefresh();
        if (didRefresh) {
          // update headers and retry
          final newToken = await _storage.getAccessToken();
          if (newToken == null) {
            handler.next(err);
            return;
          }
          final newExtra = Map<String, dynamic>.from(requestOptions.extra)..['__retried'] = true;
          final opts = Options(
            method: requestOptions.method,
            headers: Map<String, dynamic>.from(requestOptions.headers)..['Authorization'] = 'Bearer $newToken',
            extra: newExtra,
            responseType: requestOptions.responseType,
            contentType: requestOptions.contentType,
          );
          final originalData = requestOptions.extra['__raw_data'] ?? requestOptions.data;
          final cloneReq = await _authService.dio.request(
            requestOptions.path,
            data: originalData,
            queryParameters: requestOptions.queryParameters,
            options: opts,
            cancelToken: requestOptions.cancelToken,
            onReceiveProgress: requestOptions.onReceiveProgress,
            onSendProgress: requestOptions.onSendProgress,
          );
          return handler.resolve(cloneReq);
        } else {
          // refresh failed: clear storage and raise AuthException
          await _storage.clear();
          handler.next(DioException(requestOptions: requestOptions, error: ApiError.loginRequired));
          return;
        }
      } catch (e) {
        await _storage.clear();
        handler.next(DioException(requestOptions: requestOptions, error: ApiError.loginRequired));
        return;
      }
    }

    handler.next(err);
  }

  Future<bool> _runRefresh() async {
    if (_refreshCompleter != null) {
      // another refresh in progress - wait for it
      return _refreshCompleter!.future;
    }
    _refreshCompleter = Completer<bool>();
    try {
      final ok = await _authService.refresh();
      _refreshCompleter!.complete(ok);
      return ok;
    } catch (e) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      // allow a short delay before nulling to reduce races (optional)
      Future.delayed(Duration(milliseconds: 10), () {
        _refreshCompleter = null;
      });
    }
  }
}
