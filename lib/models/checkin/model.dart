import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sync_annotation/sync_annotation.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/controller/checkin_widget.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/syncstore.dart';
import 'package:xbb/models/checkin/db.dart';
import 'package:xbb/utils/utils.dart';

part 'model.g.dart';
part 'model.freezed.dart';

Future<void> reInitCheckinSync(SyncStoreClient client) async {
  await reInit<CheckinEventController>(() => CheckinEventController(client), (c) => c.ensureInitialization());
  await reInit<CheckinRecordController>(() => CheckinRecordController(client), (c) => c.ensureInitialization());
  CheckinWidgetBridge.scheduleRefresh();
}

Future<void> onReadySyncCheckin({
  bool showCompletionToast = true,
  bool skipHealthCheck = false,
  bool showErrorToast = true,
  bool rethrowOnError = false,
}) async {
  final eventController = Get.find<CheckinEventController>();
  final recordController = Get.find<CheckinRecordController>();
  if (!skipHealthCheck) {
    final SyncStoreClient ssClient = Get.find<SyncStoreControl>().syncStoreClient;
    final latency = await ssClient.pingLatencyMs();
    if (latency < 0) {
      print('SyncStore health check failed, skipping checkin initial sync.');
      if (showErrorToast) {
        flushBar(FlushLevel.WARNING, "同步服务异常", "无法连接到同步服务，打卡同步已跳过");
      }
      if (rethrowOnError) {
        throw Exception('SyncStore health check failed for checkin initial sync');
      }
      return;
    }
  }

  try {
    await runSyncTaskWithStatus(
      [
        () => eventController.syncAll(batchSize: 100),
        () => recordController.syncAll(batchSize: 100),
        () => recordController.rebuildLocal(),
        () => eventController.rebuildLocal(),
      ],
      from: 0.0,
      to: 100.0,
    );
    CheckinWidgetBridge.scheduleRefresh();
    if (showCompletionToast) {
      successSimpleFlushBar("打卡同步完成");
    }
  } catch (e) {
    print('Error during checkin initial sync: $e');
    if (showErrorToast) {
      flushBar(FlushLevel.WARNING, "同步错误", "打卡初始同步过程中发生错误: $e");
    }
    if (rethrowOnError) {
      rethrow;
    }
  }
}

Future<void> reInit<T extends GetxController>(
  FutureOr<T> Function() creator,
  FutureOr<void> Function(T controller)? initializer,
) async {
  if (Get.isRegistered<T>()) {
    await Get.delete<T>(force: true);
  }
  final controller = await Get.putAsync<T>(() async {
    return await creator();
  }, permanent: true);
  if (initializer != null) {
    await initializer(controller);
  }
}

@Repository(collectionName: 'checkin', tableName: 'event', db: CheckinDB)
@freezed
abstract class CheckinEvent with _$CheckinEvent {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CheckinEvent({required String name, required String description, required int colorValue}) =
      _CheckinEvent;

  factory CheckinEvent.fromJson(Map<String, dynamic> json) => _$CheckinEventFromJson(json);
}

@Repository(collectionName: 'checkin', tableName: 'record', db: CheckinDB)
@freezed
abstract class CheckinRecord with _$CheckinRecord {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CheckinRecord({
    required String eventId,
    required DateTime createdAtUtc,
    required String localDayKey,
    @Default(0) int timezoneOffsetMinutes,
    String? note,
  }) = _CheckinRecord;

  factory CheckinRecord.fromJson(Map<String, dynamic> json) => _$CheckinRecordFromJson(json);
}
