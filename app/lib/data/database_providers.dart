import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:xbb/data/database_change_notifier.dart';

/// 全局本地数据库变更广播总线 Provider
final dbChangeNotifierProvider = Provider<DatabaseChangeNotifier>((ref) {
  final notifier = DatabaseChangeNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

/// 当前活动用户的 SQLite Database 实例 Provider
/// 由应用启动或登录切换时进行动态覆盖/重写
final databaseProvider = Provider<Database>((ref) {
  throw UnimplementedError('databaseProvider must be initialized with an active Database instance');
});
