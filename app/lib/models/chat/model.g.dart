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

Map<String, dynamic> _$ChatUsageToJson(_ChatUsage instance) =>
    <String, dynamic>{
      'prompt_tokens': instance.promptTokens,
      'completion_tokens': instance.completionTokens,
      'total_tokens': instance.totalTokens,
    };

_ChatAssistantModelConfig _$ChatAssistantModelConfigFromJson(
  Map<String, dynamic> json,
) => _ChatAssistantModelConfig(
  provider: $enumDecodeNullable(
    _$ChatAssistantModelProviderEnumMap,
    json['provider'],
  ),
  baseUrl: json['base_url'] as String?,
  model: json['model'] as String?,
  temperature: (json['temperature'] as num?)?.toDouble(),
  thinkingEnabled: json['thinking_enabled'] as bool?,
  reasoningEffort: json['reasoning_effort'] as String?,
);

Map<String, dynamic> _$ChatAssistantModelConfigToJson(
  _ChatAssistantModelConfig instance,
) => <String, dynamic>{
  'provider': ?_$ChatAssistantModelProviderEnumMap[instance.provider],
  'base_url': ?instance.baseUrl,
  'model': ?instance.model,
  'temperature': ?instance.temperature,
  'thinking_enabled': ?instance.thinkingEnabled,
  'reasoning_effort': ?instance.reasoningEffort,
};

const _$ChatAssistantModelProviderEnumMap = {
  ChatAssistantModelProvider.deepSeek: 'deepSeek',
};

_ChatAssistant _$ChatAssistantFromJson(Map<String, dynamic> json) =>
    _ChatAssistant(
      name: json['name'] as String,
      type: $enumDecode(_$ChatAssistantTypeEnumMap, json['type']),
      description: json['description'] as String,
      prompt: json['prompt'] as String,
      avatarUrl: json['avatar_url'] as String?,
      modelConfig: json['model_config'] == null
          ? null
          : ChatAssistantModelConfig.fromJson(
              json['model_config'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ChatAssistantToJson(_ChatAssistant instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': _$ChatAssistantTypeEnumMap[instance.type]!,
      'description': instance.description,
      'prompt': instance.prompt,
      'avatar_url': instance.avatarUrl,
      'model_config': instance.modelConfig,
    };

const _$ChatAssistantTypeEnumMap = {
  ChatAssistantType.system: 'system',
  ChatAssistantType.userDefined: 'userDefined',
};

_ChatConversation _$ChatConversationFromJson(Map<String, dynamic> json) =>
    _ChatConversation(
      name: json['name'] as String,
      assistantId: json['assistant_id'] as String,
      assistantName: json['assistant_name'] as String,
      like: json['like'] as bool? ?? false,
    );

Map<String, dynamic> _$ChatConversationToJson(_ChatConversation instance) =>
    <String, dynamic>{
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
  usage: json['usage'] == null
      ? null
      : ChatUsage.fromJson(json['usage'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
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
  static String get tableName => 'chat_assistant';

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
    await db.insert(
      LocalStoreChatAssistant.tableName,
      item.toJson((r) => json.encode(r.toJson())),
    );
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

  Future<List<ChatAssistantDataItem>> listFromLocalDb({
    String? parentId,
  }) async {
    final db = await LocalStoreChatAssistant.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty
        ? whereClauses.join(' AND ')
        : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreChatAssistant.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
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

  Future<List<ChatAssistantDataItem>> listByParentIdFromLocalDb(
    String parentId, {
    bool desc = true,
  }) async {
    final db = await LocalStoreChatAssistant.getDb();
    final order = desc ? 'DESC' : 'ASC';
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM ${LocalStoreChatAssistant.tableName} WHERE parent_id = ? ORDER BY created_at $order',
      [parentId],
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
    await db.delete(
      LocalStoreChatAssistant.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
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

extension LocalStoreChatConversation on ChatConversation {
  static String get tableName => 'chat_conversation';

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
    await db.insert(
      LocalStoreChatConversation.tableName,
      item.toJson((r) => json.encode(r.toJson())),
    );
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

  Future<List<ChatConversationDataItem>> listFromLocalDb({
    String? parentId,
  }) async {
    final db = await LocalStoreChatConversation.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty
        ? whereClauses.join(' AND ')
        : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreChatConversation.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return maps
        .map(
          (map) => DataItem<ChatConversation>.fromJson(
            map,
            (jsonStr) =>
                ChatConversation.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<List<ChatConversationDataItem>> listByParentIdFromLocalDb(
    String parentId, {
    bool desc = true,
  }) async {
    final db = await LocalStoreChatConversation.getDb();
    final order = desc ? 'DESC' : 'ASC';
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM ${LocalStoreChatConversation.tableName} WHERE parent_id = ? ORDER BY created_at $order',
      [parentId],
    );
    return maps
        .map(
          (map) => DataItem<ChatConversation>.fromJson(
            map,
            (jsonStr) =>
                ChatConversation.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreChatConversation.getDb();
    await db.delete(
      LocalStoreChatConversation.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
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

extension LocalStoreChatMessage on ChatMessage {
  static String get tableName => 'chat_message';

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
    await db.insert(
      LocalStoreChatMessage.tableName,
      item.toJson((r) => json.encode(r.toJson())),
    );
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
    final whereString = whereClauses.isNotEmpty
        ? whereClauses.join(' AND ')
        : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreChatMessage.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return maps
        .map(
          (map) => DataItem<ChatMessage>.fromJson(
            map,
            (jsonStr) => ChatMessage.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<List<ChatMessageDataItem>> listByParentIdFromLocalDb(
    String parentId, {
    bool desc = true,
  }) async {
    final db = await LocalStoreChatMessage.getDb();
    final order = desc ? 'DESC' : 'ASC';
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM ${LocalStoreChatMessage.tableName} WHERE parent_id = ? ORDER BY created_at $order',
      [parentId],
    );
    return maps
        .map(
          (map) => DataItem<ChatMessage>.fromJson(
            map,
            (jsonStr) => ChatMessage.fromJson(json.decode(jsonStr as String)),
          ),
        )
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreChatMessage.getDb();
    await db.delete(
      LocalStoreChatMessage.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
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
