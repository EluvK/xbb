import 'package:xbb/client/chat/llm/common.dart';
import 'package:xbb/client/chat/llm/deepseek.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/models/chat/model.dart';

class ChatClient {
  const ChatClient();

  ChatStreamHandle sendMessageStream({
    required ChatLLMSetting settings,
    ChatAssistantModelConfig? assistantModelConfig,
    required List<ChatMessage> messages,
    required ChatOnStream onStream,
    required ChatOnError onError,
    required ChatOnSuccess onSuccess,
  }) {
    final mergedProvider = assistantModelConfig?.provider != null
        ? _toSettingProvider(assistantModelConfig!.provider!)
        : settings.provider;
    final config = ChatModelConfig(
      baseUrl: assistantModelConfig?.baseUrl ?? settings.baseUrl,
      apiKey: settings.apiKey,
      model: assistantModelConfig?.model ?? settings.model,
      temperature: assistantModelConfig?.temperature ?? settings.temperature,
      thinkingEnabled: assistantModelConfig?.thinkingEnabled,
      reasoningEffort: assistantModelConfig?.reasoningEffort,
    );

    switch (mergedProvider) {
      case ChatLLMProvider.deepSeek:
        return deepSeekStreamChat(
          config: config,
          messages: messages,
          onStream: onStream,
          onError: onError,
          onSuccess: onSuccess,
        );
    }
  }

  ChatLLMProvider _toSettingProvider(ChatAssistantModelProvider provider) {
    switch (provider) {
      case ChatAssistantModelProvider.deepSeek:
        return ChatLLMProvider.deepSeek;
    }
  }
}
