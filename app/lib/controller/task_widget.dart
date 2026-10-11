import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:xbb/models/task/model.dart';
import 'package:xbb/sync/v2/local_first_db.dart';

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

  static Future<void> refreshFromLocalState({Database? currentDb}) async {
    if (!_isSupportedPlatform) return;
    await _publishSnapshot(await _buildSnapshot(currentDb: currentDb));
  }

  static Future<void> _publishSnapshot(TaskWidgetSnapshot snapshot) async {
    await _channel.invokeMethod<void>('updateSnapshot', {'snapshot': jsonEncode(snapshot.toJson())});
  }

  static Future<bool> requestPinWidget() async {
    if (!_isSupportedPlatform) return false;
    return await _channel.invokeMethod<bool>('requestPinWidget') ?? false;
  }

  static TaskWidgetSnapshot buildSnapshotFromTasks(List<TaskItem> tasks) {
    final sorted = sortTaskItems(tasks);
    final unfinished = sorted.where((t) => !t.done && t.content.trim().isNotEmpty).toList();
    if (unfinished.isEmpty) {
      return TaskWidgetSnapshot.empty(totalCount: sorted.length);
    }
    return TaskWidgetSnapshot(
      state: taskWidgetStateReady,
      totalCount: sorted.length,
      unfinishedCount: unfinished.length,
      generatedAt: DateTime.now().toUtc(),
      items: unfinished.map((t) => TaskWidgetSnapshotItem(id: t.id, content: t.content.trim())).toList(),
    );
  }

  static Future<TaskWidgetSnapshot> _buildSnapshot({Database? currentDb}) async {
    try {
      final db = currentDb ?? await LocalFirstDB.getDb(userId: 'default');
      final rows = await db.query('check_list', orderBy: 'created_at DESC');
      CheckList? activeCheckList;
      for (final r in rows) {
        final bodyStr = r['body'] as String? ?? '{}';
        final checkList = CheckList.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        if (!checkList.archived) {
          activeCheckList = checkList;
          break;
        }
      }

      if (activeCheckList == null) {
        return TaskWidgetSnapshot.empty(totalCount: 0);
      }

      final tasks = decodeTaskItems(activeCheckList.tasks);
      return buildSnapshotFromTasks(tasks);
    } catch (_) {
      return TaskWidgetSnapshot.empty(totalCount: 0);
    }
  }

  static bool get _isSupportedPlatform => !kIsWeb && Platform.isAndroid;
}
