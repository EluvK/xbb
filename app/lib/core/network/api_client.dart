import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 全局网络客户端管理单例 (ApiClient)
/// 负责维护 Dio 单例、BaseURL 规范化、Bearer JWT 鉴权拦截器与请求日志打印。
class ApiClient {
  static const int defaultPort = 10101;

  static String get defaultDevServerUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$defaultPort';
    }
    return 'http://127.0.0.1:$defaultPort';
  }

  static String get defaultBaseUrl => defaultDevServerUrl;

  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();

  ApiClient._() {
    _dio = Dio(_defaultOptions());
    _setupInterceptors();
  }

  late final Dio _dio;
  String _baseUrl = defaultDevServerUrl;
  String? _token;

  /// HTTP 401 未授权回调（用于引导重新登录）
  void Function()? onUnauthorized;

  /// HTTP 426 强制升级回调（用于展示升级公告）
  void Function(String message)? onUpgradeRequired;

  Dio get dio => _dio;
  String get baseUrl => _baseUrl;
  String? get token => _token;

  /// 规范化服务器 BaseURL，去除尾部斜杠及多余的 /api 后缀
  static String normalizeBaseUrl(String rawUrl) {
    var trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return defaultDevServerUrl;
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.endsWith('/api')) {
      trimmed = trimmed.substring(0, trimmed.length - 4);
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static BaseOptions _defaultOptions({String? baseUrl}) {
    return BaseOptions(
      baseUrl: baseUrl ?? defaultDevServerUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
  }

  /// 配置或初始化网络连接管道
  void configure({required String baseUrl, String? token}) {
    _baseUrl = normalizeBaseUrl(baseUrl);
    _token = token;
    _dio.options.baseUrl = _baseUrl;
  }

  /// 动态更新 BaseURL
  void updateBaseUrl(String newUrl) {
    _baseUrl = normalizeBaseUrl(newUrl);
    _dio.options.baseUrl = _baseUrl;
  }

  /// 动态更新 Bearer JWT Token
  void updateToken(String? newToken) {
    _token = newToken;
  }

  void _setupInterceptors() {
    // 1. Bearer JWT 注入拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final currentToken = _token;
          if (currentToken != null && currentToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $currentToken';
          }
          handler.next(options);
        },
      ),
    );

    // 2. HTTP 控制台请求/响应日志拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final fullUri = options.uri.toString();
          developer.log(
            '--> ${options.method} $fullUri',
            name: 'SyncHTTP',
          );
          // 控制台可见日志
          // ignore: avoid_print
          print('[SyncHTTP] --> ${options.method} $fullUri');
          handler.next(options);
        },
        onResponse: (response, handler) {
          final fullUri = response.requestOptions.uri.toString();
          developer.log(
            '<-- ${response.statusCode} ${response.requestOptions.method} $fullUri',
            name: 'SyncHTTP',
          );
          // ignore: avoid_print
          print('[SyncHTTP] <-- ${response.statusCode} ${response.requestOptions.method} $fullUri');
          handler.next(response);
        },
        onError: (DioException err, handler) {
          final fullUri = err.requestOptions.uri.toString();
          final status = err.response?.statusCode;
          developer.log(
            '<-- ERROR $status ${err.requestOptions.method} $fullUri: ${err.message}',
            name: 'SyncHTTP',
            error: err,
          );
          // ignore: avoid_print
          print('[SyncHTTP] <-- ERROR $status ${err.requestOptions.method} $fullUri (${err.message})');

          // 全局状态生命周期拦截
          if (status == 401) {
            onUnauthorized?.call();
          } else if (status == 426) {
            String upgradeMessage = '当前客户端同步协议已废弃，请升级到最新应用版本。';
            final data = err.response?.data;
            if (data is Map && data['message'] != null) {
              upgradeMessage = data['message'].toString();
            }
            onUpgradeRequired?.call(upgradeMessage);
          }

          handler.next(err);
        },
      ),
    );
  }
}
