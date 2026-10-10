import 'dart:convert';

/// 客户端提交的单条变更
class SyncMutation {
  final String table;
  final String id;
  final String op; // 'PUT' | 'DELETE'
  final dynamic data;
  final int baseVersion;
  final int? clientTimestamp;

  const SyncMutation({
    required this.table,
    required this.id,
    required this.op,
    this.data,
    this.baseVersion = 1,
    this.clientTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'table': table,
      'id': id,
      'op': op,
      if (data != null) 'data': data,
      'base_version': baseVersion,
      if (clientTimestamp != null) 'client_timestamp': clientTimestamp,
    };
  }

  factory SyncMutation.fromJson(Map<String, dynamic> json) {
    return SyncMutation(
      table: json['table'] as String,
      id: json['id'] as String,
      op: json['op'] as String,
      data: json['data'],
      baseVersion: (json['base_version'] as num?)?.toInt() ?? 1,
      clientTimestamp: (json['client_timestamp'] as num?)?.toInt(),
    );
  }
}

/// POST /sync/v1/push 请求体
class SyncPushRequest {
  final String clientId;
  final List<SyncMutation> mutations;

  const SyncPushRequest({
    required this.clientId,
    required this.mutations,
  });

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'mutations': mutations.map((m) => m.toJson()).toList(),
    };
  }
}

/// 版本冲突项
class SyncConflictItem {
  final String id;
  final String reason;
  final int? serverVersion;
  final dynamic currentData;

  const SyncConflictItem({
    required this.id,
    required this.reason,
    this.serverVersion,
    this.currentData,
  });

  factory SyncConflictItem.fromJson(Map<String, dynamic> json) {
    return SyncConflictItem(
      id: json['id'] as String,
      reason: json['reason'] as String,
      serverVersion: (json['server_version'] as num?)?.toInt(),
      currentData: json['current_data'],
    );
  }
}

/// POST /sync/v1/push 响应体
class SyncPushResponse {
  final List<String> appliedIds;
  final List<SyncConflictItem> conflicts;

  const SyncPushResponse({
    required this.appliedIds,
    this.conflicts = const [],
  });

  factory SyncPushResponse.fromJson(Map<String, dynamic> json) {
    final applied = (json['applied_ids'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final conflicts = (json['conflicts'] as List<dynamic>?)
            ?.map((e) => SyncConflictItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return SyncPushResponse(appliedIds: applied, conflicts: conflicts);
  }
}

/// 增量变更项
class SyncChangeItem {
  final int seq;
  final String table;
  final String id;
  final String op; // 'PUT' | 'DELETE'
  final dynamic data;
  final int version;

  const SyncChangeItem({
    required this.seq,
    required this.table,
    required this.id,
    required this.op,
    this.data,
    required this.version,
  });

  factory SyncChangeItem.fromJson(Map<String, dynamic> json) {
    return SyncChangeItem(
      seq: (json['seq'] as num).toInt(),
      table: json['table'] as String,
      id: json['id'] as String,
      op: json['op'] as String,
      data: json['data'],
      version: (json['version'] as num?)?.toInt() ?? 1,
    );
  }

  /// 获取字符串形式的 data
  String? get dataAsString {
    if (data == null) return null;
    if (data is String) return data as String;
    return jsonEncode(data);
  }
}

/// GET /sync/v1/pull 响应体
class SyncPullResponse {
  final int checkpoint;
  final bool hasMore;
  final List<SyncChangeItem> changes;

  const SyncPullResponse({
    required this.checkpoint,
    required this.hasMore,
    required this.changes,
  });

  factory SyncPullResponse.fromJson(Map<String, dynamic> json) {
    final changesList = (json['changes'] as List<dynamic>?)
            ?.map((e) => SyncChangeItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return SyncPullResponse(
      checkpoint: (json['checkpoint'] as num?)?.toInt() ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
      changes: changesList,
    );
  }
}
