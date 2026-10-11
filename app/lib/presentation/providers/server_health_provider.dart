import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/core/network/api_client.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

enum ServerHealthState { checking, available, unavailable }

class ServerHealthStatus {
  final ServerHealthState state;
  final int latencyMs;
  final String? errorMessage;
  final DateTime lastCheckedTime;
  final String baseUrl;

  const ServerHealthStatus({
    this.state = ServerHealthState.checking,
    this.latencyMs = -1,
    this.errorMessage,
    required this.lastCheckedTime,
    required this.baseUrl,
  });

  ServerHealthStatus copyWith({
    ServerHealthState? state,
    int? latencyMs,
    String? errorMessage,
    DateTime? lastCheckedTime,
    String? baseUrl,
  }) {
    return ServerHealthStatus(
      state: state ?? this.state,
      latencyMs: latencyMs ?? this.latencyMs,
      errorMessage: errorMessage ?? this.errorMessage,
      lastCheckedTime: lastCheckedTime ?? this.lastCheckedTime,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }
}

class ServerHealthNotifier extends StateNotifier<ServerHealthStatus> {
  final Dio _dio;
  final GetStorage _box;
  Timer? _timer;

  ServerHealthNotifier(this._dio, this._box)
      : super(ServerHealthStatus(
          state: ServerHealthState.checking,
          lastCheckedTime: DateTime.now(),
          baseUrl: ApiClient.instance.baseUrl,
        )) {
    checkHealth();
    // 自动探测服务器在线状态（每 30 秒自动轮询一次）
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkHealth();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 探测服务在线状态并测速
  Future<void> checkHealth() async {
    state = state.copyWith(state: ServerHealthState.checking);
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      stopwatch.stop();

      if (response.statusCode == 200) {
        state = ServerHealthStatus(
          state: ServerHealthState.available,
          latencyMs: stopwatch.elapsedMilliseconds,
          lastCheckedTime: DateTime.now(),
          baseUrl: ApiClient.instance.baseUrl,
        );
      } else {
        state = ServerHealthStatus(
          state: ServerHealthState.unavailable,
          latencyMs: -1,
          errorMessage: '状态码: ${response.statusCode}',
          lastCheckedTime: DateTime.now(),
          baseUrl: ApiClient.instance.baseUrl,
        );
      }
    } catch (e) {
      stopwatch.stop();
      state = ServerHealthStatus(
        state: ServerHealthState.unavailable,
        latencyMs: -1,
        errorMessage: '网络连接失败',
        lastCheckedTime: DateTime.now(),
        baseUrl: ApiClient.instance.baseUrl,
      );
    }
  }

  /// 更新服务器地址并重新探测与同步依赖
  Future<void> updateServerUrl(String newUrl) async {
    final normalized = ApiClient.normalizeBaseUrl(newUrl);
    ApiClient.instance.updateBaseUrl(normalized);

    // 持久化到 Storage
    final rawSetting = _box.read<Map<String, dynamic>?>(STORAGE_SETTING_SYNCSTORE_SETTINGS_KEY) ?? {};
    final updatedMap = Map<String, dynamic>.from(rawSetting)..['base_url'] = normalized;
    await _box.write(STORAGE_SETTING_SYNCSTORE_SETTINGS_KEY, updatedMap);

    // 更新 SyncWorker 网络依赖
    SyncWorker.instance.updateDependencies(dio: ApiClient.instance.dio);

    // 更新状态并立即触发 Ping 探测
    state = state.copyWith(baseUrl: normalized);
    await checkHealth();
  }
}

final serverHealthProvider = StateNotifierProvider<ServerHealthNotifier, ServerHealthStatus>((ref) {
  final dio = ApiClient.instance.dio;
  final box = GetStorage(GET_STORAGE_FILE_KEY);
  return ServerHealthNotifier(dio, box);
});
