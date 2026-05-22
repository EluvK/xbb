// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Repo _$RepoFromJson(Map<String, dynamic> json) =>
    Repo(name: json['name'] as String, status: json['status'] as String, description: json['description'] as String?);

Map<String, dynamic> _$RepoToJson(Repo instance) => <String, dynamic>{
  'name': instance.name,
  'status': instance.status,
  'description': ?instance.description,
};

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

extension LocalStoreRepo on Repo {
  static String get tableName => 'repo';

  static String get onCreateTableRepoSQL =>
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
    return await TestDataBase().getDb();
  }
}

typedef RepoDataItem = DataItem<Repo>;

class RepoRepository {
  Future<void> addToLocalDb(RepoDataItem item) async {
    final db = await LocalStoreRepo.getDb();
    await db.insert(LocalStoreRepo.tableName, item.toJson((r) => json.encode(r.toJson())));
  }

  Future<RepoDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreRepo.getDb();
    final List<Map<String, dynamic>> maps = await db.query(LocalStoreRepo.tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return DataItem<Repo>.fromJson(maps.first, (jsonStr) => Repo.fromJson(json.decode(jsonStr as String)));
    }
    return null;
  }

  Future<List<RepoDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStoreRepo.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreRepo.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps
        .map((map) => DataItem<Repo>.fromJson(map, (jsonStr) => Repo.fromJson(json.decode(jsonStr as String))))
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreRepo.getDb();
    await db.delete(LocalStoreRepo.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToLocalDb(RepoDataItem item) async {
    final db = await LocalStoreRepo.getDb();
    await db.update(
      LocalStoreRepo.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(RepoDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}

class _RepoDataItemFilterSubscription {
  final RxList<RepoDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _RepoDataItemFilterSubscription(this.filteredList, this.appliedFilters, this.worker);
}

class RepoController extends GetxController {
  final SyncStoreClient client;
  final _RepoSyncEngine _syncEngine;
  RepoController(this.client) : _syncEngine = _RepoSyncEngine(client);

  final RxList<RepoDataItem> _items = <RepoDataItem>[].obs;

  final Map<String, _RepoDataItemFilterSubscription> _dynamicSubscription = {};
  final Rx<String?> currentRepoId = Rx<String?>(null);

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
      await RepoRepository().deleteFromLocalDb(id);
    }
    await rebuildLocal();
  }

  RxList<RepoDataItem> registerFilterSubscription({
    required String filterKey,
    List<DataItemFilter> filters = const [],
  }) {
    final existing = _dynamicSubscription[filterKey];
    if (existing != null && listEquals(existing.appliedFilters, filters)) {
      return existing.filteredList;
    }
    final newList = _items.where((item) => filters.every((filter) => filter.apply(item))).toList().obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<RepoDataItem> value) {
      final newFiltered = value.where((item) => filters.every((filter) => filter.apply(item))).toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _RepoDataItemFilterSubscription(newList, filters, worker);
    return newList;
  }

  void unregisterFilterSubscription(String filterKey) {
    final sub = _dynamicSubscription.remove(filterKey);
    sub?.worker.dispose();
  }

  Future<void> rebuildLocal() async {
    _items.value = await RepoRepository().listFromLocalDb();
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void onSelectRepo(String id) {
    currentRepoId.value = id;
  }

  DataItem<Repo>? getRepo(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  List<T> getRepoDetails<T>({
    List<DataItemFilter> filters = const [],
    required T Function(RepoDataItem item) selector,
  }) {
    return _items.where((item) => filters.every((filter) => filter.apply(item))).map(selector).toList();
  }

  int getRepoCount<T>({List<DataItemFilter> filters = const []}) {
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

  void _replaceLocal(String id, RepoDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    if (currentRepoId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentRepoId.value = fetchedItem.id;
    }
  }

  void addData(Repo newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = RepoDataItem.localNew(owner, newData);
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _syncEngine.create(newItem).then((fetchedItem) {
      _replaceLocal(newItem.id, fetchedItem);
    });
  }

  void updateData(String id, Repo updatedData) {
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
    RepoRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentRepoId.value == id) {
      currentRepoId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    _syncEngine.delete(id, deleteFromServer ? true : status != SyncStatus.deleted);
  }
}

class _RepoSyncEngine {
  final SyncStoreClient client;
  _RepoSyncEngine(this.client);

  Future<RepoDataItem> create(RepoDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await RepoRepository().addToLocalDb(local);

    RepoDataItem createdItem;
    try {
      final newId = await client.create('xbb', 'repo', local.body.toJson());
      createdItem = await client.get<Repo>('xbb', 'repo', newId, Repo.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await RepoRepository().updateToLocalDb(local);
      rethrow;
    }
    createdItem.syncStatus = SyncStatus.archived;
    createdItem.colorTag = local.colorTag;

    await RepoRepository().deleteFromLocalDb(local.id);
    await RepoRepository().addToLocalDb(createdItem);
    return createdItem;
  }

  Future<RepoDataItem> update(RepoDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await RepoRepository().updateToLocalDb(local);

    RepoDataItem updatedItem;
    try {
      await client.update('xbb', 'repo', local.id, local.body.toJson());
      updatedItem = await client.get<Repo>('xbb', 'repo', local.id, Repo.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await RepoRepository().updateToLocalDb(local);
      rethrow;
    }
    updatedItem.syncStatus = SyncStatus.archived;
    updatedItem.colorTag = local.colorTag;

    await RepoRepository().updateToLocalDb(updatedItem);
    return updatedItem;
  }

  void delete(String id, bool deleteFromServer) {
    RepoRepository().deleteFromLocalDb(id);
    if (!deleteFromServer) return;
    try {
      client.delete('xbb', 'repo', id);
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
          'xbb',
          'repo',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final RepoDataItem? localItem = await RepoRepository().getFromLocalDb(summary.id);
          if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
            // only get details for new created or updated items, otherwise just skip to save performance.
            needGetIds.add(summary.id);
          } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
            // local data is newer, need to sync to server
            localItem.syncStatus = SyncStatus.failed;
            await RepoRepository().updateToLocalDb(localItem);
          } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
            // same updatedAt but marked as special status, need to sync to server
            localItem.syncStatus = SyncStatus.archived;
            await RepoRepository().updateToLocalDb(localItem);
          }
        }
      } while (nextMarker != null);
      // 2. clean up local data that are deleted from server
      final localItems = await RepoRepository().listFromLocalDb();
      for (RepoDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await RepoRepository().updateToLocalDb(localItem);
        }
      }

      // 3. batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('xbb', 'repo', batchIds, Repo.fromJson);
        for (var item in batchItems.items) {
          await RepoRepository().upsertToLocalDb(item);
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
          final ListResponse resp = await client.batchListChildren('xbb', 'repo', parentIdsBatch, marker: nextMarker);
          nextMarker = resp.pageInfo.nextMarker;
          for (var summary in resp.items) {
            serviceIds.add(summary.id);
            final RepoDataItem? localItem = await RepoRepository().getFromLocalDb(summary.id);
            if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
              // only get details for new created or updated items, otherwise just skip to save performance.
              needGetIds.add(summary.id);
            } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
              // local data is newer, need to sync to server
              localItem.syncStatus = SyncStatus.failed;
              await RepoRepository().updateToLocalDb(localItem);
            } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
              // same updatedAt but marked as special status, need to sync to server
              localItem.syncStatus = SyncStatus.archived;
              await RepoRepository().updateToLocalDb(localItem);
            }
          }
        } while (nextMarker != null);
      }
      // clean up local data that are deleted from server
      final localItems = await RepoRepository().listFromLocalDb();
      for (RepoDataItem localItem in localItems) {
        if (localItem.parentId == null || !parentIds.contains(localItem.parentId!)) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await RepoRepository().updateToLocalDb(localItem);
        }
      }
      // batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('xbb', 'repo', batchIds, Repo.fromJson);
        for (var item in batchItems.items) {
          await RepoRepository().upsertToLocalDb(item);
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
        final ListResponse resp = await client.list('xbb', 'repo', limit: 200, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final RepoDataItem? localItem = await RepoRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await RepoRepository().listFromLocalDb();
      for (RepoDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await RepoRepository().updateToLocalDb(localItem);
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
          'xbb',
          'repo',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final RepoDataItem? localItem = await RepoRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await RepoRepository().listFromLocalDb();
      for (RepoDataItem localItem in localItems) {
        if (localItem.owner == currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.hidden;
          await RepoRepository().updateToLocalDb(localItem);
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
        final ListResponse resp = await client.list('xbb', 'repo', parentId: parentId, limit: 200, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final RepoDataItem? localItem = await RepoRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await RepoRepository().listFromLocalDb(parentId: parentId);
      for (RepoDataItem localItem in localItems) {
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await RepoRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> _compareRemote(RepoDataItem? localItem, DataItemSummary summary) async {
    if (localItem == null) {
      // new from server
      final RepoDataItem item = await client.get<Repo>('xbb', 'repo', summary.id, Repo.fromJson);
      await RepoRepository().addToLocalDb(item);
    } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
      // update local data.
      final RepoDataItem item = await client.get<Repo>('xbb', 'repo', summary.id, Repo.fromJson);
      await RepoRepository().updateToLocalDb(item);
    } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
      // local data is newer, need to sync to server
      localItem.syncStatus = SyncStatus.failed;
      await RepoRepository().updateToLocalDb(localItem);
    } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
      // same updatedAt but marked as special status, need to sync to server
      localItem.syncStatus = SyncStatus.archived;
      await RepoRepository().updateToLocalDb(localItem);
    }
  }
}
