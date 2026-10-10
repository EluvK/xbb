// ignore_for_file: unused_element, unused_local_variable
part of 'model.dart';

class _CheckListDataItemFilterSubscription {
  final RxList<CheckListDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _CheckListDataItemFilterSubscription(
    this.filteredList,
    this.appliedFilters,
    this.worker,
  );
}

class CheckListController extends GetxController {
  final SyncStoreClient client;
  
  CheckListController(this.client) ;

  final RxList<CheckListDataItem> _items = <CheckListDataItem>[].obs;

  final Map<String, _CheckListDataItemFilterSubscription> _dynamicSubscription =
      {};
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
    final newList = _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .toList()
        .obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<CheckListDataItem> value) {
      final newFiltered = value
          .where((item) => filters.every((filter) => filter.apply(item)))
          .toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _CheckListDataItemFilterSubscription(
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
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .map(selector)
        .toList();
  }

  int getCheckListCount<T>({List<DataItemFilter> filters = const []}) {
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
    _replaceLocal(newItem.id, newItem);
  }

  void updateData(String id, CheckList updatedData) {
    final item = _items.firstWhere((item) => item.id == id);
    // todo maybe rewrite this update body method...
    final updatedItem = item.updatedBody(updatedData);
    _items[_items.indexOf(item)] = updatedItem;
    _replaceLocal(updatedItem.id, updatedItem);
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
    CheckListRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentCheckListId.value == id) {
      currentCheckListId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    /* deleted */
  }
}
