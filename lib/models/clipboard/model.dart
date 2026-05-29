import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sync_annotation/sync_annotation.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/syncstore.dart';
import 'package:xbb/models/clipboard/db.dart';
import 'package:xbb/utils/utils.dart';

part 'model.g.dart';
part 'model.freezed.dart';

Future<void> reInitClipboardSync(SyncStoreClient client) async {
  if (Get.isRegistered<ClipboardHistoryEntryController>()) {
    await Get.delete<ClipboardHistoryEntryController>(force: true);
  }
  final controller = await Get.putAsync<ClipboardHistoryEntryController>(() async {
    return ClipboardHistoryEntryController(client);
  }, permanent: true);
  await controller.ensureInitialization();
}

Future<void> onReadySyncClipboard({
  bool showCompletionToast = true,
  bool skipHealthCheck = false,
  bool showErrorToast = true,
  bool rethrowOnError = false,
}) async {
  final controller = Get.find<ClipboardHistoryEntryController>();
  if (!skipHealthCheck) {
    final SyncStoreClient ssClient = Get.find<SyncStoreControl>().syncStoreClient;
    final latency = await ssClient.pingLatencyMs();
    if (latency < 0) {
      print('SyncStore health check failed, skipping clipboard initial sync.');
      if (showErrorToast) {
        flushBar(FlushLevel.WARNING, '同步服务异常', '无法连接到同步服务，剪贴板同步已跳过');
      }
      if (rethrowOnError) {
        throw Exception('SyncStore health check failed for clipboard initial sync');
      }
      return;
    }
  }

  try {
    await runSyncTaskWithStatus(
      [() => controller.syncAll(batchSize: 100), () => controller.rebuildLocal()],
      from: 0.0,
      to: 100.0,
    );
    if (showCompletionToast) {
      successSimpleFlushBar('剪贴板同步完成');
    }
  } catch (e) {
    print('Error during clipboard initial sync: $e');
    if (showErrorToast) {
      flushBar(FlushLevel.WARNING, '同步错误', '剪贴板同步过程中发生错误: $e');
    }
    if (rethrowOnError) {
      rethrow;
    }
  }
}

@Repository(
  collectionName: 'clipboard_history',
  tableName: 'entry',
  db: ClipboardDB,
  toSyncJsonMethod: 'toSyncJson',
  fromRemoteJsonFactory: 'fromRemoteJson',
)
@freezed
abstract class ClipboardHistoryEntry with _$ClipboardHistoryEntry {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ClipboardHistoryEntry({required String data, @Default(true) bool localOnly}) = _ClipboardHistoryEntry;

  factory ClipboardHistoryEntry.fromJson(Map<String, dynamic> json) => _$ClipboardHistoryEntryFromJson(json);

  static ClipboardHistoryEntry fromRemoteJson(Map<String, dynamic> json) {
    final parsed = ClipboardHistoryEntry.fromJson(json);
    if (!parsed.localOnly) {
      return parsed;
    }
    return parsed.copyWith(localOnly: false);
  }
}

extension ClipboardHistoryEntrySyncPayload on ClipboardHistoryEntry {
  Map<String, dynamic> toSyncJson() {
    return <String, dynamic>{'data': data};
  }
}

class ClipboardManualSyncResult {
  final int totalSelected;
  final int syncedCount;
  final int failedCount;
  final int alreadySyncedCount;
  final Set<String> failedIds;

  const ClipboardManualSyncResult({
    required this.totalSelected,
    required this.syncedCount,
    required this.failedCount,
    required this.alreadySyncedCount,
    required this.failedIds,
  });
}

class ClipboardManualDeleteResult {
  final int totalSelected;
  final int deletedCount;
  final int failedCount;
  final Set<String> failedIds;

  const ClipboardManualDeleteResult({
    required this.totalSelected,
    required this.deletedCount,
    required this.failedCount,
    required this.failedIds,
  });
}

class ClipboardEditSaveResult {
  final bool changed;
  final bool remoteAttempted;
  final bool remoteSucceeded;

  const ClipboardEditSaveResult({required this.changed, required this.remoteAttempted, required this.remoteSucceeded});
}

Future<ClipboardManualSyncResult> confirmClipboardEntriesManualSync({
  required SyncStoreClient client,
  required List<ClipboardHistoryEntryDataItem> selectedItems,
}) async {
  int syncedCount = 0;
  int failedCount = 0;
  int alreadySyncedCount = 0;
  final failedIds = <String>{};

  for (final item in selectedItems) {
    if (!item.body.localOnly) {
      alreadySyncedCount += 1;
      continue;
    }

    item.syncStatus = SyncStatus.syncing;
    await ClipboardHistoryEntryRepository().updateToLocalDb(item);

    try {
      final newId = await client.create('clipboard_history', 'entry', item.body.toSyncJson());
      final createdItem = await client.get<ClipboardHistoryEntry>(
        'clipboard_history',
        'entry',
        newId,
        ClipboardHistoryEntry.fromRemoteJson,
      );
      createdItem.syncStatus = SyncStatus.archived;
      createdItem.colorTag = item.colorTag;

      await ClipboardHistoryEntryRepository().deleteFromLocalDb(item.id);
      await ClipboardHistoryEntryRepository().addToLocalDb(createdItem);
      syncedCount += 1;
    } catch (_) {
      item.syncStatus = SyncStatus.failed;
      await ClipboardHistoryEntryRepository().updateToLocalDb(item);
      failedCount += 1;
      failedIds.add(item.id);
    }
  }

  return ClipboardManualSyncResult(
    totalSelected: selectedItems.length,
    syncedCount: syncedCount,
    failedCount: failedCount,
    alreadySyncedCount: alreadySyncedCount,
    failedIds: failedIds,
  );
}

Future<ClipboardEditSaveResult> saveEditedClipboardEntry({
  required SyncStoreClient client,
  required ClipboardHistoryEntryDataItem item,
  required String newText,
}) async {
  if (newText == item.body.data) {
    return const ClipboardEditSaveResult(changed: false, remoteAttempted: false, remoteSucceeded: false);
  }

  final updatedBody = item.body.copyWith(data: newText);
  final updatedItem = item.updatedBody(updatedBody);
  await ClipboardHistoryEntryRepository().updateToLocalDb(updatedItem);

  if (updatedItem.body.localOnly) {
    return const ClipboardEditSaveResult(changed: true, remoteAttempted: false, remoteSucceeded: false);
  }

  updatedItem.syncStatus = SyncStatus.syncing;
  await ClipboardHistoryEntryRepository().updateToLocalDb(updatedItem);

  try {
    await client.update('clipboard_history', 'entry', updatedItem.id, updatedItem.body.toSyncJson());
    final fetched = await client.get<ClipboardHistoryEntry>(
      'clipboard_history',
      'entry',
      updatedItem.id,
      ClipboardHistoryEntry.fromRemoteJson,
    );
    fetched.syncStatus = SyncStatus.archived;
    fetched.colorTag = updatedItem.colorTag;
    await ClipboardHistoryEntryRepository().updateToLocalDb(fetched);

    return const ClipboardEditSaveResult(changed: true, remoteAttempted: true, remoteSucceeded: true);
  } catch (_) {
    updatedItem.syncStatus = SyncStatus.failed;
    await ClipboardHistoryEntryRepository().updateToLocalDb(updatedItem);
    return const ClipboardEditSaveResult(changed: true, remoteAttempted: true, remoteSucceeded: false);
  }
}

Future<ClipboardManualDeleteResult> deleteClipboardEntriesWithRemoteSync({
  required SyncStoreClient client,
  required List<ClipboardHistoryEntryDataItem> selectedItems,
}) async {
  int deletedCount = 0;
  int failedCount = 0;
  final failedIds = <String>{};

  for (final item in selectedItems) {
    try {
      if (!item.body.localOnly) {
        await client.delete('clipboard_history', 'entry', item.id);
      }
      await ClipboardHistoryEntryRepository().deleteFromLocalDb(item.id);
      deletedCount += 1;
    } catch (_) {
      failedCount += 1;
      failedIds.add(item.id);
    }
  }

  return ClipboardManualDeleteResult(
    totalSelected: selectedItems.length,
    deletedCount: deletedCount,
    failedCount: failedCount,
    failedIds: failedIds,
  );
}
