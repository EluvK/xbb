import 'package:uuid/uuid.dart';

/// 权威 UUID 生成器
class UuidService {
  static const Uuid _uuid = Uuid();

  /// 生成权威 UUIDv7（基于时间戳单调递增，符合 RFC 9562 规范）
  static String v7() {
    return _uuid.v7();
  }

  /// 生成标准 UUIDv4（随机 UUID，作为辅助或临时标识）
  static String v4() {
    return _uuid.v4();
  }
}
