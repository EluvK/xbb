import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:sync_annotation/sync_annotation.dart';

class RepositoryGenerator extends GeneratorForAnnotation<Repository> {
  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) return '';

    final className = element.name!;
    final collectionName = annotation.read('collectionName').stringValue;
    final tableName = annotation.read('tableName').stringValue;
    final dbType = annotation.read('db').typeValue.getDisplayString();
    final bool generateAcl = annotation.read('withAcls').boolValue;

    final dataItemType = '${className}DataItem';
    final repositoryType = '${className}Repository';
    final controllerType = '${className}Controller';
    final activeItemId = 'current${className}Id';
    final extName = 'LocalStore$className';
    final syncEngineType = '_${className}SyncEngine';

    final buffer = StringBuffer();

    buffer.writeln(_generateExtension(className, extName, tableName, dbType));
    buffer.writeln('typedef $dataItemType = DataItem<$className>;\n');
    buffer.writeln(_generateRepository(className, repositoryType, dataItemType, extName));
    buffer.writeln(_generateFilterSubscriptionClass(dataItemType));
    buffer.writeln(
      _generateController(
        className,
        controllerType,
        dataItemType,
        repositoryType,
        syncEngineType,
        activeItemId,
        generateAcl,
      ),
    );
    if (generateAcl) {
      buffer.writeln(_generateAclExtension(repositoryType, controllerType, extName, collectionName, tableName));
    }
    buffer.writeln(
      _generateSyncEngine(className, syncEngineType, dataItemType, repositoryType, collectionName, tableName),
    );

    return buffer.toString();
  }

  String _generateExtension(String className, String extName, String tableName, String dbType) {
    return '''
extension $extName on $className {
  static String get tableName => '$tableName';

  static String get onCreateTable${className}SQL => 
      """
        CREATE TABLE \$tableName (
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
    return await $dbType().getDb();
  }
}
''';
  }

  String _generateRepository(String className, String repositoryType, String dataItemType, String extName) {
    return '''
class $repositoryType {
  Future<void> addToLocalDb($dataItemType item) async {
    final db = await $extName.getDb();
    await db.insert(
      $extName.tableName, item.toJson((r) => json.encode(r.toJson())),
    );
  }

  Future<$dataItemType?> getFromLocalDb(String id) async {
    final db = await $extName.getDb();
    final List<Map<String, dynamic>> maps = await db.query($extName.tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return DataItem<$className>.fromJson(maps.first, (jsonStr) => $className.fromJson(json.decode(jsonStr as String)));
    }
    return null;
  }

  Future<List<$dataItemType>> listFromLocalDb({String? parentId}) async {
    final db = await $extName.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      $extName.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps.map((map) => DataItem<$className>.fromJson(
      map, (jsonStr) => $className.fromJson(json.decode(jsonStr as String))))
      .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await $extName.getDb();
    await db.delete($extName.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToLocalDb($dataItemType item) async {
    final db = await $extName.getDb();
    await db.update(
      $extName.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb($dataItemType item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}
''';
  }

  String _generateFilterSubscriptionClass(String dataItemType) {
    return '''
class _${dataItemType}FilterSubscription {
  final RxList<$dataItemType> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _${dataItemType}FilterSubscription(this.filteredList, this.appliedFilters, this.worker);
}
''';
  }

  String _generateController(
    String className,
    String controllerType,
    String dataItemType,
    String repositoryType,
    String syncEngineType,
    String activeItemId,
    bool generateAcl,
  ) {
    String aclInitLogic = generateAcl
        ? '''
// preload ACLs for all items to make sure UI can get ACL info immediately
// this can be optimized by only load ACL when needed and cache it.
for (var item in _items) {
  await _getAclLocal(item.id);
}'''
        : '';
    return '''
class $controllerType extends GetxController {
  final SyncStoreClient client;
  final $syncEngineType _syncEngine;
  $controllerType(this.client) : _syncEngine = $syncEngineType(client);

  final RxList<$dataItemType> _items = <$dataItemType>[].obs;
  ${generateAcl ? 'final RxMap<String, List<Permission>> _aclCache = <String, List<Permission>>{}.obs;' : ''}
  final Map<String, _${dataItemType}FilterSubscription> _dynamicSubscription = {};
  final Rx<String?> $activeItemId = Rx<String?>(null);

  @override
  Future<void> onInit() async {
    await rebuildLocal();
    ${aclInitLogic}
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
      await $repositoryType().deleteFromLocalDb(id);
    }
    await rebuildLocal();
  }
  RxList<$dataItemType> registerFilterSubscription({required String filterKey, List<DataItemFilter> filters = const []}) {
    final existing = _dynamicSubscription[filterKey];
    if (existing != null && listEquals(existing.appliedFilters, filters)) {
      return existing.filteredList;
    }
    final newList = _items.where((item) => filters.every((filter) => filter.apply(item))).toList().obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<$dataItemType> value) {
      final newFiltered = value.where((item) => filters.every((filter) => filter.apply(item))).toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _${dataItemType}FilterSubscription(newList, filters, worker);
    return newList;
  }
  void unregisterFilterSubscription(String filterKey) {
    final sub = _dynamicSubscription.remove(filterKey);
    sub?.worker.dispose();
  }

  Future<void> rebuildLocal() async {
    _items.value = await $repositoryType().listFromLocalDb();
    _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  void onSelect$className(String id) {
    $activeItemId.value = id;
  }
  DataItem<$className>? get$className(String id) {
    return _items.firstWhereOrNull((item) => item.id == id);
  }
  List<T> get${className}Details<T>({
    List<DataItemFilter> filters = const [],
    required T Function($dataItemType item) selector,
  }) {
    return _items.where((item) => filters.every((filter) => filter.apply(item))).map(selector).toList();
  }
  int get${className}Count<T>({
    List<DataItemFilter> filters = const [],
  }) {
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
  void _replaceLocal(String id, $dataItemType fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    if ($activeItemId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      $activeItemId.value = fetchedItem.id;
    }
  }
  void addData($className newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = $dataItemType.localNew(owner, newData);
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem); 
    _syncEngine.create(newItem).then((fetchedItem) {
      _replaceLocal(newItem.id, fetchedItem);
    });
  }
  void updateData(String id, $className updatedData) {
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
    $repositoryType().updateToLocalDb(item);
  }
  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if ($activeItemId.value == id) {
      $activeItemId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    _syncEngine.delete(id, deleteFromServer ? true : status != SyncStatus.deleted);
  }
}
''';
  }

  String _generateSyncEngine(
    String className,
    String syncEngineType,
    String dataItemType,
    String repositoryType,
    String collectionName,
    String tableName,
  ) {
    return '''
class $syncEngineType {
  final SyncStoreClient client;
  $syncEngineType(this.client);

  Future<$dataItemType> create($dataItemType local) async {
    local.syncStatus = SyncStatus.syncing;
    await $repositoryType().addToLocalDb(local);

    $dataItemType createdItem;
    try {
      final newId = await client.create('$collectionName', '$tableName', local.body.toJson());
      createdItem = await client.get<$className>('$collectionName', '$tableName', newId, $className.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await $repositoryType().updateToLocalDb(local);
      rethrow;
    }
    createdItem.syncStatus = SyncStatus.archived;
    createdItem.colorTag = local.colorTag;

    await $repositoryType().deleteFromLocalDb(local.id);
    await $repositoryType().addToLocalDb(createdItem);
    return createdItem;
  }
  Future<$dataItemType> update($dataItemType local) async {
    local.syncStatus = SyncStatus.syncing;
    await $repositoryType().updateToLocalDb(local);

    $dataItemType updatedItem;
    try {
      await client.update('$collectionName', '$tableName', local.id, local.body.toJson());
      updatedItem = await client.get<$className>('$collectionName', '$tableName', local.id, $className.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await $repositoryType().updateToLocalDb(local);
      rethrow;
    }
    updatedItem.syncStatus = SyncStatus.archived;
    updatedItem.colorTag = local.colorTag;
    
    await $repositoryType().updateToLocalDb(updatedItem);
    return updatedItem;
  }
  void delete(String id, bool deleteFromServer) {
    $repositoryType().deleteFromLocalDb(id);
    if (!deleteFromServer) return;
    try {
      client.delete('$collectionName', '$tableName', id);
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
        final ListResponse resp = await client.list('$collectionName', '$tableName', withPermission: true, limit: 200, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final $dataItemType? localItem = await $repositoryType().getFromLocalDb(summary.id);
          if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
            // only get details for new created or updated items, otherwise just skip to save performance.
            needGetIds.add(summary.id);
          } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
            // local data is newer, need to sync to server
            localItem.syncStatus = SyncStatus.failed;
            await $repositoryType().updateToLocalDb(localItem);
          } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
            // same updatedAt but marked as special status, need to sync to server
            localItem.syncStatus = SyncStatus.archived;
            await $repositoryType().updateToLocalDb(localItem);
          }
        }
      } while (nextMarker != null);
      // 2. clean up local data that are deleted from server
      final localItems = await $repositoryType().listFromLocalDb();
      for ($dataItemType localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await $repositoryType().updateToLocalDb(localItem);
        }
      }

      // 3. batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('$collectionName', '$tableName', batchIds, $className.fromJson);
        for (var item in batchItems.items) {
          await $repositoryType().upsertToLocalDb(item);
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
      for (var i = 0; i< parentIds.length; i+=100) {
        final parentIdsBatch = parentIds.skip(i).take(100).toList();
        String? nextMarker;
        do {
          final ListResponse resp = await client.batchListChildren('$collectionName', '$tableName', parentIdsBatch, marker: nextMarker);
          nextMarker = resp.pageInfo.nextMarker;
          for (var summary in resp.items) {
            serviceIds.add(summary.id);
            final $dataItemType? localItem = await $repositoryType().getFromLocalDb(summary.id);
            if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
              // only get details for new created or updated items, otherwise just skip to save performance.
              needGetIds.add(summary.id);
            } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
              // local data is newer, need to sync to server
              localItem.syncStatus = SyncStatus.failed;
              await $repositoryType().updateToLocalDb(localItem);
            } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
              // same updatedAt but marked as special status, need to sync to server
              localItem.syncStatus = SyncStatus.archived;
              await $repositoryType().updateToLocalDb(localItem);
            }
          }
        } while (nextMarker != null);
      }
      // clean up local data that are deleted from server
      final localItems = await $repositoryType().listFromLocalDb();
      for ($dataItemType localItem in localItems) {
        if (localItem.parentId == null || !parentIds.contains(localItem.parentId!)) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await $repositoryType().updateToLocalDb(localItem);
        }
      }
      // batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('$collectionName', '$tableName', batchIds, $className.fromJson);
        for (var item in batchItems.items) {
          await $repositoryType().upsertToLocalDb(item);
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
        final ListResponse resp = await client.list('$collectionName', '$tableName', limit: 200, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final $dataItemType? localItem = await $repositoryType().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await $repositoryType().listFromLocalDb();
      for ($dataItemType localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await $repositoryType().updateToLocalDb(localItem);
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
        final ListResponse resp = await client.list('$collectionName', '$tableName', withPermission: true, limit: 200, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final $dataItemType? localItem = await $repositoryType().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await $repositoryType().listFromLocalDb();
      for ($dataItemType localItem in localItems) {
        if (localItem.owner == currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.hidden;
          await $repositoryType().updateToLocalDb(localItem);
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
        final ListResponse resp = await client.list('$collectionName', '$tableName', parentId: parentId, limit: 200, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final $dataItemType? localItem = await $repositoryType().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await $repositoryType().listFromLocalDb(parentId: parentId);
      for ($dataItemType localItem in localItems) {
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await $repositoryType().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> _compareRemote($dataItemType? localItem, DataItemSummary summary) async {
    if (localItem == null) {
      // new from server
      final $dataItemType item = await client.get<$className>('$collectionName', '$tableName', summary.id, $className.fromJson);
      await $repositoryType().addToLocalDb(item);
    } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
      // update local data.
      final $dataItemType item = await client.get<$className>('$collectionName', '$tableName', summary.id, $className.fromJson);
      await $repositoryType().updateToLocalDb(item);
    } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
      // local data is newer, need to sync to server
      localItem.syncStatus = SyncStatus.failed;
      await $repositoryType().updateToLocalDb(localItem);
    } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
      // same updatedAt but marked as special status, need to sync to server
      localItem.syncStatus = SyncStatus.archived;
      await $repositoryType().updateToLocalDb(localItem);
    }
  }
}
''';
  }

  String _generateAclExtension(
    String repositoryType,
    String controllerType,
    String extName,
    String collectionName,
    String tableName,
  ) {
    return '''
extension ${repositoryType}Acl on $repositoryType {
  static String get tableNameAcl => 'acl';
  Future<List<Permission>> getAcls(String dataId) async {
    final db = await $extName.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      tableNameAcl,
      where: 'data_id = ? AND data_collection = ?',
      whereArgs: [dataId, '$tableName'],
    );
    if (maps.isEmpty) {
      return [];
    }
    final permissionsJson = maps.first['permissions'] as String;
    final List<dynamic> permissionsList = json.decode(permissionsJson) as List<dynamic>;
    return permissionsList.map((e) => Permission.fromJson(e as Map<String, dynamic>)).toList();
  }
  Future<void> setAcls(String dataId, List<Permission> permissions) async {
    final db = await $extName.getDb();
    final permissionsJson = json.encode(permissions.map((e) => e.toJson()).toList());
    await db.insert(tableNameAcl, {
      'data_id': dataId,
      'data_collection': '$tableName',
      'permissions': permissionsJson,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
extension ${controllerType}Acl on ${controllerType} {
  Future<void> syncAcls() async {
    try {
      for (var item in _items) {
        final serviceAcls = await client.getAcls('$collectionName', '$tableName', item.id);
        await $repositoryType().setAcls(item.id, serviceAcls);
        _aclCache[item.id] = serviceAcls;
      }
    } catch (e) {
      print("Error syncing ACLs: \$e");
    }
  }
  Future<List<Permission>> _getAclLocal(String dataId) async {
    final localAcls = await $repositoryType().getAcls(dataId);
    _aclCache[dataId] = localAcls;
    return localAcls;
  }
  List<Permission> getAclCached(String dataId) => _aclCache[dataId] ?? [];
  Future<List<Permission>> getAclRefresh(String dataId) async {
    try {
      final List<Permission> getAcls = await client.getAcls('$collectionName', '$tableName', dataId);
      await ${repositoryType}().setAcls(dataId, getAcls);
      _aclCache[dataId] = getAcls;
      return getAcls;
    } catch (e) {
      print("Error fetching ACLs from server: \$e");
      return await ${repositoryType}().getAcls(dataId);
    }
  }
  Future<void> setAcls(String dataId, List<Permission> permissions) async {
    try {
      await client.updateAcls('$collectionName', '$tableName', dataId, permissions);
      await ${repositoryType}().setAcls(dataId, permissions);
      _aclCache[dataId] = permissions;
    } catch (e) {
      print("Error updating ACLs to server: \$e");
    }
  }
}

''';
  }
}

Builder syncModelBuilder(BuilderOptions options) => SharedPartBuilder([RepositoryGenerator()], 'syncstore');
