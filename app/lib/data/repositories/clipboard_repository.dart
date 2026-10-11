import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/base_repository.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/models/clipboard/model.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';
import 'package:xbb/sync/v2/uuid_service.dart';

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
          id: r['id'] as String,
          owner: r['owner'] as String? ?? 'default',
          body: entry,
          createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now(),
          syncStatus: entry.localOnly ? SyncStatus.localOnly : SyncStatus.synced,
        );
      }).toList();
    });
  }

  /// 捕获新文本（ADR-0002: 强制 localOnly = true，禁止自动入队 Outbox 双写）
  Future<void> capture(String text, String currentUserId) async {
    if (text.trim().isEmpty) return;

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
        if (last.data == text) return;
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

  /// 删除条目
  Future<void> delete(String id) async {
    await db.delete('clipboard_history_entry', where: 'id = ?', whereArgs: [id]);
    changeNotifier.notify('clipboard_history_entry');
  }

  /// 清空历史
  Future<void> clearAll() async {
    await db.delete('clipboard_history_entry');
    changeNotifier.notify('clipboard_history_entry');
  }
}
