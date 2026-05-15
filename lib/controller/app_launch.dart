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
    String? launchTab;
    try {
      launchTab = await _channel.invokeMethod<String>('consumeLaunchTab');
    } on MissingPluginException catch (_) {
      // Platform implementation not available (e.g. running on non-Android),
      // treat as no launch tab and return early.
      return;
    } on PlatformException catch (e) {
      // If platform call failed for any reason, log and return early.
      print('[AppLaunch] consumeLaunchTab failed: $e');
      return;
    } catch (e) {
      // Catch-all to prevent initialization from throwing.
      print('[AppLaunch] consumeLaunchTab unexpected error: $e');
      return;
    }
    if (launchTab == null || launchTab.isEmpty) return;

    pendingHomeTab.value = launchTab;

    final settingController = Get.find<SettingController>();
    final loggedIn = settingController.userId.isNotEmpty && settingController.userName.isNotEmpty;
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
