// ignore_for_file: unused_element, unused_local_variable
part of 'model.dart';

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
  
  ClipboardHistoryEntryController(this.client)
    ;

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
    final owner = client.currentUserId();
    final newItem = ClipboardHistoryEntryDataItem.localNew(owner, newData);
    _items.add(newItem);
    _replaceLocal(newItem.id, newItem);
    unawaited(_persistItem(newItem));
  }

  void updateData(String id, ClipboardHistoryEntry updatedData) {
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
    if (currentClipboardHistoryEntryId.value == id) {
      currentClipboardHistoryEntryId.value = null;
    }
    unawaited(_deleteItem(id));
  }

  Future<void> _persistItem(ClipboardHistoryEntryDataItem item) async {
    try {
      final db = await LocalStoreClipboardHistoryEntry.getDb();
      final row = item.toJson((r) => json.encode(r.toJson()));
      await LocalFirstDB.persistPutRaw(
        db: db,
        tableName: LocalStoreClipboardHistoryEntry.tableName,
        entityId: item.id,
        entityRow: row,
      );
      SyncWorker.instance.triggerSync();
    } catch (e) {
      print('Failed to persist clipboard_history_entry item ${item.id}: $e');
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      final db = await LocalStoreClipboardHistoryEntry.getDb();
      await LocalFirstDB.persistDeleteRaw(
        db: db,
        tableName: LocalStoreClipboardHistoryEntry.tableName,
        entityId: id,
      );
      SyncWorker.instance.triggerSync();
    } catch (e) {
      print('Failed to delete clipboard_history_entry item $id: $e');
    }
  }
}
