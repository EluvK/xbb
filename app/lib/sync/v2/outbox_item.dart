import 'dart:convert';
import 'uuid_service.dart';

/// 表示本地 Outbox 变更事件
class OutboxItem {
  final String id;
  final String tableName;
  final String entityId;
  final String op; // 'PUT' | 'DELETE'
  final String? data; // JSON 字符串
  final int baseVersion;
  final int createdAt; // 毫秒时间戳

  const OutboxItem({
    required this.id,
    required this.tableName,
    required this.entityId,
    required this.op,
    this.data,
    this.baseVersion = 1,
    required this.createdAt,
  });

  /// 快速构建待发 PUT 变更事件
  factory OutboxItem.put({
    String? id,
    required String tableName,
    required String entityId,
    dynamic data,
    int baseVersion = 1,
    int? createdAt,
  }) {
    String? jsonStr;
    if (data is String) {
      jsonStr = data;
    } else if (data != null) {
      jsonStr = jsonEncode(data);
    }

    return OutboxItem(
      id: id ?? UuidService.v7(),
      tableName: tableName,
      entityId: entityId,
      op: 'PUT',
      data: jsonStr,
      baseVersion: baseVersion,
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 快速构建待发 DELETE 变更事件
  factory OutboxItem.delete({
    String? id,
    required String tableName,
    required String entityId,
    int baseVersion = 1,
    int? createdAt,
  }) {
    return OutboxItem(
      id: id ?? UuidService.v7(),
      tableName: tableName,
      entityId: entityId,
      op: 'DELETE',
      data: null,
      baseVersion: baseVersion,
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory OutboxItem.fromMap(Map<String, dynamic> map) {
    return OutboxItem(
      id: map['id'] as String,
      tableName: map['table_name'] as String,
      entityId: map['entity_id'] as String,
      op: map['op'] as String,
      data: map['data'] as String?,
      baseVersion: (map['base_version'] as num?)?.toInt() ?? 1,
      createdAt: (map['created_at'] as num).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table_name': tableName,
      'entity_id': entityId,
      'op': op,
      'data': data,
      'base_version': baseVersion,
      'created_at': createdAt,
    };
  }

  /// 解析 data 字符串为 Map<String, dynamic>
  Map<String, dynamic>? get parsedData {
    if (data == null) return null;
    try {
      final decoded = jsonDecode(data!);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'value': decoded};
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutboxItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          tableName == other.tableName &&
          entityId == other.entityId &&
          op == other.op &&
          data == other.data &&
          baseVersion == other.baseVersion &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, tableName, entityId, op, data, baseVersion, createdAt);

  @override
  String toString() =>
      'OutboxItem(id: $id, table: $tableName, entityId: $entityId, op: $op, v: $baseVersion, createdAt: $createdAt)';
}
