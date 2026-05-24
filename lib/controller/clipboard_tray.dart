import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart' show DataItem;
import 'package:uuid/uuid.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/models/clipboard/model.dart';
import 'package:xbb/utils/utils.dart';

class ClipboardTrayController extends GetxController {
  static const MethodChannel _channel = MethodChannel('com.eluvk.xbb/clipboard_tray');
  static const Duration _dedupWindow = Duration(seconds: 30);
  static const int _dedupRecentCount = 8;

  final RxBool featureEnabled = false.obs;
  final RxBool listeningEnabled = false.obs;
  final RxnString lastCollectedTime = RxnString();

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
      final payload = <String, dynamic>{'listeningEnabled': featureEnabled.value && listeningEnabled.value};
      final ts = lastCollectedTime.value;
      if (ts != null && ts.isNotEmpty) {
        payload['lastCollectedTime'] = ts;
      }
      await _channel.invokeMethod('updateTrayStatus', payload);
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
      case 'onClipboardTextChanged':
        await _onClipboardTextChanged(call.arguments);
        return;
      default:
        return;
    }
  }

  Future<void> _onClipboardTextChanged(dynamic args) async {
    if (!featureEnabled.value || !listeningEnabled.value) {
      return;
    }

    String? text;
    int? timestampMs;
    if (args is Map) {
      final rawText = args['text'];
      if (rawText is String) {
        text = rawText;
      }
      final rawTs = args['timestampMs'];
      if (rawTs is int) {
        timestampMs = rawTs;
      } else if (rawTs is num) {
        timestampMs = rawTs.toInt();
      }
    }
    if (text == null || text.isEmpty) {
      return;
    }

    final dt = timestampMs != null
        ? DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true)
        : DateTime.now().toUtc();

    final shouldSkip = await _shouldSkipDuplicate(text, dt);
    if (shouldSkip) {
      return;
    }

    final owner = Get.find<SettingController>().userId;
    final entry = ClipboardHistoryEntry(data: text, localOnly: true);
    final id = const Uuid().v4();
    final item = DataItem<ClipboardHistoryEntry>(id, dt, dt, owner, null, null, body: entry);

    await ClipboardHistoryEntryRepository().addToLocalDb(item);
    if (Get.isRegistered<ClipboardHistoryEntryController>()) {
      await Get.find<ClipboardHistoryEntryController>().rebuildLocal();
    }
    lastCollectedTime.value = detailedDateStr(dt);
    await _syncNativeTrayStatus();
  }

  Future<bool> _shouldSkipDuplicate(String incoming, DateTime incomingAtUtc) async {
    List<ClipboardHistoryEntryDataItem> items;
    if (Get.isRegistered<ClipboardHistoryEntryController>()) {
      final controller = Get.find<ClipboardHistoryEntryController>();
      items = controller.getClipboardHistoryEntryDetails(selector: (item) => item);
    } else {
      items = await ClipboardHistoryEntryRepository().listFromLocalDb();
    }

    if (items.isEmpty) {
      return false;
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final latest = items.first;
    if (latest.body.data == incoming) {
      return true;
    }

    final recent = items.take(_dedupRecentCount);
    for (final item in recent) {
      if (item.body.data != incoming) {
        continue;
      }
      final delta = incomingAtUtc.difference(item.createdAt).abs();
      if (delta <= _dedupWindow) {
        return true;
      }
    }
    return false;
  }
}
