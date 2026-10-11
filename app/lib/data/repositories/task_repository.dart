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
    return watchArchivedSegmentsCumulative(limit: -1);
  }

  /// 分页监听归档历史段落 (支持 page / pageSize)
  Stream<List<DataItem<CheckList>>> watchArchivedSegments({int page = 1, int pageSize = 10}) {
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
      final start = ((page - 1) * pageSize).clamp(0, list.length);
      final end = (start + pageSize).clamp(0, list.length);
      return list.sublist(start, end);
    });
  }

  /// 累加监听归档历史段落（支持“加载更多”视图，按指定 limit 截取）
  Stream<List<DataItem<CheckList>>> watchArchivedSegmentsCumulative({int limit = 10}) {
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
      if (limit <= 0 || limit >= list.length) {
        return list;
      }
      return list.sublist(0, limit);
    });
  }

  /// 获取归档历史段落总数
  Future<int> getArchivedSegmentsTotalCount() async {
    final rows = await db.query('check_list');
    var count = 0;
    for (final r in rows) {
      final bodyStr = r['body'] as String? ?? '{}';
      try {
        final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
        if (bodyJson['archived'] == true) {
          count++;
        }
      } catch (_) {}
    }
    return count;
  }

  /// 删除指定归档历史段落，在本地数据库与 Outbox 同步删除
  Future<void> deleteArchivedSegment(String listId) async {
    await LocalFirstDB.persistDeleteRaw(
      db: db,
      tableName: 'check_list',
      entityId: listId,
    );
    changeNotifier.notify('check_list');
    SyncWorker.instance.notifyLocalWrite();
    await TaskWidgetBridge.refreshFromLocalState(currentDb: db);
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
    await TaskWidgetBridge.refreshFromLocalState(currentDb: db);
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

  /// 拖拽调整任务排序并更新权重
  Future<void> reorderTasks(int oldIndex, int newIndex, String currentUserId) async {
    final active = await getOrCreateActiveCheckList(currentUserId);
    final items = sortTaskItems(decodeTaskItems(active.body.tasks));
    if (oldIndex < 0 || oldIndex >= items.length) return;
    if (newIndex < 0 || newIndex > items.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final movedItem = items.removeAt(oldIndex);
    items.insert(newIndex, movedItem);

    final now = DateTime.now();
    final updatedList = <TaskItem>[];
    for (var i = 0; i < items.length; i++) {
      updatedList.add(items[i].copyWith(sortOrder: i, lastModifiedAt: now));
    }

    final updatedCheckList = active.body.copyWith(tasks: encodeTaskItems(updatedList));
    await saveCheckList(DataItem<CheckList>(
      active.id,
      active.createdAt,
      now,
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

  /// 归档当前清单已完成任务并初始化/保留活跃清单
  Future<void> archiveActiveCheckList(String currentUserId) async {
    final active = await getOrCreateActiveCheckList(currentUserId);
    final items = decodeTaskItems(active.body.tasks);
    if (items.isEmpty) return;

    final completed = items.where((t) => t.done).toList();
    if (completed.isEmpty) return;
    final remaining = items.where((t) => !t.done).toList();

    // 1. 生成已完成任务的历史段落
    final archivedId = UuidService.v7();
    final now = DateTime.now();
    final archivedItem = DataItem<CheckList>(
      archivedId,
      now,
      now,
      currentUserId,
      null,
      null,
      body: CheckList(
        tasks: encodeTaskItems(completed),
        archived: true,
        archivedAt: now,
      ),
      syncStatus: SyncStatus.pending,
    );
    await saveCheckList(archivedItem);

    // 2. 活跃工作区保留未完成任务并重置序号
    final normalizedRemaining = [
      for (var i = 0; i < remaining.length; i++)
        remaining[i].copyWith(sortOrder: i, lastModifiedAt: now),
    ];
    final updatedActive = active.body.copyWith(
      tasks: encodeTaskItems(normalizedRemaining),
      archived: false,
      archivedAt: null,
    );
    await saveCheckList(DataItem<CheckList>(
      active.id,
      active.createdAt,
      now,
      active.owner,
      active.parentId,
      active.unique,
      body: updatedActive,
      syncStatus: SyncStatus.pending,
    ));
    await TaskWidgetBridge.refreshFromLocalState();
  }
}
