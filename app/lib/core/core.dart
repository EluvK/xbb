library core;

import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xbb/utils/utils.dart';

export 'locate.dart';
export 'navigator.dart';
export 'state.dart';
export 'package:xbb/utils/translation.dart';

import 'locate.dart';
import 'navigator.dart';
import 'state.dart';
import 'package:xbb/utils/translation.dart';

/// 纯净的轻量平台检测（替代 GetPlatform）
class GetPlatform {
  static bool get isMobile => !kIsWeb && (io.Platform.isAndroid || io.Platform.isIOS);
  static bool get isAndroid => !kIsWeb && io.Platform.isAndroid;
  static bool get isIOS => !kIsWeb && io.Platform.isIOS;
  static bool get isMacOS => !kIsWeb && io.Platform.isMacOS;
  static bool get isWindows => !kIsWeb && io.Platform.isWindows;
  static bool get isLinux => !kIsWeb && io.Platform.isLinux;
  static bool get isWeb => kIsWeb;
}

class _RoutingHelper {
  String get current => AppNavigator.currentRoute;
}

/// 纯净的轻量门面（彻底替代 package:get/get.dart）
class Get {
  static T find<T>() => Locate.find<T>();
  static T? findOrNull<T>() => Locate.findOrNull<T>();
  static T put<T>(T instance, {bool permanent = false}) =>
      Locate.put<T>(instance, permanent: permanent);
  static Future<T> putAsync<T>(
    FutureOr<T> Function() builder, {
    bool permanent = false,
  }) =>
      Locate.putAsync<T>(builder, permanent: permanent);
  static bool isRegistered<T>() => Locate.isRegistered<T>();
  static Future<void> delete<T>({bool force = false}) =>
      Locate.delete<T>(force: force);

  static BuildContext? get context => AppNavigator.context;
  static dynamic get arguments => AppNavigator.arguments;

  static double get width {
    final ctx = context;
    if (ctx != null) return MediaQuery.of(ctx).size.width;
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isNotEmpty) {
      return MediaQueryData.fromView(views.first).size.width;
    }
    return 800.0;
  }

  static double get height {
    final ctx = context;
    if (ctx != null) return MediaQuery.of(ctx).size.height;
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isNotEmpty) {
      return MediaQueryData.fromView(views.first).size.height;
    }
    return 600.0;
  }

  static ThemeData get theme {
    final ctx = context;
    if (ctx != null) return Theme.of(ctx);
    return ThemeData.light();
  }

  static Locale? get locale {
    return Locale(Translation.currentLocale.split('_').first);
  }

  static void changeThemeMode(ThemeMode themeMode) {}
  static void updateLocale(Locale loc) {
    Translation.currentLocale = '${loc.languageCode}_${loc.countryCode ?? ""}';
  }
  static void forceAppUpdate() {}

  static String get currentRoute => AppNavigator.currentRoute;
  static dynamic get routing => _RoutingHelper();

  static Future<T?> to<T>(dynamic page) =>
      AppNavigator.to<T>(page is Widget ? page : (page is Function ? page() : page));

  static Future<T?> toNamed<T>(String page, {dynamic arguments}) =>
      AppNavigator.toNamed<T>(page, arguments: arguments);

  static Future<T?> offAllNamed<T>(String newRouteName, {dynamic arguments}) =>
      AppNavigator.offAllNamed<T>(newRouteName, arguments: arguments);

  static Future<T?> offNamed<T>(String page, {dynamic arguments}) =>
      AppNavigator.offNamed<T>(page, arguments: arguments);

  static void back<T>([T? result]) => AppNavigator.back<T>(result);

  static Future<T?> bottomSheet<T>(
    Widget bottomsheet, {
    Color? backgroundColor,
    bool isDismissible = true,
    bool isScrollControlled = false,
    ShapeBorder? shape,
  }) =>
      AppNavigator.bottomSheet<T>(
        bottomsheet,
        backgroundColor: backgroundColor,
        isDismissible: isDismissible,
        isScrollControlled: isScrollControlled,
        shape: shape,
      );

  static void snackbar(
    String title,
    String message, {
    dynamic snackPosition,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
  }) {
    flushBar(FlushLevel.INFO, title, message);
  }

  static Future<T?> defaultDialog<T>({
    String title = '提示',
    String middleText = '',
    String textConfirm = '确定',
    String? textCancel,
    Color? confirmTextColor,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) =>
      AppNavigator.showAppDialog<T>(
        title: title,
        middleText: middleText,
        textConfirm: textConfirm,
        textCancel: textCancel,
        confirmTextColor: confirmTextColor,
        onConfirm: onConfirm,
        onCancel: onCancel,
      );
}

abstract class GetResponsiveView extends StatelessWidget {
  const GetResponsiveView({super.key});

  Widget? phone() => null;
  Widget? tablet() => null;
  Widget? desktop() => null;
  Widget? watch() => null;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return phone() ?? desktop() ?? const SizedBox.shrink();
    } else if (width < 900) {
      return tablet() ?? desktop() ?? phone() ?? const SizedBox.shrink();
    } else {
      return desktop() ?? tablet() ?? phone() ?? const SizedBox.shrink();
    }
  }
}

typedef GetxController = AppController;
