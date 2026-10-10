import 'dart:async';

/// 纯净的轻量服务定位器（替代 Get.find / Get.put）
class Locate {
  static final Map<Type, dynamic> _instances = {};

  /// 获取已注册的实例
  static T find<T>() {
    final instance = _instances[T];
    if (instance == null) {
      throw StateError('Service of type $T is not registered in Locate.');
    }
    return instance as T;
  }

  /// 查找实例（若不存在返回 null）
  static T? findOrNull<T>() {
    final instance = _instances[T];
    return instance as T?;
  }

  /// 注册单例对象
  static T put<T>(T instance, {bool permanent = false}) {
    _instances[T] = instance;
    return instance;
  }

  /// 异步注册单例对象
  static Future<T> putAsync<T>(
    FutureOr<T> Function() builder, {
    bool permanent = false,
  }) async {
    final instance = await builder();
    _instances[T] = instance;
    return instance;
  }

  /// 检查某类型服务是否已注册
  static bool isRegistered<T>() => _instances.containsKey(T);

  /// 移除已注册的服务
  static Future<void> delete<T>({bool force = false}) async {
    final instance = _instances.remove(T);
    if (instance != null) {
      try {
        instance.dispose();
      } catch (_) {}
    }
  }

  /// 清空所有注册服务
  static void clear() {
    _instances.clear();
  }
}
