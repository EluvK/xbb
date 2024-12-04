import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:ota_update/ota_update.dart';
import 'package:xbb/utils/predefined.dart';
import 'package:xbb/utils/utils.dart';

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
  final currentUserPasswd = "".obs;
  final currentUserId = "".obs;
  final currentUserAvatarUrl = "".obs;

  final downloadProgress = 0.0.obs;

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
    currentUserPasswd.value = box.read('current_user_passwd') ?? '';
    currentUserId.value = box.read('current_user_id') ?? '';
    currentUserAvatarUrl.value =
        box.read('current_user_avatar_url') ?? defaultAvatarLink;
  }

  setThemeMode(ThemeMode theme) {
    print('setting theme: $theme');
    themeMode.value = theme;
    Get.changeThemeMode(themeMode.value);
    box.write('theme', themeMode.value.toString());
  }

  getCurrentBaseAuth() {
    return 'Basic ${base64Encode(utf8.encode('$currentUserId/$currentUserName:$currentUserPasswd'))}';
  }

  setServerAddress(String address) {
    serverAddress.value = address;
    box.write('server_address', address);
  }

  getServerAddress() {
    return serverAddress.value;
  }

  setUser(String id, {String? name, String? password, String? avatarUrl}) {
    currentUserId.value = id;
    box.write('current_user_id', currentUserId.value);
    if (name != null) {
      currentUserName.value = name;
      box.write('current_user_name', currentUserName.value);
    }
    if (password != null) {
      currentUserPasswd.value = password;
      box.write('current_user_passwd', currentUserPasswd.value);
    }
    if (avatarUrl != null) {
      currentUserAvatarUrl.value = avatarUrl;
      box.write('current_user_avatar_url', currentUserAvatarUrl.value);
    }
  }

  setCurrentRepo(String repo) {
    currentRepoId.value = repo;
    box.write('current_repo_id', repo);
  }

  downloadApk(String url) {
    try {
      OtaUpdate().execute(url, destinationFilename: "xbb.apk").listen((event) {
        print('event: $event');
        print('status: ${event.status}, value: ${event.value}');
        if (event.status == OtaStatus.DOWNLOADING) {
          downloadProgress.value = double.parse(event.value ?? '0') / 100;
        } else if (event.status == OtaStatus.DOWNLOAD_ERROR) {
          flushBar(FlushLevel.WARNING, 'Failed', event.value);
        } else if (event.status == OtaStatus.INSTALLING) {
          downloadProgress.value = 0.0;
          flushBar(FlushLevel.OK, 'Success', 'Download success');
        }
      });
    } catch (e) {
      print('Failed to make OTA update. Details: $e');
      flushBar(FlushLevel.WARNING, 'Failed', 'Failed to make OTA update $e');
    }
  }
}
