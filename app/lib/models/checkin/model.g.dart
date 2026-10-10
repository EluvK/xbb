// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CheckinEvent _$CheckinEventFromJson(Map<String, dynamic> json) => _CheckinEvent(
  name: json['name'] as String,
  description: json['description'] as String,
  colorValue: (json['color_value'] as num).toInt(),
);

Map<String, dynamic> _$CheckinEventToJson(_CheckinEvent instance) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'color_value': instance.colorValue,
};

_CheckinRecord _$CheckinRecordFromJson(Map<String, dynamic> json) => _CheckinRecord(
  eventId: json['event_id'] as String,
  createdAtUtc: DateTime.parse(json['created_at_utc'] as String),
  localDayKey: json['local_day_key'] as String,
  timezoneOffsetMinutes: (json['timezone_offset_minutes'] as num?)?.toInt() ?? 0,
  note: json['note'] as String?,
);

Map<String, dynamic> _$CheckinRecordToJson(_CheckinRecord instance) => <String, dynamic>{
  'event_id': instance.eventId,
  'created_at_utc': instance.createdAtUtc.toIso8601String(),
  'local_day_key': instance.localDayKey,
  'timezone_offset_minutes': instance.timezoneOffsetMinutes,
  'note': instance.note,
};

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

extension LocalStoreCheckinEvent on CheckinEvent {
  static String get tableName => 'event';

  static String get onCreateTableCheckinEventSQL =>
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
    return await CheckinDB().getDb();
  }
}

typedef CheckinEventDataItem = DataItem<CheckinEvent>;

class CheckinEventRepository {
  Future<void> addToLocalDb(CheckinEventDataItem item) async {
    final db = await LocalStoreCheckinEvent.getDb();
    await db.insert(LocalStoreCheckinEvent.tableName, item.toJson((r) => json.encode(r.toJson())));
  }

  Future<CheckinEventDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreCheckinEvent.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreCheckinEvent.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<CheckinEvent>.fromJson(
        maps.first,
        (jsonStr) => CheckinEvent.fromJson(json.decode(jsonStr as String)),
      );
    }
    return null;
  }

  Future<List<CheckinEventDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStoreCheckinEvent.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreCheckinEvent.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps
        .map(
          (map) =>
              DataItem<CheckinEvent>.fromJson(map, (jsonStr) => CheckinEvent.fromJson(json.decode(jsonStr as String))),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreCheckinEvent.getDb();
    await db.delete(LocalStoreCheckinEvent.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToLocalDb(CheckinEventDataItem item) async {
    final db = await LocalStoreCheckinEvent.getDb();
    await db.update(
      LocalStoreCheckinEvent.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(CheckinEventDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}

class _CheckinEventDataItemFilterSubscription {
  final RxList<CheckinEventDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _CheckinEventDataItemFilterSubscription(this.filteredList, this.appliedFilters, this.worker);
}

class CheckinEventController extends GetxController {
  final SyncStoreClient client;
  final _CheckinEventSyncEngine _syncEngine;
  CheckinEventController(this.client) : _syncEngine = _CheckinEventSyncEngine(client);

  final RxList<CheckinEventDataItem> _items = <CheckinEventDataItem>[].obs;

  final Map<String, _CheckinEventDataItemFilterSubscription> _dynamicSubscription = {};
  final Rx<String?> currentCheckinEventId = Rx<String?>(null);

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
      await CheckinEventRepository().deleteFromLocalDb(id);
    }
    await rebuildLocal();
  }

  RxList<CheckinEventDataItem> registerFilterSubscription({
    required String filterKey,
    List<DataItemFilter> filters = const [],
  }) {
    final existing = _dynamicSubscription[filterKey];
    if (existing != null && listEquals(existing.appliedFilters, filters)) {
      return existing.filteredList;
    }
    final newList = _items.where((item) => filters.every((filter) => filter.apply(item))).toList().obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<CheckinEventDataItem> value) {
      final newFiltered = value.where((item) => filters.every((filter) => filter.apply(item))).toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _CheckinEventDataItemFilterSubscription(newList, filters, worker);
    return newList;
  }

  void unregisterFilterSubscription(String filterKey) {
    final sub = _dynamicSubscription.remove(filterKey);
    sub?.worker.dispose();
  }

  Future<void> rebuildLocal() async {
    _items.value = await CheckinEventRepository().listFromLocalDb();
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void onSelectCheckinEvent(String id) {
    currentCheckinEventId.value = id;
  }

  DataItem<CheckinEvent>? getCheckinEvent(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  List<T> getCheckinEventDetails<T>({
    List<DataItemFilter> filters = const [],
    required T Function(CheckinEventDataItem item) selector,
  }) {
    return _items.where((item) => filters.every((filter) => filter.apply(item))).map(selector).toList();
  }

  int getCheckinEventCount<T>({List<DataItemFilter> filters = const []}) {
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

  void _replaceLocal(String id, CheckinEventDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    if (currentCheckinEventId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentCheckinEventId.value = fetchedItem.id;
    }
  }

  void addData(CheckinEvent newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = CheckinEventDataItem.localNew(owner, newData);
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _syncEngine.create(newItem).then((fetchedItem) {
      _replaceLocal(newItem.id, fetchedItem);
    });
  }

  void updateData(String id, CheckinEvent updatedData) {
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
    CheckinEventRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentCheckinEventId.value == id) {
      currentCheckinEventId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    _syncEngine.delete(id, deleteFromServer ? true : status != SyncStatus.deleted);
  }
}

class _CheckinEventSyncEngine {
  final SyncStoreClient client;
  _CheckinEventSyncEngine(this.client);

  Future<CheckinEventDataItem> create(CheckinEventDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await CheckinEventRepository().addToLocalDb(local);

    CheckinEventDataItem createdItem;
    try {
      final newId = await client.create('checkin', 'event', local.body.toJson());
      createdItem = await client.get<CheckinEvent>('checkin', 'event', newId, CheckinEvent.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await CheckinEventRepository().updateToLocalDb(local);
      rethrow;
    }
    createdItem.syncStatus = SyncStatus.archived;
    createdItem.colorTag = local.colorTag;

    await CheckinEventRepository().deleteFromLocalDb(local.id);
    await CheckinEventRepository().addToLocalDb(createdItem);
    return createdItem;
  }

  Future<CheckinEventDataItem> update(CheckinEventDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await CheckinEventRepository().updateToLocalDb(local);

    CheckinEventDataItem updatedItem;
    try {
      await client.update('checkin', 'event', local.id, local.body.toJson());
      updatedItem = await client.get<CheckinEvent>('checkin', 'event', local.id, CheckinEvent.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await CheckinEventRepository().updateToLocalDb(local);
      rethrow;
    }
    updatedItem.syncStatus = SyncStatus.archived;
    updatedItem.colorTag = local.colorTag;

    await CheckinEventRepository().updateToLocalDb(updatedItem);
    return updatedItem;
  }

  void delete(String id, bool deleteFromServer) {
    CheckinEventRepository().deleteFromLocalDb(id);
    if (!deleteFromServer) return;
    try {
      client.delete('checkin', 'event', id);
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
          'checkin',
          'event',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final CheckinEventDataItem? localItem = await CheckinEventRepository().getFromLocalDb(summary.id);
          if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
            // only get details for new created or updated items, otherwise just skip to save performance.
            needGetIds.add(summary.id);
          } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
            // local data is newer, need to sync to server
            localItem.syncStatus = SyncStatus.failed;
            await CheckinEventRepository().updateToLocalDb(localItem);
          } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
            // same updatedAt but marked as special status, need to sync to server
            localItem.syncStatus = SyncStatus.archived;
            await CheckinEventRepository().updateToLocalDb(localItem);
          }
        }
      } while (nextMarker != null);
      // 2. clean up local data that are deleted from server
      final localItems = await CheckinEventRepository().listFromLocalDb();
      for (CheckinEventDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await CheckinEventRepository().updateToLocalDb(localItem);
        }
      }

      // 3. batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('checkin', 'event', batchIds, CheckinEvent.fromJson);
        for (var item in batchItems.items) {
          await CheckinEventRepository().upsertToLocalDb(item);
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
            'checkin',
            'event',
            parentIdsBatch,
            marker: nextMarker,
          );
          nextMarker = resp.pageInfo.nextMarker;
          for (var summary in resp.items) {
            serviceIds.add(summary.id);
            final CheckinEventDataItem? localItem = await CheckinEventRepository().getFromLocalDb(summary.id);
            if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
              // only get details for new created or updated items, otherwise just skip to save performance.
              needGetIds.add(summary.id);
            } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
              // local data is newer, need to sync to server
              localItem.syncStatus = SyncStatus.failed;
              await CheckinEventRepository().updateToLocalDb(localItem);
            } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
              // same updatedAt but marked as special status, need to sync to server
              localItem.syncStatus = SyncStatus.archived;
              await CheckinEventRepository().updateToLocalDb(localItem);
            }
          }
        } while (nextMarker != null);
      }
      // clean up local data that are deleted from server
      final localItems = await CheckinEventRepository().listFromLocalDb();
      for (CheckinEventDataItem localItem in localItems) {
        if (localItem.parentId == null || !parentIds.contains(localItem.parentId!)) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await CheckinEventRepository().updateToLocalDb(localItem);
        }
      }
      // batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('checkin', 'event', batchIds, CheckinEvent.fromJson);
        for (var item in batchItems.items) {
          await CheckinEventRepository().upsertToLocalDb(item);
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
        final ListResponse resp = await client.list('checkin', 'event', limit: 200, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final CheckinEventDataItem? localItem = await CheckinEventRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await CheckinEventRepository().listFromLocalDb();
      for (CheckinEventDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await CheckinEventRepository().updateToLocalDb(localItem);
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
          'checkin',
          'event',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final CheckinEventDataItem? localItem = await CheckinEventRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await CheckinEventRepository().listFromLocalDb();
      for (CheckinEventDataItem localItem in localItems) {
        if (localItem.owner == currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.hidden;
          await CheckinEventRepository().updateToLocalDb(localItem);
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
          'checkin',
          'event',
          parentId: parentId,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final CheckinEventDataItem? localItem = await CheckinEventRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await CheckinEventRepository().listFromLocalDb(parentId: parentId);
      for (CheckinEventDataItem localItem in localItems) {
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await CheckinEventRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> _compareRemote(CheckinEventDataItem? localItem, DataItemSummary summary) async {
    if (localItem == null) {
      // new from server
      final CheckinEventDataItem item = await client.get<CheckinEvent>(
        'checkin',
        'event',
        summary.id,
        CheckinEvent.fromJson,
      );
      await CheckinEventRepository().addToLocalDb(item);
    } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
      // update local data.
      final CheckinEventDataItem item = await client.get<CheckinEvent>(
        'checkin',
        'event',
        summary.id,
        CheckinEvent.fromJson,
      );
      await CheckinEventRepository().updateToLocalDb(item);
    } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
      // local data is newer, need to sync to server
      localItem.syncStatus = SyncStatus.failed;
      await CheckinEventRepository().updateToLocalDb(localItem);
    } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
      // same updatedAt but marked as special status, need to sync to server
      localItem.syncStatus = SyncStatus.archived;
      await CheckinEventRepository().updateToLocalDb(localItem);
    }
  }
}

extension LocalStoreCheckinRecord on CheckinRecord {
  static String get tableName => 'record';

  static String get onCreateTableCheckinRecordSQL =>
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
    return await CheckinDB().getDb();
  }
}

typedef CheckinRecordDataItem = DataItem<CheckinRecord>;

class CheckinRecordRepository {
  Future<void> addToLocalDb(CheckinRecordDataItem item) async {
    final db = await LocalStoreCheckinRecord.getDb();
    await db.insert(LocalStoreCheckinRecord.tableName, item.toJson((r) => json.encode(r.toJson())));
  }

  Future<CheckinRecordDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreCheckinRecord.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreCheckinRecord.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<CheckinRecord>.fromJson(
        maps.first,
        (jsonStr) => CheckinRecord.fromJson(json.decode(jsonStr as String)),
      );
    }
    return null;
  }

  Future<List<CheckinRecordDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStoreCheckinRecord.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreCheckinRecord.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps
        .map(
          (map) => DataItem<CheckinRecord>.fromJson(
            map,
            (jsonStr) => CheckinRecord.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreCheckinRecord.getDb();
    await db.delete(LocalStoreCheckinRecord.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToLocalDb(CheckinRecordDataItem item) async {
    final db = await LocalStoreCheckinRecord.getDb();
    await db.update(
      LocalStoreCheckinRecord.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(CheckinRecordDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}

class _CheckinRecordDataItemFilterSubscription {
  final RxList<CheckinRecordDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _CheckinRecordDataItemFilterSubscription(this.filteredList, this.appliedFilters, this.worker);
}

class CheckinRecordController extends GetxController {
  final SyncStoreClient client;
  final _CheckinRecordSyncEngine _syncEngine;
  CheckinRecordController(this.client) : _syncEngine = _CheckinRecordSyncEngine(client);

  final RxList<CheckinRecordDataItem> _items = <CheckinRecordDataItem>[].obs;

  final Map<String, _CheckinRecordDataItemFilterSubscription> _dynamicSubscription = {};
  final Rx<String?> currentCheckinRecordId = Rx<String?>(null);

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
      await CheckinRecordRepository().deleteFromLocalDb(id);
    }
    await rebuildLocal();
  }

  RxList<CheckinRecordDataItem> registerFilterSubscription({
    required String filterKey,
    List<DataItemFilter> filters = const [],
  }) {
    final existing = _dynamicSubscription[filterKey];
    if (existing != null && listEquals(existing.appliedFilters, filters)) {
      return existing.filteredList;
    }
    final newList = _items.where((item) => filters.every((filter) => filter.apply(item))).toList().obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<CheckinRecordDataItem> value) {
      final newFiltered = value.where((item) => filters.every((filter) => filter.apply(item))).toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _CheckinRecordDataItemFilterSubscription(newList, filters, worker);
    return newList;
  }

  void unregisterFilterSubscription(String filterKey) {
    final sub = _dynamicSubscription.remove(filterKey);
    sub?.worker.dispose();
  }

  Future<void> rebuildLocal() async {
    _items.value = await CheckinRecordRepository().listFromLocalDb();
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void onSelectCheckinRecord(String id) {
    currentCheckinRecordId.value = id;
  }

  DataItem<CheckinRecord>? getCheckinRecord(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  List<T> getCheckinRecordDetails<T>({
    List<DataItemFilter> filters = const [],
    required T Function(CheckinRecordDataItem item) selector,
  }) {
    return _items.where((item) => filters.every((filter) => filter.apply(item))).map(selector).toList();
  }

  int getCheckinRecordCount<T>({List<DataItemFilter> filters = const []}) {
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

  void _replaceLocal(String id, CheckinRecordDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    if (currentCheckinRecordId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentCheckinRecordId.value = fetchedItem.id;
    }
  }

  void addData(CheckinRecord newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = CheckinRecordDataItem.localNew(owner, newData);
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _syncEngine.create(newItem).then((fetchedItem) {
      _replaceLocal(newItem.id, fetchedItem);
    });
  }

  void updateData(String id, CheckinRecord updatedData) {
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
    CheckinRecordRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentCheckinRecordId.value == id) {
      currentCheckinRecordId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    _syncEngine.delete(id, deleteFromServer ? true : status != SyncStatus.deleted);
  }
}

class _CheckinRecordSyncEngine {
  final SyncStoreClient client;
  _CheckinRecordSyncEngine(this.client);

  Future<CheckinRecordDataItem> create(CheckinRecordDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await CheckinRecordRepository().addToLocalDb(local);

    CheckinRecordDataItem createdItem;
    try {
      final newId = await client.create('checkin', 'record', local.body.toJson());
      createdItem = await client.get<CheckinRecord>('checkin', 'record', newId, CheckinRecord.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await CheckinRecordRepository().updateToLocalDb(local);
      rethrow;
    }
    createdItem.syncStatus = SyncStatus.archived;
    createdItem.colorTag = local.colorTag;

    await CheckinRecordRepository().deleteFromLocalDb(local.id);
    await CheckinRecordRepository().addToLocalDb(createdItem);
    return createdItem;
  }

  Future<CheckinRecordDataItem> update(CheckinRecordDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await CheckinRecordRepository().updateToLocalDb(local);

    CheckinRecordDataItem updatedItem;
    try {
      await client.update('checkin', 'record', local.id, local.body.toJson());
      updatedItem = await client.get<CheckinRecord>('checkin', 'record', local.id, CheckinRecord.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await CheckinRecordRepository().updateToLocalDb(local);
      rethrow;
    }
    updatedItem.syncStatus = SyncStatus.archived;
    updatedItem.colorTag = local.colorTag;

    await CheckinRecordRepository().updateToLocalDb(updatedItem);
    return updatedItem;
  }

  void delete(String id, bool deleteFromServer) {
    CheckinRecordRepository().deleteFromLocalDb(id);
    if (!deleteFromServer) return;
    try {
      client.delete('checkin', 'record', id);
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
          'checkin',
          'record',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final CheckinRecordDataItem? localItem = await CheckinRecordRepository().getFromLocalDb(summary.id);
          if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
            // only get details for new created or updated items, otherwise just skip to save performance.
            needGetIds.add(summary.id);
          } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
            // local data is newer, need to sync to server
            localItem.syncStatus = SyncStatus.failed;
            await CheckinRecordRepository().updateToLocalDb(localItem);
          } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
            // same updatedAt but marked as special status, need to sync to server
            localItem.syncStatus = SyncStatus.archived;
            await CheckinRecordRepository().updateToLocalDb(localItem);
          }
        }
      } while (nextMarker != null);
      // 2. clean up local data that are deleted from server
      final localItems = await CheckinRecordRepository().listFromLocalDb();
      for (CheckinRecordDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await CheckinRecordRepository().updateToLocalDb(localItem);
        }
      }

      // 3. batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('checkin', 'record', batchIds, CheckinRecord.fromJson);
        for (var item in batchItems.items) {
          await CheckinRecordRepository().upsertToLocalDb(item);
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
            'checkin',
            'record',
            parentIdsBatch,
            marker: nextMarker,
          );
          nextMarker = resp.pageInfo.nextMarker;
          for (var summary in resp.items) {
            serviceIds.add(summary.id);
            final CheckinRecordDataItem? localItem = await CheckinRecordRepository().getFromLocalDb(summary.id);
            if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
              // only get details for new created or updated items, otherwise just skip to save performance.
              needGetIds.add(summary.id);
            } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
              // local data is newer, need to sync to server
              localItem.syncStatus = SyncStatus.failed;
              await CheckinRecordRepository().updateToLocalDb(localItem);
            } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
              // same updatedAt but marked as special status, need to sync to server
              localItem.syncStatus = SyncStatus.archived;
              await CheckinRecordRepository().updateToLocalDb(localItem);
            }
          }
        } while (nextMarker != null);
      }
      // clean up local data that are deleted from server
      final localItems = await CheckinRecordRepository().listFromLocalDb();
      for (CheckinRecordDataItem localItem in localItems) {
        if (localItem.parentId == null || !parentIds.contains(localItem.parentId!)) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await CheckinRecordRepository().updateToLocalDb(localItem);
        }
      }
      // batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('checkin', 'record', batchIds, CheckinRecord.fromJson);
        for (var item in batchItems.items) {
          await CheckinRecordRepository().upsertToLocalDb(item);
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
        final ListResponse resp = await client.list('checkin', 'record', limit: 200, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final CheckinRecordDataItem? localItem = await CheckinRecordRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await CheckinRecordRepository().listFromLocalDb();
      for (CheckinRecordDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await CheckinRecordRepository().updateToLocalDb(localItem);
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
          'checkin',
          'record',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final CheckinRecordDataItem? localItem = await CheckinRecordRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await CheckinRecordRepository().listFromLocalDb();
      for (CheckinRecordDataItem localItem in localItems) {
        if (localItem.owner == currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.hidden;
          await CheckinRecordRepository().updateToLocalDb(localItem);
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
          'checkin',
          'record',
          parentId: parentId,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final CheckinRecordDataItem? localItem = await CheckinRecordRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await CheckinRecordRepository().listFromLocalDb(parentId: parentId);
      for (CheckinRecordDataItem localItem in localItems) {
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await CheckinRecordRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> _compareRemote(CheckinRecordDataItem? localItem, DataItemSummary summary) async {
    if (localItem == null) {
      // new from server
      final CheckinRecordDataItem item = await client.get<CheckinRecord>(
        'checkin',
        'record',
        summary.id,
        CheckinRecord.fromJson,
      );
      await CheckinRecordRepository().addToLocalDb(item);
    } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
      // update local data.
      final CheckinRecordDataItem item = await client.get<CheckinRecord>(
        'checkin',
        'record',
        summary.id,
        CheckinRecord.fromJson,
      );
      await CheckinRecordRepository().updateToLocalDb(item);
    } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
      // local data is newer, need to sync to server
      localItem.syncStatus = SyncStatus.failed;
      await CheckinRecordRepository().updateToLocalDb(localItem);
    } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
      // same updatedAt but marked as special status, need to sync to server
      localItem.syncStatus = SyncStatus.archived;
      await CheckinRecordRepository().updateToLocalDb(localItem);
    }
  }
}
