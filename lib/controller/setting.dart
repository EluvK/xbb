import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SettingController extends GetxController {
  final box = GetStorage('XbbGetStorage');

  // app settings
  final themeMode = ThemeMode.system.obs;

  // cache information
  final currentRepo = "".obs;
  final currentUser = "".obs;
  final currentUserPasswd = "".obs;

  @override
  Future onInit() async {
    print('setting controller onInit');
    getAppSetting();
    getCacheSetting();
    super.onInit();
    _initialized = true;
  }

  bool _initialized = false;
  Future<void> ensureInitialization() async {
    while (!_initialized) {
      await onInit();
    }
    return;
  }

  getAppSetting() {
    String themeText = box.read('theme') ?? 'system';
    print('read theme from box $themeText');
    try {
      themeMode.value =
          ThemeMode.values.firstWhere((e) => e.toString() == themeText);
    } catch (_) {
      print('theme not found, setting to system');
      themeMode.value = ThemeMode.system;
    }
  }

  saveAppSetting() {
    box.write('theme', themeMode.value.toString());
  }

  setThemeMode(ThemeMode theme) {
    print('setting theme: $theme');
    themeMode.value = theme;
    Get.changeThemeMode(themeMode.value);
    box.write('theme', themeMode.value.toString());
  }

  getCacheSetting() {
    currentUser.value = box.read('current_user') ?? '';
    currentUserPasswd.value = box.read('current_user_passwd') ?? '';
  }

  getCurrentBaseAuth() {
    return 'Basic ${base64Encode(utf8.encode('$currentUser:$currentUserPasswd'))}';
  }
}
