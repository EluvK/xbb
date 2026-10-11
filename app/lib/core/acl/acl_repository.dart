import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:xbb/core/network/api_client.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/sync/v2/outbox_dao.dart';
import 'package:xbb/sync/v2/outbox_item.dart';
import 'package:xbb/sync/v2/sync_worker.dart';
import 'package:xbb/sync/v2/uuid_service.dart';

/// 权限角色等级
enum EntityAclRole {
  spy, // Spy 只读
  subscribe, // Subscribe 订阅评论
  share, // Share 读写更新
  fullAccess, // Full Access 全部权限
}

extension EntityAclRoleExt on EntityAclRole {
  String get label {
    switch (this) {
      case EntityAclRole.spy:
        return 'Spy (只读)';
      case EntityAclRole.subscribe:
        return 'Subscribe (订阅评论)';
      case EntityAclRole.share:
        return 'Share (读写更新)';
      case EntityAclRole.fullAccess:
        return 'Full Access (全部权限)';
    }
  }

  String get description {
    switch (this) {
      case EntityAclRole.spy:
        return '仅允许浏览与查阅内容';
      case EntityAclRole.subscribe:
        return '允许阅读内容并发表评论';
      case EntityAclRole.share:
        return '允许阅读、发表评论与协同编辑更新';
      case EntityAclRole.fullAccess:
        return '具备完全的读写、更新及协作管理权限';
    }
  }

  /// 对应 Rust 服务端的权限代码 ("READ" | "WRITE")
  String get serverPermission {
    switch (this) {
      case EntityAclRole.spy:
      case EntityAclRole.subscribe:
        return 'READ';
      case EntityAclRole.share:
      case EntityAclRole.fullAccess:
        return 'WRITE';
    }
  }
}

/// 实体协作者权限条目
class EntityAclEntry {
  final String userId;
  final String username;
  final String nickname;
  final String avatar;
  final EntityAclRole role;

  EntityAclEntry({
    required this.userId,
    required this.username,
    required this.nickname,
    required this.avatar,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'nickname': nickname,
        'avatar': avatar,
        'role': role.name,
      };

  factory EntityAclEntry.fromJson(Map<String, dynamic> json) {
    EntityAclRole role = EntityAclRole.spy;
    final roleStr = json['role'] as String? ?? 'spy';
    for (final r in EntityAclRole.values) {
      if (r.name.toLowerCase() == roleStr.toLowerCase()) {
        role = r;
        break;
      }
    }

    return EntityAclEntry(
      userId: json['userId'] as String? ?? json['user'] as String? ?? '',
      username: json['username'] as String? ?? '',
      nickname: json['nickname'] as String? ?? json['username'] as String? ?? '',
      avatar: json['avatar'] as String? ?? 'avatar_1',
      role: role,
    );
  }
}

/// 细粒度权限控制核心仓储 (AclRepository)
/// 负责本地 SQLite `acl` 表的管理、与 Rust 服务端 `/sync/v1/acl/grant` & `revoke` 的网络协同
class AclRepository {
  final DatabaseChangeNotifier _changeNotifier;
  final Dio? _dio;

  AclRepository(this._changeNotifier, [Dio? dio]) : _dio = dio;

  Dio get _clientDio => _dio ?? ApiClient.instance.dio;

  /// 读取本地实体的协作者权限列表
  Future<List<EntityAclEntry>> getAcls(
    Database db, {
    required String table,
    required String entityId,
  }) async {
    final rows = await db.query(
      'acl',
      where: 'data_id = ? AND data_collection = ?',
      whereArgs: [entityId, table],
      limit: 1,
    );

    if (rows.isEmpty) return [];
    final jsonStr = rows.first['permissions'] as String?;
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded
          .map((e) => EntityAclEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 监听实体的权限流
  Stream<List<EntityAclEntry>> watchAcls(
    Database db, {
    required String table,
    required String entityId,
  }) {
    return _changeNotifier.watchTable('acl').asyncMap((_) async {
      return getAcls(db, table: table, entityId: entityId);
    });
  }

  /// 为实体添加或更新协作者权限
  Future<void> grantPermission({
    required Database db,
    required String table,
    required String entityId,
    required EntityAclEntry entry,
  }) async {
    // 1. 获取现有权限并合并
    final currentList = await getAcls(db, table: table, entityId: entityId);
    final map = {for (final e in currentList) e.userId: e};
    map[entry.userId] = entry;
    final updatedList = map.values.toList();

    // 2. 本地 SQLite 事务落盘与入队 Outbox
    await db.transaction((txn) async {
      final jsonStr = jsonEncode(updatedList.map((e) => e.toJson()).toList());
      await txn.rawInsert(
        'INSERT OR REPLACE INTO acl (data_id, data_collection, permissions) VALUES (?, ?, ?)',
        [entityId, table, jsonStr],
      );
      final outboxItem = OutboxItem.put(
        id: UuidService.v7(),
        tableName: 'acl',
        entityId: entityId,
        data: jsonStr,
      );
      await OutboxDao.enqueue(txn, outboxItem);
    });

    // 3. 广播本地变动
    _changeNotifier.notify('acl');
    SyncWorker.instance.notifyLocalWrite();

    // 4. 异步推送至远端 Rust 服务端 /sync/v1/acl/grant
    try {
      await _clientDio.post(
        '/sync/v1/acl/grant',
        data: {
          'table': table,
          'entity_id': entityId,
          'grantee_id': entry.userId,
          'permission': entry.role.serverPermission,
        },
      );
    } catch (_) {
      // 离线容错，本地优先
    }
  }

  /// 为实体移除协作者权限
  Future<void> revokePermission({
    required Database db,
    required String table,
    required String entityId,
    required String granteeId,
  }) async {
    final currentList = await getAcls(db, table: table, entityId: entityId);
    final updatedList = currentList.where((e) => e.userId != granteeId).toList();

    await db.transaction((txn) async {
      final jsonStr = jsonEncode(updatedList.map((e) => e.toJson()).toList());
      await txn.rawInsert(
        'INSERT OR REPLACE INTO acl (data_id, data_collection, permissions) VALUES (?, ?, ?)',
        [entityId, table, jsonStr],
      );
      final outboxItem = OutboxItem.put(
        id: UuidService.v7(),
        tableName: 'acl',
        entityId: entityId,
        data: jsonStr,
      );
      await OutboxDao.enqueue(txn, outboxItem);
    });

    _changeNotifier.notify('acl');
    SyncWorker.instance.notifyLocalWrite();

    try {
      await _clientDio.post(
        '/sync/v1/acl/revoke',
        data: {
          'table': table,
          'entity_id': entityId,
          'grantee_id': granteeId,
        },
      );
    } catch (_) {
      // 离线容错，本地优先
    }
  }
}
