import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/models/checkin/model.dart';

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

  static Future<bool> requestPinWidget() async {
    if (!_isSupportedPlatform) return false;
    return await _channel.invokeMethod<bool>('requestPinWidget') ?? false;
  }

  static String _formatDayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String _fmtTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static Future<CheckinWidgetSnapshot> _buildSnapshot() async {
    final SettingController settingController = Get.find<SettingController>();
    if (settingController.userId.isEmpty) {
      return CheckinWidgetSnapshot.requiresLogin();
    }

    final events = await CheckinEventRepository().listFromLocalDb();
    if (events.isEmpty) {
      return CheckinWidgetSnapshot.empty();
    }

    final todayKey = _formatDayKey(DateTime.now());
    final records = await CheckinRecordRepository().listFromLocalDb();
    final todayRecords = records.where((r) => r.body.localDayKey == todayKey).toList();

    final items = events.map((event) {
      final record = todayRecords.firstWhereOrNull(
        (r) => r.body.eventId == event.id,
      );
      final isChecked = record != null;
      return CheckinWidgetSnapshotItem(
        id: event.id,
        eventName: event.body.name,
        eventColor: event.body.colorValue,
        isChecked: isChecked,
        checkinTime: isChecked ? _fmtTime(record.body.createdAtUtc) : '',
      );
    }).toList()
      ..sort((a, b) {
        if (a.isChecked != b.isChecked) return a.isChecked ? 1 : -1;
        return a.eventName.compareTo(b.eventName);
      });

    final checkedCount = items.where((item) => item.isChecked).length;

    return CheckinWidgetSnapshot(
      state: checkinWidgetStateReady,
      eventCount: items.length,
      checkedCount: checkedCount,
      generatedAt: DateTime.now().toUtc(),
      items: items,
    );
  }

  static bool get _isSupportedPlatform => !kIsWeb && Platform.isAndroid;
}
