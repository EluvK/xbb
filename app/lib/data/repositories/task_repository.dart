import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/controller/task_widget.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/models/task/model.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';
import 'package:xbb/sync/v2/uuid_service.dart';

class TaskRepository {
  final Database db;
  final DatabaseChangeNotifier changeNotifier;

  TaskRepository({
    required this.db,
    required this.changeNotifier,
  });

  /// 监听当前活动的 CheckList
  Stream<DataItem<CheckList>?> watchActiveCheckList() {
    return changeNotifier.watchTable('check_list').asyncMap((_) async {
      final rows = await db.query(
        'check_list',
        orderBy: 'created_at DESC',
      );
      final now = DateTime.now();
      for (final r in rows) {
        final bodyStr = r['body'] as String? ?? '{}';
        try {
          final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
          final checkList = CheckList.fromJson(bodyJson);
          if (!checkList.archived) {
            return DataItem<CheckList>(
              r['id'] as String,
              DateTime.tryParse(r['created_at'] as String? ?? '') ?? now,
              DateTime.tryParse(r['updated_at'] as String? ?? '') ?? now,
              r['owner'] as String? ?? 'default',
              null,
              null,
              body: checkList,
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
    return changeNotifier.watchTable('check_list').asyncMap((_) async {
      final rows = await db.query(
        'check_list',
        orderBy: 'created_at DESC',
      );
      final list = <DataItem<CheckList>>[];
      final now = DateTime.now();
      for (final r in rows) {
        final bodyStr = r['body'] as String? ?? '{}';
        try {
          final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
          final checkList = CheckList.fromJson(bodyJson);
          if (checkList.archived) {
            list.add(DataItem<CheckList>(
              r['id'] as String,
              DateTime.tryParse(r['created_at'] as String? ?? '') ?? now,
              DateTime.tryParse(r['updated_at'] as String? ?? '') ?? now,
              r['owner'] as String? ?? 'default',
              null,
              null,
              body: checkList,
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
    final rows = await db.query('check_list', orderBy: 'created_at DESC');
    final now = DateTime.now();
    for (final r in rows) {
      final bodyStr = r['body'] as String? ?? '{}';
      try {
        final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
        final checkList = CheckList.fromJson(bodyJson);
        if (!checkList.archived) {
          return DataItem<CheckList>(
            r['id'] as String,
            DateTime.tryParse(r['created_at'] as String? ?? '') ?? now,
            DateTime.tryParse(r['updated_at'] as String? ?? '') ?? now,
            r['owner'] as String? ?? currentUserId,
            null,
            null,
            body: checkList,
            syncStatus: SyncStatus.synced,
          );
        }
      } catch (_) {}
    }

    final newId = UuidService.v7();
    final newCheckList = CheckList(tasks: '[]', archived: false);
    final newItem = DataItem<CheckList>(
      newId,
      now,
      now,
      currentUserId,
      null,
      null,
      body: newCheckList,
      syncStatus: SyncStatus.pending,
    );
    await saveCheckList(newItem);
    return newItem;
  }

  Future<void> saveCheckList(DataItem<CheckList> item) async {
    final nowIso = DateTime.now().toIso8601String();
    final row = <String, dynamic>{
      'id': item.id,
      'created_at': nowIso,
      'updated_at': nowIso,
      'owner': item.owner,
      'parent_id': null,
      'sync_status': 'pending',
      'color_tag': 'default',
      'body': jsonEncode(item.body.toJson()),
    };
    await LocalFirstDB.persistPutRaw(
      db: db,
      tableName: 'check_list',
      entityId: item.id,
      entityRow: row,
    );
    changeNotifier.notify('check_list');
    SyncWorker.instance.notifyLocalWrite();
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
    await saveCheckList(DataItem<CheckList>(
      active.id,
      active.createdAt,
      DateTime.now(),
      active.owner,
      active.parentId,
      active.unique,
      body: updatedCheckList,
      syncStatus: SyncStatus.pending,
    ));
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
    await saveCheckList(DataItem<CheckList>(
      active.id,
      active.createdAt,
      DateTime.now(),
      active.owner,
      active.parentId,
      active.unique,
      body: updatedCheckList,
      syncStatus: SyncStatus.pending,
    ));
    await TaskWidgetBridge.refreshFromLocalState();
  }

  /// 更新单项任务内容
  Future<void> updateTaskContent(String taskId, String newContent, String currentUserId) async {
    final trimmed = newContent.trim();
    if (trimmed.isEmpty) return;
    final active = await getOrCreateActiveCheckList(currentUserId);
    final items = decodeTaskItems(active.body.tasks);
    final index = items.indexWhere((i) => i.id == taskId);
    if (index == -1) return;

    final target = items[index];
    if (target.content == trimmed) return;

    final updatedTarget = target.copyWith(
      content: trimmed,
      lastModifiedAt: DateTime.now(),
    );
    final updatedList = List<TaskItem>.from(items)..[index] = updatedTarget;
    final updatedCheckList = active.body.copyWith(tasks: encodeTaskItems(updatedList));
    await saveCheckList(DataItem<CheckList>(
      active.id,
      active.createdAt,
      DateTime.now(),
      active.owner,
      active.parentId,
      active.unique,
      body: updatedCheckList,
      syncStatus: SyncStatus.pending,
    ));
    await TaskWidgetBridge.refreshFromLocalState();
  }

  /// 删除单项任务
  Future<void> deleteTask(String taskId, String currentUserId) async {
    final active = await getOrCreateActiveCheckList(currentUserId);
    final items = decodeTaskItems(active.body.tasks);
    final updatedList = items.where((i) => i.id != taskId).toList();
    final updatedCheckList = active.body.copyWith(tasks: encodeTaskItems(updatedList));
    await saveCheckList(DataItem<CheckList>(
      active.id,
      active.createdAt,
      DateTime.now(),
      active.owner,
      active.parentId,
      active.unique,
      body: updatedCheckList,
      syncStatus: SyncStatus.pending,
    ));
    await TaskWidgetBridge.refreshFromLocalState();
  }

  /// 归档当前清单并初始化新清单
  Future<void> archiveActiveCheckList(String currentUserId) async {
    final active = await getOrCreateActiveCheckList(currentUserId);
    final items = decodeTaskItems(active.body.tasks);
    if (items.isEmpty) return;

    final archived = active.body.copyWith(
      archived: true,
      archivedAt: DateTime.now(),
    );
    await saveCheckList(DataItem<CheckList>(
      active.id,
      active.createdAt,
      DateTime.now(),
      active.owner,
      active.parentId,
      active.unique,
      body: archived,
      syncStatus: SyncStatus.pending,
    ));

    final pendingItems = items.where((i) => !i.done).map((i) => i.copyWith(lastModifiedAt: DateTime.now())).toList();
    final newId = UuidService.v7();
    final now = DateTime.now();
    final newItem = DataItem<CheckList>(
      newId,
      now,
      now,
      currentUserId,
      null,
      null,
      body: CheckList(
        tasks: encodeTaskItems(pendingItems),
        archived: false,
      ),
      syncStatus: SyncStatus.pending,
    );
    await saveCheckList(newItem);
    await TaskWidgetBridge.refreshFromLocalState();
  }
}
