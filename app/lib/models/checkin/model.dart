import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sync_annotation/sync_annotation.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/checkin/db.dart';

part 'model.g.dart';
part 'model.freezed.dart';

@Repository(collectionName: 'checkin', tableName: 'checkin_event', db: CheckinDB)
@freezed
abstract class CheckinEvent with _$CheckinEvent {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CheckinEvent({required String name, required String description, required int colorValue}) =
      _CheckinEvent;

  factory CheckinEvent.fromJson(Map<String, dynamic> json) => _$CheckinEventFromJson(json);
}

@Repository(collectionName: 'checkin', tableName: 'checkin_record', db: CheckinDB)
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
