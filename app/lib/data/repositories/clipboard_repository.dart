import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/models/clipboard/model.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';
import 'package:xbb/sync/v2/uuid_service.dart';

class ClipboardSyncBatchResult {
  final int syncedCount;
  final int skippedCount;
  final int failedCount;
  final List<String> failedIds;

  const ClipboardSyncBatchResult({
    required this.syncedCount,
    required this.skippedCount,
    required this.failedCount,
    required this.failedIds,
  });
}

class ClipboardDeleteBatchResult {
  final int deletedCount;
  final int failedCount;
  final List<String> failedIds;

  const ClipboardDeleteBatchResult({
    required this.deletedCount,
    required this.failedCount,
    required this.failedIds,
  });
}

class ClipboardRepository {
  final Database db;
  final DatabaseChangeNotifier changeNotifier;

  ClipboardRepository({
    required this.db,
    required this.changeNotifier,
  });

  /// 监听全部剪贴板记录
  Stream<List<DataItem<ClipboardHistoryEntry>>> watchEntries() {
    return changeNotifier.watchTable('clipboard_history_entry').asyncMap((_) async {
      final rows = await db.query(
        'clipboard_history_entry',
        orderBy: 'created_at DESC',
      );
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final entry = ClipboardHistoryEntry.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        return DataItem<ClipboardHistoryEntry>(
          r['id'] as String,
          DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
          DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now(),
          r['owner'] as String? ?? 'default',
          null,
          null,
          body: entry,
          syncStatus: entry.localOnly ? SyncStatus.hidden : SyncStatus.synced,
        );
      }).toList();
    });
  }

  /// 捕获新文本（ADR-0002: 强制 localOnly = true，禁止自动入队 Outbox 双写）
  Future<bool> capture(String text, String currentUserId) async {
    if (text.trim().isEmpty) return false;

    // 查重：避免连续重复录入相同文本
    final recent = await db.query(
      'clipboard_history_entry',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (recent.isNotEmpty) {
      final lastBodyStr = recent.first['body'] as String? ?? '{}';
      try {
        final last = ClipboardHistoryEntry.fromJson(jsonDecode(lastBodyStr) as Map<String, dynamic>);
        if (last.data == text) return false;
      } catch (_) {}
    }

    final newId = UuidService.v7();
    final entry = ClipboardHistoryEntry(
      data: text,
      capturedAt: DateTime.now(),
      localOnly: true, // ADR-0002
    );

    final row = <String, dynamic>{
      'id': newId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'owner': currentUserId,
      'parent_id': null,
      'sync_status': 'local_only',
      'color_tag': 'default',
      'body': jsonEncode(entry.toJson()),
    };

    // 仅写入本地库，严禁生成 Outbox 项
    await db.insert('clipboard_history_entry', row, conflictAlgorithm: ConflictAlgorithm.replace);
    changeNotifier.notify('clipboard_history_entry');
    return true;
  }

  /// 用户显式确认上云（ADR-0002: 仅显式确认后才入队 Outbox）
  Future<void> syncToCloud(DataItem<ClipboardHistoryEntry> item) async {
    final updated = item.body.copyWith(localOnly: false);
    final row = <String, dynamic>{
      'id': item.id,
      'created_at': item.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'owner': item.owner,
      'parent_id': null,
      'sync_status': 'pending',
      'color_tag': 'default',
      'body': jsonEncode(updated.toJson()),
    };

    await LocalFirstDB.persistPutRaw(
      db: db,
      tableName: 'clipboard_history_entry',
      entityId: item.id,
      entityRow: row,
    );

    changeNotifier.notify('clipboard_history_entry');
    SyncWorker.instance.notifyLocalWrite();
  }

  /// 复制到系统剪贴板
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// 原位修改剪贴板文本（遵循 ADR-0002 规则：localOnly 仅本地更新，非 localOnly 入队 Outbox）
  Future<bool> updateEntryText(String id, String newText) async {
    final rows = await db.query('clipboard_history_entry', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return false;

    final row = rows.first;
    final bodyStr = row['body'] as String? ?? '{}';
    ClipboardHistoryEntry entry;
    try {
      entry = ClipboardHistoryEntry.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
    } catch (_) {
      return false;
    }

    if (entry.data == newText) {
      return false; // 无变动
    }

    final updatedEntry = entry.copyWith(data: newText);
    final updatedRow = <String, dynamic>{
      'id': id,
      'created_at': row['created_at'],
      'updated_at': DateTime.now().toIso8601String(),
      'owner': row['owner'],
      'parent_id': row['parent_id'],
      'sync_status': row['sync_status'],
      'color_tag': row['color_tag'],
      'body': jsonEncode(updatedEntry.toJson()),
    };

    if (entry.localOnly) {
      await db.update('clipboard_history_entry', updatedRow, where: 'id = ?', whereArgs: [id]);
    } else {
      await LocalFirstDB.persistPutRaw(
        db: db,
        tableName: 'clipboard_history_entry',
        entityId: id,
        entityRow: updatedRow,
      );
      SyncWorker.instance.notifyLocalWrite();
    }

    changeNotifier.notify('clipboard_history_entry');
    return true;
  }

  /// 批量备份上云（ADR-0002: 跳过已同步项，仅未同步项入队 Outbox，失败项记录保留）
  Future<ClipboardSyncBatchResult> syncSelectedToCloud(List<DataItem<ClipboardHistoryEntry>> items) async {
    int syncedCount = 0;
    int skippedCount = 0;
    int failedCount = 0;
    final failedIds = <String>[];

    for (final item in items) {
      if (!item.body.localOnly) {
        skippedCount++;
        continue;
      }

      try {
        final updated = item.body.copyWith(localOnly: false);
        final row = <String, dynamic>{
          'id': item.id,
          'created_at': item.createdAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'owner': item.owner,
          'parent_id': null,
          'sync_status': 'pending',
          'color_tag': 'default',
          'body': jsonEncode(updated.toJson()),
        };

        await LocalFirstDB.persistPutRaw(
          db: db,
          tableName: 'clipboard_history_entry',
          entityId: item.id,
          entityRow: row,
        );
        syncedCount++;
      } catch (_) {
        failedCount++;
        failedIds.add(item.id);
      }
    }

    if (syncedCount > 0) {
      changeNotifier.notify('clipboard_history_entry');
      SyncWorker.instance.notifyLocalWrite();
    }

    return ClipboardSyncBatchResult(
      syncedCount: syncedCount,
      skippedCount: skippedCount,
      failedCount: failedCount,
      failedIds: failedIds,
    );
  }

  /// 批量删除条目（ADR-0002: localOnly 仅本地物理删除，非 localOnly 需入队 Outbox DELETE 记录）
  Future<ClipboardDeleteBatchResult> deleteSelected(List<DataItem<ClipboardHistoryEntry>> items) async {
    int deletedCount = 0;
    int failedCount = 0;
    final failedIds = <String>[];

    for (final item in items) {
      try {
        if (item.body.localOnly) {
          await db.delete('clipboard_history_entry', where: 'id = ?', whereArgs: [item.id]);
        } else {
          await LocalFirstDB.persistDeleteRaw(
            db: db,
            tableName: 'clipboard_history_entry',
            entityId: item.id,
          );
        }
        deletedCount++;
      } catch (_) {
        failedCount++;
        failedIds.add(item.id);
      }
    }

    if (deletedCount > 0) {
      changeNotifier.notify('clipboard_history_entry');
      SyncWorker.instance.notifyLocalWrite();
    }

    return ClipboardDeleteBatchResult(
      deletedCount: deletedCount,
      failedCount: failedCount,
      failedIds: failedIds,
    );
  }

  /// 删除单条目（遵循 ADR-0002）
  Future<void> delete(String id) async {
    final rows = await db.query('clipboard_history_entry', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return;
    final row = rows.first;
    final bodyStr = row['body'] as String? ?? '{}';
    bool localOnly = true;
    try {
      final entry = ClipboardHistoryEntry.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
      localOnly = entry.localOnly;
    } catch (_) {}

    if (localOnly) {
      await db.delete('clipboard_history_entry', where: 'id = ?', whereArgs: [id]);
    } else {
      await LocalFirstDB.persistDeleteRaw(
        db: db,
        tableName: 'clipboard_history_entry',
        entityId: id,
      );
      SyncWorker.instance.notifyLocalWrite();
    }
    changeNotifier.notify('clipboard_history_entry');
  }

  /// 清空历史（遵循 ADR-0002：对已同步上云条目入队 Outbox DELETE）
  Future<void> clearAll() async {
    final rows = await db.query('clipboard_history_entry');
    bool hasCloudEntries = false;
    for (final row in rows) {
      final bodyStr = row['body'] as String? ?? '{}';
      bool localOnly = true;
      try {
        final entry = ClipboardHistoryEntry.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        localOnly = entry.localOnly;
      } catch (_) {}

      if (!localOnly) {
        hasCloudEntries = true;
        await LocalFirstDB.persistDeleteRaw(
          db: db,
          tableName: 'clipboard_history_entry',
          entityId: row['id'] as String,
        );
      }
    }

    await db.delete('clipboard_history_entry');
    changeNotifier.notify('clipboard_history_entry');
    if (hasCloudEntries) {
      SyncWorker.instance.notifyLocalWrite();
    }
  }
}
