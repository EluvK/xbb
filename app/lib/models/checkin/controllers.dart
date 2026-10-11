// ignore_for_file: unused_element, unused_local_variable
part of 'model.dart';

class _CheckinEventDataItemFilterSubscription {
  final RxList<CheckinEventDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _CheckinEventDataItemFilterSubscription(
    this.filteredList,
    this.appliedFilters,
    this.worker,
  );
}

class CheckinEventController extends GetxController {
  final SyncStoreClient client;
  
  CheckinEventController(this.client)
    ;

  final RxList<CheckinEventDataItem> _items = <CheckinEventDataItem>[].obs;

  final Map<String, _CheckinEventDataItemFilterSubscription>
  _dynamicSubscription = {};
  final Rx<String?> currentCheckinEventId = Rx<String?>(null);

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
    final newList = _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .toList()
        .obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<CheckinEventDataItem> value) {
      final newFiltered = value
          .where((item) => filters.every((filter) => filter.apply(item)))
          .toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _CheckinEventDataItemFilterSubscription(
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
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .map(selector)
        .toList();
  }

  int getCheckinEventCount<T>({List<DataItemFilter> filters = const []}) {
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
    final owner = client.currentUserId();
    final newItem = CheckinEventDataItem.localNew(owner, newData);
    _items.add(newItem);
    _replaceLocal(newItem.id, newItem);
    unawaited(_persistItem(newItem));
  }

  void updateData(String id, CheckinEvent updatedData) {
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
    if (currentCheckinEventId.value == id) {
      currentCheckinEventId.value = null;
    }
    unawaited(_deleteItem(id));
  }

  Future<void> _persistItem(CheckinEventDataItem item) async {
    try {
      final db = await LocalStoreCheckinEvent.getDb();
      final row = item.toJson((r) => json.encode(r.toJson()));
      await LocalFirstDB.persistPutRaw(
        db: db,
        tableName: LocalStoreCheckinEvent.tableName,
        entityId: item.id,
        entityRow: row,
      );
      SyncWorker.instance.triggerSync();
    } catch (e) {
      print('Failed to persist checkin_event item ${item.id}: $e');
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      final db = await LocalStoreCheckinEvent.getDb();
      await LocalFirstDB.persistDeleteRaw(
        db: db,
        tableName: LocalStoreCheckinEvent.tableName,
        entityId: id,
      );
      SyncWorker.instance.triggerSync();
    } catch (e) {
      print('Failed to delete checkin_event item $id: $e');
    }
  }
}

class _CheckinRecordDataItemFilterSubscription {
  final RxList<CheckinRecordDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _CheckinRecordDataItemFilterSubscription(
    this.filteredList,
    this.appliedFilters,
    this.worker,
  );
}

class CheckinRecordController extends GetxController {
  final SyncStoreClient client;
  
  CheckinRecordController(this.client)
    ;

  final RxList<CheckinRecordDataItem> _items = <CheckinRecordDataItem>[].obs;

  final Map<String, _CheckinRecordDataItemFilterSubscription>
  _dynamicSubscription = {};
  final Rx<String?> currentCheckinRecordId = Rx<String?>(null);

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
    final newList = _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .toList()
        .obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<CheckinRecordDataItem> value) {
      final newFiltered = value
          .where((item) => filters.every((filter) => filter.apply(item)))
          .toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _CheckinRecordDataItemFilterSubscription(
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
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .map(selector)
        .toList();
  }

  int getCheckinRecordCount<T>({List<DataItemFilter> filters = const []}) {
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
    final owner = client.currentUserId();
    final newItem = CheckinRecordDataItem.localNew(owner, newData);
    _items.add(newItem);
    _replaceLocal(newItem.id, newItem);
    unawaited(_persistItem(newItem));
  }

  void updateData(String id, CheckinRecord updatedData) {
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
    if (currentCheckinRecordId.value == id) {
      currentCheckinRecordId.value = null;
    }
    unawaited(_deleteItem(id));
  }

  Future<void> _persistItem(CheckinRecordDataItem item) async {
    try {
      final db = await LocalStoreCheckinRecord.getDb();
      final row = item.toJson((r) => json.encode(r.toJson()));
      await LocalFirstDB.persistPutRaw(
        db: db,
        tableName: LocalStoreCheckinRecord.tableName,
        entityId: item.id,
        entityRow: row,
      );
      SyncWorker.instance.triggerSync();
    } catch (e) {
      print('Failed to persist checkin_record item ${item.id}: $e');
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      final db = await LocalStoreCheckinRecord.getDb();
      await LocalFirstDB.persistDeleteRaw(
        db: db,
        tableName: LocalStoreCheckinRecord.tableName,
        entityId: id,
      );
      SyncWorker.instance.triggerSync();
    } catch (e) {
      print('Failed to delete checkin_record item $id: $e');
    }
  }
}
