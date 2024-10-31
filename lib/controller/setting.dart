import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

bool initFirstTime() {
  var settingController = Get.find<SettingController>();
  if (settingController.currentUserName.isNotEmpty &&
      settingController.currentUserPasswd.isNotEmpty) {
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
  final serverAddress = "".obs;
  final currentRepoId = "".obs;
  final currentUserName = "".obs;
  final currentUserId = "".obs;
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
    serverAddress.value = box.read('server_address') ?? 'https://';
    currentRepoId.value = box.read('current_repo_id') ?? '0';
    currentUserName.value = box.read('current_user_name') ?? '';
    currentUserId.value = box.read('current_user_id') ?? '';
    currentUserPasswd.value = box.read('current_user_passwd') ?? '';
  }

  setThemeMode(ThemeMode theme) {
    print('setting theme: $theme');
    themeMode.value = theme;
    Get.changeThemeMode(themeMode.value);
    box.write('theme', themeMode.value.toString());
  }

  getCurrentBaseAuth() {
    return 'Basic ${base64Encode(utf8.encode('$currentUserName:$currentUserPasswd'))}';
  }

  setServerAddress(String address) {
    serverAddress.value = address;
    box.write('server_address', address);
  }

  getServerAddress() {
    return serverAddress.value;
  }

  setUserLoginInfo(String name, String password) {
    currentUserName.value = name;
    currentUserPasswd.value = password;
    box.write('current_user_name', currentUserName.value);
    box.write('current_user_passwd', currentUserPasswd.value);
  }

  setUserId(String id) {
    currentUserId.value = id;
    box.write('current_user_id', currentUserId.value);
  }

  setCurrentRepo(String repo) {
    currentRepoId.value = repo;
    box.write('current_repo_id', repo);
  }
}
