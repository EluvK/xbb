import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sync_annotation/sync_annotation.dart';
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
  @JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
  const factory TrackerConfig.event({
    required int periodDays,
  }) = EventTrackerConfig;

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TrackerConfig.milestone({
    required String goalType,
    required String targetValue,
    @Default('accumulate') String progressMode,
  }) = MilestoneTrackerConfig;

  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TrackerConfig.anniversary({
    required DateTime baseDate,
    required bool isLunar,
    required String remindType,
  }) = AnniversaryTrackerConfig;

  factory TrackerConfig.fromJson(Map<String, dynamic> json) => _$TrackerConfigFromJson(json);
}

@Repository(collectionName: 'tracker', tableName: 'tracker_record', db: TrackerDB)
@Freezed()
abstract class TrackerRecord with _$TrackerRecord {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory TrackerRecord({
    required String trackerId,
    required DateTime timestamp,
    String? value,
    String? content,
  }) = _TrackerRecord;

  factory TrackerRecord.fromJson(Map<String, dynamic> json) => _$TrackerRecordFromJson(json);
}
