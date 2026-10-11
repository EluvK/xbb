import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/controller/task_widget.dart';
import 'package:xbb/data/base_repository.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/models/task/model.dart';
import 'package:xbb/sync/v2/uuid_service.dart';

class TaskRepository extends BaseLocalFirstRepository<DataItem<CheckList>> {
  TaskRepository({
    required super.db,
    required super.changeNotifier,
  }) : super(tableName: 'check_list');

  @override
  String getId(DataItem<CheckList> entity) => entity.id;

  @override
  String getOwner(DataItem<CheckList> entity) => entity.owner;

  @override
  String serialize(DataItem<CheckList> entity) {
    return jsonEncode(entity.body.toJson());
  }

  @override
  DataItem<CheckList> deserialize(Map<String, dynamic> json) {
    final body = CheckList.fromJson(json);
    return DataItem<CheckList>(
      id: '',
      owner: '',
      body: body,
      syncStatus: SyncStatus.synced,
    );
  }

  /// 监听当前活动的 CheckList
  Stream<DataItem<CheckList>?> watchActiveCheckList() {
    return changeNotifier.watchTable(tableName).asyncMap((_) async {
      final rows = await db.query(
        tableName,
        orderBy: 'created_at DESC',
      );
      for (final r in rows) {
        final bodyStr = r['body'] as String? ?? '{}';
        try {
          final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
          final checkList = CheckList.fromJson(bodyJson);
          if (!checkList.archived) {
            return DataItem<CheckList>(
              id: r['id'] as String,
              owner: r['owner'] as String? ?? 'default',
              body: checkList,
              createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now(),
              syncStatus: SyncStatus.synced,
            );
          }
        } catch (_) {}
      }
      return null;
    });
  }

  /// 监听所有已归档的 CheckList
  Stream<List<DataItem<CheckList>>> watchArchivedCheckLists() {
    return changeNotifier.watchTable(tableName).asyncMap((_) async {
      final rows = await db.query(
        tableName,
        orderBy: 'created_at DESC',
      );
      final list = <DataItem<CheckList>>[];
      for (final r in rows) {
        final bodyStr = r['body'] as String? ?? '{}';
        try {
          final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
          final checkList = CheckList.fromJson(bodyJson);
          if (checkList.archived) {
            list.add(DataItem<CheckList>(
              id: r['id'] as String,
              owner: r['owner'] as String? ?? 'default',
              body: checkList,
              createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now(),
              syncStatus: SyncStatus.synced,
            ));
          }
        } catch (_) {}
      }
      return list;
    });
  }

  /// 获取或新建活动 CheckList
  Future<DataItem<CheckList>> getOrCreateActiveCheckList(String currentUserId) async {
    final rows = await db.query(tableName, orderBy: 'created_at DESC');
    for (final r in rows) {
      final bodyStr = r['body'] as String? ?? '{}';
      try {
        final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
        final checkList = CheckList.fromJson(bodyJson);
        if (!checkList.archived) {
          return DataItem<CheckList>(
            id: r['id'] as String,
            owner: r['owner'] as String? ?? currentUserId,
            body: checkList,
            syncStatus: SyncStatus.synced,
          );
        }
      } catch (_) {}
    }

    // 创建新的活动 CheckList
    final newId = UuidService.v7();
    final newCheckList = CheckList(tasks: '[]', archived: false);
    final newItem = DataItem<CheckList>(
      id: newId,
      owner: currentUserId,
      body: newCheckList,
      syncStatus: SyncStatus.pending,
    );
    await save(newItem);
    return newItem;
  }

  /// 添加任务项
  Future<void> addTask(String content, String currentUserId) async {
    if (content.trim().isEmpty) return;
    final active = await getOrCreateActiveCheckList(currentUserId);
    final items = decodeTaskItems(active.body.tasks);
    final newItem = TaskItem(
      id: UuidService.v7(),
      content: content.trim(),
      done: false,
      lastModifiedAt: DateTime.now(),
      sortOrder: items.length,
    );
    final updatedList = List<TaskItem>.from(items)..add(newItem);
    final updatedCheckList = active.body.copyWith(tasks: encodeTaskItems(updatedList));
    await save(active.copyWith(body: updatedCheckList));
    await TaskWidgetBridge.refreshFromLocalState();
  }

  /// 切换任务完成状态
  Future<void> toggleTaskDone(String taskId, String currentUserId) async {
    final active = await getOrCreateActiveCheckList(currentUserId);
    final items = decodeTaskItems(active.body.tasks);
    final index = items.indexWhere((i) => i.id == taskId);
    if (index == -1) return;

    final target = items[index];
    final updatedDone = !target.done;
    final updatedTarget = target.copyWith(
      done: updatedDone,
      doneAt: updatedDone ? DateTime.now() : null,
      lastModifiedAt: DateTime.now(),
    );
    final updatedList = List<TaskItem>.from(items)..[index] = updatedTarget;
    final updatedCheckList = active.body.copyWith(tasks: encodeTaskItems(updatedList));
    await save(active.copyWith(body: updatedCheckList));
    await TaskWidgetBridge.refreshFromLocalState();
  }

  /// 删除单项任务
  Future<void> deleteTask(String taskId, String currentUserId) async {
    final active = await getOrCreateActiveCheckList(currentUserId);
    final items = decodeTaskItems(active.body.tasks);
    final updatedList = items.where((i) => i.id != taskId).toList();
    final updatedCheckList = active.body.copyWith(tasks: encodeTaskItems(updatedList));
    await save(active.copyWith(body: updatedCheckList));
    await TaskWidgetBridge.refreshFromLocalState();
  }

  /// 归档当前清单并初始化新清单
  Future<void> archiveActiveCheckList(String currentUserId) async {
    final active = await getOrCreateActiveCheckList(currentUserId);
    final items = decodeTaskItems(active.body.tasks);
    if (items.isEmpty) return;

    // 1. 将当前清单标记为已归档
    final archived = active.body.copyWith(
      archived: true,
      archivedAt: DateTime.now(),
    );
    await save(active.copyWith(body: archived));

    // 2. 将未完成的任务结转到新活动清单中
    final pendingItems = items.where((i) => !i.done).map((i) => i.copyWith(lastModifiedAt: DateTime.now())).toList();
    final newId = UuidService.v7();
    final newItem = DataItem<CheckList>(
      id: newId,
      owner: currentUserId,
      body: CheckList(
        tasks: encodeTaskItems(pendingItems),
        archived: false,
      ),
      syncStatus: SyncStatus.pending,
    );
    await save(newItem);
    await TaskWidgetBridge.refreshFromLocalState();
  }
}
