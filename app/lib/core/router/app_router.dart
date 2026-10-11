import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xbb/core/network/api_client.dart';
import 'package:xbb/pages/chat/chat_page.dart';
import 'package:xbb/pages/checkin/edit_event_page.dart';
import 'package:xbb/pages/home.dart';
import 'package:xbb/pages/login.dart';
import 'package:xbb/pages/notes/editor_pages.dart';
import 'package:xbb/pages/notes/view_post.dart';
import 'package:xbb/pages/profile.dart';
import 'package:xbb/pages/task/task_page.dart';
import 'package:xbb/pages/trackers/edit_tracker.dart';
import 'package:xbb/pages/trackers/view_tracker.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');

/// 纯函数路由重定向守卫逻辑，便于测试与独立调用
String? appRouterRedirect({
  required bool isLoggedIn,
  required String location,
  Map<String, String>? queryParameters,
}) {
  final isGoingToLogin = location == '/login';

  // 1. 已登录用户访问登录页时，自动重定向至原目标或主页
  if (isLoggedIn && isGoingToLogin) {
    final from = queryParameters?['from'];
    if (from != null && from.isNotEmpty && from != '/login') {
      return from;
    }
    return '/';
  }

  // 2. 未登录访问需登录态保护页面时（如个人资料与好友中心），优雅重定向至登录页
  const protectedPaths = ['/profile'];
  if (!isLoggedIn && protectedPaths.contains(location)) {
    return '/login?from=$location';
  }

  return null;
}

/// 全局声明式 GoRouter Provider（集成鉴权守卫与网络错误生命周期）
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  // 绑定全局网络层未授权 (401) 与强制升级 (426) 生命周期拦截
  ApiClient.instance.onUnauthorized = () {
    ref.read(authProvider.notifier).logout();
    rootNavigatorKey.currentState?.context.go('/login');
  };

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      return appRouterRedirect(
        isLoggedIn: auth.isLoggedIn,
        location: state.matchedLocation,
        queryParameters: state.uri.queryParameters,
      );
    },
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePageWrapper(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/task',
        name: 'task',
        builder: (context, state) => const TaskPage(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatPage(),
      ),
      GoRoute(
        path: '/notes/view-post',
        name: 'notes-view-post',
        builder: (context, state) => const ViewPostPage(),
      ),
      GoRoute(
        path: '/notes/edit-post',
        name: 'notes-edit-post',
        builder: (context, state) => const EditPostPage(),
      ),
      GoRoute(
        path: '/notes/edit-repo',
        name: 'notes-edit-repo',
        builder: (context, state) => const EditRepoPage(),
      ),
      GoRoute(
        path: '/tracker/edit-tracker',
        name: 'tracker-edit-tracker',
        builder: (context, state) => const EditTrackerPage(),
      ),
      GoRoute(
        path: '/tracker/view-tracker',
        name: 'tracker-view-tracker',
        builder: (context, state) => const ViewTrackerDetailPage(),
      ),
      GoRoute(
        path: '/checkin/edit-event',
        name: 'checkin-edit-event',
        builder: (context, state) => const EditCheckinEventPage(),
      ),
    ],
  );
});
