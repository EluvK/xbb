import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/setting.dart';

const String taskHomeTabId = 'task';

class AppLaunchController extends GetxController with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel('com.eluvk.xbb/launch');

  final RxnString pendingHomeTab = RxnString();
  bool _initialized = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    await _consumeLaunchTab();
    _initialized = true;
  }

  Future<void> ensureInitialization() async {
    while (!_initialized) {
      await onInit();
    }
  }

  String? takePendingHomeTab() {
    final pending = pendingHomeTab.value;
    pendingHomeTab.value = null;
    return pending;
  }

  void clearPendingHomeTab() {
    pendingHomeTab.value = null;
  }

  Future<void> _consumeLaunchTab() async {
    final String? launchTab = await _channel.invokeMethod<String>(
      'consumeLaunchTab',
    );
    if (launchTab == null || launchTab.isEmpty) return;

    pendingHomeTab.value = launchTab;

    final settingController = Get.find<SettingController>();
    final loggedIn =
        settingController.userId.isNotEmpty &&
        settingController.userName.isNotEmpty;
    if (loggedIn && Get.currentRoute.isNotEmpty && Get.currentRoute != '/') {
      Get.offAllNamed('/');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_consumeLaunchTab());
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
