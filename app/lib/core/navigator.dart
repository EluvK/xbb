import 'package:flutter/material.dart';

/// 纯净的全局导航管理（替代 Get.toNamed / Get.back / Get.arguments 等）
class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static String _currentRoute = '/';
  static String get currentRoute => _currentRoute;

  static BuildContext? get context => navigatorKey.currentContext;

  /// 导航到新页面
  static Future<T?> to<T>(Widget page) {
    final state = navigatorKey.currentState;
    if (state == null) return Future.value(null);
    return state.push<T>(MaterialPageRoute(builder: (_) => page));
  }

  /// 导航到命名路由
  static Future<T?> toNamed<T>(String routeName, {dynamic arguments}) {
    _currentRoute = routeName;
    final state = navigatorKey.currentState;
    if (state == null) return Future.value(null);
    return state.pushNamed<T>(routeName, arguments: arguments);
  }

  /// 导航并清空所有上层路由
  static Future<T?> offAllNamed<T>(String routeName, {dynamic arguments}) {
    _currentRoute = routeName;
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

  /// 获取路由参数（若当前 context 存在）
  static dynamic get arguments {
    final ctx = context;
    if (ctx == null) return null;
    return ModalRoute.of(ctx)?.settings.arguments;
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
