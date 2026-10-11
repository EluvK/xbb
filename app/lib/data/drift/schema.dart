import 'package:drift/drift.dart';

/// Drift 强类型数据表通用结构定义 (与 SyncStore 统一数据信封对齐)
abstract class SyncStoreEntityTable extends Table {
  TextColumn get id => text()();
  TextColumn get createdAt => text().named('created_at')();
  TextColumn get updatedAt => text().named('updated_at')();
  TextColumn get owner => text()();
  TextColumn get parentId => text().named('parent_id').nullable()();
  TextColumn get syncStatus => text().named('sync_status')();
  TextColumn get colorTag => text().named('color_tag').withDefault(const Constant('default'))();
  TextColumn get body => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 笔记知识库 - 仓库表
class RepoTable extends SyncStoreEntityTable {
  @override
  String get tableName => 'repo';
}

/// 笔记知识库 - 文章表
class PostTable extends SyncStoreEntityTable {
  @override
  String get tableName => 'post';
}

/// 笔记知识库 - 段落批注讨论表
class CommentTable extends SyncStoreEntityTable {
  @override
  String get tableName => 'comment';
}

/// 待办清单 - 检查单主表
class CheckListTable extends SyncStoreEntityTable {
  @override
  String get tableName => 'checklist';
}

/// 待办清单 - 归档段落表
class ArchivedSegmentTable extends SyncStoreEntityTable {
  @override
  String get tableName => 'archived_segment';
}

/// 习惯打卡 - 主题事件表
class CheckinEventTable extends SyncStoreEntityTable {
  @override
  String get tableName => 'checkin_event';
}

/// 习惯打卡 - 每日完成凭据表
class CheckinRecordTable extends SyncStoreEntityTable {
  @override
  String get tableName => 'checkin_record';
}

/// 目标追踪 - 追踪器配置表
class TrackerTable extends SyncStoreEntityTable {
  @override
  String get tableName => 'tracker';
}

/// 目标追踪 - 时序流水记录表
class TrackerRecordTable extends SyncStoreEntityTable {
  @override
  String get tableName => 'tracker_record';
}

/// 剪贴板 - 本地历史记录表 (ADR-0002 隐私本地存储)
class ClipboardHistoryTable extends SyncStoreEntityTable {
  @override
  String get tableName => 'clipboard_history_entry';
}

/// 通用同步出队日志表 (Outbox)
class OutboxTable extends Table {
  @override
  String get tableName => 'outbox';

  TextColumn get id => text()();
  TextColumn get createdAt => text().named('created_at')();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get opType => text().named('op_type')();
  TextColumn get payload => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().named('retry_count').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
