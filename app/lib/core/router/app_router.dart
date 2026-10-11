import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xbb/pages/login.dart';
import 'package:xbb/pages/profile.dart';
import 'package:xbb/pages/chat/chat_page.dart';
import 'package:xbb/pages/notes/editor_pages.dart';
import 'package:xbb/pages/notes/view_post.dart';
import 'package:xbb/pages/task/task_page.dart';
import 'package:xbb/pages/trackers/edit_tracker.dart';
import 'package:xbb/pages/trackers/view_tracker.dart';
import 'package:xbb/pages/checkin/edit_event_page.dart';
import 'package:xbb/pages/home.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');

/// 全局 GoRouter Provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
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
