import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sync_annotation/sync_annotation.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/chat/db.dart';

part 'model.g.dart';
part 'model.freezed.dart';

enum ChatMessageRole { system, user, assistant }

enum ChatAssistantType { system, userDefined }

enum ChatAssistantModelProvider { deepSeek }

@freezed
abstract class ChatUsage with _$ChatUsage {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ChatUsage({required int promptTokens, required int completionTokens, required int totalTokens}) =
      _ChatUsage;

  factory ChatUsage.fromJson(Map<String, dynamic> json) => _$ChatUsageFromJson(json);
}

@freezed
abstract class ChatAssistantModelConfig with _$ChatAssistantModelConfig {
  @JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
  const factory ChatAssistantModelConfig({
    ChatAssistantModelProvider? provider,
    String? baseUrl,
    String? model,
    double? temperature,
    bool? thinkingEnabled,
    String? reasoningEffort,
  }) = _ChatAssistantModelConfig;

  factory ChatAssistantModelConfig.fromJson(Map<String, dynamic> json) => _$ChatAssistantModelConfigFromJson(json);
}

@Repository(collectionName: 'chat', tableName: 'assistant', db: ChatDB)
@freezed
abstract class ChatAssistant with _$ChatAssistant {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ChatAssistant({
    required String name,
    required ChatAssistantType type,
    required String description,
    required String prompt,
    String? avatarUrl,
    ChatAssistantModelConfig? modelConfig,
  }) = _ChatAssistant;

  factory ChatAssistant.fromJson(Map<String, dynamic> json) => _$ChatAssistantFromJson(json);
}

@Repository(collectionName: 'chat', tableName: 'conversation', db: ChatDB)
@freezed
abstract class ChatConversation with _$ChatConversation {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ChatConversation({
    required String name,
    required String assistantId,
    required String assistantName,
    @Default(false) bool like,
  }) = _ChatConversation;

  factory ChatConversation.fromJson(Map<String, dynamic> json) => _$ChatConversationFromJson(json);

  static ChatConversation fromRemoteJson(Map<String, dynamic> json) {
    return ChatConversation.fromJson(json);
  }
}

@Repository(collectionName: 'chat', tableName: 'message', db: ChatDB, parentIdField: 'conversationId')
@freezed
abstract class ChatMessage with _$ChatMessage {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ChatMessage({
    required String conversationId,
    required ChatMessageRole role,
    required String text,
    String? reasoningText,
    ChatUsage? usage,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}

extension ChatMessageSyncPayload on ChatMessage {
  Map<String, dynamic> toSyncJson() {
    return <String, dynamic>{
      'conversation_id': conversationId,
      'role': role.name,
      'text': text,
      if (reasoningText != null) 'reasoning_text': reasoningText,
      if (usage != null) 'usage': usage!.toJson(),
    };
  }
}
