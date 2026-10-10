import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'errors.dart';
import 'models.dart';

class DeepSeekClient {
  final String baseUrl;
  final String? apiKey;
  final http.Client _httpClient;

  DeepSeekClient({
    this.baseUrl = 'https://api.deepseek.com',
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  DeepSeekChatApi get chat => DeepSeekChatApi(this);

  DeepSeekModelsApi get models => DeepSeekModelsApi(this);

  DeepSeekFimApi get fim => DeepSeekFimApi(this);

  DeepSeekChatApi get betaChat => DeepSeekChatApi(this, useBetaBaseUrl: true);

  Uri buildUri(String path, {bool useBetaBaseUrl = false}) {
    final root = useBetaBaseUrl ? '$baseUrl/beta' : baseUrl;
    return Uri.parse('$root$path');
  }

  Map<String, String> buildHeaders({String accept = 'application/json'}) {
    return <String, String>{
      'Content-Type': 'application/json',
      'Accept': accept,
      if ((apiKey ?? '').isNotEmpty) 'Authorization': 'Bearer $apiKey',
    };
  }

  Never throwMappedException(http.Response response) {
    Map<String, dynamic>? errorMap;
    String message = 'Request failed';
    final raw = response.body;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          errorMap = error;
          final rawMessage = error['message'];
          if (rawMessage is String && rawMessage.isNotEmpty) {
            message = rawMessage;
          }
        }
      }
    } catch (_) {}

    final code = response.statusCode;
    if (code == 400) {
      throw DeepSeekBadRequestException(
        statusCode: code,
        message: message,
        error: errorMap,
        rawBody: raw,
      );
    }
    if (code == 401) {
      throw DeepSeekAuthenticationException(
        statusCode: code,
        message: message,
        error: errorMap,
        rawBody: raw,
      );
    }
    if (code == 402) {
      throw DeepSeekInsufficientBalanceException(
        statusCode: code,
        message: message,
        error: errorMap,
        rawBody: raw,
      );
    }
    if (code == 422) {
      throw DeepSeekInvalidParameterException(
        statusCode: code,
        message: message,
        error: errorMap,
        rawBody: raw,
      );
    }
    if (code == 429) {
      throw DeepSeekRateLimitException(
        statusCode: code,
        message: message,
        error: errorMap,
        rawBody: raw,
      );
    }
    if (code == 500 || code == 503) {
      throw DeepSeekServerException(
        statusCode: code,
        message: message,
        error: errorMap,
        rawBody: raw,
      );
    }
    throw DeepSeekApiException(
      statusCode: code,
      message: message,
      error: errorMap,
      rawBody: raw,
    );
  }

  void close() {
    _httpClient.close();
  }
}

class DeepSeekChatApi {
  final DeepSeekClient _client;
  final bool useBetaBaseUrl;

  const DeepSeekChatApi(this._client, {this.useBetaBaseUrl = false});

  Future<DeepSeekChatResponse> create(DeepSeekChatRequest request) async {
    final uri = _client.buildUri(
      '/chat/completions',
      useBetaBaseUrl: useBetaBaseUrl,
    );
    final response = await _client._httpClient.post(
      uri,
      headers: _client.buildHeaders(),
      body: jsonEncode(request.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _client.throwMappedException(response);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return DeepSeekChatResponse.fromJson(
      Map<String, dynamic>.from(decoded as Map),
    );
  }

  Stream<DeepSeekChatChunk> createStream(
    DeepSeekChatRequest request, {
    Duration? timeout,
  }) async* {
    final uri = _client.buildUri(
      '/chat/completions',
      useBetaBaseUrl: useBetaBaseUrl,
    );
    final req = http.Request('POST', uri)
      ..headers.addAll(_client.buildHeaders(accept: 'text/event-stream'))
      ..body = jsonEncode(request.toJson(includeStreamOptions: true));

    final response = await _client._httpClient.send(req);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final bodyBytes = await response.stream.toBytes();
      final fake = http.Response.bytes(bodyBytes, response.statusCode);
      _client.throwMappedException(fake);
    }

    Stream<String> lineStream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    if (timeout != null) {
      lineStream = lineStream.timeout(timeout);
    }

    await for (final line in lineStream) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) continue;
      final payload = trimmed.substring(5).trim();
      if (payload.isEmpty) continue;
      if (payload == '[DONE]') break;
      dynamic decoded;
      try {
        decoded = jsonDecode(payload);
      } catch (_) {
        continue;
      }
      if (decoded is Map<String, dynamic>) {
        yield DeepSeekChatChunk.fromJson(decoded);
      }
    }
  }
}

class DeepSeekModelsApi {
  final DeepSeekClient _client;

  const DeepSeekModelsApi(this._client);

  Future<DeepSeekListModelsResponse> list() async {
    final uri = _client.buildUri('/models');
    final response = await _client._httpClient.get(
      uri,
      headers: _client.buildHeaders(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _client.throwMappedException(response);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return DeepSeekListModelsResponse.fromJson(
      Map<String, dynamic>.from(decoded as Map),
    );
  }
}

class DeepSeekFimApi {
  final DeepSeekClient _client;

  const DeepSeekFimApi(this._client);

  Future<Map<String, dynamic>> complete({
    required String model,
    required String prompt,
    required String suffix,
    int? maxTokens,
    double? temperature,
  }) async {
    final uri = _client.buildUri('/completions', useBetaBaseUrl: true);
    final body = <String, dynamic>{
      'model': model,
      'prompt': prompt,
      'suffix': suffix,
      if (maxTokens != null) 'max_tokens': maxTokens,
      if (temperature != null) 'temperature': temperature,
    };
    final response = await _client._httpClient.post(
      uri,
      headers: _client.buildHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _client.throwMappedException(response);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return Map<String, dynamic>.from(decoded as Map);
  }
}
