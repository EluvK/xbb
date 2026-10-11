import 'package:flutter/material.dart';

class _RouteEntry {
  final Route<dynamic> route;
  final dynamic arguments;
  _RouteEntry(this.route, this.arguments);
}

/// 纯净的全局导航管理（替代 Get.toNamed / Get.back / Get.arguments 等）
class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final AppNavigatorObserver observer = AppNavigatorObserver();

  static final List<_RouteEntry> _history = [];
  static dynamic _pendingArguments;

  static String _currentRoute = '/';
  static String get currentRoute => _currentRoute;

  static BuildContext? get context => navigatorKey.currentContext;

  /// 获取路由参数（若当前 context 存在或通过路由观察器追踪）
  static dynamic get arguments {
    if (_history.isNotEmpty) {
      final top = _history.last;
      if (top.arguments != null) return top.arguments;
      if (top.route.settings.arguments != null) return top.route.settings.arguments;
    }
    return _pendingArguments;
  }

  static void _onRoutePushed(Route<dynamic> route) {
    final routeArgs = route.settings.arguments ?? _pendingArguments;
    _history.add(_RouteEntry(route, routeArgs));
    _pendingArguments = null;
    if (route.settings.name != null) {
      _currentRoute = route.settings.name!;
    }
  }

  static void _onRoutePopped(Route<dynamic> route) {
    _history.removeWhere((e) => e.route == route);
    if (_history.isNotEmpty) {
      final top = _history.last;
      if (top.route.settings.name != null) {
        _currentRoute = top.route.settings.name!;
      }
    }
  }

  static void _onRouteReplaced(Route<dynamic> newRoute, Route<dynamic>? oldRoute) {
    if (oldRoute != null) {
      _history.removeWhere((e) => e.route == oldRoute);
    }
    final routeArgs = newRoute.settings.arguments ?? _pendingArguments;
    _history.add(_RouteEntry(newRoute, routeArgs));
    _pendingArguments = null;
    if (newRoute.settings.name != null) {
      _currentRoute = newRoute.settings.name!;
    }
  }

  static void _onRouteRemoved(Route<dynamic> route) {
    _history.removeWhere((e) => e.route == route);
  }

  /// 导航到新页面
  static Future<T?> to<T>(Widget page, {dynamic arguments}) {
    _pendingArguments = arguments;
    final state = navigatorKey.currentState;
    if (state == null) return Future.value(null);
    return state.push<T>(MaterialPageRoute(
      builder: (_) => page,
      settings: RouteSettings(arguments: arguments),
    ));
  }

  /// 导航到命名路由
  static Future<T?> toNamed<T>(String routeName, {dynamic arguments}) {
    _currentRoute = routeName;
    _pendingArguments = arguments;
    final state = navigatorKey.currentState;
    if (state == null) return Future.value(null);
    return state.pushNamed<T>(routeName, arguments: arguments);
  }

  /// 导航并清空所有上层路由
  static Future<T?> offAllNamed<T>(String routeName, {dynamic arguments}) {
    _currentRoute = routeName;
    _pendingArguments = arguments;
    final state = navigatorKey.currentState;
    if (state == null) return Future.value(null);
    return state.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// 替换当前路由
  static Future<T?> offNamed<T>(String routeName, {dynamic arguments}) {
    _currentRoute = routeName;
    _pendingArguments = arguments;
    final state = navigatorKey.currentState;
    if (state == null) return Future.value(null);
    return state.pushReplacementNamed<T, dynamic>(routeName, arguments: arguments);
  }

  /// 弹出当前路由
  static void back<T>([T? result]) {
    final state = navigatorKey.currentState;
    if (state != null && state.canPop()) {
      state.pop<T>(result);
    }
  }

  /// 底部面板
  static Future<T?> bottomSheet<T>(
    Widget bottomsheet, {
    Color? backgroundColor,
    bool isDismissible = true,
    bool isScrollControlled = false,
    ShapeBorder? shape,
  }) {
    final ctx = context;
    if (ctx == null) return Future.value(null);
    return showModalBottomSheet<T>(
      context: ctx,
      backgroundColor: backgroundColor,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      shape: shape,
      builder: (_) => bottomsheet,
    );
  }

  /// 显示通用对话框（替代 Get.defaultDialog）
  static Future<T?> showAppDialog<T>({
    String title = '提示',
    String middleText = '',
    String textConfirm = '确定',
    String? textCancel,
    Color? confirmTextColor,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    final ctx = context;
    if (ctx == null) return Future.value(null);

    return showDialog<T>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: Text(middleText),
        actions: [
          if (textCancel != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                onCancel?.call();
              },
              child: Text(textCancel),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              onConfirm?.call();
            },
            style: confirmTextColor != null
                ? TextButton.styleFrom(foregroundColor: confirmTextColor)
                : null,
            child: Text(textConfirm),
          ),
        ],
      ),
    );
  }
}

class AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppNavigator._onRoutePushed(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppNavigator._onRoutePopped(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      AppNavigator._onRouteReplaced(newRoute, oldRoute);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppNavigator._onRouteRemoved(route);
  }
}
