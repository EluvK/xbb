import 'dart:async';

import 'package:xbb/models/chat/model.dart';

class ChatModelConfig {
  final String baseUrl;
  final String? apiKey;
  final String model;
  final double temperature;
  final bool? thinkingEnabled;
  final String? reasoningEffort;

  const ChatModelConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    required this.temperature,
    this.thinkingEnabled,
    this.reasoningEffort,
  });
}

class ChatStreamDelta {
  final String? textDelta;
  final String? reasoningDelta;
  final ChatUsage? usage;

  const ChatStreamDelta({this.textDelta, this.reasoningDelta, this.usage});
}

class ChatStreamHandle {
  final Future<void> Function() _cancel;

  const ChatStreamHandle(this._cancel);

  Future<void> cancel() {
    return _cancel();
  }
}

typedef ChatOnStream = void Function(ChatStreamDelta delta);
typedef ChatOnError = void Function(Object error);
typedef ChatOnSuccess = void Function();
