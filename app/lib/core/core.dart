library core;

import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
export 'package:xbb/utils/translation.dart';

/// 纯净的轻量平台检测工具
class AppPlatform {
  static bool get isMobile => !kIsWeb && (io.Platform.isAndroid || io.Platform.isIOS);
  static bool get isAndroid => !kIsWeb && io.Platform.isAndroid;
  static bool get isIOS => !kIsWeb && io.Platform.isIOS;
  static bool get isMacOS => !kIsWeb && io.Platform.isMacOS;
  static bool get isWindows => !kIsWeb && io.Platform.isWindows;
  static bool get isLinux => !kIsWeb && io.Platform.isLinux;
  static bool get isWeb => kIsWeb;
}

class GetPlatform {
  static bool get isMobile => AppPlatform.isMobile;
  static bool get isAndroid => AppPlatform.isAndroid;
  static bool get isIOS => AppPlatform.isIOS;
  static bool get isMacOS => AppPlatform.isMacOS;
  static bool get isWindows => AppPlatform.isWindows;
  static bool get isLinux => AppPlatform.isLinux;
  static bool get isWeb => AppPlatform.isWeb;
}

/// 兼容旧代码简单数据容器封装
class RxCompat<T> extends ValueNotifier<T> {
  RxCompat(super.value);
  void update(void Function(T val) fn) {
    fn(value);
    notifyListeners();
  }
}

extension RxCompatExtension<T> on T {
  RxCompat<T> get obs => RxCompat<T>(this);
}
