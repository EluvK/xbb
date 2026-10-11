library core;

import 'dart:io' as io;
import 'package:flutter/foundation.dart';
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
