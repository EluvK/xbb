import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:xbb/models/checkin/model.dart';
import 'package:xbb/sync/v2/local_first_db.dart';

const String checkinWidgetStateReady = 'ready';
const String checkinWidgetStateEmpty = 'empty';
const String checkinWidgetStateRequiresLogin = 'requires_login';

class CheckinWidgetSnapshotItem {
  const CheckinWidgetSnapshotItem({
    required this.id,
    required this.eventName,
    required this.eventColor,
    required this.isChecked,
    required this.checkinTime,
  });

  final String id;
  final String eventName;
  final int eventColor;
  final bool isChecked;
  final String checkinTime;

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_name': eventName,
    'event_color': eventColor,
    'is_checked': isChecked,
    'checkin_time': checkinTime,
  };
}

class CheckinWidgetSnapshot {
  const CheckinWidgetSnapshot({
    required this.state,
    required this.eventCount,
    required this.checkedCount,
    required this.items,
    required this.generatedAt,
  });

  factory CheckinWidgetSnapshot.requiresLogin() {
    return CheckinWidgetSnapshot(
      state: checkinWidgetStateRequiresLogin,
      eventCount: 0,
      checkedCount: 0,
      items: const <CheckinWidgetSnapshotItem>[],
      generatedAt: DateTime.now().toUtc(),
    );
  }

  factory CheckinWidgetSnapshot.empty() {
    return CheckinWidgetSnapshot(
      state: checkinWidgetStateEmpty,
      eventCount: 0,
      checkedCount: 0,
      items: const <CheckinWidgetSnapshotItem>[],
      generatedAt: DateTime.now().toUtc(),
    );
  }

  final String state;
  final int eventCount;
  final int checkedCount;
  final List<CheckinWidgetSnapshotItem> items;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() => {
    'state': state,
    'event_count': eventCount,
    'checked_count': checkedCount,
    'generated_at': generatedAt.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };
}

class CheckinWidgetBridge {
  static const MethodChannel _channel = MethodChannel('com.eluvk.xbb/checkin_widget');
  static Timer? _refreshTimer;

  static void scheduleRefresh({Duration delay = const Duration(milliseconds: 150)}) {
    if (!_isSupportedPlatform) return;
    _refreshTimer?.cancel();
    _refreshTimer = Timer(delay, () {
      unawaited(refreshFromLocalState());
    });
  }

  static void scheduleLoggedOutState({Duration delay = Duration.zero}) {
    if (!_isSupportedPlatform) return;
    _refreshTimer?.cancel();
    _refreshTimer = Timer(delay, () {
      unawaited(_publishSnapshot(CheckinWidgetSnapshot.requiresLogin()));
    });
  }

  static Future<void> refreshFromLocalState() async {
    if (!_isSupportedPlatform) return;
    await _publishSnapshot(await _buildSnapshot());
  }

  static Future<void> _publishSnapshot(CheckinWidgetSnapshot snapshot) async {
    await _channel.invokeMethod<void>('updateSnapshot', {'snapshot': jsonEncode(snapshot.toJson())});
  }

  static String _formatDayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _fmtTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static Future<CheckinWidgetSnapshot> _buildSnapshot() async {
    try {
      final db = await LocalFirstDB.getDb(userId: 'default');
      final eventRows = await db.query('checkin_event', orderBy: 'created_at ASC');
      if (eventRows.isEmpty) {
        return CheckinWidgetSnapshot.empty();
      }

      final todayKey = _formatDayKey(DateTime.now());
      final recordRows = await db.query('checkin_record', orderBy: 'created_at DESC');
      final todayRecords = <CheckinRecord>[];
      for (final r in recordRows) {
        final bodyStr = r['body'] as String? ?? '{}';
        final rec = CheckinRecord.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        if (rec.localDayKey == todayKey) {
          todayRecords.add(rec);
        }
      }

      final items = <CheckinWidgetSnapshotItem>[];
      for (final r in eventRows) {
        final bodyStr = r['body'] as String? ?? '{}';
        final ev = CheckinEvent.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        final id = r['id'] as String;
        CheckinRecord? matched;
        for (final rec in todayRecords) {
          if (rec.eventId == id) {
            matched = rec;
            break;
          }
        }
        final isChecked = matched != null;
        items.add(CheckinWidgetSnapshotItem(
          id: id,
          eventName: ev.name,
          eventColor: ev.colorValue,
          isChecked: isChecked,
          checkinTime: isChecked ? _fmtTime(matched.createdAtUtc) : '',
        ));
      }

      final checkedCount = items.where((i) => i.isChecked).length;
      return CheckinWidgetSnapshot(
        state: checkinWidgetStateReady,
        eventCount: items.length,
        checkedCount: checkedCount,
        items: items,
        generatedAt: DateTime.now().toUtc(),
      );
    } catch (_) {
      return CheckinWidgetSnapshot.empty();
    }
  }

  static bool get _isSupportedPlatform => !kIsWeb && Platform.isAndroid;
}
