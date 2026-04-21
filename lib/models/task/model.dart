import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sync_annotation/sync_annotation.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/syncstore.dart';
import 'package:xbb/models/task/db.dart';
import 'package:xbb/utils/utils.dart';

part 'model.g.dart';
part 'model.freezed.dart';

Future<void> reInitTaskSync(SyncStoreClient client) async {
  await reInit<CheckListController>(() => CheckListController(client), (c) => c.ensureInitialization());
  final SettingController settingController = Get.find<SettingController>();
  if (settingController.taskEnabled) {
    onReadySyncTask();
  }
}

Future<void> onReadySyncTask() async {
  final checkListController = Get.find<CheckListController>();
  final SyncStoreClient ssClient = Get.find<SyncStoreControl>().syncStoreClient;
  final latency = await ssClient.pingLatencyMs();
  if (latency < 0) {
    print('SyncStore health check failed, skipping task initial sync.');
    flushBar(FlushLevel.WARNING, "同步服务异常", "无法连接到同步服务，Task 同步已跳过");
    return;
  }

  try {
    await runSyncTaskWithStatus(
      [() => checkListController.syncAll(batchSize: 100), () => checkListController.rebuildLocal()],
      from: 0.0,
      to: 100.0,
    );
    successSimpleFlushBar("Task 同步完成");
  } catch (e) {
    print('Error during task initial sync: $e');
    flushBar(FlushLevel.WARNING, "同步错误", "Task 初始同步过程中发生错误: $e");
  }
}

Future<void> reInit<T extends GetxController>(
  FutureOr<T> Function() creator,
  FutureOr<void> Function(T controller)? initializer,
) async {
  if (Get.isRegistered<T>()) {
    await Get.delete<T>(force: true);
  }
  final controller = await Get.putAsync<T>(() async {
    return await creator();
  }, permanent: true);
  if (initializer != null) {
    await initializer(controller);
  }
}

@Repository(collectionName: 'task', tableName: 'check_list', db: TaskDB)
@freezed
abstract class CheckList with _$CheckList {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CheckList({required String tasks, required bool archived, DateTime? archivedAt}) = _CheckList;

  factory CheckList.fromJson(Map<String, dynamic> json) => _$CheckListFromJson(json);
}

@freezed
abstract class TaskItem with _$TaskItem {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TaskItem({
    required String id,
    required String content,
    required bool done,
    DateTime? doneAt,
    required DateTime lastModifiedAt,
  }) = _TaskItem;

  factory TaskItem.fromJson(Map<String, dynamic> json) => _$TaskItemFromJson(json);
}

List<TaskItem> decodeTaskItems(String tasksPayload) {
  if (tasksPayload.trim().isEmpty) return <TaskItem>[];

  try {
    final dynamic decoded = jsonDecode(tasksPayload);
    if (decoded is! List) return <TaskItem>[];

    return decoded.map((item) => TaskItem.fromJson(Map<String, dynamic>.from(item as Map))).toList(growable: false);
  } catch (_) {
    return <TaskItem>[];
  }
}

String encodeTaskItems(List<TaskItem> tasks) {
  return jsonEncode(tasks.map((task) => task.toJson()).toList(growable: false));
}

List<TaskItem> sortTaskItems(List<TaskItem> tasks) {
  final copied = List<TaskItem>.of(tasks);
  copied.sort((a, b) {
    if (a.done != b.done) {
      return a.done ? -1 : 1;
    }

    if (!a.done) {
      return a.lastModifiedAt.compareTo(b.lastModifiedAt);
    }

    final doneAtCompare = a.doneAt!.compareTo(b.doneAt!);
    if (doneAtCompare != 0) return doneAtCompare;
    return a.lastModifiedAt.compareTo(b.lastModifiedAt);
  });
  return copied;
}

bool isCheckListStateValid(CheckList checkList) {
  if (checkList.archived && checkList.archivedAt == null) return false;
  if (!checkList.archived && checkList.archivedAt != null) return false;
  return true;
}

bool isTaskItemStateValid(TaskItem taskItem) {
  if (taskItem.done && taskItem.doneAt == null) return false;
  if (!taskItem.done && taskItem.doneAt != null) return false;
  return true;
}
