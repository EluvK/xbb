import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

bool initFirstTime() {
  var settingController = Get.find<SettingController>();
  if (settingController.currentUser.isNotEmpty &&
      settingController.currentRepo.isNotEmpty) {
    print('already done first init before');
    return false;
  }
  print('first init');
  return true;
}

Future<void> initCacheSetting() async {}

class SettingController extends GetxController {
  final box = GetStorage('XbbGetStorage');

  // app settings
  final themeMode = ThemeMode.system.obs;

  // cache information
  final serverAddress = "https://".obs;
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

  getCacheSetting() {
    serverAddress.value = box.read('server_address') ?? '';
    currentUser.value = box.read('current_user') ?? '';
    currentUserPasswd.value = box.read('current_user_passwd') ?? '';
  }

  setThemeMode(ThemeMode theme) {
    print('setting theme: $theme');
    themeMode.value = theme;
    Get.changeThemeMode(themeMode.value);
    box.write('theme', themeMode.value.toString());
  }

  getCurrentBaseAuth() {
    return 'Basic ${base64Encode(utf8.encode('$currentUser:$currentUserPasswd'))}';
  }

  setServerAddress(String address) {
    serverAddress.value = address;
    box.write('server_address', address);
  }

  getServerAddress() {
    return serverAddress.value;
  }

  setUserInfo(String name, String password) {
    currentUser.value = name;
    currentUserPasswd.value = password;
    box.write('current_user', currentUser.value);
    box.write('current_user_passwd', currentUserPasswd.value);
  }
}
