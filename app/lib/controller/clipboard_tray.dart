import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:syncstore_client/syncstore_client.dart' show DataItem, SyncStatus;
import 'package:uuid/uuid.dart';
import 'package:xbb/models/clipboard/model.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/outbox_item.dart';
import 'package:xbb/utils/utils.dart';

/// 纯净的 Windows 托盘与剪贴板后台监听服务（ADR-0002 约束）
class ClipboardTrayService extends ChangeNotifier {
  static final ClipboardTrayService instance = ClipboardTrayService._();
  ClipboardTrayService._();

  static const MethodChannel _channel = MethodChannel('com.eluvk.xbb/clipboard_tray');
  static const Duration _dedupWindow = Duration(seconds: 30);
  static const int _dedupRecentCount = 8;

  bool _featureEnabled = false;
  bool _listeningEnabled = false;
  String? _lastCollectedTime;

  bool get featureEnabled => _featureEnabled;
  bool get listeningEnabled => _listeningEnabled;
  String? get lastCollectedTime => _lastCollectedTime;

  Future<void> init({bool featureEnabled = true, bool listeningEnabled = true}) async {
    _featureEnabled = featureEnabled;
    _listeningEnabled = listeningEnabled;
    _channel.setMethodCallHandler(_onMethodCall);
    await _syncNativeTrayStatus();
  }

  Future<void> setFeatureEnabled(bool enabled) async {
    _featureEnabled = enabled;
    if (!enabled) {
      _listeningEnabled = false;
    }
    notifyListeners();
    await _syncNativeTrayStatus();
  }

  Future<void> setListeningEnabled(bool enabled) async {
    if (!_featureEnabled && enabled) {
      _featureEnabled = true;
    }
    _listeningEnabled = _featureEnabled && enabled;
    notifyListeners();
    await _syncNativeTrayStatus();
  }

  Future<void> _syncNativeTrayStatus() async {
    try {
      await _channel.invokeMethod('setListeningEnabled', _featureEnabled && _listeningEnabled);
      final payload = <String, dynamic>{
        'listeningEnabled': _featureEnabled && _listeningEnabled,
      };
      if (_lastCollectedTime != null && _lastCollectedTime!.isNotEmpty) {
        payload['lastCollectedTime'] = _lastCollectedTime;
      }
      await _channel.invokeMethod('updateTrayStatus', payload);
    } on MissingPluginException {
      // 非 Windows 平台静默忽略
    } on PlatformException catch (e) {
      debugPrint('Sync clipboard tray status failed: $e');
    }
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onClipboardDataCollected':
        final text = call.arguments['text'] as String?;
        final timeStr = call.arguments['time'] as String?;
        if (text != null && text.isNotEmpty) {
          DateTime time = DateTime.now();
          if (timeStr != null && timeStr.isNotEmpty) {
            time = DateTime.tryParse(timeStr) ?? DateTime.now();
          }
          await _onNewTextCollected(text, time);
        }
        return true;
      case 'onTrayMenuExit':
        await SystemNavigator.pop();
        return true;
      default:
        return null;
    }
  }

  Future<void> _onNewTextCollected(String text, DateTime dt) async {
    final entry = ClipboardHistoryEntry(data: text, capturedAt: dt, localOnly: true);
    final id = const Uuid().v4();
    final item = DataItem<ClipboardHistoryEntry>(
      id,
      dt,
      dt,
      'default',
      null,
      null,
      body: entry,
      syncStatus: SyncStatus.hidden,
    );

    try {
      final db = await LocalFirstDB.getDb(userId: 'default');
      await LocalFirstDB.saveEntityWithOutbox(
        db: db,
        tableName: 'clipboard_history_entry',
        entityRow: {
          'id': id,
          'created_at': dt.toIso8601String(),
          'updated_at': dt.toIso8601String(),
          'owner': 'default',
          'parent_id': null,
          'sync_status': 'hidden',
          'color_tag': 'none',
          'body': entry.toJson().toString(),
        },
        outboxItem: OutboxItem.put(
          id: id,
          tableName: 'clipboard_history_entry',
          entityId: id,
          data: entry.toJson().toString(),
          baseVersion: 1,
          createdAt: dt.millisecondsSinceEpoch,
        ),
      );
    } catch (_) {}

    _lastCollectedTime = detailedDateStr(dt);
    notifyListeners();
    await _syncNativeTrayStatus();
  }
}
