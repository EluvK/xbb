import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/setting.dart';

class ClipboardTrayController extends GetxController {
  static const MethodChannel _channel = MethodChannel('com.eluvk.xbb/clipboard_tray');

  final RxBool featureEnabled = false.obs;
  final RxBool listeningEnabled = false.obs;

  bool _initialized = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    final settingController = Get.find<SettingController>();
    featureEnabled.value = settingController.clipboardBackupEnabled;
    listeningEnabled.value = settingController.clipboardListeningEnabled;

    _channel.setMethodCallHandler(_onMethodCall);
    await _syncNativeTrayStatus();
    _initialized = true;
  }

  Future<void> ensureInitialization() async {
    while (!_initialized) {
      await onInit();
    }
  }

  Future<void> setFeatureEnabled(bool enabled) async {
    featureEnabled.value = enabled;
    if (!enabled) {
      listeningEnabled.value = false;
    }

    final settingController = Get.find<SettingController>();
    settingController.updateAppFeaturesManagement(
      enableClipboardBackup: enabled,
      enableClipboardListening: listeningEnabled.value,
    );

    await _syncNativeTrayStatus();
  }

  Future<void> setListeningEnabled(bool enabled) async {
    if (!featureEnabled.value && enabled) {
      featureEnabled.value = true;
    }
    listeningEnabled.value = featureEnabled.value && enabled;

    final settingController = Get.find<SettingController>();
    settingController.updateAppFeaturesManagement(
      enableClipboardBackup: featureEnabled.value,
      enableClipboardListening: listeningEnabled.value,
    );

    await _syncNativeTrayStatus();
  }

  Future<void> _syncNativeTrayStatus() async {
    try {
      await _channel.invokeMethod('setListeningEnabled', featureEnabled.value && listeningEnabled.value);
      await _channel.invokeMethod('updateTrayStatus', {
        'listeningEnabled': featureEnabled.value && listeningEnabled.value,
      });
    } on MissingPluginException {
      // Platform implementation unavailable on non-Windows targets.
    } on PlatformException catch (e) {
      print('[ClipboardTray] sync status failed: $e');
    } catch (e) {
      print('[ClipboardTray] unexpected sync error: $e');
    }
  }

  Future<void> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onTrayToggleListening':
        final args = call.arguments;
        bool enabled = false;
        if (args is Map) {
          final value = args['enabled'];
          if (value is bool) {
            enabled = value;
          }
        }
        await setListeningEnabled(enabled);
        return;
      case 'onTrayShowMainWindow':
        return;
      case 'onTrayExitApp':
        return;
      default:
        return;
    }
  }
}
