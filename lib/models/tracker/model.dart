import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sync_annotation/sync_annotation.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/tracker/db.dart';

part 'model.g.dart';
part 'model.freezed.dart';

@Repository(collectionName: 'tracker', tableName: 'tracker', db: TrackerDB)
@Freezed()
abstract class Tracker with _$Tracker {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Tracker({
    required String name,
    required String description,
    required String category,
    required String type,
    required TrackerConfig config,
  }) = _Tracker;

  factory Tracker.fromJson(Map<String, dynamic> json) => _$TrackerFromJson(json);
}

@Freezed(unionKey: 'type')
sealed class TrackerConfig with _$TrackerConfig {
  // Event (周期性事件/习惯)
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TrackerConfig.event({
    int? periodDays, // 每 X 天
    required String detailUnit, // duration / number / boolean
  }) = EventTrackerConfig;

  // Milestone (阶段性目标)
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TrackerConfig.milestone({
    required String goalType, // 'time' / 'number' / 'boolean'
    required String targetValue, // 统一存为 String，例如 "3600", "50.0", "true"
  }) = MilestoneTrackerConfig;

  // Anniversary (时间节点)
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TrackerConfig.anniversary({
    required DateTime baseDate,
    required bool isLunar,
    required String remindType, // per_year / per_100_days / t_minus
  }) = AnniversaryTrackerConfig;

  factory TrackerConfig.fromJson(Map<String, dynamic> json) => _$TrackerConfigFromJson(json);
}

@Repository(collectionName: 'tracker', tableName: 'record', db: TrackerDB)
@Freezed()
abstract class TrackerRecord with _$TrackerRecord {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TrackerRecord({
    required String trackerId,
    required DateTime timestamp,
    String? value, // 统一存为 String，例如 "3600", "50.0", "true"
    String? content, // 笔记/感悟
  }) = _TrackerRecord;

  factory TrackerRecord.fromJson(Map<String, dynamic> json) => _$TrackerRecordFromJson(json);
}
