import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xbb/core/network/api_client.dart';
import 'package:xbb/core/router/app_router.dart';

class _LifecycleMockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;
  _LifecycleMockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('TASK-0.6: 声明式路由守卫与鉴权状态生命周期', () {
    test('未登录访问受保护路由正确引导至 /login 携带原路由', () {
      final redirectResult = appRouterRedirect(
        isLoggedIn: false,
        location: '/profile',
      );
      expect(redirectResult, equals('/login?from=/profile'));

      // 访问普通主页，离线允许正常访问
      final homeResult = appRouterRedirect(
        isLoggedIn: false,
        location: '/',
      );
      expect(homeResult, isNull);
    });

    test('已登录用户访问 /login 自动返回原目标路由或主页', () {
      // 携带 from 参数
      final redirectWithFrom = appRouterRedirect(
        isLoggedIn: true,
        location: '/login',
        queryParameters: {'from': '/notes/view-post'},
      );
      expect(redirectWithFrom, equals('/notes/view-post'));

      // 无 from 参数，默认重定向回主页 '/'
      final redirectDefault = appRouterRedirect(
        isLoggedIn: true,
        location: '/login',
      );
      expect(redirectDefault, equals('/'));

      // 访问已登录页面无需重定向
      final redirectProfile = appRouterRedirect(
        isLoggedIn: true,
        location: '/profile',
      );
      expect(redirectProfile, isNull);
    });

    test('网络层拦截 HTTP 401 触发 onUnauthorized 全局生命周期回调', () async {
      final client = ApiClient.instance;
      bool unauthorizedTriggered = false;
      client.onUnauthorized = () {
        unauthorizedTriggered = true;
      };

      client.dio.httpClientAdapter = _LifecycleMockAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({'code': 'UNAUTHORIZED', 'message': 'Token expired'}),
          401,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      try {
        await client.dio.get('/test-401');
      } catch (_) {}

      expect(unauthorizedTriggered, isTrue);
    });

    test('网络层拦截 HTTP 426 触发 onUpgradeRequired 强制升级公告', () async {
      final client = ApiClient.instance;
      String? upgradeNotice;
      client.onUpgradeRequired = (msg) {
        upgradeNotice = msg;
      };

      client.dio.httpClientAdapter = _LifecycleMockAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({
            'code': 'CLIENT_UPGRADE_REQUIRED',
            'message': '客户端同步协议已废弃，请升级到最新版。',
          }),
          426,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      try {
        await client.dio.get('/test-426');
      } catch (_) {}

      expect(upgradeNotice, equals('客户端同步协议已废弃，请升级到最新版。'));
    });
  });
}
