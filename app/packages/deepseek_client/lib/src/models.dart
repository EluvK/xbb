class DeepSeekMessage {
  final String role;
  final String content;
  final bool? prefix;

  const DeepSeekMessage({
    required this.role,
    required this.content,
    this.prefix,
  });

  factory DeepSeekMessage.system(String content) {
    return DeepSeekMessage(role: 'system', content: content);
  }

  factory DeepSeekMessage.user(String content) {
    return DeepSeekMessage(role: 'user', content: content);
  }

  factory DeepSeekMessage.assistant(String content, {bool? prefix}) {
    return DeepSeekMessage(role: 'assistant', content: content, prefix: prefix);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'role': role,
      'content': content,
      if (prefix != null) 'prefix': prefix,
    };
  }

  factory DeepSeekMessage.fromJson(Map<String, dynamic> json) {
    return DeepSeekMessage(
      role: json['role'] as String,
      content: json['content'] as String? ?? '',
      prefix: json['prefix'] as bool?,
    );
  }
}

class DeepSeekThinkingConfig {
  final String type;

  const DeepSeekThinkingConfig.enabled() : type = 'enabled';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'type': type};
  }
}

class DeepSeekChatRequest {
  final String model;
  final List<DeepSeekMessage> messages;
  final bool stream;
  final double? temperature;
  final DeepSeekThinkingConfig? thinking;
  final String? reasoningEffort;

  const DeepSeekChatRequest({
    required this.model,
    required this.messages,
    this.stream = false,
    this.temperature,
    this.thinking,
    this.reasoningEffort,
  });

  Map<String, dynamic> toJson({bool includeStreamOptions = false}) {
    return <String, dynamic>{
      'model': model,
      'messages': messages.map((e) => e.toJson()).toList(growable: false),
      'stream': stream,
      if (temperature != null) 'temperature': temperature,
      if (thinking != null) 'thinking': thinking!.toJson(),
      if (reasoningEffort != null) 'reasoning_effort': reasoningEffort,
      if (includeStreamOptions)
        'stream_options': <String, dynamic>{'include_usage': true},
    };
  }
}

class DeepSeekUsage {
  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;
  final int? promptCacheHitTokens;
  final int? promptCacheMissTokens;

  const DeepSeekUsage({
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.promptCacheHitTokens,
    this.promptCacheMissTokens,
  });

  factory DeepSeekUsage.fromJson(Map<String, dynamic> json) {
    int? asInt(String key) {
      final raw = json[key];
      if (raw == null) return null;
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return int.tryParse(raw.toString());
    }

    return DeepSeekUsage(
      promptTokens: asInt('prompt_tokens'),
      completionTokens: asInt('completion_tokens'),
      totalTokens: asInt('total_tokens'),
      promptCacheHitTokens: asInt('prompt_cache_hit_tokens'),
      promptCacheMissTokens: asInt('prompt_cache_miss_tokens'),
    );
  }
}

class DeepSeekChatDelta {
  final String? content;
  final String? reasoningContent;

  const DeepSeekChatDelta({this.content, this.reasoningContent});

  factory DeepSeekChatDelta.fromJson(Map<String, dynamic> json) {
    return DeepSeekChatDelta(
      content: json['content'] as String?,
      reasoningContent: json['reasoning_content'] as String?,
    );
  }
}

class DeepSeekChatChoiceChunk {
  final int? index;
  final DeepSeekChatDelta delta;
  final String? finishReason;

  const DeepSeekChatChoiceChunk({
    this.index,
    required this.delta,
    this.finishReason,
  });

  factory DeepSeekChatChoiceChunk.fromJson(Map<String, dynamic> json) {
    return DeepSeekChatChoiceChunk(
      index: (json['index'] as num?)?.toInt(),
      delta: DeepSeekChatDelta.fromJson(
        (json['delta'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
      ),
      finishReason: json['finish_reason'] as String?,
    );
  }
}

class DeepSeekChatChunk {
  final String? id;
  final String? model;
  final List<DeepSeekChatChoiceChunk> choices;
  final DeepSeekUsage? usage;
  final Map<String, dynamic> raw;

  const DeepSeekChatChunk({
    this.id,
    this.model,
    required this.choices,
    required this.raw,
    this.usage,
  });

  factory DeepSeekChatChunk.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'];
    final choices = rawChoices is List
        ? rawChoices
              .whereType<Map>()
              .map(
                (e) =>
                    DeepSeekChatChoiceChunk.fromJson(e.cast<String, dynamic>()),
              )
              .toList(growable: false)
        : const <DeepSeekChatChoiceChunk>[];
    final usageRaw = json['usage'];
    return DeepSeekChatChunk(
      id: json['id'] as String?,
      model: json['model'] as String?,
      choices: choices,
      usage: usageRaw is Map<String, dynamic>
          ? DeepSeekUsage.fromJson(usageRaw)
          : null,
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class DeepSeekChatChoice {
  final int? index;
  final DeepSeekMessage message;
  final String? finishReason;

  const DeepSeekChatChoice({
    this.index,
    required this.message,
    this.finishReason,
  });

  factory DeepSeekChatChoice.fromJson(Map<String, dynamic> json) {
    return DeepSeekChatChoice(
      index: (json['index'] as num?)?.toInt(),
      message: DeepSeekMessage.fromJson(
        (json['message'] as Map).cast<String, dynamic>(),
      ),
      finishReason: json['finish_reason'] as String?,
    );
  }
}

class DeepSeekChatResponse {
  final String id;
  final String model;
  final List<DeepSeekChatChoice> choices;
  final DeepSeekUsage? usage;
  final Map<String, dynamic> raw;

  const DeepSeekChatResponse({
    required this.id,
    required this.model,
    required this.choices,
    required this.usage,
    required this.raw,
  });

  factory DeepSeekChatResponse.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'] as List? ?? const [];
    return DeepSeekChatResponse(
      id: json['id'] as String? ?? '',
      model: json['model'] as String? ?? '',
      choices: rawChoices
          .whereType<Map>()
          .map((e) => DeepSeekChatChoice.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
      usage: json['usage'] is Map<String, dynamic>
          ? DeepSeekUsage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
      raw: Map<String, dynamic>.from(json),
    );
  }
}

class DeepSeekModelInfo {
  final String id;
  final String? object;

  const DeepSeekModelInfo({required this.id, this.object});

  factory DeepSeekModelInfo.fromJson(Map<String, dynamic> json) {
    return DeepSeekModelInfo(
      id: json['id'] as String? ?? '',
      object: json['object'] as String?,
    );
  }
}

class DeepSeekListModelsResponse {
  final List<DeepSeekModelInfo> data;
  final String? object;

  const DeepSeekListModelsResponse({required this.data, this.object});

  factory DeepSeekListModelsResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] as List? ?? const [];
    return DeepSeekListModelsResponse(
      object: json['object'] as String?,
      data: rawList
          .whereType<Map>()
          .map((e) => DeepSeekModelInfo.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }
}
