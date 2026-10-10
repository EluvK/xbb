// ignore_for_file: unused_element, unused_local_variable
part of 'model.dart';

class _RepoDataItemFilterSubscription {
  final RxList<RepoDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _RepoDataItemFilterSubscription(
    this.filteredList,
    this.appliedFilters,
    this.worker,
  );
}

class RepoController extends GetxController {
  final SyncStoreClient client;
  
  RepoController(this.client) ;

  final RxList<RepoDataItem> _items = <RepoDataItem>[].obs;
  final RxMap<String, List<Permission>> _aclCache =
      <String, List<Permission>>{}.obs;
  final Map<String, _RepoDataItemFilterSubscription> _dynamicSubscription = {};
  final Rx<String?> currentRepoId = Rx<String?>(null);

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
    final newList = _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .toList()
        .obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<RepoDataItem> value) {
      final newFiltered = value
          .where((item) => filters.every((filter) => filter.apply(item)))
          .toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _RepoDataItemFilterSubscription(
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
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .map(selector)
        .toList();
  }

  int getRepoCount<T>({List<DataItemFilter> filters = const []}) {
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
    _replaceLocal(newItem.id, newItem);
  }

  void updateData(String id, Repo updatedData) {
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
    RepoRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentRepoId.value == id) {
      currentRepoId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    /* deleted */
  }
}

extension RepoRepositoryAcl on RepoRepository {
  static String get tableNameAcl => 'acl';
  Future<List<Permission>> getAcls(String dataId) async {
    final db = await LocalStoreRepo.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      tableNameAcl,
      where: 'data_id = ? AND data_collection = ?',
      whereArgs: [dataId, 'repo'],
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
    final db = await LocalStoreRepo.getDb();
    final permissionsJson = json.encode(
      permissions.map((e) => e.toJson()).toList(),
    );
    await db.insert(tableNameAcl, {
      'data_id': dataId,
      'data_collection': 'repo',
      'permissions': permissionsJson,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

extension RepoControllerAcl on RepoController {
  Future<void> syncAcls() async {
    try {
      for (var item in _items) {
        final serviceAcls = await client.getAcls('xbb', 'repo', item.id);
        await RepoRepository().setAcls(item.id, serviceAcls);
        _aclCache[item.id] = serviceAcls;
      }
    } catch (e) {
      print("Error syncing ACLs: $e");
    }
  }

  Future<List<Permission>> _getAclLocal(String dataId) async {
    final localAcls = await RepoRepository().getAcls(dataId);
    _aclCache[dataId] = localAcls;
    return localAcls;
  }

  List<Permission> getAclCached(String dataId) => _aclCache[dataId] ?? [];
  Future<List<Permission>> getAclRefresh(String dataId) async {
    try {
      final List<Permission> getAcls = await client.getAcls(
        'xbb',
        'repo',
        dataId,
      );
      await RepoRepository().setAcls(dataId, getAcls);
      _aclCache[dataId] = getAcls;
      return getAcls;
    } catch (e) {
      print("Error fetching ACLs from server: $e");
      return await RepoRepository().getAcls(dataId);
    }
  }

  Future<void> setAcls(String dataId, List<Permission> permissions) async {
    try {
      await client.updateAcls('xbb', 'repo', dataId, permissions);
      await RepoRepository().setAcls(dataId, permissions);
      _aclCache[dataId] = permissions;
    } catch (e) {
      print("Error updating ACLs to server: $e");
    }
  }
}

class _PostDataItemFilterSubscription {
  final RxList<PostDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _PostDataItemFilterSubscription(
    this.filteredList,
    this.appliedFilters,
    this.worker,
  );
}

class PostController extends GetxController {
  final SyncStoreClient client;
  
  PostController(this.client) ;

  final RxList<PostDataItem> _items = <PostDataItem>[].obs;

  final Map<String, _PostDataItemFilterSubscription> _dynamicSubscription = {};
  final Rx<String?> currentPostId = Rx<String?>(null);

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
      await PostRepository().deleteFromLocalDb(id);
    }
    await rebuildLocal();
  }

  RxList<PostDataItem> registerFilterSubscription({
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
    final worker = debounce(_items, (List<PostDataItem> value) {
      final newFiltered = value
          .where((item) => filters.every((filter) => filter.apply(item)))
          .toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _PostDataItemFilterSubscription(
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
    _items.value = await PostRepository().listFromLocalDb();
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void onSelectPost(String id) {
    currentPostId.value = id;
  }

  DataItem<Post>? getPost(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  List<T> getPostDetails<T>({
    List<DataItemFilter> filters = const [],
    required T Function(PostDataItem item) selector,
  }) {
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .map(selector)
        .toList();
  }

  int getPostCount<T>({List<DataItemFilter> filters = const []}) {
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

  void _replaceLocal(String id, PostDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    if (currentPostId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentPostId.value = fetchedItem.id;
    }
  }

  void addData(Post newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = PostDataItem.localNew(
      owner,
      newData,
      parentId: newData.repoId,
    );
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _replaceLocal(newItem.id, newItem);
  }

  void updateData(String id, Post updatedData) {
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
    PostRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentPostId.value == id) {
      currentPostId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    /* deleted */
  }
}

class _CommentDataItemFilterSubscription {
  final RxList<CommentDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _CommentDataItemFilterSubscription(
    this.filteredList,
    this.appliedFilters,
    this.worker,
  );
}

class CommentController extends GetxController {
  final SyncStoreClient client;
  
  CommentController(this.client) ;

  final RxList<CommentDataItem> _items = <CommentDataItem>[].obs;

  final Map<String, _CommentDataItemFilterSubscription> _dynamicSubscription =
      {};
  final Rx<String?> currentCommentId = Rx<String?>(null);

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
      await CommentRepository().deleteFromLocalDb(id);
    }
    await rebuildLocal();
  }

  RxList<CommentDataItem> registerFilterSubscription({
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
    final worker = debounce(_items, (List<CommentDataItem> value) {
      final newFiltered = value
          .where((item) => filters.every((filter) => filter.apply(item)))
          .toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _CommentDataItemFilterSubscription(
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
    _items.value = await CommentRepository().listFromLocalDb();
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void onSelectComment(String id) {
    currentCommentId.value = id;
  }

  DataItem<Comment>? getComment(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }

  List<T> getCommentDetails<T>({
    List<DataItemFilter> filters = const [],
    required T Function(CommentDataItem item) selector,
  }) {
    return _items
        .where((item) => filters.every((filter) => filter.apply(item)))
        .map(selector)
        .toList();
  }

  int getCommentCount<T>({List<DataItemFilter> filters = const []}) {
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

  void _replaceLocal(String id, CommentDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    if (currentCommentId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentCommentId.value = fetchedItem.id;
    }
  }

  void addData(Comment newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = CommentDataItem.localNew(
      owner,
      newData,
      parentId: newData.postId,
    );
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _replaceLocal(newItem.id, newItem);
  }

  void updateData(String id, Comment updatedData) {
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
    CommentRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentCommentId.value == id) {
      currentCommentId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    /* deleted */
  }
}
