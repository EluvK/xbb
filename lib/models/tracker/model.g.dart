// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Tracker _$TrackerFromJson(Map<String, dynamic> json) => _Tracker(
  name: json['name'] as String,
  description: json['description'] as String,
  category: json['category'] as String,
  type: json['type'] as String,
  config: TrackerConfig.fromJson(json['config'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TrackerToJson(_Tracker instance) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'category': instance.category,
  'type': instance.type,
  'config': instance.config,
};

EventTrackerConfig _$EventTrackerConfigFromJson(Map<String, dynamic> json) =>
    EventTrackerConfig(periodDays: (json['period_days'] as num).toInt(), $type: json['type'] as String?);

Map<String, dynamic> _$EventTrackerConfigToJson(EventTrackerConfig instance) => <String, dynamic>{
  'period_days': instance.periodDays,
  'type': instance.$type,
};

MilestoneTrackerConfig _$MilestoneTrackerConfigFromJson(Map<String, dynamic> json) => MilestoneTrackerConfig(
  goalType: json['goal_type'] as String,
  targetValue: json['target_value'] as String,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$MilestoneTrackerConfigToJson(MilestoneTrackerConfig instance) => <String, dynamic>{
  'goal_type': instance.goalType,
  'target_value': instance.targetValue,
  'type': instance.$type,
};

AnniversaryTrackerConfig _$AnniversaryTrackerConfigFromJson(Map<String, dynamic> json) => AnniversaryTrackerConfig(
  baseDate: DateTime.parse(json['base_date'] as String),
  isLunar: json['is_lunar'] as bool,
  remindType: json['remind_type'] as String,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$AnniversaryTrackerConfigToJson(AnniversaryTrackerConfig instance) => <String, dynamic>{
  'base_date': instance.baseDate.toIso8601String(),
  'is_lunar': instance.isLunar,
  'remind_type': instance.remindType,
  'type': instance.$type,
};

_TrackerRecord _$TrackerRecordFromJson(Map<String, dynamic> json) => _TrackerRecord(
  trackerId: json['tracker_id'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  value: json['value'] as String?,
  content: json['content'] as String?,
);

Map<String, dynamic> _$TrackerRecordToJson(_TrackerRecord instance) => <String, dynamic>{
  'tracker_id': instance.trackerId,
  'timestamp': instance.timestamp.toIso8601String(),
  'value': instance.value,
  'content': instance.content,
};

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

extension LocalStoreTracker on Tracker {
  static String get tableName => 'tracker';

  static String get onCreateTableTrackerSQL =>
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
    return await TrackerDB().getDb();
  }
}

typedef TrackerDataItem = DataItem<Tracker>;

class TrackerRepository {
  Future<void> addToLocalDb(TrackerDataItem item) async {
    final db = await LocalStoreTracker.getDb();
    await db.insert(LocalStoreTracker.tableName, item.toJson((r) => json.encode(r.toJson())));
  }

  Future<TrackerDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreTracker.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreTracker.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<Tracker>.fromJson(maps.first, (jsonStr) => Tracker.fromJson(json.decode(jsonStr as String)));
    }
    return null;
  }

  Future<List<TrackerDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStoreTracker.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreTracker.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps
        .map((map) => DataItem<Tracker>.fromJson(map, (jsonStr) => Tracker.fromJson(json.decode(jsonStr as String))))
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreTracker.getDb();
    await db.delete(LocalStoreTracker.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToLocalDb(TrackerDataItem item) async {
    final db = await LocalStoreTracker.getDb();
    await db.update(
      LocalStoreTracker.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(TrackerDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}

class _TrackerDataItemFilterSubscription {
  final RxList<TrackerDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _TrackerDataItemFilterSubscription(this.filteredList, this.appliedFilters, this.worker);
}

class TrackerController extends GetxController {
  final SyncStoreClient client;
  final _TrackerSyncEngine _syncEngine;
  TrackerController(this.client) : _syncEngine = _TrackerSyncEngine(client);

  final RxList<TrackerDataItem> _items = <TrackerDataItem>[].obs;
  final RxMap<String, List<Permission>> _aclCache = <String, List<Permission>>{}.obs;
  final Map<String, _TrackerDataItemFilterSubscription> _dynamicSubscription = {};
  final Rx<String?> currentTrackerId = Rx<String?>(null);

  @override
  Future<void> onInit() async {
    await rebuildLocal();
    // preload ACLs for all items to make sure UI can get ACL info immediately
    // this can be optimized by only load ACL when needed and cache it.
    for (var item in _items) {
      await getAclLocal(item.id);
    }
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
      await TrackerRepository().deleteFromLocalDb(id);
    }
    await rebuildLocal();
  }

  RxList<TrackerDataItem> registerFilterSubscription({
    required String filterKey,
    List<DataItemFilter> filters = const [],
  }) {
    final existing = _dynamicSubscription[filterKey];
    if (existing != null && listEquals(existing.appliedFilters, filters)) {
      return existing.filteredList;
    }
    final newList = _items.where((item) => filters.every((filter) => filter.apply(item))).toList().obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<TrackerDataItem> value) {
      final newFiltered = value.where((item) => filters.every((filter) => filter.apply(item))).toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _TrackerDataItemFilterSubscription(newList, filters, worker);
    return newList;
  }

  void unregisterFilterSubscription(String filterKey) {
    final sub = _dynamicSubscription.remove(filterKey);
    sub?.worker.dispose();
  }

  Future<void> rebuildLocal() async {
    _items.value = await TrackerRepository().listFromLocalDb();
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void onSelectTracker(String id) {
    currentTrackerId.value = id;
  }

  DataItem<Tracker>? getTracker(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  List<T> getTrackerDetails<T>({
    List<DataItemFilter> filters = const [],
    required T Function(TrackerDataItem item) selector,
  }) {
    return _items.where((item) => filters.every((filter) => filter.apply(item))).map(selector).toList();
  }

  int getTrackerCount<T>({List<DataItemFilter> filters = const []}) {
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

  void _replaceLocal(String id, TrackerDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    if (currentTrackerId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentTrackerId.value = fetchedItem.id;
    }
  }

  void addData(Tracker newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = TrackerDataItem.localNew(owner, newData);
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _syncEngine.create(newItem).then((fetchedItem) {
      _replaceLocal(newItem.id, fetchedItem);
    });
  }

  void updateData(String id, Tracker updatedData) {
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
    TrackerRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentTrackerId.value == id) {
      currentTrackerId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    _syncEngine.delete(id, deleteFromServer ? true : status != SyncStatus.deleted);
  }
}

extension TrackerRepositoryAcl on TrackerRepository {
  static String get tableNameAcl => 'acl';
  Future<List<Permission>> getAcls(String dataId) async {
    final db = await LocalStoreTracker.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      tableNameAcl,
      where: 'data_id = ? AND data_collection = ?',
      whereArgs: [dataId, 'tracker'],
    );
    if (maps.isEmpty) {
      return [];
    }
    final permissionsJson = maps.first['permissions'] as String;
    final List<dynamic> permissionsList = json.decode(permissionsJson) as List<dynamic>;
    return permissionsList.map((e) => Permission.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> setAcls(String dataId, List<Permission> permissions) async {
    final db = await LocalStoreTracker.getDb();
    final permissionsJson = json.encode(permissions.map((e) => e.toJson()).toList());
    await db.insert(tableNameAcl, {
      'data_id': dataId,
      'data_collection': 'tracker',
      'permissions': permissionsJson,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

extension TrackerControllerAcl on TrackerController {
  Future<void> syncAcls() async {
    try {
      for (var item in _items) {
        final serviceAcls = await client.getAcls('tracker', 'tracker', item.id);
        await TrackerRepository().setAcls(item.id, serviceAcls);
        _aclCache[item.id] = serviceAcls;
      }
    } catch (e) {
      print("Error syncing ACLs: $e");
    }
  }

  Future<List<Permission>> getAclLocal(String dataId) async {
    final localAcls = await TrackerRepository().getAcls(dataId);
    _aclCache[dataId] = localAcls;
    return localAcls;
  }

  List<Permission> getAclCached(String dataId) => _aclCache[dataId] ?? [];
  Future<List<Permission>> getAclRefresh(String dataId) async {
    try {
      final List<Permission> getAcls = await client.getAcls('tracker', 'tracker', dataId);
      await TrackerRepository().setAcls(dataId, getAcls);
      _aclCache[dataId] = getAcls;
      return getAcls;
    } catch (e) {
      print("Error fetching ACLs from server: $e");
      return await TrackerRepository().getAcls(dataId);
    }
  }

  Future<void> setAcls(String dataId, List<Permission> permissions) async {
    try {
      await client.updateAcls('tracker', 'tracker', dataId, permissions);
      await TrackerRepository().setAcls(dataId, permissions);
      _aclCache[dataId] = permissions;
    } catch (e) {
      print("Error updating ACLs to server: $e");
    }
  }
}

class _TrackerSyncEngine {
  final SyncStoreClient client;
  _TrackerSyncEngine(this.client);

  Future<TrackerDataItem> create(TrackerDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await TrackerRepository().addToLocalDb(local);

    TrackerDataItem createdItem;
    try {
      final newId = await client.create('tracker', 'tracker', local.body.toJson());
      createdItem = await client.get<Tracker>('tracker', 'tracker', newId, Tracker.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await TrackerRepository().updateToLocalDb(local);
      rethrow;
    }
    createdItem.syncStatus = SyncStatus.archived;
    createdItem.colorTag = local.colorTag;

    await TrackerRepository().deleteFromLocalDb(local.id);
    await TrackerRepository().addToLocalDb(createdItem);
    return createdItem;
  }

  Future<TrackerDataItem> update(TrackerDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await TrackerRepository().updateToLocalDb(local);

    TrackerDataItem updatedItem;
    try {
      await client.update('tracker', 'tracker', local.id, local.body.toJson());
      updatedItem = await client.get<Tracker>('tracker', 'tracker', local.id, Tracker.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await TrackerRepository().updateToLocalDb(local);
      rethrow;
    }
    updatedItem.syncStatus = SyncStatus.archived;
    updatedItem.colorTag = local.colorTag;

    await TrackerRepository().updateToLocalDb(updatedItem);
    return updatedItem;
  }

  void delete(String id, bool deleteFromServer) {
    TrackerRepository().deleteFromLocalDb(id);
    if (!deleteFromServer) return;
    try {
      client.delete('tracker', 'tracker', id);
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
          'tracker',
          'tracker',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final TrackerDataItem? localItem = await TrackerRepository().getFromLocalDb(summary.id);
          if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
            // only get details for new created or updated items, otherwise just skip to save performance.
            needGetIds.add(summary.id);
          } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
            // local data is newer, need to sync to server
            localItem.syncStatus = SyncStatus.failed;
            await TrackerRepository().updateToLocalDb(localItem);
          } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
            // same updatedAt but marked as special status, need to sync to server
            localItem.syncStatus = SyncStatus.archived;
            await TrackerRepository().updateToLocalDb(localItem);
          }
        }
      } while (nextMarker != null);
      // 2. clean up local data that are deleted from server
      final localItems = await TrackerRepository().listFromLocalDb();
      for (TrackerDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await TrackerRepository().updateToLocalDb(localItem);
        }
      }

      // 3. batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('tracker', 'tracker', batchIds, Tracker.fromJson);
        for (var item in batchItems.items) {
          await TrackerRepository().upsertToLocalDb(item);
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
            'tracker',
            'tracker',
            parentIdsBatch,
            marker: nextMarker,
          );
          nextMarker = resp.pageInfo.nextMarker;
          for (var summary in resp.items) {
            serviceIds.add(summary.id);
            final TrackerDataItem? localItem = await TrackerRepository().getFromLocalDb(summary.id);
            if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
              // only get details for new created or updated items, otherwise just skip to save performance.
              needGetIds.add(summary.id);
            } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
              // local data is newer, need to sync to server
              localItem.syncStatus = SyncStatus.failed;
              await TrackerRepository().updateToLocalDb(localItem);
            } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
              // same updatedAt but marked as special status, need to sync to server
              localItem.syncStatus = SyncStatus.archived;
              await TrackerRepository().updateToLocalDb(localItem);
            }
          }
        } while (nextMarker != null);
      }
      // clean up local data that are deleted from server
      final localItems = await TrackerRepository().listFromLocalDb();
      for (TrackerDataItem localItem in localItems) {
        if (localItem.parentId == null || !parentIds.contains(localItem.parentId!)) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await TrackerRepository().updateToLocalDb(localItem);
        }
      }
      // batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('tracker', 'tracker', batchIds, Tracker.fromJson);
        for (var item in batchItems.items) {
          await TrackerRepository().upsertToLocalDb(item);
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
        final ListResponse resp = await client.list('tracker', 'tracker', limit: 200, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final TrackerDataItem? localItem = await TrackerRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await TrackerRepository().listFromLocalDb();
      for (TrackerDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await TrackerRepository().updateToLocalDb(localItem);
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
          'tracker',
          'tracker',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final TrackerDataItem? localItem = await TrackerRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await TrackerRepository().listFromLocalDb();
      for (TrackerDataItem localItem in localItems) {
        if (localItem.owner == currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.hidden;
          await TrackerRepository().updateToLocalDb(localItem);
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
          'tracker',
          'tracker',
          parentId: parentId,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final TrackerDataItem? localItem = await TrackerRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await TrackerRepository().listFromLocalDb(parentId: parentId);
      for (TrackerDataItem localItem in localItems) {
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await TrackerRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> _compareRemote(TrackerDataItem? localItem, DataItemSummary summary) async {
    if (localItem == null) {
      // new from server
      final TrackerDataItem item = await client.get<Tracker>('tracker', 'tracker', summary.id, Tracker.fromJson);
      await TrackerRepository().addToLocalDb(item);
    } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
      // update local data.
      final TrackerDataItem item = await client.get<Tracker>('tracker', 'tracker', summary.id, Tracker.fromJson);
      await TrackerRepository().updateToLocalDb(item);
    } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
      // local data is newer, need to sync to server
      localItem.syncStatus = SyncStatus.failed;
      await TrackerRepository().updateToLocalDb(localItem);
    } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
      // same updatedAt but marked as special status, need to sync to server
      localItem.syncStatus = SyncStatus.archived;
      await TrackerRepository().updateToLocalDb(localItem);
    }
  }
}

extension LocalStoreTrackerRecord on TrackerRecord {
  static String get tableName => 'record';

  static String get onCreateTableTrackerRecordSQL =>
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
    return await TrackerDB().getDb();
  }
}

typedef TrackerRecordDataItem = DataItem<TrackerRecord>;

class TrackerRecordRepository {
  Future<void> addToLocalDb(TrackerRecordDataItem item) async {
    final db = await LocalStoreTrackerRecord.getDb();
    await db.insert(LocalStoreTrackerRecord.tableName, item.toJson((r) => json.encode(r.toJson())));
  }

  Future<TrackerRecordDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreTrackerRecord.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreTrackerRecord.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<TrackerRecord>.fromJson(
        maps.first,
        (jsonStr) => TrackerRecord.fromJson(json.decode(jsonStr as String)),
      );
    }
    return null;
  }

  Future<List<TrackerRecordDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStoreTrackerRecord.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreTrackerRecord.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps
        .map(
          (map) => DataItem<TrackerRecord>.fromJson(
            map,
            (jsonStr) => TrackerRecord.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreTrackerRecord.getDb();
    await db.delete(LocalStoreTrackerRecord.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToLocalDb(TrackerRecordDataItem item) async {
    final db = await LocalStoreTrackerRecord.getDb();
    await db.update(
      LocalStoreTrackerRecord.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(TrackerRecordDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}

class _TrackerRecordDataItemFilterSubscription {
  final RxList<TrackerRecordDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _TrackerRecordDataItemFilterSubscription(this.filteredList, this.appliedFilters, this.worker);
}

class TrackerRecordController extends GetxController {
  final SyncStoreClient client;
  final _TrackerRecordSyncEngine _syncEngine;
  TrackerRecordController(this.client) : _syncEngine = _TrackerRecordSyncEngine(client);

  final RxList<TrackerRecordDataItem> _items = <TrackerRecordDataItem>[].obs;

  final Map<String, _TrackerRecordDataItemFilterSubscription> _dynamicSubscription = {};
  final Rx<String?> currentTrackerRecordId = Rx<String?>(null);

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
      await TrackerRecordRepository().deleteFromLocalDb(id);
    }
    await rebuildLocal();
  }

  RxList<TrackerRecordDataItem> registerFilterSubscription({
    required String filterKey,
    List<DataItemFilter> filters = const [],
  }) {
    final existing = _dynamicSubscription[filterKey];
    if (existing != null && listEquals(existing.appliedFilters, filters)) {
      return existing.filteredList;
    }
    final newList = _items.where((item) => filters.every((filter) => filter.apply(item))).toList().obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<TrackerRecordDataItem> value) {
      final newFiltered = value.where((item) => filters.every((filter) => filter.apply(item))).toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _TrackerRecordDataItemFilterSubscription(newList, filters, worker);
    return newList;
  }

  void unregisterFilterSubscription(String filterKey) {
    final sub = _dynamicSubscription.remove(filterKey);
    sub?.worker.dispose();
  }

  Future<void> rebuildLocal() async {
    _items.value = await TrackerRecordRepository().listFromLocalDb();
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void onSelectTrackerRecord(String id) {
    currentTrackerRecordId.value = id;
  }

  DataItem<TrackerRecord>? getTrackerRecord(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  List<T> getTrackerRecordDetails<T>({
    List<DataItemFilter> filters = const [],
    required T Function(TrackerRecordDataItem item) selector,
  }) {
    return _items.where((item) => filters.every((filter) => filter.apply(item))).map(selector).toList();
  }

  int getTrackerRecordCount<T>({List<DataItemFilter> filters = const []}) {
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

  void _replaceLocal(String id, TrackerRecordDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    if (currentTrackerRecordId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentTrackerRecordId.value = fetchedItem.id;
    }
  }

  void addData(TrackerRecord newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = TrackerRecordDataItem.localNew(owner, newData);
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _syncEngine.create(newItem).then((fetchedItem) {
      _replaceLocal(newItem.id, fetchedItem);
    });
  }

  void updateData(String id, TrackerRecord updatedData) {
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
    TrackerRecordRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentTrackerRecordId.value == id) {
      currentTrackerRecordId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    _syncEngine.delete(id, deleteFromServer ? true : status != SyncStatus.deleted);
  }
}

class _TrackerRecordSyncEngine {
  final SyncStoreClient client;
  _TrackerRecordSyncEngine(this.client);

  Future<TrackerRecordDataItem> create(TrackerRecordDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await TrackerRecordRepository().addToLocalDb(local);

    TrackerRecordDataItem createdItem;
    try {
      final newId = await client.create('tracker', 'record', local.body.toJson());
      createdItem = await client.get<TrackerRecord>('tracker', 'record', newId, TrackerRecord.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await TrackerRecordRepository().updateToLocalDb(local);
      rethrow;
    }
    createdItem.syncStatus = SyncStatus.archived;
    createdItem.colorTag = local.colorTag;

    await TrackerRecordRepository().deleteFromLocalDb(local.id);
    await TrackerRecordRepository().addToLocalDb(createdItem);
    return createdItem;
  }

  Future<TrackerRecordDataItem> update(TrackerRecordDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await TrackerRecordRepository().updateToLocalDb(local);

    TrackerRecordDataItem updatedItem;
    try {
      await client.update('tracker', 'record', local.id, local.body.toJson());
      updatedItem = await client.get<TrackerRecord>('tracker', 'record', local.id, TrackerRecord.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await TrackerRecordRepository().updateToLocalDb(local);
      rethrow;
    }
    updatedItem.syncStatus = SyncStatus.archived;
    updatedItem.colorTag = local.colorTag;

    await TrackerRecordRepository().updateToLocalDb(updatedItem);
    return updatedItem;
  }

  void delete(String id, bool deleteFromServer) {
    TrackerRecordRepository().deleteFromLocalDb(id);
    if (!deleteFromServer) return;
    try {
      client.delete('tracker', 'record', id);
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
          'tracker',
          'record',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final TrackerRecordDataItem? localItem = await TrackerRecordRepository().getFromLocalDb(summary.id);
          if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
            // only get details for new created or updated items, otherwise just skip to save performance.
            needGetIds.add(summary.id);
          } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
            // local data is newer, need to sync to server
            localItem.syncStatus = SyncStatus.failed;
            await TrackerRecordRepository().updateToLocalDb(localItem);
          } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
            // same updatedAt but marked as special status, need to sync to server
            localItem.syncStatus = SyncStatus.archived;
            await TrackerRecordRepository().updateToLocalDb(localItem);
          }
        }
      } while (nextMarker != null);
      // 2. clean up local data that are deleted from server
      final localItems = await TrackerRecordRepository().listFromLocalDb();
      for (TrackerRecordDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await TrackerRecordRepository().updateToLocalDb(localItem);
        }
      }

      // 3. batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('tracker', 'record', batchIds, TrackerRecord.fromJson);
        for (var item in batchItems.items) {
          await TrackerRecordRepository().upsertToLocalDb(item);
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
            'tracker',
            'record',
            parentIdsBatch,
            marker: nextMarker,
          );
          nextMarker = resp.pageInfo.nextMarker;
          for (var summary in resp.items) {
            serviceIds.add(summary.id);
            final TrackerRecordDataItem? localItem = await TrackerRecordRepository().getFromLocalDb(summary.id);
            if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
              // only get details for new created or updated items, otherwise just skip to save performance.
              needGetIds.add(summary.id);
            } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
              // local data is newer, need to sync to server
              localItem.syncStatus = SyncStatus.failed;
              await TrackerRecordRepository().updateToLocalDb(localItem);
            } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
              // same updatedAt but marked as special status, need to sync to server
              localItem.syncStatus = SyncStatus.archived;
              await TrackerRecordRepository().updateToLocalDb(localItem);
            }
          }
        } while (nextMarker != null);
      }
      // clean up local data that are deleted from server
      final localItems = await TrackerRecordRepository().listFromLocalDb();
      for (TrackerRecordDataItem localItem in localItems) {
        if (localItem.parentId == null || !parentIds.contains(localItem.parentId!)) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await TrackerRecordRepository().updateToLocalDb(localItem);
        }
      }
      // batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('tracker', 'record', batchIds, TrackerRecord.fromJson);
        for (var item in batchItems.items) {
          await TrackerRecordRepository().upsertToLocalDb(item);
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
        final ListResponse resp = await client.list('tracker', 'record', limit: 200, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final TrackerRecordDataItem? localItem = await TrackerRecordRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await TrackerRecordRepository().listFromLocalDb();
      for (TrackerRecordDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await TrackerRecordRepository().updateToLocalDb(localItem);
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
          'tracker',
          'record',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final TrackerRecordDataItem? localItem = await TrackerRecordRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await TrackerRecordRepository().listFromLocalDb();
      for (TrackerRecordDataItem localItem in localItems) {
        if (localItem.owner == currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.hidden;
          await TrackerRecordRepository().updateToLocalDb(localItem);
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
          'tracker',
          'record',
          parentId: parentId,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final TrackerRecordDataItem? localItem = await TrackerRecordRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await TrackerRecordRepository().listFromLocalDb(parentId: parentId);
      for (TrackerRecordDataItem localItem in localItems) {
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await TrackerRecordRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> _compareRemote(TrackerRecordDataItem? localItem, DataItemSummary summary) async {
    if (localItem == null) {
      // new from server
      final TrackerRecordDataItem item = await client.get<TrackerRecord>(
        'tracker',
        'record',
        summary.id,
        TrackerRecord.fromJson,
      );
      await TrackerRecordRepository().addToLocalDb(item);
    } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
      // update local data.
      final TrackerRecordDataItem item = await client.get<TrackerRecord>(
        'tracker',
        'record',
        summary.id,
        TrackerRecord.fromJson,
      );
      await TrackerRecordRepository().updateToLocalDb(item);
    } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
      // local data is newer, need to sync to server
      localItem.syncStatus = SyncStatus.failed;
      await TrackerRecordRepository().updateToLocalDb(localItem);
    } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
      // same updatedAt but marked as special status, need to sync to server
      localItem.syncStatus = SyncStatus.archived;
      await TrackerRecordRepository().updateToLocalDb(localItem);
    }
  }
}
