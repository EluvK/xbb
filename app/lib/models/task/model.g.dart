// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CheckList _$CheckListFromJson(Map<String, dynamic> json) => _CheckList(
  tasks: json['tasks'] as String,
  archived: json['archived'] as bool,
  archivedAt: json['archived_at'] == null ? null : DateTime.parse(json['archived_at'] as String),
);

Map<String, dynamic> _$CheckListToJson(_CheckList instance) => <String, dynamic>{
  'tasks': instance.tasks,
  'archived': instance.archived,
  'archived_at': instance.archivedAt?.toIso8601String(),
};

_TaskItem _$TaskItemFromJson(Map<String, dynamic> json) => _TaskItem(
  id: json['id'] as String,
  content: json['content'] as String,
  done: json['done'] as bool,
  doneAt: json['done_at'] == null ? null : DateTime.parse(json['done_at'] as String),
  lastModifiedAt: DateTime.parse(json['last_modified_at'] as String),
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$TaskItemToJson(_TaskItem instance) => <String, dynamic>{
  'id': instance.id,
  'content': instance.content,
  'done': instance.done,
  'done_at': instance.doneAt?.toIso8601String(),
  'last_modified_at': instance.lastModifiedAt.toIso8601String(),
  'sort_order': instance.sortOrder,
};

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

extension LocalStoreCheckList on CheckList {
  static String get tableName => 'check_list';

  static String get onCreateTableCheckListSQL =>
      """
        CREATE TABLE $tableName (
          id TEXT PRIMARY KEY,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          owner TEXT NOT NULL,
          parent_id TEXT,
          "unique" TEXT,
          sync_status TEXT NOT NULL,
          color_tag TEXT NOT NULL,
          body TEXT NOT NULL
        )
      """;

  static Future<Database> getDb() async {
    return await TaskDB().getDb();
  }
}

typedef CheckListDataItem = DataItem<CheckList>;

class CheckListRepository {
  Future<void> addToLocalDb(CheckListDataItem item) async {
    final db = await LocalStoreCheckList.getDb();
    await db.insert(LocalStoreCheckList.tableName, item.toJson((r) => json.encode(r.toJson())));
  }

  Future<CheckListDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreCheckList.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreCheckList.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<CheckList>.fromJson(maps.first, (jsonStr) => CheckList.fromJson(json.decode(jsonStr as String)));
    }
    return null;
  }

  Future<List<CheckListDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStoreCheckList.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreCheckList.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps
        .map(
          (map) => DataItem<CheckList>.fromJson(map, (jsonStr) => CheckList.fromJson(json.decode(jsonStr as String))),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreCheckList.getDb();
    await db.delete(LocalStoreCheckList.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToLocalDb(CheckListDataItem item) async {
    final db = await LocalStoreCheckList.getDb();
    await db.update(
      LocalStoreCheckList.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(CheckListDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}

class _CheckListDataItemFilterSubscription {
  final RxList<CheckListDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _CheckListDataItemFilterSubscription(this.filteredList, this.appliedFilters, this.worker);
}

class CheckListController extends GetxController {
  final SyncStoreClient client;
  final _CheckListSyncEngine _syncEngine;
  CheckListController(this.client) : _syncEngine = _CheckListSyncEngine(client);

  final RxList<CheckListDataItem> _items = <CheckListDataItem>[].obs;

  final Map<String, _CheckListDataItemFilterSubscription> _dynamicSubscription = {};
  final Rx<String?> currentCheckListId = Rx<String?>(null);

  @override
  Future<void> onInit() async {
    await rebuildLocal();

    super.onInit();
    _initialized = true;
  }

  bool _initialized = false;
  Future<void> ensureInitialization() async {
    while (!_initialized) {
      await onInit();
    }
    return;
  }

  @override
  void onClose() {
    for (var sub in _dynamicSubscription.values) {
      sub.worker.dispose();
    }
    _dynamicSubscription.clear();
    super.onClose();
  }

  /// ALERT: this will delete all local data, use with caution.
  Future<void> clearLocal() async {
    final ids = _items.map((e) => e.id).toList();
    for (var id in ids) {
      await CheckListRepository().deleteFromLocalDb(id);
    }
    await rebuildLocal();
  }

  RxList<CheckListDataItem> registerFilterSubscription({
    required String filterKey,
    List<DataItemFilter> filters = const [],
  }) {
    final existing = _dynamicSubscription[filterKey];
    if (existing != null && listEquals(existing.appliedFilters, filters)) {
      return existing.filteredList;
    }
    final newList = _items.where((item) => filters.every((filter) => filter.apply(item))).toList().obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<CheckListDataItem> value) {
      final newFiltered = value.where((item) => filters.every((filter) => filter.apply(item))).toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _CheckListDataItemFilterSubscription(newList, filters, worker);
    return newList;
  }

  void unregisterFilterSubscription(String filterKey) {
    final sub = _dynamicSubscription.remove(filterKey);
    sub?.worker.dispose();
  }

  Future<void> rebuildLocal() async {
    _items.value = await CheckListRepository().listFromLocalDb();
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void onSelectCheckList(String id) {
    currentCheckListId.value = id;
  }

  DataItem<CheckList>? getCheckList(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  List<T> getCheckListDetails<T>({
    List<DataItemFilter> filters = const [],
    required T Function(CheckListDataItem item) selector,
  }) {
    return _items.where((item) => filters.every((filter) => filter.apply(item))).map(selector).toList();
  }

  int getCheckListCount<T>({List<DataItemFilter> filters = const []}) {
    return _items.where((item) => filters.every((filter) => filter.apply(item))).length;
  }

  Future<void> syncAll({int batchSize = 20}) async {
    await _syncEngine.syncAllData(batchSize: batchSize);
  }

  Future<void> syncChildren(String parentId, {int batchSize = 20}) async {
    await _syncEngine.syncChildrenBatch([parentId], batchSize: batchSize);
  }

  Future<void> syncMultiChildren(List<String> parentIds, {int batchSize = 20}) async {
    await _syncEngine.syncChildrenBatch(parentIds, batchSize: batchSize);
  }

  Future<void> syncOwned() async {
    await _syncEngine.syncOwned();
  }

  Future<void> syncGranted() async {
    await _syncEngine.syncGranted();
  }

  void _replaceLocal(String id, CheckListDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    if (currentCheckListId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentCheckListId.value = fetchedItem.id;
    }
  }

  void addData(CheckList newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = CheckListDataItem.localNew(owner, newData);
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _syncEngine.create(newItem).then((fetchedItem) {
      _replaceLocal(newItem.id, fetchedItem);
    });
  }

  void updateData(String id, CheckList updatedData) {
    final item = _items.firstWhere((item) => item.id == id);
    // todo maybe rewrite this update body method...
    final updatedItem = item.updatedBody(updatedData);
    _items[_items.indexOf(item)] = updatedItem;
    _syncEngine.update(updatedItem).then((fetchedItem) {
      _replaceLocal(updatedItem.id, fetchedItem);
    });
  }

  void onUpdateLocalField(String id, {ColorTag? colorTag, SyncStatus? syncStatus}) {
    final item = _items.firstWhere((item) => item.id == id);
    if (colorTag != null) {
      item.colorTag = colorTag;
    }
    if (syncStatus != null) {
      item.syncStatus = syncStatus;
    }
    CheckListRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentCheckListId.value == id) {
      currentCheckListId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    _syncEngine.delete(id, deleteFromServer ? true : status != SyncStatus.deleted);
  }
}

class _CheckListSyncEngine {
  final SyncStoreClient client;
  _CheckListSyncEngine(this.client);

  Future<CheckListDataItem> create(CheckListDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await CheckListRepository().addToLocalDb(local);

    CheckListDataItem createdItem;
    try {
      final newId = await client.create('task', 'check_list', local.body.toJson());
      createdItem = await client.get<CheckList>('task', 'check_list', newId, CheckList.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await CheckListRepository().updateToLocalDb(local);
      rethrow;
    }
    createdItem.syncStatus = SyncStatus.archived;
    createdItem.colorTag = local.colorTag;

    await CheckListRepository().deleteFromLocalDb(local.id);
    await CheckListRepository().addToLocalDb(createdItem);
    return createdItem;
  }

  Future<CheckListDataItem> update(CheckListDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await CheckListRepository().updateToLocalDb(local);

    CheckListDataItem updatedItem;
    try {
      await client.update('task', 'check_list', local.id, local.body.toJson());
      updatedItem = await client.get<CheckList>('task', 'check_list', local.id, CheckList.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await CheckListRepository().updateToLocalDb(local);
      rethrow;
    }
    updatedItem.syncStatus = SyncStatus.archived;
    updatedItem.colorTag = local.colorTag;

    await CheckListRepository().updateToLocalDb(updatedItem);
    return updatedItem;
  }

  void delete(String id, bool deleteFromServer) {
    CheckListRepository().deleteFromLocalDb(id);
    if (!deleteFromServer) return;
    try {
      client.delete('task', 'check_list', id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncAllData({int batchSize = 20}) async {
    final currentUserId = client.currentUserId();
    try {
      String? nextMarker;
      final serviceIds = <String>{};
      final needGetIds = <String>{};
      // 1. list all data ids from server, and compare with local data to find out which data need to fetch details and which data are deleted from server.
      do {
        final ListResponse resp = await client.list(
          'task',
          'check_list',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final CheckListDataItem? localItem = await CheckListRepository().getFromLocalDb(summary.id);
          if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
            // only get details for new created or updated items, otherwise just skip to save performance.
            needGetIds.add(summary.id);
          } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
            // local data is newer, need to sync to server
            localItem.syncStatus = SyncStatus.failed;
            await CheckListRepository().updateToLocalDb(localItem);
          } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
            // same updatedAt but marked as special status, need to sync to server
            localItem.syncStatus = SyncStatus.archived;
            await CheckListRepository().updateToLocalDb(localItem);
          }
        }
      } while (nextMarker != null);
      // 2. clean up local data that are deleted from server
      final localItems = await CheckListRepository().listFromLocalDb();
      for (CheckListDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await CheckListRepository().updateToLocalDb(localItem);
        }
      }

      // 3. batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('task', 'check_list', batchIds, CheckList.fromJson);
        for (var item in batchItems.items) {
          await CheckListRepository().upsertToLocalDb(item);
        }
        final truncated = batchItems.truncated;
        if (truncated != null) {
          i = needGetIdsList.indexOf(truncated);
          if (i == -1) {
            // just in case, if truncated id is not found in the list, fallback to next batch.
            i += batchSize;
          }
        } else {
          i += batchSize;
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> syncChildrenBatch(List<String> parentIds, {int batchSize = 20}) async {
    try {
      final needGetIds = <String>{};
      final serviceIds = <String>{};
      for (var i = 0; i < parentIds.length; i += 100) {
        final parentIdsBatch = parentIds.skip(i).take(100).toList();
        String? nextMarker;
        do {
          final ListResponse resp = await client.batchListChildren(
            'task',
            'check_list',
            parentIdsBatch,
            marker: nextMarker,
          );
          nextMarker = resp.pageInfo.nextMarker;
          for (var summary in resp.items) {
            serviceIds.add(summary.id);
            final CheckListDataItem? localItem = await CheckListRepository().getFromLocalDb(summary.id);
            if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
              // only get details for new created or updated items, otherwise just skip to save performance.
              needGetIds.add(summary.id);
            } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
              // local data is newer, need to sync to server
              localItem.syncStatus = SyncStatus.failed;
              await CheckListRepository().updateToLocalDb(localItem);
            } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
              // same updatedAt but marked as special status, need to sync to server
              localItem.syncStatus = SyncStatus.archived;
              await CheckListRepository().updateToLocalDb(localItem);
            }
          }
        } while (nextMarker != null);
      }
      // clean up local data that are deleted from server
      final localItems = await CheckListRepository().listFromLocalDb();
      for (CheckListDataItem localItem in localItems) {
        if (localItem.parentId == null || !parentIds.contains(localItem.parentId!)) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await CheckListRepository().updateToLocalDb(localItem);
        }
      }
      // batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('task', 'check_list', batchIds, CheckList.fromJson);
        for (var item in batchItems.items) {
          await CheckListRepository().upsertToLocalDb(item);
        }
        final truncated = batchItems.truncated;
        if (truncated != null) {
          i = needGetIdsList.indexOf(truncated);
          if (i == -1) {
            // just in case, if truncated id is not found in the list, fallback to next batch.
            i += batchSize;
          }
        } else {
          i += batchSize;
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> syncOwned() async {
    final currentUserId = client.currentUserId();
    try {
      String? nextMarker;
      final serviceIds = <String>{};
      do {
        final ListResponse resp = await client.list('task', 'check_list', limit: 200, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final CheckListDataItem? localItem = await CheckListRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await CheckListRepository().listFromLocalDb();
      for (CheckListDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await CheckListRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> syncGranted() async {
    final currentUserId = client.currentUserId();
    try {
      String? nextMarker;
      final serviceIds = <String>{};
      do {
        final ListResponse resp = await client.list(
          'task',
          'check_list',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final CheckListDataItem? localItem = await CheckListRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await CheckListRepository().listFromLocalDb();
      for (CheckListDataItem localItem in localItems) {
        if (localItem.owner == currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.hidden;
          await CheckListRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> syncChildren(String parentId) async {
    try {
      String? nextMarker;
      final serviceIds = <String>{};
      do {
        final ListResponse resp = await client.list(
          'task',
          'check_list',
          parentId: parentId,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final CheckListDataItem? localItem = await CheckListRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await CheckListRepository().listFromLocalDb(parentId: parentId);
      for (CheckListDataItem localItem in localItems) {
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await CheckListRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> _compareRemote(CheckListDataItem? localItem, DataItemSummary summary) async {
    if (localItem == null) {
      // new from server
      final CheckListDataItem item = await client.get<CheckList>('task', 'check_list', summary.id, CheckList.fromJson);
      await CheckListRepository().addToLocalDb(item);
    } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
      // update local data.
      final CheckListDataItem item = await client.get<CheckList>('task', 'check_list', summary.id, CheckList.fromJson);
      await CheckListRepository().updateToLocalDb(item);
    } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
      // local data is newer, need to sync to server
      localItem.syncStatus = SyncStatus.failed;
      await CheckListRepository().updateToLocalDb(localItem);
    } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
      // same updatedAt but marked as special status, need to sync to server
      localItem.syncStatus = SyncStatus.archived;
      await CheckListRepository().updateToLocalDb(localItem);
    }
  }
}
