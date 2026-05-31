import 'dart:async';

import 'package:deepseek_client/deepseek_client.dart';
import 'package:xbb/client/chat/llm/common.dart';
import 'package:xbb/models/chat/model.dart';

DeepSeekMessage _toDeepSeekMessage(ChatMessage message) {
  return switch (message.role) {
    ChatMessageRole.system => DeepSeekMessage.system(message.text),
    ChatMessageRole.assistant => DeepSeekMessage.assistant(message.text),
    ChatMessageRole.user => DeepSeekMessage.user(message.text),
  };
}

ChatStreamHandle deepSeekStreamChat({
  required ChatModelConfig config,
  required List<ChatMessage> messages,
  required ChatOnStream onStream,
  required ChatOnError onError,
  required ChatOnSuccess onSuccess,
  Duration timeout = const Duration(seconds: 90),
}) {
  final client = DeepSeekClient(baseUrl: config.baseUrl, apiKey: config.apiKey);

  StreamSubscription<DeepSeekChatChunk>? subscription;
  Timer? timeoutTimer;
  var isDone = false;

  void cleanup() {
    timeoutTimer?.cancel();
    timeoutTimer = null;
    client.close();
  }

  void fail(Object error) {
    if (isDone) return;
    isDone = true;
    cleanup();
    onError(error);
  }

  void succeed() {
    if (isDone) return;
    isDone = true;
    cleanup();
    onSuccess();
  }

  void onChunk(DeepSeekChatChunk chunk) {
    ChatUsage? usage;
    if (chunk.usage != null) {
      usage = ChatUsage(
        promptTokens: chunk.usage!.promptTokens ?? 0,
        completionTokens: chunk.usage!.completionTokens ?? 0,
        totalTokens: chunk.usage!.totalTokens ?? 0,
      );
    }

    String? textDelta;
    String? reasoningDelta;
    if (chunk.choices.isNotEmpty) {
      final delta = chunk.choices.first.delta;
      if ((delta.content ?? '').isNotEmpty) {
        textDelta = delta.content;
      }
      if ((delta.reasoningContent ?? '').isNotEmpty) {
        reasoningDelta = delta.reasoningContent;
      }
    }

    if (textDelta != null || reasoningDelta != null || usage != null) {
      onStream(ChatStreamDelta(textDelta: textDelta, reasoningDelta: reasoningDelta, usage: usage));
    }
  }

  timeoutTimer = Timer(timeout, () {
    fail(TimeoutException('Chat request timeout after ${timeout.inSeconds}s'));
  });

  final stream = client.chat.createStream(
    DeepSeekChatRequest(
      model: config.model,
      messages: messages.map(_toDeepSeekMessage).toList(growable: false),
      stream: true,
      temperature: config.temperature,
      thinking: config.thinkingEnabled == true ? const DeepSeekThinkingConfig.enabled() : null,
      reasoningEffort: config.reasoningEffort,
    ),
  );

  subscription = stream.listen(
    (chunk) {
      if (isDone) return;
      onChunk(chunk);
    },
    onError: (error) {
      fail(error);
    },
    onDone: () {
      if (!isDone) {
        succeed();
      }
    },
    cancelOnError: true,
  );

  Future<void> cancel() async {
    if (isDone) return;
    isDone = true;
    timeoutTimer?.cancel();
    if (subscription != null) {
      await subscription.cancel();
    }
    cleanup();
  }

  return ChatStreamHandle(cancel);
}
