import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:xbb/data/repositories/clipboard_repository.dart';
import 'package:xbb/models/clipboard/model.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/uuid_service.dart';

/// 纯净的 Windows/macOS 托盘与剪贴板后台监听服务（ADR-0002 约束）
class ClipboardTrayService extends ChangeNotifier {
  static final ClipboardTrayService instance = ClipboardTrayService._();
  ClipboardTrayService._();

  static const MethodChannel _channel = MethodChannel('com.eluvk.xbb/clipboard_tray');

  bool _featureEnabled = true;
  bool _listeningEnabled = false;
  String? _lastCollectedTime;
  ClipboardRepository? _repository;
  String _currentUserId = 'default';

  bool get featureEnabled => _featureEnabled;
  bool get listeningEnabled => _listeningEnabled;
  bool get isListeningActive => _featureEnabled && _listeningEnabled;
  String? get lastCollectedTime => _lastCollectedTime;

  /// 配置关联的 Repository 与当前用户 ID
  void configure({ClipboardRepository? repository, String userId = 'default'}) {
    _repository = repository;
    _currentUserId = userId;
  }

  Future<void> init({bool featureEnabled = true, bool listeningEnabled = false}) async {
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
      await _channel.invokeMethod('setListeningEnabled', isListeningActive);
      final payload = <String, dynamic>{
        'listeningEnabled': isListeningActive,
      };
      if (_lastCollectedTime != null && _lastCollectedTime!.isNotEmpty) {
        payload['lastCollectedTime'] = _lastCollectedTime;
      }
      await _channel.invokeMethod('updateTrayStatus', payload);
    } on MissingPluginException {
      // 桌面平台在没有接入对应实现时静默忽略
    } on PlatformException catch (e) {
      debugPrint('Sync clipboard tray status failed: $e');
    }
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onClipboardTextChanged':
      case 'onClipboardDataCollected':
        final args = call.arguments;
        String? text;
        DateTime? time;
        if (args is Map) {
          text = args['text'] as String?;
          final rawTs = args['timestampMs'];
          if (rawTs is int) {
            time = DateTime.fromMillisecondsSinceEpoch(rawTs);
          } else if (rawTs is num) {
            time = DateTime.fromMillisecondsSinceEpoch(rawTs.toInt());
          } else if (args['time'] is String) {
            time = DateTime.tryParse(args['time'] as String);
          }
        }
        if (text != null && text.isNotEmpty) {
          await handleCollectedText(text, time ?? DateTime.now());
        }
        return true;
      case 'onTrayToggleListening':
        final args = call.arguments;
        bool enabled = !_listeningEnabled;
        if (args is Map && args['enabled'] is bool) {
          enabled = args['enabled'] as bool;
        } else if (args is bool) {
          enabled = args;
        }
        await setListeningEnabled(enabled);
        return true;
      case 'onTrayShowMainWindow':
        // 原生窗口处理，Dart 端确认收到
        return true;
      case 'onTrayExitApp':
      case 'onTrayMenuExit':
        await SystemNavigator.pop();
        return true;
      default:
        return null;
    }
  }

  /// 核心捕获入口（受 isListeningActive 开关控制，关闭后不再捕获）
  Future<bool> handleCollectedText(String text, [DateTime? time]) async {
    if (!isListeningActive) {
      // 开关关闭，直接忽略
      return false;
    }

    final dt = time ?? DateTime.now();
    bool inserted = false;

    if (_repository != null) {
      inserted = await _repository!.capture(text, _currentUserId);
    } else {
      // 本地兜底持久化（严禁入队 Outbox，严格遵守 ADR-0002 约束）
      try {
        final db = await LocalFirstDB.getDb(userId: _currentUserId);
        // 查重：避免连续重复录入相同文本
        final recent = await db.query(
          'clipboard_history_entry',
          orderBy: 'created_at DESC',
          limit: 1,
        );
        if (recent.isNotEmpty) {
          final lastBodyStr = recent.first['body'] as String? ?? '{}';
          try {
            final last = ClipboardHistoryEntry.fromJson(jsonDecode(lastBodyStr) as Map<String, dynamic>);
            if (last.data == text) return false;
          } catch (_) {}
        }

        final newId = UuidService.v7();
        final entry = ClipboardHistoryEntry(
          data: text,
          capturedAt: dt,
          localOnly: true,
        );
        await db.insert(
          'clipboard_history_entry',
          {
            'id': newId,
            'created_at': dt.toIso8601String(),
            'updated_at': dt.toIso8601String(),
            'owner': _currentUserId,
            'parent_id': null,
            'sync_status': 'local_only',
            'color_tag': 'default',
            'body': jsonEncode(entry.toJson()),
          },
        );
        inserted = true;
      } catch (e) {
        debugPrint('Fallback capture clipboard entry failed: $e');
        return false;
      }
    }

    if (!inserted) {
      return false;
    }

    _lastCollectedTime = dt.toLocal().toString().split('.').first;
    notifyListeners();
    await _syncNativeTrayStatus();
    return true;
  }
}
