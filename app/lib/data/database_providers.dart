import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:xbb/data/database_change_notifier.dart';

/// 全局本地数据库变更广播总线 Provider
final dbChangeNotifierProvider = Provider<DatabaseChangeNotifier>((ref) {
  final notifier = DatabaseChangeNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

Database? _activeDatabaseInstance;

/// 运行时设置全局活动数据库实例
void setActiveDatabase(Database? db) {
  _activeDatabaseInstance = db;
}

Database? getActiveDatabase() => _activeDatabaseInstance;

/// 动态响应式数据库状态 Provider
final activeDatabaseStateProvider = StateProvider<Database?>((ref) => _activeDatabaseInstance);

/// 当前活动用户的 SQLite Database 实例 Provider
/// 原生支持单测 overrideWithValue，同时在运行时响应 activeDatabaseStateProvider 动态切换
final databaseProvider = Provider<Database>((ref) {
  final dynamicDb = ref.watch(activeDatabaseStateProvider);
  if (dynamicDb != null) {
    return dynamicDb;
  }
  if (_activeDatabaseInstance != null) {
    return _activeDatabaseInstance!;
  }
  throw UnimplementedError('databaseProvider must be initialized with an active Database instance');
});
