import 'dart:async';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:uuid/uuid.dart';
import 'package:xbb/client/chat/client.dart';
import 'package:xbb/client/chat/llm/common.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/syncstore.dart';
import 'package:xbb/models/chat/model.dart';
import 'package:xbb/utils/utils.dart';

enum ChatLocalMessageState { streaming, completed, error, cancelled }

enum ChatConversationSyncState { localOnly, dirty, synced, syncError }

class ChatSyncMeta {
  final String? remoteConversationId;
  final String? lastSyncedMessageId;
  final int syncedMessageCount;
  final DateTime? lastSyncedAt;

  const ChatSyncMeta({
    this.remoteConversationId,
    this.lastSyncedMessageId,
    this.syncedMessageCount = 0,
    this.lastSyncedAt,
  });

  ChatSyncMeta copyWith({
    String? remoteConversationId,
    String? lastSyncedMessageId,
    int? syncedMessageCount,
    DateTime? lastSyncedAt,
  }) {
    return ChatSyncMeta(
      remoteConversationId: remoteConversationId ?? this.remoteConversationId,
      lastSyncedMessageId: lastSyncedMessageId ?? this.lastSyncedMessageId,
      syncedMessageCount: syncedMessageCount ?? this.syncedMessageCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'remote_conversation_id': remoteConversationId,
      'last_synced_message_id': lastSyncedMessageId,
      'synced_message_count': syncedMessageCount,
      'last_synced_at': lastSyncedAt?.toUtc().toIso8601String(),
    };
  }

  factory ChatSyncMeta.fromJson(Map<String, dynamic> json) {
    return ChatSyncMeta(
      remoteConversationId: json['remote_conversation_id'] as String?,
      lastSyncedMessageId: json['last_synced_message_id'] as String?,
      syncedMessageCount: ((json['synced_message_count'] as num?) ?? 0).toInt(),
      lastSyncedAt: json['last_synced_at'] == null ? null : DateTime.tryParse(json['last_synced_at'] as String),
    );
  }
}

class ChatConversationViewModel {
  final ChatConversationDataItem item;
  final ChatSyncMeta syncMeta;
  final ChatConversationSyncState syncState;
  final int pendingSyncCount;

  const ChatConversationViewModel({
    required this.item,
    required this.syncMeta,
    required this.syncState,
    required this.pendingSyncCount,
  });
}

class ChatManualSyncResult {
  final int totalCandidates;
  final int syncedCount;
  final int skippedCount;
  final bool success;
  final String? failedMessageId;

  const ChatManualSyncResult({
    required this.totalCandidates,
    required this.syncedCount,
    required this.skippedCount,
    required this.success,
    this.failedMessageId,
  });
}

Future<void> reInitChatController() async {
  if (_reInitChatControllerFuture != null) {
    await _reInitChatControllerFuture;
    return;
  }
  _reInitChatControllerFuture = () async {
    if (Get.isRegistered<ChatController>()) {
      await Get.delete<ChatController>(force: true);
    }
    await Get.putAsync<ChatController>(() async {
      final controller = ChatController();
      await controller.ensureInitialization();
      return controller;
    }, permanent: true);
  }();
  try {
    await _reInitChatControllerFuture;
  } finally {
    _reInitChatControllerFuture = null;
  }
}

Future<void>? _reInitChatControllerFuture;

class ChatController extends GetxController {
  static const Uuid _uuid = Uuid();

  final _chatClient = const ChatClient();
  final _storage = GetStorage(GET_STORAGE_FILE_KEY);
  final RxBool waitingForResponse = false.obs;
  final RxSet<String> syncingConversationIds = <String>{}.obs;
  final RxnString currentConversationId = RxnString();
  final RxList<ChatConversationDataItem> conversationList = <ChatConversationDataItem>[].obs;
  final RxList<ChatMessageDataItem> messageList = <ChatMessageDataItem>[].obs;
  final RxList<ChatConversationViewModel> conversationViewModels = <ChatConversationViewModel>[].obs;

  final Map<String, ChatSyncMeta> _syncMetaByConversation = <String, ChatSyncMeta>{};
  final Map<String, ChatLocalMessageState> _localStateByMessage = <String, ChatLocalMessageState>{};
  final Map<String, String> _remoteMessageIdByMessage = <String, String>{};
  final Map<String, Future<void>> _pendingDeltaByMessage = <String, Future<void>>{};

  ChatStreamHandle? _currentStream;
  String? _streamingMessageId;
  bool _initialized = false;

  Future<void> ensureInitialization() async {
    while (!_initialized) {
      await onInit();
    }
  }

  @override
  Future<void> onInit() async {
    await _ensureGeneratedControllers();
    _loadMetaMapsFromStorage();
    await reloadConversations();
    _initialized = true;
    super.onInit();
  }

  @override
  void onClose() {
    _currentStream?.cancel();
    super.onClose();
  }

  Future<void> _ensureGeneratedControllers() async {
    final client = Get.find<SyncStoreControl>().syncStoreClient;
    if (!Get.isRegistered<ChatAssistantController>()) {
      final controller = await Get.putAsync<ChatAssistantController>(
        () async => ChatAssistantController(client),
        permanent: true,
      );
      await controller.ensureInitialization();
    }
    if (!Get.isRegistered<ChatConversationController>()) {
      final controller = await Get.putAsync<ChatConversationController>(
        () async => ChatConversationController(client),
        permanent: true,
      );
      await controller.ensureInitialization();
    }
    if (!Get.isRegistered<ChatMessageController>()) {
      final controller = await Get.putAsync<ChatMessageController>(
        () async => ChatMessageController(client),
        permanent: true,
      );
      await controller.ensureInitialization();
    }
  }

  void _loadMetaMapsFromStorage() {
    final rawMeta = _storage.read<Map<String, dynamic>>(STORAGE_CHAT_SYNC_META_KEY) ?? <String, dynamic>{};
    final rawState = _storage.read<Map<String, dynamic>>(STORAGE_CHAT_MESSAGE_STATE_KEY) ?? <String, dynamic>{};
    final rawRemote = _storage.read<Map<String, dynamic>>(STORAGE_CHAT_MESSAGE_REMOTE_ID_KEY) ?? <String, dynamic>{};

    _syncMetaByConversation
      ..clear()
      ..addAll(
        rawMeta.map((key, value) => MapEntry(key, ChatSyncMeta.fromJson(Map<String, dynamic>.from(value as Map)))),
      );
    _localStateByMessage
      ..clear()
      ..addAll(
        rawState.map((key, value) {
          final parsed = ChatLocalMessageState.values.firstWhere(
            (e) => e.name == value,
            orElse: () => ChatLocalMessageState.completed,
          );
          return MapEntry(key, parsed);
        }),
      );
    _remoteMessageIdByMessage
      ..clear()
      ..addAll(rawRemote.map((key, value) => MapEntry(key, value.toString())));
  }

  void _saveMetaMaps() {
    _storage.write(
      STORAGE_CHAT_SYNC_META_KEY,
      _syncMetaByConversation.map((key, value) => MapEntry(key, value.toJson())),
    );
    _storage.write(STORAGE_CHAT_MESSAGE_STATE_KEY, _localStateByMessage.map((key, value) => MapEntry(key, value.name)));
    _storage.write(STORAGE_CHAT_MESSAGE_REMOTE_ID_KEY, _remoteMessageIdByMessage);
  }

  ChatSyncMeta _metaOfConversation(String conversationId) {
    return _syncMetaByConversation[conversationId] ?? const ChatSyncMeta();
  }

  ChatLocalMessageState _stateOfMessage(String messageId) {
    return _localStateByMessage[messageId] ?? ChatLocalMessageState.completed;
  }

  ChatLocalMessageState messageStateOf(String messageId) {
    return _stateOfMessage(messageId);
  }

  void _setMessageState(String messageId, ChatLocalMessageState state) {
    _localStateByMessage[messageId] = state;
    _saveMetaMaps();
  }

  Future<void> reloadConversations() async {
    final conversations = await ChatConversationRepository().listFromLocalDb();
    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    conversationList.assignAll(conversations);
    await _refreshConversationViewModels();

    final selectedId = currentConversationId.value;
    if (selectedId != null) {
      if (conversations.any((element) => element.id == selectedId)) {
        await selectConversation(selectedId);
      } else {
        currentConversationId.value = null;
        messageList.clear();
      }
    }
  }

  Future<void> _refreshConversationViewModels() async {
    final vms = <ChatConversationViewModel>[];
    for (final item in conversationList) {
      final meta = _metaOfConversation(item.id);
      final pending = await _countPendingMessages(item.id, meta.lastSyncedMessageId);
      final hasSyncError = item.syncStatus == SyncStatus.failed;
      final state = hasSyncError
          ? ChatConversationSyncState.syncError
          : meta.remoteConversationId == null
          ? ChatConversationSyncState.localOnly
          : pending > 0
          ? ChatConversationSyncState.dirty
          : ChatConversationSyncState.synced;
      vms.add(ChatConversationViewModel(item: item, syncMeta: meta, syncState: state, pendingSyncCount: pending));
    }
    conversationViewModels.assignAll(vms);
  }

  Future<int> _countPendingMessages(String conversationId, String? lastSyncedMessageId) async {
    final messages = await _loadMessagesByConversation(conversationId);
    if (messages.isEmpty) return 0;
    var startIndex = 0;
    if (lastSyncedMessageId != null) {
      final idx = messages.indexWhere((m) => m.id == lastSyncedMessageId);
      if (idx != -1) {
        startIndex = idx + 1;
      }
    }
    var count = 0;
    for (var i = startIndex; i < messages.length; i += 1) {
      if (_stateOfMessage(messages[i].id) == ChatLocalMessageState.completed) {
        count += 1;
      }
    }
    return count;
  }

  Future<List<ChatMessageDataItem>> _loadMessagesByConversation(String conversationId) async {
    final messages = await ChatMessageRepository().listFromLocalDb(parentId: conversationId);
    messages.sort((a, b) {
      final t = a.createdAt.compareTo(b.createdAt);
      if (t != 0) return t;
      return a.id.compareTo(b.id);
    });
    return messages;
  }

  Future<void> selectConversation(String conversationId) async {
    if (waitingForResponse.value && currentConversationId.value != conversationId) {
      await cancelCurrentStreamingBySwitch();
    }
    currentConversationId.value = conversationId;
    final messages = await _loadMessagesByConversation(conversationId);
    messageList.assignAll(messages);
  }

  Future<ChatConversationDataItem> createConversation({
    required String name,
    required ChatAssistantDataItem assistant,
  }) async {
    final owner = Get.find<SettingController>().userId;
    final now = DateTime.now().toUtc();
    final conversation = ChatConversation(
      name: name,
      assistantId: assistant.id,
      assistantName: assistant.body.name,
      like: false,
    );
    final conversationId = _uuid.v4();
    final conversationItem = DataItem<ChatConversation>(
      conversationId,
      now,
      now,
      owner,
      null,
      null,
      body: conversation,
      syncStatus: SyncStatus.pending,
    );
    await ChatConversationRepository().addToLocalDb(conversationItem);

    final systemMessageBody = ChatMessage(
      conversationId: conversationId,
      role: ChatMessageRole.system,
      text: assistant.body.prompt,
      reasoningText: null,
      usage: null,
    );
    final systemMessage = DataItem<ChatMessage>(
      _uuid.v4(),
      now,
      now,
      owner,
      conversationId,
      null,
      body: systemMessageBody,
      syncStatus: SyncStatus.pending,
    );
    await ChatMessageRepository().addToLocalDb(systemMessage);
    _setMessageState(systemMessage.id, ChatLocalMessageState.completed);

    _syncMetaByConversation[conversationId] = const ChatSyncMeta();
    _saveMetaMaps();

    await reloadConversations();
    await selectConversation(conversationId);
    return conversationItem;
  }

  Future<void> sendUserMessage(String text) async {
    final conversationId = currentConversationId.value;
    if (conversationId == null || text.trim().isEmpty) {
      return;
    }
    if (waitingForResponse.value) {
      flushBar(FlushLevel.INFO, null, 'chat_wait_previous_response'.tr);
      return;
    }
    if (syncingConversationIds.contains(conversationId)) {
      flushBar(FlushLevel.INFO, null, 'chat_syncing_input_locked'.tr);
      return;
    }

    final owner = Get.find<SettingController>().userId;
    final now = DateTime.now().toUtc();
    final userItem = DataItem<ChatMessage>(
      _uuid.v4(),
      now,
      now,
      owner,
      conversationId,
      null,
      body: ChatMessage(
        conversationId: conversationId,
        role: ChatMessageRole.user,
        text: text,
        reasoningText: null,
        usage: null,
      ),
      syncStatus: SyncStatus.pending,
    );
    await ChatMessageRepository().addToLocalDb(userItem);
    _setMessageState(userItem.id, ChatLocalMessageState.completed);

    await selectConversation(conversationId);
    final payloadMessages = await _buildRequestMessages(conversationId);
    final settings = Get.find<SettingController>().chatLLMSetting.value;
    final assistantModelConfig = await _resolveAssistantModelConfig(conversationId);

    final assistantItem = DataItem<ChatMessage>(
      _uuid.v4(),
      now,
      now,
      owner,
      conversationId,
      null,
      body: ChatMessage(
        conversationId: conversationId,
        role: ChatMessageRole.assistant,
        text: '',
        reasoningText: null,
        usage: null,
      ),
      syncStatus: SyncStatus.pending,
    );
    await ChatMessageRepository().addToLocalDb(assistantItem);
    _setMessageState(assistantItem.id, ChatLocalMessageState.streaming);

    waitingForResponse.value = true;
    _streamingMessageId = assistantItem.id;
    await selectConversation(conversationId);

    _currentStream = _chatClient.sendMessageStream(
      settings: settings,
      assistantModelConfig: assistantModelConfig,
      messages: payloadMessages,
      onStream: (delta) {
        _enqueueStreamDelta(assistantItem.id, delta);
      },
      onError: (error) {
        unawaited(_onStreamError(assistantItem.id, error));
      },
      onSuccess: () {
        unawaited(_onStreamSuccess(assistantItem.id));
      },
    );
  }

  void _enqueueStreamDelta(String assistantMessageId, ChatStreamDelta delta) {
    final previous = _pendingDeltaByMessage[assistantMessageId] ?? Future<void>.value();
    final next = previous.then((_) async {
      try {
        await _onStreamDelta(assistantMessageId, delta);
      } catch (error, stackTrace) {
        print('chat delta handling failed: $error');
        print(stackTrace);
      }
    });
    _pendingDeltaByMessage[assistantMessageId] = next;
    unawaited(
      next.whenComplete(() {
        if (identical(_pendingDeltaByMessage[assistantMessageId], next)) {
          _pendingDeltaByMessage.remove(assistantMessageId);
        }
      }),
    );
  }

  Future<void> _flushPendingStreamDeltas(String assistantMessageId) async {
    final pending = _pendingDeltaByMessage[assistantMessageId];
    if (pending != null) {
      await pending;
    }
  }

  Future<ChatAssistantModelConfig?> _resolveAssistantModelConfig(String conversationId) async {
    final conversation = await ChatConversationRepository().getFromLocalDb(conversationId);
    if (conversation == null) return null;
    final assistant = await ChatAssistantRepository().getFromLocalDb(conversation.body.assistantId);
    return assistant?.body.modelConfig;
  }

  Future<List<ChatMessage>> _buildRequestMessages(String conversationId) async {
    final all = await _loadMessagesByConversation(conversationId);
    final latestSystemIndex = all.lastIndexWhere((element) => element.body.role == ChatMessageRole.system);
    final start = latestSystemIndex == -1 ? 0 : latestSystemIndex;
    final messages = <ChatMessage>[];
    for (var i = start; i < all.length; i += 1) {
      final state = _stateOfMessage(all[i].id);
      if (state == ChatLocalMessageState.cancelled || state == ChatLocalMessageState.error) {
        continue;
      }
      messages.add(all[i].body);
    }
    return messages;
  }

  Future<void> _onStreamDelta(String assistantMessageId, ChatStreamDelta delta) async {
    final item = await ChatMessageRepository().getFromLocalDb(assistantMessageId);
    if (item == null) return;
    var updated = item.body;
    if (delta.reasoningDelta != null && delta.reasoningDelta!.isNotEmpty) {
      updated = updated.copyWith(reasoningText: '${updated.reasoningText ?? ''}${delta.reasoningDelta}');
    }
    if (delta.textDelta != null && delta.textDelta!.isNotEmpty) {
      updated = updated.copyWith(text: '${updated.text}${delta.textDelta}');
    }
    if (delta.usage != null) {
      updated = updated.copyWith(usage: delta.usage);
    }
    final updatedItem = item.updatedBody(updated);
    await ChatMessageRepository().updateToLocalDb(updatedItem);
    await _reloadCurrentConversationMessages();
  }

  Future<void> _onStreamError(String assistantMessageId, Object error) async {
    await _flushPendingStreamDeltas(assistantMessageId);

    waitingForResponse.value = false;
    _streamingMessageId = null;
    _currentStream = null;

    final item = await ChatMessageRepository().getFromLocalDb(assistantMessageId);
    if (item != null) {
      var updated = item;
      if (updated.body.text.trim().isEmpty) {
        updated = updated.updatedBody(updated.body.copyWith(text: '$error'));
      }
      await ChatMessageRepository().updateToLocalDb(updated);
    }
    _setMessageState(assistantMessageId, ChatLocalMessageState.error);
    await _reloadCurrentConversationMessages();
    flushBar(FlushLevel.WARNING, null, 'chat_request_failed'.trParams({'error': '$error'}));
  }

  Future<void> _onStreamSuccess(String assistantMessageId) async {
    await _flushPendingStreamDeltas(assistantMessageId);

    waitingForResponse.value = false;
    _streamingMessageId = null;
    _currentStream = null;
    _setMessageState(assistantMessageId, ChatLocalMessageState.completed);
    await _reloadCurrentConversationMessages();
  }

  Future<void> _reloadCurrentConversationMessages() async {
    final id = currentConversationId.value;
    if (id == null) return;
    await selectConversation(id);
    await _refreshConversationViewModels();
  }

  Future<void> cancelCurrentStreamingBySwitch() async {
    final messageId = _streamingMessageId;
    if (!waitingForResponse.value || messageId == null) return;
    await _currentStream?.cancel();
    _currentStream = null;
    waitingForResponse.value = false;
    _streamingMessageId = null;
    _setMessageState(messageId, ChatLocalMessageState.cancelled);
    await _reloadCurrentConversationMessages();
  }

  Future<void> cancelCurrentStreamingByUser() async {
    await cancelCurrentStreamingBySwitch();
  }

  Future<void> retryLastUserTurn() async {
    final conversationId = currentConversationId.value;
    if (conversationId == null || waitingForResponse.value) {
      return;
    }
    final messages = await _loadMessagesByConversation(conversationId);
    if (messages.isEmpty) return;

    final lastUserIndex = messages.lastIndexWhere((element) => element.body.role == ChatMessageRole.user);
    if (lastUserIndex == -1 || lastUserIndex >= messages.length - 1) {
      return;
    }
    final lastUserMessage = messages[lastUserIndex];
    if (_isMessageLockedBySync(conversationId, lastUserMessage.id)) {
      flushBar(FlushLevel.INFO, null, 'chat_synced_prefix_locked'.tr);
      return;
    }

    final afterUser = messages.sublist(lastUserIndex + 1);
    final allRetryable = afterUser.every((element) {
      if (element.body.role != ChatMessageRole.assistant) return false;
      final state = _stateOfMessage(element.id);
      return state == ChatLocalMessageState.error || state == ChatLocalMessageState.cancelled;
    });
    if (!allRetryable) {
      flushBar(FlushLevel.INFO, null, 'chat_retry_last_turn_only'.tr);
      return;
    }

    final oldText = lastUserMessage.body.text;
    await _deleteMessageItems([lastUserMessage.id, ...afterUser.map((e) => e.id)]);
    await _reloadCurrentConversationMessages();
    await sendUserMessage(oldText);
  }

  Future<void> rewriteLastUserTurnAndResend(String newText) async {
    final conversationId = currentConversationId.value;
    if (conversationId == null || waitingForResponse.value) {
      return;
    }
    final messages = await _loadMessagesByConversation(conversationId);
    if (messages.isEmpty) return;

    final lastUserIndex = messages.lastIndexWhere((element) => element.body.role == ChatMessageRole.user);
    if (lastUserIndex == -1) return;
    final lastUser = messages[lastUserIndex];
    if (_isMessageLockedBySync(conversationId, lastUser.id)) {
      flushBar(FlushLevel.INFO, null, 'chat_synced_prefix_locked'.tr);
      return;
    }
    final deletions = <String>[lastUser.id];
    for (var i = lastUserIndex + 1; i < messages.length; i += 1) {
      if (messages[i].body.role == ChatMessageRole.assistant) {
        deletions.add(messages[i].id);
      }
    }
    await _deleteMessageItems(deletions);
    await _reloadCurrentConversationMessages();
    await sendUserMessage(newText);
  }

  bool _isMessageLockedBySync(String conversationId, String messageId) {
    final meta = _metaOfConversation(conversationId);
    if (meta.lastSyncedMessageId == null) return false;
    final ids = messageList.map((e) => e.id).toList(growable: false);
    final lastSyncedIndex = ids.indexOf(meta.lastSyncedMessageId!);
    final targetIndex = ids.indexOf(messageId);
    return lastSyncedIndex != -1 && targetIndex != -1 && targetIndex <= lastSyncedIndex;
  }

  Future<void> _deleteMessageItems(List<String> ids) async {
    for (final id in ids) {
      await ChatMessageRepository().deleteFromLocalDb(id);
      _localStateByMessage.remove(id);
      _remoteMessageIdByMessage.remove(id);
    }
    _saveMetaMaps();
  }

  Future<ChatManualSyncResult> manualSyncConversation(String conversationId) async {
    if (syncingConversationIds.contains(conversationId)) {
      return const ChatManualSyncResult(totalCandidates: 0, syncedCount: 0, skippedCount: 0, success: false);
    }
    syncingConversationIds.add(conversationId);
    await _refreshConversationViewModels();

    try {
      final conversation = await ChatConversationRepository().getFromLocalDb(conversationId);
      if (conversation == null) {
        return const ChatManualSyncResult(totalCandidates: 0, syncedCount: 0, skippedCount: 0, success: false);
      }
      final allMessages = await _loadMessagesByConversation(conversationId);
      final userCount = allMessages.where((m) => m.body.role == ChatMessageRole.user).length;
      if (userCount == 0) {
        flushBar(FlushLevel.INFO, null, 'chat_sync_requires_user_message'.tr);
        return const ChatManualSyncResult(totalCandidates: 0, syncedCount: 0, skippedCount: 0, success: false);
      }

      final client = Get.find<SyncStoreControl>().syncStoreClient;
      var meta = _metaOfConversation(conversationId);
      String? remoteConversationId = meta.remoteConversationId;

      if (remoteConversationId == null) {
        remoteConversationId = await client.create('chat', 'conversation', conversation.body.toJson());
        final fetched = await client.get<ChatConversation>(
          'chat',
          'conversation',
          remoteConversationId,
          ChatConversation.fromRemoteJson,
        );
        await ChatConversationRepository().updateToLocalDb(conversation.updatedBody(fetched.body));
        meta = meta.copyWith(remoteConversationId: remoteConversationId);
        _syncMetaByConversation[conversationId] = meta;
        _saveMetaMaps();
      }

      final pending = _collectPendingCompletedMessages(allMessages, meta.lastSyncedMessageId);
      var syncedCount = 0;
      var skippedCount = 0;
      String? failedMessageId;

      for (final item in pending) {
        final localState = _stateOfMessage(item.id);
        if (localState != ChatLocalMessageState.completed) {
          skippedCount += 1;
          continue;
        }
        final existingRemoteId = _remoteMessageIdByMessage[item.id];
        if (existingRemoteId != null) {
          skippedCount += 1;
          continue;
        }
        final payload = item.body.toSyncJson();
        payload['conversation_id'] = remoteConversationId;
        try {
          final remoteMessageId = await client.create('chat', 'message', payload);
          _remoteMessageIdByMessage[item.id] = remoteMessageId;
          syncedCount += 1;
          meta = meta.copyWith(
            lastSyncedMessageId: item.id,
            syncedMessageCount: meta.syncedMessageCount + 1,
            lastSyncedAt: DateTime.now().toUtc(),
          );
          _syncMetaByConversation[conversationId] = meta;
          _saveMetaMaps();
        } catch (_) {
          failedMessageId = item.id;
          break;
        }
      }

      if (failedMessageId == null) {
        final conv = await ChatConversationRepository().getFromLocalDb(conversationId);
        if (conv != null) {
          conv.syncStatus = SyncStatus.archived;
          await ChatConversationRepository().updateToLocalDb(conv);
        }
      } else {
        final conv = await ChatConversationRepository().getFromLocalDb(conversationId);
        if (conv != null) {
          conv.syncStatus = SyncStatus.failed;
          await ChatConversationRepository().updateToLocalDb(conv);
        }
      }

      await reloadConversations();

      return ChatManualSyncResult(
        totalCandidates: pending.length,
        syncedCount: syncedCount,
        skippedCount: skippedCount,
        success: failedMessageId == null,
        failedMessageId: failedMessageId,
      );
    } finally {
      syncingConversationIds.remove(conversationId);
      await _refreshConversationViewModels();
    }
  }

  List<ChatMessageDataItem> _collectPendingCompletedMessages(
    List<ChatMessageDataItem> allMessages,
    String? lastSyncedMessageId,
  ) {
    var start = 0;
    if (lastSyncedMessageId != null) {
      final idx = allMessages.indexWhere((e) => e.id == lastSyncedMessageId);
      if (idx != -1) {
        start = idx + 1;
      }
    }
    return allMessages
        .sublist(start)
        .where((e) => _stateOfMessage(e.id) == ChatLocalMessageState.completed)
        .toList(growable: false);
  }

  Future<bool> deleteConversationWithRemote(String conversationId) async {
    final client = Get.find<SyncStoreControl>().syncStoreClient;
    final meta = _metaOfConversation(conversationId);
    try {
      final remoteConversationId = meta.remoteConversationId;
      if (remoteConversationId != null) {
        final messages = await _loadMessagesByConversation(conversationId);
        for (final message in messages) {
          final remoteMessageId = _remoteMessageIdByMessage[message.id];
          if (remoteMessageId != null) {
            await client.delete('chat', 'message', remoteMessageId);
          }
        }
        await client.delete('chat', 'conversation', remoteConversationId);
      }

      final messages = await _loadMessagesByConversation(conversationId);
      for (final message in messages) {
        await ChatMessageRepository().deleteFromLocalDb(message.id);
        _localStateByMessage.remove(message.id);
        _remoteMessageIdByMessage.remove(message.id);
      }
      await ChatConversationRepository().deleteFromLocalDb(conversationId);
      _syncMetaByConversation.remove(conversationId);
      _saveMetaMaps();

      if (currentConversationId.value == conversationId) {
        currentConversationId.value = null;
        messageList.clear();
      }
      await reloadConversations();
      return true;
    } catch (e) {
      final conversation = await ChatConversationRepository().getFromLocalDb(conversationId);
      if (conversation != null) {
        conversation.syncStatus = SyncStatus.failed;
        await ChatConversationRepository().updateToLocalDb(conversation);
      }
      await reloadConversations();
      flushBar(FlushLevel.WARNING, null, 'chat_delete_conversation_failed'.trParams({'error': '$e'}));
      return false;
    }
  }

  Future<void> upsertAssistant(ChatAssistantDataItem? existing, ChatAssistant body) async {
    final assistantController = Get.find<ChatAssistantController>();
    if (existing == null) {
      assistantController.addData(body);
      return;
    }
    assistantController.updateData(existing.id, body);
  }

  Future<void> resetAssistantPromptToDefault(ChatAssistantDataItem assistant, String defaultPrompt) async {
    final updated = assistant.body.copyWith(prompt: defaultPrompt);
    await upsertAssistant(assistant, updated);
  }
}
