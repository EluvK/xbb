import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sync_annotation/sync_annotation.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/task/db.dart';

part 'model.g.dart';
part 'model.freezed.dart';

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
    @Default(0) int sortOrder,
  }) = _TaskItem;

  factory TaskItem.fromJson(Map<String, dynamic> json) => _$TaskItemFromJson(json);
}

List<TaskItem> decodeTaskItems(String tasksPayload) {
  if (tasksPayload.trim().isEmpty) return <TaskItem>[];

  try {
    final dynamic decoded = jsonDecode(tasksPayload);
    if (decoded is! List) return <TaskItem>[];

    final items = <TaskItem>[];
    for (var i = 0; i < decoded.length; i++) {
      final rawMap = Map<String, dynamic>.from(decoded[i] as Map);
      final hasSortOrder = rawMap.containsKey('sort_order') || rawMap.containsKey('sortOrder');
      final parsed = TaskItem.fromJson(rawMap);
      items.add(hasSortOrder ? parsed : parsed.copyWith(sortOrder: i));
    }
    return items;
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
    final orderCompare = a.sortOrder.compareTo(b.sortOrder);
    if (orderCompare != 0) return orderCompare;
    return a.lastModifiedAt.compareTo(b.lastModifiedAt);
  });
  return copied;
}

bool isCheckListStateValid(CheckList checkList) {
  if (checkList.archived && checkList.archivedAt == null) return false;
  if (!checkList.archived && checkList.archivedAt != null) return false;
  return true;
}
