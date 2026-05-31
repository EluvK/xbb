// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatUsage _$ChatUsageFromJson(Map<String, dynamic> json) => _ChatUsage(
  promptTokens: (json['prompt_tokens'] as num).toInt(),
  completionTokens: (json['completion_tokens'] as num).toInt(),
  totalTokens: (json['total_tokens'] as num).toInt(),
);

Map<String, dynamic> _$ChatUsageToJson(_ChatUsage instance) => <String, dynamic>{
  'prompt_tokens': instance.promptTokens,
  'completion_tokens': instance.completionTokens,
  'total_tokens': instance.totalTokens,
};

_ChatAssistantModelConfig _$ChatAssistantModelConfigFromJson(Map<String, dynamic> json) => _ChatAssistantModelConfig(
  provider: $enumDecodeNullable(_$ChatAssistantModelProviderEnumMap, json['provider']),
  baseUrl: json['base_url'] as String?,
  model: json['model'] as String?,
  temperature: (json['temperature'] as num?)?.toDouble(),
  thinkingEnabled: json['thinking_enabled'] as bool?,
  reasoningEffort: json['reasoning_effort'] as String?,
);

Map<String, dynamic> _$ChatAssistantModelConfigToJson(_ChatAssistantModelConfig instance) => <String, dynamic>{
  'provider': ?_$ChatAssistantModelProviderEnumMap[instance.provider],
  'base_url': ?instance.baseUrl,
  'model': ?instance.model,
  'temperature': ?instance.temperature,
  'thinking_enabled': ?instance.thinkingEnabled,
  'reasoning_effort': ?instance.reasoningEffort,
};

const _$ChatAssistantModelProviderEnumMap = {ChatAssistantModelProvider.deepSeek: 'deepSeek'};

_ChatAssistant _$ChatAssistantFromJson(Map<String, dynamic> json) => _ChatAssistant(
  name: json['name'] as String,
  type: $enumDecode(_$ChatAssistantTypeEnumMap, json['type']),
  description: json['description'] as String,
  prompt: json['prompt'] as String,
  avatarUrl: json['avatar_url'] as String?,
  modelConfig: json['model_config'] == null
      ? null
      : ChatAssistantModelConfig.fromJson(json['model_config'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ChatAssistantToJson(_ChatAssistant instance) => <String, dynamic>{
  'name': instance.name,
  'type': _$ChatAssistantTypeEnumMap[instance.type]!,
  'description': instance.description,
  'prompt': instance.prompt,
  'avatar_url': instance.avatarUrl,
  'model_config': instance.modelConfig,
};

const _$ChatAssistantTypeEnumMap = {ChatAssistantType.system: 'system', ChatAssistantType.userDefined: 'userDefined'};

_ChatConversation _$ChatConversationFromJson(Map<String, dynamic> json) => _ChatConversation(
  name: json['name'] as String,
  assistantId: json['assistant_id'] as String,
  assistantName: json['assistant_name'] as String,
  like: json['like'] as bool? ?? false,
);

Map<String, dynamic> _$ChatConversationToJson(_ChatConversation instance) => <String, dynamic>{
  'name': instance.name,
  'assistant_id': instance.assistantId,
  'assistant_name': instance.assistantName,
  'like': instance.like,
};

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  conversationId: json['conversation_id'] as String,
  role: $enumDecode(_$ChatMessageRoleEnumMap, json['role']),
  text: json['text'] as String,
  reasoningText: json['reasoning_text'] as String?,
  usage: json['usage'] == null ? null : ChatUsage.fromJson(json['usage'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) => <String, dynamic>{
  'conversation_id': instance.conversationId,
  'role': _$ChatMessageRoleEnumMap[instance.role]!,
  'text': instance.text,
  'reasoning_text': instance.reasoningText,
  'usage': instance.usage,
};

const _$ChatMessageRoleEnumMap = {
  ChatMessageRole.system: 'system',
  ChatMessageRole.user: 'user',
  ChatMessageRole.assistant: 'assistant',
};

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

extension LocalStoreChatAssistant on ChatAssistant {
  static String get tableName => 'assistant';

  static String get onCreateTableChatAssistantSQL =>
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
    return await ChatDB().getDb();
  }
}

typedef ChatAssistantDataItem = DataItem<ChatAssistant>;

class ChatAssistantRepository {
  Future<void> addToLocalDb(ChatAssistantDataItem item) async {
    final db = await LocalStoreChatAssistant.getDb();
    await db.insert(LocalStoreChatAssistant.tableName, item.toJson((r) => json.encode(r.toJson())));
  }

  Future<ChatAssistantDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreChatAssistant.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreChatAssistant.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<ChatAssistant>.fromJson(
        maps.first,
        (jsonStr) => ChatAssistant.fromJson(json.decode(jsonStr as String)),
      );
    }
    return null;
  }

  Future<List<ChatAssistantDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStoreChatAssistant.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreChatAssistant.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps
        .map(
          (map) => DataItem<ChatAssistant>.fromJson(
            map,
            (jsonStr) => ChatAssistant.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreChatAssistant.getDb();
    await db.delete(LocalStoreChatAssistant.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToLocalDb(ChatAssistantDataItem item) async {
    final db = await LocalStoreChatAssistant.getDb();
    await db.update(
      LocalStoreChatAssistant.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(ChatAssistantDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}

class _ChatAssistantDataItemFilterSubscription {
  final RxList<ChatAssistantDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _ChatAssistantDataItemFilterSubscription(this.filteredList, this.appliedFilters, this.worker);
}

class ChatAssistantController extends GetxController {
  final SyncStoreClient client;
  final _ChatAssistantSyncEngine _syncEngine;
  ChatAssistantController(this.client) : _syncEngine = _ChatAssistantSyncEngine(client);

  final RxList<ChatAssistantDataItem> _items = <ChatAssistantDataItem>[].obs;

  final Map<String, _ChatAssistantDataItemFilterSubscription> _dynamicSubscription = {};
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
    final newList = _items.where((item) => filters.every((filter) => filter.apply(item))).toList().obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<ChatAssistantDataItem> value) {
      final newFiltered = value.where((item) => filters.every((filter) => filter.apply(item))).toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _ChatAssistantDataItemFilterSubscription(newList, filters, worker);
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
    return _items.where((item) => filters.every((filter) => filter.apply(item))).map(selector).toList();
  }

  int getChatAssistantCount<T>({List<DataItemFilter> filters = const []}) {
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
    _syncEngine.create(newItem).then((fetchedItem) {
      _replaceLocal(newItem.id, fetchedItem);
    });
  }

  void updateData(String id, ChatAssistant updatedData) {
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
    ChatAssistantRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentChatAssistantId.value == id) {
      currentChatAssistantId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    _syncEngine.delete(id, deleteFromServer ? true : status != SyncStatus.deleted);
  }
}

class _ChatAssistantSyncEngine {
  final SyncStoreClient client;
  _ChatAssistantSyncEngine(this.client);

  Future<ChatAssistantDataItem> create(ChatAssistantDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await ChatAssistantRepository().addToLocalDb(local);

    ChatAssistantDataItem createdItem;
    try {
      final newId = await client.create('chat', 'assistant', local.body.toJson());
      createdItem = await client.get<ChatAssistant>('chat', 'assistant', newId, ChatAssistant.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await ChatAssistantRepository().updateToLocalDb(local);
      rethrow;
    }
    createdItem.syncStatus = SyncStatus.archived;
    createdItem.colorTag = local.colorTag;

    await ChatAssistantRepository().deleteFromLocalDb(local.id);
    await ChatAssistantRepository().addToLocalDb(createdItem);
    return createdItem;
  }

  Future<ChatAssistantDataItem> update(ChatAssistantDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await ChatAssistantRepository().updateToLocalDb(local);

    ChatAssistantDataItem updatedItem;
    try {
      await client.update('chat', 'assistant', local.id, local.body.toJson());
      updatedItem = await client.get<ChatAssistant>('chat', 'assistant', local.id, ChatAssistant.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await ChatAssistantRepository().updateToLocalDb(local);
      rethrow;
    }
    updatedItem.syncStatus = SyncStatus.archived;
    updatedItem.colorTag = local.colorTag;

    await ChatAssistantRepository().updateToLocalDb(updatedItem);
    return updatedItem;
  }

  void delete(String id, bool deleteFromServer) {
    ChatAssistantRepository().deleteFromLocalDb(id);
    if (!deleteFromServer) return;
    try {
      client.delete('chat', 'assistant', id);
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
          'chat',
          'assistant',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ChatAssistantDataItem? localItem = await ChatAssistantRepository().getFromLocalDb(summary.id);
          if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
            // only get details for new created or updated items, otherwise just skip to save performance.
            needGetIds.add(summary.id);
          } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
            // local data is newer, need to sync to server
            localItem.syncStatus = SyncStatus.failed;
            await ChatAssistantRepository().updateToLocalDb(localItem);
          } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
            // same updatedAt but marked as special status, need to sync to server
            localItem.syncStatus = SyncStatus.archived;
            await ChatAssistantRepository().updateToLocalDb(localItem);
          }
        }
      } while (nextMarker != null);
      // 2. clean up local data that are deleted from server
      final localItems = await ChatAssistantRepository().listFromLocalDb();
      for (ChatAssistantDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ChatAssistantRepository().updateToLocalDb(localItem);
        }
      }

      // 3. batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('chat', 'assistant', batchIds, ChatAssistant.fromJson);
        for (var item in batchItems.items) {
          await ChatAssistantRepository().upsertToLocalDb(item);
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
            'chat',
            'assistant',
            parentIdsBatch,
            marker: nextMarker,
          );
          nextMarker = resp.pageInfo.nextMarker;
          for (var summary in resp.items) {
            serviceIds.add(summary.id);
            final ChatAssistantDataItem? localItem = await ChatAssistantRepository().getFromLocalDb(summary.id);
            if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
              // only get details for new created or updated items, otherwise just skip to save performance.
              needGetIds.add(summary.id);
            } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
              // local data is newer, need to sync to server
              localItem.syncStatus = SyncStatus.failed;
              await ChatAssistantRepository().updateToLocalDb(localItem);
            } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
              // same updatedAt but marked as special status, need to sync to server
              localItem.syncStatus = SyncStatus.archived;
              await ChatAssistantRepository().updateToLocalDb(localItem);
            }
          }
        } while (nextMarker != null);
      }
      // clean up local data that are deleted from server
      final localItems = await ChatAssistantRepository().listFromLocalDb();
      for (ChatAssistantDataItem localItem in localItems) {
        if (localItem.parentId == null || !parentIds.contains(localItem.parentId!)) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ChatAssistantRepository().updateToLocalDb(localItem);
        }
      }
      // batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('chat', 'assistant', batchIds, ChatAssistant.fromJson);
        for (var item in batchItems.items) {
          await ChatAssistantRepository().upsertToLocalDb(item);
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
        final ListResponse resp = await client.list('chat', 'assistant', limit: 200, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ChatAssistantDataItem? localItem = await ChatAssistantRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await ChatAssistantRepository().listFromLocalDb();
      for (ChatAssistantDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ChatAssistantRepository().updateToLocalDb(localItem);
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
          'chat',
          'assistant',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ChatAssistantDataItem? localItem = await ChatAssistantRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await ChatAssistantRepository().listFromLocalDb();
      for (ChatAssistantDataItem localItem in localItems) {
        if (localItem.owner == currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.hidden;
          await ChatAssistantRepository().updateToLocalDb(localItem);
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
          'chat',
          'assistant',
          parentId: parentId,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ChatAssistantDataItem? localItem = await ChatAssistantRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await ChatAssistantRepository().listFromLocalDb(parentId: parentId);
      for (ChatAssistantDataItem localItem in localItems) {
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ChatAssistantRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> _compareRemote(ChatAssistantDataItem? localItem, DataItemSummary summary) async {
    if (localItem == null) {
      // new from server
      final ChatAssistantDataItem item = await client.get<ChatAssistant>(
        'chat',
        'assistant',
        summary.id,
        ChatAssistant.fromJson,
      );
      await ChatAssistantRepository().addToLocalDb(item);
    } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
      // update local data.
      final ChatAssistantDataItem item = await client.get<ChatAssistant>(
        'chat',
        'assistant',
        summary.id,
        ChatAssistant.fromJson,
      );
      await ChatAssistantRepository().updateToLocalDb(item);
    } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
      // local data is newer, need to sync to server
      localItem.syncStatus = SyncStatus.failed;
      await ChatAssistantRepository().updateToLocalDb(localItem);
    } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
      // same updatedAt but marked as special status, need to sync to server
      localItem.syncStatus = SyncStatus.archived;
      await ChatAssistantRepository().updateToLocalDb(localItem);
    }
  }
}

extension LocalStoreChatConversation on ChatConversation {
  static String get tableName => 'conversation';

  static String get onCreateTableChatConversationSQL =>
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
    return await ChatDB().getDb();
  }
}

typedef ChatConversationDataItem = DataItem<ChatConversation>;

class ChatConversationRepository {
  Future<void> addToLocalDb(ChatConversationDataItem item) async {
    final db = await LocalStoreChatConversation.getDb();
    await db.insert(LocalStoreChatConversation.tableName, item.toJson((r) => json.encode(r.toJson())));
  }

  Future<ChatConversationDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreChatConversation.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreChatConversation.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<ChatConversation>.fromJson(
        maps.first,
        (jsonStr) => ChatConversation.fromJson(json.decode(jsonStr as String)),
      );
    }
    return null;
  }

  Future<List<ChatConversationDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStoreChatConversation.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreChatConversation.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps
        .map(
          (map) => DataItem<ChatConversation>.fromJson(
            map,
            (jsonStr) => ChatConversation.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreChatConversation.getDb();
    await db.delete(LocalStoreChatConversation.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToLocalDb(ChatConversationDataItem item) async {
    final db = await LocalStoreChatConversation.getDb();
    await db.update(
      LocalStoreChatConversation.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(ChatConversationDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}

class _ChatConversationDataItemFilterSubscription {
  final RxList<ChatConversationDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _ChatConversationDataItemFilterSubscription(this.filteredList, this.appliedFilters, this.worker);
}

class ChatConversationController extends GetxController {
  final SyncStoreClient client;
  final _ChatConversationSyncEngine _syncEngine;
  ChatConversationController(this.client) : _syncEngine = _ChatConversationSyncEngine(client);

  final RxList<ChatConversationDataItem> _items = <ChatConversationDataItem>[].obs;

  final Map<String, _ChatConversationDataItemFilterSubscription> _dynamicSubscription = {};
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
    final newList = _items.where((item) => filters.every((filter) => filter.apply(item))).toList().obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<ChatConversationDataItem> value) {
      final newFiltered = value.where((item) => filters.every((filter) => filter.apply(item))).toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _ChatConversationDataItemFilterSubscription(newList, filters, worker);
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
    return _items.where((item) => filters.every((filter) => filter.apply(item))).map(selector).toList();
  }

  int getChatConversationCount<T>({List<DataItemFilter> filters = const []}) {
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
    _syncEngine.create(newItem).then((fetchedItem) {
      _replaceLocal(newItem.id, fetchedItem);
    });
  }

  void updateData(String id, ChatConversation updatedData) {
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
    ChatConversationRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentChatConversationId.value == id) {
      currentChatConversationId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    _syncEngine.delete(id, deleteFromServer ? true : status != SyncStatus.deleted);
  }
}

class _ChatConversationSyncEngine {
  final SyncStoreClient client;
  _ChatConversationSyncEngine(this.client);

  Future<ChatConversationDataItem> create(ChatConversationDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await ChatConversationRepository().addToLocalDb(local);

    ChatConversationDataItem createdItem;
    try {
      final newId = await client.create('chat', 'conversation', local.body.toJson());
      createdItem = await client.get<ChatConversation>('chat', 'conversation', newId, ChatConversation.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await ChatConversationRepository().updateToLocalDb(local);
      rethrow;
    }
    createdItem.syncStatus = SyncStatus.archived;
    createdItem.colorTag = local.colorTag;

    await ChatConversationRepository().deleteFromLocalDb(local.id);
    await ChatConversationRepository().addToLocalDb(createdItem);
    return createdItem;
  }

  Future<ChatConversationDataItem> update(ChatConversationDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await ChatConversationRepository().updateToLocalDb(local);

    ChatConversationDataItem updatedItem;
    try {
      await client.update('chat', 'conversation', local.id, local.body.toJson());
      updatedItem = await client.get<ChatConversation>('chat', 'conversation', local.id, ChatConversation.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await ChatConversationRepository().updateToLocalDb(local);
      rethrow;
    }
    updatedItem.syncStatus = SyncStatus.archived;
    updatedItem.colorTag = local.colorTag;

    await ChatConversationRepository().updateToLocalDb(updatedItem);
    return updatedItem;
  }

  void delete(String id, bool deleteFromServer) {
    ChatConversationRepository().deleteFromLocalDb(id);
    if (!deleteFromServer) return;
    try {
      client.delete('chat', 'conversation', id);
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
          'chat',
          'conversation',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ChatConversationDataItem? localItem = await ChatConversationRepository().getFromLocalDb(summary.id);
          if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
            // only get details for new created or updated items, otherwise just skip to save performance.
            needGetIds.add(summary.id);
          } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
            // local data is newer, need to sync to server
            localItem.syncStatus = SyncStatus.failed;
            await ChatConversationRepository().updateToLocalDb(localItem);
          } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
            // same updatedAt but marked as special status, need to sync to server
            localItem.syncStatus = SyncStatus.archived;
            await ChatConversationRepository().updateToLocalDb(localItem);
          }
        }
      } while (nextMarker != null);
      // 2. clean up local data that are deleted from server
      final localItems = await ChatConversationRepository().listFromLocalDb();
      for (ChatConversationDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ChatConversationRepository().updateToLocalDb(localItem);
        }
      }

      // 3. batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('chat', 'conversation', batchIds, ChatConversation.fromJson);
        for (var item in batchItems.items) {
          await ChatConversationRepository().upsertToLocalDb(item);
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
            'chat',
            'conversation',
            parentIdsBatch,
            marker: nextMarker,
          );
          nextMarker = resp.pageInfo.nextMarker;
          for (var summary in resp.items) {
            serviceIds.add(summary.id);
            final ChatConversationDataItem? localItem = await ChatConversationRepository().getFromLocalDb(summary.id);
            if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
              // only get details for new created or updated items, otherwise just skip to save performance.
              needGetIds.add(summary.id);
            } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
              // local data is newer, need to sync to server
              localItem.syncStatus = SyncStatus.failed;
              await ChatConversationRepository().updateToLocalDb(localItem);
            } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
              // same updatedAt but marked as special status, need to sync to server
              localItem.syncStatus = SyncStatus.archived;
              await ChatConversationRepository().updateToLocalDb(localItem);
            }
          }
        } while (nextMarker != null);
      }
      // clean up local data that are deleted from server
      final localItems = await ChatConversationRepository().listFromLocalDb();
      for (ChatConversationDataItem localItem in localItems) {
        if (localItem.parentId == null || !parentIds.contains(localItem.parentId!)) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ChatConversationRepository().updateToLocalDb(localItem);
        }
      }
      // batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('chat', 'conversation', batchIds, ChatConversation.fromJson);
        for (var item in batchItems.items) {
          await ChatConversationRepository().upsertToLocalDb(item);
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
        final ListResponse resp = await client.list('chat', 'conversation', limit: 200, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ChatConversationDataItem? localItem = await ChatConversationRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await ChatConversationRepository().listFromLocalDb();
      for (ChatConversationDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ChatConversationRepository().updateToLocalDb(localItem);
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
          'chat',
          'conversation',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ChatConversationDataItem? localItem = await ChatConversationRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await ChatConversationRepository().listFromLocalDb();
      for (ChatConversationDataItem localItem in localItems) {
        if (localItem.owner == currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.hidden;
          await ChatConversationRepository().updateToLocalDb(localItem);
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
          'chat',
          'conversation',
          parentId: parentId,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ChatConversationDataItem? localItem = await ChatConversationRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await ChatConversationRepository().listFromLocalDb(parentId: parentId);
      for (ChatConversationDataItem localItem in localItems) {
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ChatConversationRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> _compareRemote(ChatConversationDataItem? localItem, DataItemSummary summary) async {
    if (localItem == null) {
      // new from server
      final ChatConversationDataItem item = await client.get<ChatConversation>(
        'chat',
        'conversation',
        summary.id,
        ChatConversation.fromJson,
      );
      await ChatConversationRepository().addToLocalDb(item);
    } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
      // update local data.
      final ChatConversationDataItem item = await client.get<ChatConversation>(
        'chat',
        'conversation',
        summary.id,
        ChatConversation.fromJson,
      );
      await ChatConversationRepository().updateToLocalDb(item);
    } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
      // local data is newer, need to sync to server
      localItem.syncStatus = SyncStatus.failed;
      await ChatConversationRepository().updateToLocalDb(localItem);
    } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
      // same updatedAt but marked as special status, need to sync to server
      localItem.syncStatus = SyncStatus.archived;
      await ChatConversationRepository().updateToLocalDb(localItem);
    }
  }
}

extension LocalStoreChatMessage on ChatMessage {
  static String get tableName => 'message';

  static String get onCreateTableChatMessageSQL =>
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
    return await ChatDB().getDb();
  }
}

typedef ChatMessageDataItem = DataItem<ChatMessage>;

class ChatMessageRepository {
  Future<void> addToLocalDb(ChatMessageDataItem item) async {
    final db = await LocalStoreChatMessage.getDb();
    await db.insert(LocalStoreChatMessage.tableName, item.toJson((r) => json.encode(r.toJson())));
  }

  Future<ChatMessageDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreChatMessage.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreChatMessage.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<ChatMessage>.fromJson(
        maps.first,
        (jsonStr) => ChatMessage.fromJson(json.decode(jsonStr as String)),
      );
    }
    return null;
  }

  Future<List<ChatMessageDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStoreChatMessage.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreChatMessage.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps
        .map(
          (map) =>
              DataItem<ChatMessage>.fromJson(map, (jsonStr) => ChatMessage.fromJson(json.decode(jsonStr as String))),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreChatMessage.getDb();
    await db.delete(LocalStoreChatMessage.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToLocalDb(ChatMessageDataItem item) async {
    final db = await LocalStoreChatMessage.getDb();
    await db.update(
      LocalStoreChatMessage.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(ChatMessageDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}

class _ChatMessageDataItemFilterSubscription {
  final RxList<ChatMessageDataItem> filteredList;
  final List<DataItemFilter> appliedFilters;
  final Worker worker;
  _ChatMessageDataItemFilterSubscription(this.filteredList, this.appliedFilters, this.worker);
}

class ChatMessageController extends GetxController {
  final SyncStoreClient client;
  final _ChatMessageSyncEngine _syncEngine;
  ChatMessageController(this.client) : _syncEngine = _ChatMessageSyncEngine(client);

  final RxList<ChatMessageDataItem> _items = <ChatMessageDataItem>[].obs;

  final Map<String, _ChatMessageDataItemFilterSubscription> _dynamicSubscription = {};
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
    final newList = _items.where((item) => filters.every((filter) => filter.apply(item))).toList().obs;
    existing?.worker.dispose();
    final worker = debounce(_items, (List<ChatMessageDataItem> value) {
      final newFiltered = value.where((item) => filters.every((filter) => filter.apply(item))).toList();
      newList.assignAll(newFiltered);
    }, time: const Duration(milliseconds: 100));
    _dynamicSubscription[filterKey] = _ChatMessageDataItemFilterSubscription(newList, filters, worker);
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
    return _items.where((item) => filters.every((filter) => filter.apply(item))).map(selector).toList();
  }

  int getChatMessageCount<T>({List<DataItemFilter> filters = const []}) {
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
    final newItem = ChatMessageDataItem.localNew(owner, newData, parentId: newData.conversationId);
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _syncEngine.create(newItem).then((fetchedItem) {
      _replaceLocal(newItem.id, fetchedItem);
    });
  }

  void updateData(String id, ChatMessage updatedData) {
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
    ChatMessageRepository().updateToLocalDb(item);
  }

  void deleteData(String id, {bool deleteFromServer = false}) {
    _items.removeWhere((item) => item.id == id);
    if (currentChatMessageId.value == id) {
      currentChatMessageId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    _syncEngine.delete(id, deleteFromServer ? true : status != SyncStatus.deleted);
  }
}

class _ChatMessageSyncEngine {
  final SyncStoreClient client;
  _ChatMessageSyncEngine(this.client);

  Future<ChatMessageDataItem> create(ChatMessageDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await ChatMessageRepository().addToLocalDb(local);

    ChatMessageDataItem createdItem;
    try {
      final newId = await client.create('chat', 'message', local.body.toJson());
      createdItem = await client.get<ChatMessage>('chat', 'message', newId, ChatMessage.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await ChatMessageRepository().updateToLocalDb(local);
      rethrow;
    }
    createdItem.syncStatus = SyncStatus.archived;
    createdItem.colorTag = local.colorTag;

    await ChatMessageRepository().deleteFromLocalDb(local.id);
    await ChatMessageRepository().addToLocalDb(createdItem);
    return createdItem;
  }

  Future<ChatMessageDataItem> update(ChatMessageDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await ChatMessageRepository().updateToLocalDb(local);

    ChatMessageDataItem updatedItem;
    try {
      await client.update('chat', 'message', local.id, local.body.toJson());
      updatedItem = await client.get<ChatMessage>('chat', 'message', local.id, ChatMessage.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await ChatMessageRepository().updateToLocalDb(local);
      rethrow;
    }
    updatedItem.syncStatus = SyncStatus.archived;
    updatedItem.colorTag = local.colorTag;

    await ChatMessageRepository().updateToLocalDb(updatedItem);
    return updatedItem;
  }

  void delete(String id, bool deleteFromServer) {
    ChatMessageRepository().deleteFromLocalDb(id);
    if (!deleteFromServer) return;
    try {
      client.delete('chat', 'message', id);
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
          'chat',
          'message',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ChatMessageDataItem? localItem = await ChatMessageRepository().getFromLocalDb(summary.id);
          if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
            // only get details for new created or updated items, otherwise just skip to save performance.
            needGetIds.add(summary.id);
          } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
            // local data is newer, need to sync to server
            localItem.syncStatus = SyncStatus.failed;
            await ChatMessageRepository().updateToLocalDb(localItem);
          } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
            // same updatedAt but marked as special status, need to sync to server
            localItem.syncStatus = SyncStatus.archived;
            await ChatMessageRepository().updateToLocalDb(localItem);
          }
        }
      } while (nextMarker != null);
      // 2. clean up local data that are deleted from server
      final localItems = await ChatMessageRepository().listFromLocalDb();
      for (ChatMessageDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ChatMessageRepository().updateToLocalDb(localItem);
        }
      }

      // 3. batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('chat', 'message', batchIds, ChatMessage.fromJson);
        for (var item in batchItems.items) {
          await ChatMessageRepository().upsertToLocalDb(item);
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
            'chat',
            'message',
            parentIdsBatch,
            marker: nextMarker,
          );
          nextMarker = resp.pageInfo.nextMarker;
          for (var summary in resp.items) {
            serviceIds.add(summary.id);
            final ChatMessageDataItem? localItem = await ChatMessageRepository().getFromLocalDb(summary.id);
            if (localItem == null || localItem.updatedAt.isBefore(summary.updatedAt)) {
              // only get details for new created or updated items, otherwise just skip to save performance.
              needGetIds.add(summary.id);
            } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
              // local data is newer, need to sync to server
              localItem.syncStatus = SyncStatus.failed;
              await ChatMessageRepository().updateToLocalDb(localItem);
            } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
              // same updatedAt but marked as special status, need to sync to server
              localItem.syncStatus = SyncStatus.archived;
              await ChatMessageRepository().updateToLocalDb(localItem);
            }
          }
        } while (nextMarker != null);
      }
      // clean up local data that are deleted from server
      final localItems = await ChatMessageRepository().listFromLocalDb();
      for (ChatMessageDataItem localItem in localItems) {
        if (localItem.parentId == null || !parentIds.contains(localItem.parentId!)) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ChatMessageRepository().updateToLocalDb(localItem);
        }
      }
      // batch get details for items that need to be updated or created locally
      final needGetIdsList = needGetIds.toList();
      for (var i = 0; i < needGetIdsList.length;) {
        final batchIds = needGetIdsList.skip(i).take(batchSize).toList();
        final batchItems = await client.batchGet('chat', 'message', batchIds, ChatMessage.fromJson);
        for (var item in batchItems.items) {
          await ChatMessageRepository().upsertToLocalDb(item);
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
        final ListResponse resp = await client.list('chat', 'message', limit: 200, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ChatMessageDataItem? localItem = await ChatMessageRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await ChatMessageRepository().listFromLocalDb();
      for (ChatMessageDataItem localItem in localItems) {
        if (localItem.owner != currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ChatMessageRepository().updateToLocalDb(localItem);
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
          'chat',
          'message',
          withPermission: true,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ChatMessageDataItem? localItem = await ChatMessageRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await ChatMessageRepository().listFromLocalDb();
      for (ChatMessageDataItem localItem in localItems) {
        if (localItem.owner == currentUserId) {
          continue;
        }
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.hidden;
          await ChatMessageRepository().updateToLocalDb(localItem);
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
          'chat',
          'message',
          parentId: parentId,
          limit: 200,
          marker: nextMarker,
        );
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final ChatMessageDataItem? localItem = await ChatMessageRepository().getFromLocalDb(summary.id);
          await _compareRemote(localItem, summary);
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await ChatMessageRepository().listFromLocalDb(parentId: parentId);
      for (ChatMessageDataItem localItem in localItems) {
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await ChatMessageRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }

  Future<void> _compareRemote(ChatMessageDataItem? localItem, DataItemSummary summary) async {
    if (localItem == null) {
      // new from server
      final ChatMessageDataItem item = await client.get<ChatMessage>(
        'chat',
        'message',
        summary.id,
        ChatMessage.fromJson,
      );
      await ChatMessageRepository().addToLocalDb(item);
    } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
      // update local data.
      final ChatMessageDataItem item = await client.get<ChatMessage>(
        'chat',
        'message',
        summary.id,
        ChatMessage.fromJson,
      );
      await ChatMessageRepository().updateToLocalDb(item);
    } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
      // local data is newer, need to sync to server
      localItem.syncStatus = SyncStatus.failed;
      await ChatMessageRepository().updateToLocalDb(localItem);
    } else if (localItem.syncStatus == SyncStatus.deleted || localItem.syncStatus == SyncStatus.hidden) {
      // same updatedAt but marked as special status, need to sync to server
      localItem.syncStatus = SyncStatus.archived;
      await ChatMessageRepository().updateToLocalDb(localItem);
    }
  }
}
