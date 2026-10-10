// ignore_for_file: unused_element, unused_local_variable
part of 'model.dart';

class _ChatAssistantDataItemFilterSubscription {
  final RxList<ChatAssistantDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _ChatAssistantDataItemFilterSubscription(
    this.filteredList,
    this.appliedFilters,
    this.worker,
  );
}

class ChatAssistantController extends GetxController {
  final SyncStoreClient client;
  
  ChatAssistantController(this.client)
    ;

  final RxList<ChatAssistantDataItem> _items = <ChatAssistantDataItem>[].obs;

  final Map<String, _ChatAssistantDataItemFilterSubscription>
  _dynamicSubscription = {};
  final Rx<String?> currentChatAssistantId = Rx<String?>(null);

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
      await ChatAssistantRepository().deleteFromLocalDb(id);
    }
    await rebuildLocal();
  }

  RxList<ChatAssistantDataItem> registerFilterSubscription({
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
    final worker = debounce(_items, (List<ChatAssistantDataItem> value) {
      final newFiltered = value
          .where((item) => filters.every((filter) => filter.apply(item)))
          .toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _ChatAssistantDataItemFilterSubscription(
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
    _items.value = await ChatAssistantRepository().listFromLocalDb();
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void onSelectChatAssistant(String id) {
    currentChatAssistantId.value = id;
  }

  DataItem<ChatAssistant>? getChatAssistant(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  List<T> getChatAssistantDetails<T>({
    List<DataItemFilter> filters = const [],
    required T Function(ChatAssistantDataItem item) selector,
  }) {
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .map(selector)
        .toList();
  }

  int getChatAssistantCount<T>({List<DataItemFilter> filters = const []}) {
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

  void _replaceLocal(String id, ChatAssistantDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    if (currentChatAssistantId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentChatAssistantId.value = fetchedItem.id;
    }
  }

  void addData(ChatAssistant newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = ChatAssistantDataItem.localNew(owner, newData);
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _replaceLocal(newItem.id, newItem);
  }

  void updateData(String id, ChatAssistant updatedData) {
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
    ChatAssistantRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentChatAssistantId.value == id) {
      currentChatAssistantId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    /* deleted */
  }
}

class _ChatConversationDataItemFilterSubscription {
  final RxList<ChatConversationDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _ChatConversationDataItemFilterSubscription(
    this.filteredList,
    this.appliedFilters,
    this.worker,
  );
}

class ChatConversationController extends GetxController {
  final SyncStoreClient client;
  
  ChatConversationController(this.client)
    ;

  final RxList<ChatConversationDataItem> _items =
      <ChatConversationDataItem>[].obs;

  final Map<String, _ChatConversationDataItemFilterSubscription>
  _dynamicSubscription = {};
  final Rx<String?> currentChatConversationId = Rx<String?>(null);

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
      await ChatConversationRepository().deleteFromLocalDb(id);
    }
    await rebuildLocal();
  }

  RxList<ChatConversationDataItem> registerFilterSubscription({
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
    final worker = debounce(_items, (List<ChatConversationDataItem> value) {
      final newFiltered = value
          .where((item) => filters.every((filter) => filter.apply(item)))
          .toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] =
        _ChatConversationDataItemFilterSubscription(newList, filters, worker);
    return newList;
  }

  void unregisterFilterSubscription(String filterKey) {
    final sub = _dynamicSubscription.remove(filterKey);
    sub?.worker.dispose();
  }

  Future<void> rebuildLocal() async {
    _items.value = await ChatConversationRepository().listFromLocalDb();
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void onSelectChatConversation(String id) {
    currentChatConversationId.value = id;
  }

  DataItem<ChatConversation>? getChatConversation(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  List<T> getChatConversationDetails<T>({
    List<DataItemFilter> filters = const [],
    required T Function(ChatConversationDataItem item) selector,
  }) {
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .map(selector)
        .toList();
  }

  int getChatConversationCount<T>({List<DataItemFilter> filters = const []}) {
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

  void _replaceLocal(String id, ChatConversationDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    if (currentChatConversationId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentChatConversationId.value = fetchedItem.id;
    }
  }

  void addData(ChatConversation newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = ChatConversationDataItem.localNew(owner, newData);
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _replaceLocal(newItem.id, newItem);
  }

  void updateData(String id, ChatConversation updatedData) {
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
    ChatConversationRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentChatConversationId.value == id) {
      currentChatConversationId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    /* deleted */
  }
}

class _ChatMessageDataItemFilterSubscription {
  final RxList<ChatMessageDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _ChatMessageDataItemFilterSubscription(
    this.filteredList,
    this.appliedFilters,
    this.worker,
  );
}

class ChatMessageController extends GetxController {
  final SyncStoreClient client;
  
  ChatMessageController(this.client)
    ;

  final RxList<ChatMessageDataItem> _items = <ChatMessageDataItem>[].obs;

  final Map<String, _ChatMessageDataItemFilterSubscription>
  _dynamicSubscription = {};
  final Rx<String?> currentChatMessageId = Rx<String?>(null);

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
      await ChatMessageRepository().deleteFromLocalDb(id);
    }
    await rebuildLocal();
  }

  RxList<ChatMessageDataItem> registerFilterSubscription({
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
    final worker = debounce(_items, (List<ChatMessageDataItem> value) {
      final newFiltered = value
          .where((item) => filters.every((filter) => filter.apply(item)))
          .toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _ChatMessageDataItemFilterSubscription(
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
    _items.value = await ChatMessageRepository().listFromLocalDb();
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void onSelectChatMessage(String id) {
    currentChatMessageId.value = id;
  }

  DataItem<ChatMessage>? getChatMessage(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  List<T> getChatMessageDetails<T>({
    List<DataItemFilter> filters = const [],
    required T Function(ChatMessageDataItem item) selector,
  }) {
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .map(selector)
        .toList();
  }

  int getChatMessageCount<T>({List<DataItemFilter> filters = const []}) {
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

  void _replaceLocal(String id, ChatMessageDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    if (currentChatMessageId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentChatMessageId.value = fetchedItem.id;
    }
  }

  void addData(ChatMessage newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = ChatMessageDataItem.localNew(
      owner,
      newData,
      parentId: newData.conversationId,
    );
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _replaceLocal(newItem.id, newItem);
  }

  void updateData(String id, ChatMessage updatedData) {
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
    ChatMessageRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentChatMessageId.value == id) {
      currentChatMessageId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    /* deleted */
  }
}
