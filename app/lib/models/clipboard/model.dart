import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sync_annotation/sync_annotation.dart';
import 'package:xbb/models/clipboard/db.dart';

part 'model.g.dart';
part 'model.freezed.dart';

@Repository(
  collectionName: 'clipboard_history',
  tableName: 'clipboard_history_entry',
  db: ClipboardDB,
  toSyncJsonMethod: 'toSyncJson',
  fromRemoteJsonFactory: 'fromRemoteJson',
)
@freezed
abstract class ClipboardHistoryEntry with _$ClipboardHistoryEntry {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory ClipboardHistoryEntry({
    required String data,
    DateTime? capturedAt,
    @Default(true) bool localOnly,
  }) = _ClipboardHistoryEntry;

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
    return <String, dynamic>{
      'data': data,
      if (capturedAt != null) 'captured_at': capturedAt!.toUtc().toIso8601String(),
    };
  }
}
