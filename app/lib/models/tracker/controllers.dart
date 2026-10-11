// ignore_for_file: unused_element, unused_local_variable
part of 'model.dart';

class _TrackerDataItemFilterSubscription {
  final RxList<TrackerDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _TrackerDataItemFilterSubscription(
    this.filteredList,
    this.appliedFilters,
    this.worker,
  );
}

class TrackerController extends GetxController {
  final SyncStoreClient client;
  
  TrackerController(this.client) ;

  final RxList<TrackerDataItem> _items = <TrackerDataItem>[].obs;
  final RxMap<String, List<Permission>> _aclCache =
      <String, List<Permission>>{}.obs;
  final Map<String, _TrackerDataItemFilterSubscription> _dynamicSubscription =
      {};
  final Rx<String?> currentTrackerId = Rx<String?>(null);

  @override
  Future<void> onInit() async {
    await rebuildLocal();
    // preload ACLs for all items to make sure UI can get ACL info immediately
    // this can be optimized by only load ACL when needed and cache it.
    for (var item in _items) {
      await _getAclLocal(item.id);
    }
    super.onInit();
    _initialized = true;
  }

  bool _initialized = false;
  @override
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
    final newList = _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .toList()
        .obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<TrackerDataItem> value) {
      final newFiltered = value
          .where((item) => filters.every((filter) => filter.apply(item)))
          .toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _TrackerDataItemFilterSubscription(
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
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .map(selector)
        .toList();
  }

  int getTrackerCount<T>({List<DataItemFilter> filters = const []}) {
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .length;
  }

  Future<void> syncAll({int batchSize = 20}) async {
    return;
  }

  Future<void> syncChildren(String parentId, {int batchSize = 20}) async {
    return;
  }

  Future<void> syncMultiChildren(List<String> parentIds, {int batchSize = 20}) async {
    return;
  }

  Future<void> syncOwned() async {
    return;
  }

  Future<void> syncGranted() async {
    return;
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
    final owner = client.currentUserId();
    final newItem = TrackerDataItem.localNew(owner, newData);
    _items.add(newItem);
    _replaceLocal(newItem.id, newItem);
    unawaited(_persistItem(newItem));
  }

  void updateData(String id, Tracker updatedData) {
    final item = _items.firstWhereOrNull((item) => item.id == id);
    if (item == null) return;
    final updatedItem = item.updatedBody(updatedData);
    _items[_items.indexOf(item)] = updatedItem;
    _replaceLocal(updatedItem.id, updatedItem);
    unawaited(_persistItem(updatedItem));
  }

  void onUpdateLocalField(
    String id, {
    ColorTag? colorTag,
    SyncStatus? syncStatus,
  }) {
    final item = _items.firstWhereOrNull((item) => item.id == id);
    if (item == null) return;
    if (colorTag != null) {
      item.colorTag = colorTag;
    }
    if (syncStatus != null) {
      item.syncStatus = syncStatus;
    }
    unawaited(_persistItem(item));
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentTrackerId.value == id) {
      currentTrackerId.value = null;
    }
    unawaited(_deleteItem(id));
  }

  Future<void> _persistItem(TrackerDataItem item) async {
    try {
      final db = await LocalStoreTracker.getDb();
      final row = item.toJson((r) => json.encode(r.toJson()));
      await LocalFirstDB.persistPutRaw(
        db: db,
        tableName: LocalStoreTracker.tableName,
        entityId: item.id,
        entityRow: row,
      );
      SyncWorker.instance.triggerSync();
    } catch (e) {
      print('Failed to persist tracker item ${item.id}: $e');
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      final db = await LocalStoreTracker.getDb();
      await LocalFirstDB.persistDeleteRaw(
        db: db,
        tableName: LocalStoreTracker.tableName,
        entityId: id,
      );
      SyncWorker.instance.triggerSync();
    } catch (e) {
      print('Failed to delete tracker item $id: $e');
    }
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
    final List<dynamic> permissionsList =
        json.decode(permissionsJson) as List<dynamic>;
    return permissionsList
        .map((e) => Permission.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setAcls(String dataId, List<Permission> permissions) async {
    final db = await LocalStoreTracker.getDb();
    final permissionsJson = json.encode(
      permissions.map((e) => e.toJson()).toList(),
    );
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

  Future<List<Permission>> _getAclLocal(String dataId) async {
    final localAcls = await TrackerRepository().getAcls(dataId);
    _aclCache[dataId] = localAcls;
    return localAcls;
  }

  List<Permission> getAclCached(String dataId) => _aclCache[dataId] ?? [];
  Future<List<Permission>> getAclRefresh(String dataId) async {
    try {
      final List<Permission> getAcls = await client.getAcls(
        'tracker',
        'tracker',
        dataId,
      );
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

class _TrackerRecordDataItemFilterSubscription {
  final RxList<TrackerRecordDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _TrackerRecordDataItemFilterSubscription(
    this.filteredList,
    this.appliedFilters,
    this.worker,
  );
}

class TrackerRecordController extends GetxController {
  final SyncStoreClient client;
  
  TrackerRecordController(this.client)
    ;

  final RxList<TrackerRecordDataItem> _items = <TrackerRecordDataItem>[].obs;

  final Map<String, _TrackerRecordDataItemFilterSubscription>
  _dynamicSubscription = {};
  final Rx<String?> currentTrackerRecordId = Rx<String?>(null);

  @override
  Future<void> onInit() async {
    await rebuildLocal();

    super.onInit();
    _initialized = true;
  }

  bool _initialized = false;
  @override
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
    final newList = _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .toList()
        .obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<TrackerRecordDataItem> value) {
      final newFiltered = value
          .where((item) => filters.every((filter) => filter.apply(item)))
          .toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _TrackerRecordDataItemFilterSubscription(
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
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .map(selector)
        .toList();
  }

  int getTrackerRecordCount<T>({List<DataItemFilter> filters = const []}) {
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .length;
  }

  Future<void> syncAll({int batchSize = 20}) async {
    return;
  }

  Future<void> syncChildren(String parentId, {int batchSize = 20}) async {
    return;
  }

  Future<void> syncMultiChildren(List<String> parentIds, {int batchSize = 20}) async {
    return;
  }

  Future<void> syncOwned() async {
    return;
  }

  Future<void> syncGranted() async {
    return;
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
    final owner = client.currentUserId();
    final newItem = TrackerRecordDataItem.localNew(owner, newData);
    _items.add(newItem);
    _replaceLocal(newItem.id, newItem);
    unawaited(_persistItem(newItem));
  }

  void updateData(String id, TrackerRecord updatedData) {
    final item = _items.firstWhereOrNull((item) => item.id == id);
    if (item == null) return;
    final updatedItem = item.updatedBody(updatedData);
    _items[_items.indexOf(item)] = updatedItem;
    _replaceLocal(updatedItem.id, updatedItem);
    unawaited(_persistItem(updatedItem));
  }

  void onUpdateLocalField(
    String id, {
    ColorTag? colorTag,
    SyncStatus? syncStatus,
  }) {
    final item = _items.firstWhereOrNull((item) => item.id == id);
    if (item == null) return;
    if (colorTag != null) {
      item.colorTag = colorTag;
    }
    if (syncStatus != null) {
      item.syncStatus = syncStatus;
    }
    unawaited(_persistItem(item));
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentTrackerRecordId.value == id) {
      currentTrackerRecordId.value = null;
    }
    unawaited(_deleteItem(id));
  }

  Future<void> _persistItem(TrackerRecordDataItem item) async {
    try {
      final db = await LocalStoreTrackerRecord.getDb();
      final row = item.toJson((r) => json.encode(r.toJson()));
      await LocalFirstDB.persistPutRaw(
        db: db,
        tableName: LocalStoreTrackerRecord.tableName,
        entityId: item.id,
        entityRow: row,
      );
      SyncWorker.instance.triggerSync();
    } catch (e) {
      print('Failed to persist tracker_record item ${item.id}: $e');
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      final db = await LocalStoreTrackerRecord.getDb();
      await LocalFirstDB.persistDeleteRaw(
        db: db,
        tableName: LocalStoreTrackerRecord.tableName,
        entityId: id,
      );
      SyncWorker.instance.triggerSync();
    } catch (e) {
      print('Failed to delete tracker_record item $id: $e');
    }
  }
}
