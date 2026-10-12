import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/models/chat/model.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';
import 'package:xbb/sync/v2/uuid_service.dart';

class ChatRepository {
  final Database db;
  final DatabaseChangeNotifier changeNotifier;

  ChatRepository({
    required this.db,
    required this.changeNotifier,
  });

  /// 监听全部 AI 助手
  Stream<List<DataItem<ChatAssistant>>> watchAssistants() {
    return changeNotifier.watchTable('chat_assistant').asyncMap((_) async {
      final rows = await db.query('chat_assistant', orderBy: 'created_at ASC');
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final assistant = ChatAssistant.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        return DataItem<ChatAssistant>(
          r['id'] as String,
          DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
          DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now(),
          r['owner'] as String? ?? 'default',
          null,
          null,
          body: assistant,
          syncStatus: SyncStatus.synced,
        );
      }).toList();
    });
  }

  /// 监听全部对话会话
  Stream<List<DataItem<ChatConversation>>> watchConversations() {
    return changeNotifier.watchTable('chat_conversation').asyncMap((_) async {
      final rows = await db.query('chat_conversation', orderBy: 'created_at DESC');
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final conv = ChatConversation.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        return DataItem<ChatConversation>(
          r['id'] as String,
          DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
          DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now(),
          r['owner'] as String? ?? 'default',
          null,
          null,
          body: conv,
          syncStatus: SyncStatus.synced,
        );
      }).toList();
    });
  }

  /// 监听特定会话的所有消息
  Stream<List<DataItem<ChatMessage>>> watchMessages(String? conversationId) {
    return changeNotifier.watchTable('chat_message').asyncMap((_) async {
      if (conversationId == null || conversationId.isEmpty) return <DataItem<ChatMessage>>[];
      final rows = await db.query(
        'chat_message',
        where: 'parent_id = ?',
        whereArgs: [conversationId],
        orderBy: 'created_at ASC',
      );
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final msg = ChatMessage.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        return DataItem<ChatMessage>(
          r['id'] as String,
          DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
          DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now(),
          r['owner'] as String? ?? 'default',
          conversationId,
          null,
          body: msg,
          syncStatus: SyncStatus.synced,
        );
      }).toList();
    });
  }

  /// 确保至少存在一个默认 AI 助手
  Future<String> ensureDefaultAssistant(String userId) async {
    final rows = await db.query('chat_assistant', limit: 1);
    if (rows.isNotEmpty) {
      return rows.first['id'] as String;
    }
    final newId = UuidService.v7();
    final assistant = ChatAssistant(
      name: '通用智能助理',
      type: ChatAssistantType.system,
      description: '全能生产力知识助手，支持深度思考推理',
      prompt: '你是一个高效、友善的生产力 AI 助手，善于解决各类任务与梳理知识。',
      modelConfig: const ChatAssistantModelConfig(
        provider: ChatAssistantModelProvider.deepSeek,
        model: 'deepseek-chat',
        temperature: 0.7,
        thinkingEnabled: true,
      ),
    );
    final row = <String, dynamic>{
      'id': newId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'owner': userId,
      'parent_id': null,
      'sync_status': 'pending',
      'color_tag': 'default',
      'body': jsonEncode(assistant.toJson()),
    };
    await LocalFirstDB.persistPutRaw(db: db, tableName: 'chat_assistant', entityId: newId, entityRow: row);
    changeNotifier.notify('chat_assistant');
    return newId;
  }

  /// 创建新会话
  Future<String> createConversation({
    required String assistantId,
    required String assistantName,
    required String currentUserId,
    String title = '新对话',
  }) async {
    final newId = UuidService.v7();
    final conv = ChatConversation(
      name: title,
      assistantId: assistantId,
      assistantName: assistantName,
    );
    final row = <String, dynamic>{
      'id': newId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'owner': currentUserId,
      'parent_id': null,
      'sync_status': 'pending',
      'color_tag': 'default',
      'body': jsonEncode(conv.toJson()),
    };
    await LocalFirstDB.persistPutRaw(db: db, tableName: 'chat_conversation', entityId: newId, entityRow: row);
    changeNotifier.notify('chat_conversation');
    return newId;
  }

  /// 发送一条纯文本消息（存入本地）
  Future<String> saveMessage({
    required String conversationId,
    required ChatMessageRole role,
    required String text,
    String? reasoningText,
    required String currentUserId,
    String? customId,
  }) async {
    final id = customId ?? UuidService.v7();
    final msg = ChatMessage(
      conversationId: conversationId,
      role: role,
      text: text,
      reasoningText: reasoningText,
    );
    final row = <String, dynamic>{
      'id': id,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'owner': currentUserId,
      'parent_id': conversationId,
      'sync_status': 'pending',
      'color_tag': 'default',
      'body': jsonEncode(msg.toJson()),
    };
    await LocalFirstDB.persistPutRaw(db: db, tableName: 'chat_message', entityId: id, entityRow: row);
    changeNotifier.notify('chat_message');
    return id;
  }

  /// 删除会话及级联消息（入队 Outbox DELETE 并通知同步守护进程）
  Future<void> deleteConversation(String convId) async {
    // 1. 级联删除该会话下的所有关联消息并在 Outbox 产生 DELETE 记录
    final messages = await db.query(
      'chat_message',
      columns: ['id'],
      where: 'parent_id = ?',
      whereArgs: [convId],
    );
    for (final m in messages) {
      final msgId = m['id'] as String;
      await LocalFirstDB.persistDeleteRaw(
        db: db,
        tableName: 'chat_message',
        entityId: msgId,
      );
    }

    // 2. 删除会话本身
    await LocalFirstDB.persistDeleteRaw(db: db, tableName: 'chat_conversation', entityId: convId);
    changeNotifier.notify('chat_message');
    changeNotifier.notify('chat_conversation');
    SyncWorker.instance.notifyLocalWrite();
  }
}
