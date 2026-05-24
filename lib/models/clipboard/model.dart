import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sync_annotation/sync_annotation.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/clipboard/db.dart';

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

@Repository(collectionName: 'clipboard_history', tableName: 'entry', db: ClipboardDB)
@freezed
abstract class ClipboardHistoryEntry with _$ClipboardHistoryEntry {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ClipboardHistoryEntry({required String data, @Default(true) bool localOnly}) = _ClipboardHistoryEntry;

  factory ClipboardHistoryEntry.fromJson(Map<String, dynamic> json) => _$ClipboardHistoryEntryFromJson(json);
}
