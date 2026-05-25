// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClipboardHistoryEntry _$ClipboardHistoryEntryFromJson(
  Map<String, dynamic> json,
) => _ClipboardHistoryEntry(
  data: json['data'] as String,
  localOnly: json['local_only'] as bool? ?? true,
);

Map<String, dynamic> _$ClipboardHistoryEntryToJson(
  _ClipboardHistoryEntry instance,
) => <String, dynamic>{'data': instance.data, 'local_only': instance.localOnly};

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

extension LocalStoreClipboardHistoryEntry on ClipboardHistoryEntry {
  static String get tableName => 'entry';

  static String get onCreateTableClipboardHistoryEntrySQL =>
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
    return await ClipboardDB().getDb();
  }
}

typedef ClipboardHistoryEntryDataItem = DataItem<ClipboardHistoryEntry>;

class ClipboardHistoryEntryRepository {
  Future<void> addToLocalDb(ClipboardHistoryEntryDataItem item) async {
    final db = await LocalStoreClipboardHistoryEntry.getDb();
    await db.insert(
      LocalStoreClipboardHistoryEntry.tableName,
      item.toJson((r) => json.encode(r.toJson())),
    );
  }

  Future<ClipboardHistoryEntryDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreClipboardHistoryEntry.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreClipboardHistoryEntry.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<ClipboardHistoryEntry>.fromJson(
        maps.first,
        (jsonStr) =>
            ClipboardHistoryEntry.fromJson(json.decode(jsonStr as String)),
      );
    }
    return null;
  }

  Future<List<ClipboardHistoryEntryDataItem>> listFromLocalDb({
    String? parentId,
  }) async {
    final db = await LocalStoreClipboardHistoryEntry.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty
        ? whereClauses.join(' AND ')
        : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreClipboardHistoryEntry.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps
        .map(
          (map) => DataItem<ClipboardHistoryEntry>.fromJson(
            map,
            (jsonStr) =>
                ClipboardHistoryEntry.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreClipboardHistoryEntry.getDb();
    await db.delete(
      LocalStoreClipboardHistoryEntry.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateToLocalDb(ClipboardHistoryEntryDataItem item) async {
    final db = await LocalStoreClipboardHistoryEntry.getDb();
    await db.update(
      LocalStoreClipboardHistoryEntry.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(ClipboardHistoryEntryDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}

class _ClipboardHistoryEntryDataItemFilterSubscription {
  final RxList<ClipboardHistoryEntryDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _ClipboardHistoryEntryDataItemFilterSubscription(
    this.filteredList,
    this.appliedFilters,
    this.worker,
  );
}

class ClipboardHistoryEntryController extends GetxController {
  final SyncStoreClient client;
  final _ClipboardHistoryEntrySyncEngine _syncEngine;
  ClipboardHistoryEntryController(this.client)
    : _syncEngine = _ClipboardHistoryEntrySyncEngine(client);

  final RxList<ClipboardHistoryEntryDataItem> _items =
      <ClipboardHistoryEntryDataItem>[].obs;

  final Map<String, _ClipboardHistoryEntryDataItemFilterSubscription>
  _dynamicSubscription = {};
  final Rx<String?> currentClipboardHistoryEntryId = Rx<String?>(null);

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
      await ClipboardHistoryEntryRepository().deleteFromLocalDb(id);
    }
    await rebuildLocal();
  }

  RxList<ClipboardHistoryEntryDataItem> registerFilterSubscription({
    required String filterKey,
    List<DataItemFilter> filters = const [],
  }) {
    final existing = _dynamicSubscription[filterKey];
    if (existing != null && listEquals(existing.appliedFilters, filters)) {
      return existing.filteredList;
    }
    final newList = _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .toList()
        .obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (
      List<ClipboardHistoryEntryDataItem> value,
    ) {
      final newFiltered = value
          .where((item) => filters.every((filter) => filter.apply(item)))
          .toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] =
        _ClipboardHistoryEntryDataItemFilterSubscription(
          newList,
          filters,
          worker,
        );
    return newList;
  }

  void unregisterFilterSubscription(String filterKey) {
    final sub = _dynamicSubscription.remove(filterKey);
    sub?.worker.dispose();
  }

  Future<void> rebuildLocal() async {
    _items.value = await ClipboardHistoryEntryRepository().listFromLocalDb();
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void onSelectClipboardHistoryEntry(String id) {
    currentClipboardHistoryEntryId.value = id;
  }

  DataItem<ClipboardHistoryEntry>? getClipboardHistoryEntry(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  List<T> getClipboardHistoryEntryDetails<T>({
    List<DataItemFilter> filters = const [],
    required T Function(ClipboardHistoryEntryDataItem item) selector,
  }) {
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .map(selector)
        .toList();
  }

  int getClipboardHistoryEntryCount<T>({
    List<DataItemFilter> filters = const [],
  }) {
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .length;
  }

  Future<void> syncAll({int batchSize = 20}) async {
    await _syncEngine.syncAllData(batchSize: batchSize);
  }

  Future<void> syncChildren(String parentId, {int batchSize = 20}) async {
    await _syncEngine.syncChildrenBatch([parentId], batchSize: batchSize);
  }

  Future<void> syncMultiChildren(
    List<String> parentIds, {
    int batchSize = 20,
  }) async {
    await _syncEngine.syncChildrenBatch(parentIds, batchSize: batchSize);
  }

  Future<void> syncOwned() async {
    await _syncEngine.syncOwned();
  }

  Future<void> syncGranted() async {
    await _syncEngine.syncGranted();
  }

  void _replaceLocal(String id, ClipboardHistoryEntryDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    if (currentClipboardHistoryEntryId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentClipboardHistoryEntryId.value = fetchedItem.id;
    }
  }

  void addData(ClipboardHistoryEntry newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = ClipboardHistoryEntryDataItem.localNew(owner, newData);
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _syncEngine.create(newItem).then((fetchedItem) {
      _replaceLocal(newItem.id, fetchedItem);
    });
  }

  void updateData(String id, ClipboardHistoryEntry updatedData) {
    final item = _items.firstWhere((item) => item.id == id);
    // todo maybe rewrite this update body method...
    final updatedItem = item.updatedBody(updatedData);
    _items[_items.indexOf(item)] = updatedItem;
    _syncEngine.update(updatedItem).then((fetchedItem) {
      _replaceLocal(updatedItem.id, fetchedItem);
    });
  }

  void onUpdateLocalField(
    String id, {
    ColorTag? colorTag,
    SyncStatus? syncStatus,
  }) {
    final item = _items.firstWhere((item) => item.id == id);
    if (colorTag != null) {
      item.colorTag = colorTag;
    }
    if (syncStatus != null) {
      item.syncStatus = syncStatus;
    }
    ClipboardHistoryEntryRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentClipboardHistoryEntryId.value == id) {
      currentClipboardHistoryEntryId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    _syncEngine.delete(
      id,
      deleteFromServer ? true : status != SyncStatus.deleted,
    );
  }
}

class _ClipboardHistoryEntrySyncEngine {
  final SyncStoreClient client;
  _ClipboardHistoryEntrySyncEngine(this.client);

  Future<ClipboardHistoryEntryDataItem> create(
    ClipboardHistoryEntryDataItem local,
  ) async {
    local.syncStatus = SyncStatus.syncing;
    await ClipboardHistoryEntryRepository().addToLocalDb(local);

    ClipboardHistoryEntryDataItem createdItem;
    try {
      final newId = await client.create(
        'clipboard_history',
        'entry',
        local.body.toSyncJson(),
      );
      createdItem = await client.get<ClipboardHistoryEntry>(
        'clipboard_history',
        'entry',
        newId,
        ClipboardHistoryEntry.fromRemoteJson,
      );
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await ClipboardHistoryEntryRepository().updateToLocalDb(local);
      rethrow;
    }
    createdItem.syncStatus = SyncStatus.archived;
    createdItem.colorTag = local.colorTag;

    await ClipboardHistoryEntryRepository().deleteFromLocalDb(local.id);
    await ClipboardHistoryEntryRepository().addToLocalDb(createdItem);
    return createdItem;
  }

  Future<ClipboardHistoryEntryDataItem> update(
    ClipboardHistoryEntryDataItem local,
  ) async {
    local.syncStatus = SyncStatus.syncing;
    await ClipboardHistoryEntryRepository().updateToLocalDb(local);

    ClipboardHistoryEntryDataItem updatedItem;
    try {
      await client.update(
        'clipboard_history',
        'entry',
        local.id,
        local.body.toSyncJson(),
      );
      updatedItem = await client.get<ClipboardHistoryEntry>(
        'clipboard_history',
        'entry',
        local.id,
        ClipboardHistoryEntry.fromRemoteJson,
      );
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await ClipboardHistoryEntryRepository().updateToLocalDb(local);
      rethrow;
    }
    updatedItem.syncStatus = SyncStatus.archived;
    updatedItem.colorTag = local.colorTag;

    await ClipboardHistoryEntryRepository().updateToLocalDb(updatedItem);
    return updatedItem;
  }

  void delete(String id, bool deleteFromServer) {
    ClipboardHistoryEntryRepository().deleteFromLocalDb(id);
    if (!deleteFromServer) return;
    try {
      client.delete('clipboard_history', 'entry', id);
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
          'clipboard_history',
          'entry',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ClipboardHistoryEntryDataItem? localItem =
              await ClipboardHistoryEntryRepository().getFromLocalDb(
                summary.id,
              );
          if (localItem == null ||
              localItem.updatedAt.isBefore(summary.updatedAt)) {
            // only get details for new created or updated items, otherwise just skip to save performance.
            needGetIds.add(summary.id);
          } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
            // local data is newer, need to sync to server
            localItem.syncStatus = SyncStatus.failed;
            await ClipboardHistoryEntryRepository().updateToLocalDb(localItem);
          } else if (localItem.syncStatus == SyncStatus.deleted ||
              localItem.syncStatus == SyncStatus.hidden) {
            // same updatedAt but marked as special status, need to sync to server
            localItem.syncStatus = SyncStatus.archived;
            await ClipboardHistoryEntryRepository().updateToLocalDb(localItem);
          }
        }
      } while (nextMarker != null);
      // 2. clean up local data that are deleted from server
      final localItems = await ClipboardHistoryEntryRepository()
          .listFromLocalDb();
      for (ClipboardHistoryEntryDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ClipboardHistoryEntryRepository().updateToLocalDb(localItem);
        }
      }

      // 3. batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet(
          'clipboard_history',
          'entry',
          batchIds,
          ClipboardHistoryEntry.fromRemoteJson,
        );
        for (var item in batchItems.items) {
          await ClipboardHistoryEntryRepository().upsertToLocalDb(item);
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

  Future<void> syncChildrenBatch(
    List<String> parentIds, {
    int batchSize = 20,
  }) async {
    try {
      final needGetIds = <String>{};
      final serviceIds = <String>{};
      for (var i = 0; i < parentIds.length; i += 100) {
        final parentIdsBatch = parentIds.skip(i).take(100).toList();
        String? nextMarker;
        do {
          final ListResponse resp = await client.batchListChildren(
            'clipboard_history',
            'entry',
            parentIdsBatch,
            marker: nextMarker,
          );
          nextMarker = resp.pageInfo.nextMarker;
          for (var summary in resp.items) {
            serviceIds.add(summary.id);
            final ClipboardHistoryEntryDataItem? localItem =
                await ClipboardHistoryEntryRepository().getFromLocalDb(
                  summary.id,
                );
            if (localItem == null ||
                localItem.updatedAt.isBefore(summary.updatedAt)) {
              // only get details for new created or updated items, otherwise just skip to save performance.
              needGetIds.add(summary.id);
            } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
              // local data is newer, need to sync to server
              localItem.syncStatus = SyncStatus.failed;
              await ClipboardHistoryEntryRepository().updateToLocalDb(
                localItem,
              );
            } else if (localItem.syncStatus == SyncStatus.deleted ||
                localItem.syncStatus == SyncStatus.hidden) {
              // same updatedAt but marked as special status, need to sync to server
              localItem.syncStatus = SyncStatus.archived;
              await ClipboardHistoryEntryRepository().updateToLocalDb(
                localItem,
              );
            }
          }
        } while (nextMarker != null);
      }
      // clean up local data that are deleted from server
      final localItems = await ClipboardHistoryEntryRepository()
          .listFromLocalDb();
      for (ClipboardHistoryEntryDataItem localItem in localItems) {
        if (localItem.parentId == null ||
            !parentIds.contains(localItem.parentId!)) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ClipboardHistoryEntryRepository().updateToLocalDb(localItem);
        }
      }
      // batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet(
          'clipboard_history',
          'entry',
          batchIds,
          ClipboardHistoryEntry.fromRemoteJson,
        );
        for (var item in batchItems.items) {
          await ClipboardHistoryEntryRepository().upsertToLocalDb(item);
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
        final ListResponse resp = await client.list(
          'clipboard_history',
          'entry',
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ClipboardHistoryEntryDataItem? localItem =
              await ClipboardHistoryEntryRepository().getFromLocalDb(
                summary.id,
              );
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await ClipboardHistoryEntryRepository()
          .listFromLocalDb();
      for (ClipboardHistoryEntryDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ClipboardHistoryEntryRepository().updateToLocalDb(localItem);
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
          'clipboard_history',
          'entry',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ClipboardHistoryEntryDataItem? localItem =
              await ClipboardHistoryEntryRepository().getFromLocalDb(
                summary.id,
              );
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await ClipboardHistoryEntryRepository()
          .listFromLocalDb();
      for (ClipboardHistoryEntryDataItem localItem in localItems) {
        if (localItem.owner == currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.hidden;
          await ClipboardHistoryEntryRepository().updateToLocalDb(localItem);
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
          'clipboard_history',
          'entry',
          parentId: parentId,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ClipboardHistoryEntryDataItem? localItem =
              await ClipboardHistoryEntryRepository().getFromLocalDb(
                summary.id,
              );
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await ClipboardHistoryEntryRepository()
          .listFromLocalDb(parentId: parentId);
      for (ClipboardHistoryEntryDataItem localItem in localItems) {
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ClipboardHistoryEntryRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> _compareRemote(
    ClipboardHistoryEntryDataItem? localItem,
    DataItemSummary summary,
  ) async {
    if (localItem == null) {
      // new from server
      final ClipboardHistoryEntryDataItem item = await client
          .get<ClipboardHistoryEntry>(
            'clipboard_history',
            'entry',
            summary.id,
            ClipboardHistoryEntry.fromRemoteJson,
          );
      await ClipboardHistoryEntryRepository().addToLocalDb(item);
    } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
      // update local data.
      final ClipboardHistoryEntryDataItem item = await client
          .get<ClipboardHistoryEntry>(
            'clipboard_history',
            'entry',
            summary.id,
            ClipboardHistoryEntry.fromRemoteJson,
          );
      await ClipboardHistoryEntryRepository().updateToLocalDb(item);
    } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
      // local data is newer, need to sync to server
      localItem.syncStatus = SyncStatus.failed;
      await ClipboardHistoryEntryRepository().updateToLocalDb(localItem);
    } else if (localItem.syncStatus == SyncStatus.deleted ||
        localItem.syncStatus == SyncStatus.hidden) {
      // same updatedAt but marked as special status, need to sync to server
      localItem.syncStatus = SyncStatus.archived;
      await ClipboardHistoryEntryRepository().updateToLocalDb(localItem);
    }
  }
}
