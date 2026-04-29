import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/models/task/model.dart';

const String taskWidgetStateReady = 'ready';
const String taskWidgetStateEmpty = 'empty';
const String taskWidgetStateRequiresLogin = 'requires_login';

class TaskWidgetSnapshotItem {
  const TaskWidgetSnapshotItem({required this.id, required this.content});

  final String id;
  final String content;

  Map<String, dynamic> toJson() => {'id': id, 'content': content};
}

class TaskWidgetSnapshot {
  const TaskWidgetSnapshot({
    required this.state,
    required this.totalCount,
    required this.unfinishedCount,
    required this.items,
    required this.generatedAt,
  });

  factory TaskWidgetSnapshot.requiresLogin() {
    return TaskWidgetSnapshot(
      state: taskWidgetStateRequiresLogin,
      totalCount: 0,
      unfinishedCount: 0,
      items: const <TaskWidgetSnapshotItem>[],
      generatedAt: DateTime.now().toUtc(),
    );
  }

  factory TaskWidgetSnapshot.empty({required int totalCount}) {
    return TaskWidgetSnapshot(
      state: taskWidgetStateEmpty,
      totalCount: totalCount,
      unfinishedCount: 0,
      items: const <TaskWidgetSnapshotItem>[],
      generatedAt: DateTime.now().toUtc(),
    );
  }

  final String state;
  final int totalCount;
  final int unfinishedCount;
  final List<TaskWidgetSnapshotItem> items;
  final DateTime generatedAt;

  Map<String, dynamic> toJson() => {
    'state': state,
    'total_count': totalCount,
    'unfinished_count': unfinishedCount,
    'generated_at': generatedAt.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };
}

class TaskWidgetBridge {
  static const MethodChannel _channel = MethodChannel('com.eluvk.xbb/task_widget');
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
      unawaited(_publishSnapshot(TaskWidgetSnapshot.requiresLogin()));
    });
  }

  static Future<void> refreshFromLocalState() async {
    if (!_isSupportedPlatform) return;
    await _publishSnapshot(await _buildSnapshot());
  }

  static Future<void> _publishSnapshot(TaskWidgetSnapshot snapshot) async {
    await _channel.invokeMethod<void>('updateSnapshot', {'snapshot': jsonEncode(snapshot.toJson())});
  }

  /// 返回 true 表示系统支持并已弹出添加对话框，false 表示不支持（需引导用户手动添加）
  static Future<bool> requestPinWidget() async {
    if (!_isSupportedPlatform) return false;
    return await _channel.invokeMethod<bool>('requestPinWidget') ?? false;
  }

  static Future<TaskWidgetSnapshot> _buildSnapshot() async {
    final SettingController settingController = Get.find<SettingController>();
    if (settingController.userId.isEmpty) {
      return TaskWidgetSnapshot.requiresLogin();
    }

    final items = await _loadCheckLists();
    final activeCandidates = items.where((item) => item.body.archived == false).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (activeCandidates.isEmpty) {
      return TaskWidgetSnapshot.empty(totalCount: 0);
    }

    final activeCheckList = activeCandidates.first.body;
    final tasks = sortTaskItems(decodeTaskItems(activeCheckList.tasks));
    final unfinished = tasks
        .where((task) => task.done == false && task.content.trim().isNotEmpty)
        .toList(growable: false);
    if (unfinished.isEmpty) {
      return TaskWidgetSnapshot.empty(totalCount: tasks.length);
    }

    return TaskWidgetSnapshot(
      state: taskWidgetStateReady,
      totalCount: tasks.length,
      unfinishedCount: unfinished.length,
      generatedAt: DateTime.now().toUtc(),
      items: unfinished.map((task) => TaskWidgetSnapshotItem(id: task.id, content: task.content.trim())).toList(),
    );
  }

  static Future<List<CheckListDataItem>> _loadCheckLists() async {
    if (Get.isRegistered<CheckListController>()) {
      final controller = Get.find<CheckListController>();
      await controller.ensureInitialization();
      return controller.getCheckListDetails(selector: (item) => item);
    }
    return CheckListRepository().listFromLocalDb();
  }

  static bool get _isSupportedPlatform => !kIsWeb && Platform.isAndroid;
}
