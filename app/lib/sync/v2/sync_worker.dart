import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:xbb/core/network/api_client.dart';
import 'local_first_db.dart';
import 'outbox_dao.dart';
import 'outbox_item.dart';
import 'sync_meta_dao.dart';
import 'sync_models.dart';
import 'uuid_service.dart';

/// 后台守护进程运行状态
enum SyncWorkerState { idle, syncing, error }

/// 全局单例 SyncWorker（后台同步守护进程）
/// 负责本地变更 Push 到服务端，以及服务端最新变更流 Pull 回放至本地
class SyncWorker {
  static SyncWorker? _instance;

  /// 获取全局单例（需先调用 configure 或提供默认参数）
  static SyncWorker get instance {
    _instance ??= SyncWorker();
    return _instance!;
  }

  /// 配置或重置全局单例
  static SyncWorker configure({
    required Dio dio,
    required Database db,
    String? clientId,
    Duration pollInterval = const Duration(seconds: 15),
    void Function(String message)? onUpgradeRequired,
  }) {
    _instance?.stop();
    _instance = SyncWorker(
      dio: dio,
      db: db,
      clientId: clientId,
      pollInterval: pollInterval,
      onUpgradeRequired: onUpgradeRequired,
    );
    return _instance!;
  }

  Dio? _dio;
  Database? _db;
  String _clientId;
  final Duration _pollInterval;

  Timer? _pollTimer;
  bool _isRunning = false;
  bool _isSyncing = false;
  bool _hasPendingTrigger = false;
  bool _isUpgradeRequired = false;
  SyncWorkerState _state = SyncWorkerState.idle;

  /// 同步状态流转监听 (syncing -> idle / error)
  void Function(SyncWorkerState state, {Object? error})? onStateChanged;

  /// 426 升级要求回调
  void Function(String message)? onUpgradeRequired;

  /// Push 成功事件监听
  void Function(SyncPushResponse response)? onPushCompleted;

  /// Pull 成功事件监听
  void Function(SyncPullResponse response)? onPullCompleted;

  /// 同步异常监听
  void Function(Object error)? onError;

  SyncWorker({
    Dio? dio,
    Database? db,
    String? clientId,
    Duration pollInterval = const Duration(seconds: 15),
    this.onUpgradeRequired,
  })  : _dio = dio,
        _db = db,
        _clientId = clientId ?? UuidService.v4(),
        _pollInterval = pollInterval;

  // --- Getters & Setters ---

  bool get isRunning => _isRunning;
  bool get isSyncing => _isSyncing;
  bool get isUpgradeRequired => _isUpgradeRequired;
  SyncWorkerState get state => _state;
  String get clientId => _clientId;

  void updateDependencies({Dio? dio, Database? db, String? clientId}) {
    if (dio != null) _dio = dio;
    if (db != null) _db = db;
    if (clientId != null) _clientId = clientId;
  }

  /// 启动后台守护定时同步
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _isUpgradeRequired = false;

    // 启动即触发一次首轮同步
    triggerSync();

    // 开启定时轮询
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      triggerSync();
    });
  }

  /// 停止后台轮询
  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isRunning = false;
  }

  /// 唤醒机制：本地发生写操作后主动唤醒
  void notifyLocalWrite() {
    triggerSync();
  }

  /// 唤醒机制：检测到网络恢复后主动唤醒
  void notifyNetworkRestored() {
    triggerSync();
  }

  /// 触发一次完整的同步周期（Push + Pull）
  /// 具备并发互斥锁与待定任务累积（Debounce / Serialized execution）
  Future<void> triggerSync() async {
    if (_isUpgradeRequired) return;

    if (_isSyncing) {
      _hasPendingTrigger = true;
      return;
    }

    _isSyncing = true;
    _state = SyncWorkerState.syncing;
    onStateChanged?.call(SyncWorkerState.syncing);

    try {
      await _runSyncCycle();
      _state = SyncWorkerState.idle;
      onStateChanged?.call(SyncWorkerState.idle);
    } catch (e) {
      _state = SyncWorkerState.error;
      onError?.call(e);
      // 检查是否为 426 Upgrade Required
      _handlePotentialUpgradeRequired(e);
      onStateChanged?.call(SyncWorkerState.error, error: e);
    } finally {
      _isSyncing = false;
      if (_hasPendingTrigger) {
        _hasPendingTrigger = false;
        // 还有待处理触发，继续下一轮
        unawaited(triggerSync());
      }
    }
  }

  /// 执行一次单次同步周期（先 Push，后 Pull）
  Future<void> _runSyncCycle() async {
    final dio = _dio;
    final db = _db;
    if (dio == null || db == null) {
      // ignore: avoid_print
      print('[SyncWorker] Skipped sync cycle: dio is ${dio == null ? 'null' : 'injected'}, db is ${db == null ? 'null' : 'injected'}');
      return;
    }

    // 1. Push 流程
    await _pushPendingMutations(dio, db);

    // 2. Pull 流程
    await _pullRemoteChanges(dio, db);
  }

  /// Push 流程：读取本地 outbox，提交至 /sync/v1/push，成功后批量清除
  Future<SyncPushResponse?> _pushPendingMutations(Dio dio, Database db) async {
    final pending = await OutboxDao.getPending(db, limit: 100);
    if (pending.isEmpty) return null;

    // 按 (tableName, entityId) 分组折叠：保留最后一条变更作为权威状态，并记录其初始 baseVersion
    final Map<String, OutboxItem> coalescedMap = {};
    final Map<String, int> entityFirstBaseVersion = {};
    final Map<String, List<String>> entityToOutboxIds = {};

    for (final item in pending) {
      final key = '${item.tableName}:${item.entityId}';
      entityFirstBaseVersion.putIfAbsent(key, () => item.baseVersion);
      coalescedMap[key] = item;
      entityToOutboxIds.putIfAbsent(item.entityId, () => []).add(item.id);
    }

    final mutations = coalescedMap.entries.map((entry) {
      final item = entry.value;
      // 提交时 baseVersion 采用该实体在本批次发生首次改动时的 baseVersion，消除批内中间版本冲突
      final initialBaseVersion = entityFirstBaseVersion[entry.key] ?? item.baseVersion;
      return SyncMutation(
        table: item.tableName,
        id: item.entityId,
        op: item.op,
        data: item.parsedData ?? item.data,
        baseVersion: initialBaseVersion,
        clientTimestamp: item.createdAt,
      );
    }).toList();

    final pushReq = SyncPushRequest(clientId: _clientId, mutations: mutations);

    final response = await dio.post<Map<String, dynamic>>(
      '/sync/v1/push',
      data: pushReq.toJson(),
    );

    if (response.data == null) return null;
    final pushResp = SyncPushResponse.fromJson(response.data!);

    // 匹配出服务端已应用或处理的 entityId，对应清除 outbox 表中的记录
    final appliedEntityIds = pushResp.appliedIds.toSet();
    final conflictEntityIds = pushResp.conflicts.map((c) => c.id).toSet();

    // 对于 CAS 版本冲突，使用服务端返回的权威最新数据就地对齐本地
    for (final conflict in pushResp.conflicts) {
      if (conflict.serverVersion != null && conflict.currentData != null) {
        final matches = pending.where((m) => m.entityId == conflict.id);
        for (final m in matches) {
          try {
            final curDataStr = conflict.currentData is String
                ? conflict.currentData as String
                : jsonEncode(conflict.currentData);
            await db.update(
              m.tableName,
              {
                'body': curDataStr,
                'version': conflict.serverVersion,
                'sync_status': 'synced',
              },
              where: 'id = ?',
              whereArgs: [conflict.id],
            );
          } catch (_) {}
        }
      }
    }

    // 收集所有已应用或冲突实体的全部关联 outbox 记录 ID 批量清除
    final Set<String> outboxIdsToDelete = {};
    for (final entityId in appliedEntityIds) {
      final ids = entityToOutboxIds[entityId];
      if (ids != null) outboxIdsToDelete.addAll(ids);
    }
    for (final entityId in conflictEntityIds) {
      final ids = entityToOutboxIds[entityId];
      if (ids != null) outboxIdsToDelete.addAll(ids);
    }

    if (outboxIdsToDelete.isNotEmpty) {
      await OutboxDao.deleteByIds(db, outboxIdsToDelete.toList());
    }

    onPushCompleted?.call(pushResp);
    return pushResp;
  }

  /// Pull 流程：带上 last_seq 调用 /sync/v1/pull，本地事务内批量回放 changes 并推进游标
  Future<SyncPullResponse?> _pullRemoteChanges(Dio dio, Database db) async {
    bool hasMore = true;
    SyncPullResponse? lastResp;

    while (hasMore) {
      final lastSeq = await SyncMetaDao.getLastSeq(db);

      final response = await dio.get<Map<String, dynamic>>(
        '/sync/v1/pull',
        queryParameters: {
          'checkpoint': lastSeq,
          'limit': 200,
        },
      );

      if (response.data == null) break;
      final pullResp = SyncPullResponse.fromJson(response.data!);
      lastResp = pullResp;

      if (pullResp.changes.isNotEmpty) {
        // 在本地事务内批量原子回放
        await db.transaction((txn) async {
          for (final change in pullResp.changes) {
            await _applyRemoteChange(txn, change);
          }
          // 推进本地同步游标
          await SyncMetaDao.setLastSeq(txn, pullResp.checkpoint);
        });
      } else if (pullResp.checkpoint > lastSeq) {
        // 即便无可见变更（如过滤权限后），依然推进游标避免重复扫描
        await SyncMetaDao.setLastSeq(db, pullResp.checkpoint);
      }

      hasMore = pullResp.hasMore;
      onPullCompleted?.call(pullResp);
    }

    return lastResp;
  }

  /// 将远程增量变更回放到本地业务实体表中
  Future<void> _applyRemoteChange(DatabaseExecutor txn, SyncChangeItem change) async {
    final table = change.table;
    final entityId = change.id;
    final op = change.op.toUpperCase();

    // 确保目标实体表已存在
    await txn.execute(LocalFirstDB.buildEntityTableSql(table));

    if (op == 'DELETE') {
      // 软删除或直接物理删除
      await txn.delete(table, where: 'id = ?', whereArgs: [entityId]);
    } else if (op == 'PUT') {
      final nowStr = DateTime.now().toUtc().toIso8601String();
      final dataStr = change.dataAsString ?? '{}';

      String? parentId;
      String? remoteOwner = change.ownerId;
      String? remoteCreatedAt;
      String? colorTag;
      final parsed = change.parsedData;
      if (parsed is Map) {
        parentId = (parsed['repo_id'] ??
                parsed['repoId'] ??
                parsed['post_id'] ??
                parsed['postId'] ??
                parsed['event_id'] ??
                parsed['eventId'] ??
                parsed['tracker_id'] ??
                parsed['trackerId'] ??
                parsed['conversation_id'] ??
                parsed['conversationId'] ??
                parsed['parent_id'] ??
                parsed['parentId'])
            ?.toString();
        remoteOwner ??= parsed['owner']?.toString();
        remoteCreatedAt = parsed['created_at']?.toString() ?? parsed['createdAt']?.toString();
        colorTag = parsed['color_tag']?.toString() ?? parsed['colorTag']?.toString();
      }

      if (remoteCreatedAt == null && change.createdAt != null && change.createdAt! > 0) {
        remoteCreatedAt = DateTime.fromMillisecondsSinceEpoch(change.createdAt!).toUtc().toIso8601String();
      }

      final exists = await txn.query(
        table,
        where: 'id = ?',
        whereArgs: [entityId],
        limit: 1,
      );

      if (exists.isNotEmpty) {
        final updateMap = <String, dynamic>{
          'body': dataStr,
          'sync_status': 'synced',
          'version': change.version,
          'updated_at': nowStr,
        };
        if (parentId != null) {
          updateMap['parent_id'] = parentId;
        }
        if (remoteOwner != null && remoteOwner.isNotEmpty) {
          updateMap['owner'] = remoteOwner;
        }
        if (colorTag != null && colorTag.isNotEmpty) {
          updateMap['color_tag'] = colorTag;
        }
        await txn.update(
          table,
          updateMap,
          where: 'id = ?',
          whereArgs: [entityId],
        );
      } else {
        await txn.insert(
          table,
          {
            'id': entityId,
            'created_at': remoteCreatedAt ?? nowStr,
            'updated_at': nowStr,
            'owner': remoteOwner ?? 'remote',
            'parent_id': parentId,
            'unique': null,
            'sync_status': 'synced',
            'color_tag': colorTag ?? 'none',
            'version': change.version,
            'body': dataStr,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  /// 拦截与优雅处理 426 Upgrade Required
  void _handlePotentialUpgradeRequired(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 426) {
        _isUpgradeRequired = true;
        stop(); // 停止轮询，避免对废弃端点无效请求

        String upgradeMessage = '当前客户端同步协议已废弃，请升级到最新应用版本。';
        final data = error.response?.data;
        if (data is Map && data['message'] != null) {
          upgradeMessage = data['message'].toString();
        }

        onUpgradeRequired?.call(upgradeMessage);
      }
    }
  }
}
