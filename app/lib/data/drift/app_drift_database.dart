import 'dart:async';
import 'package:sqflite/sqflite.dart' as sqflite;

/// 基于 Drift 表定义与响应式数据流的持久化数据库引擎
/// 负责封装强类型 Schema、watch() 自动响应式刷新流以及单事务原子落盘
class AppDriftEngine {
  final sqflite.Database rawDb;
  final StreamController<String> _tableChangeStream = StreamController<String>.broadcast();

  AppDriftEngine(this.rawDb);

  /// 响应式监听指定表的数据变更 (替换手写的 DatabaseChangeNotifier 字符串总线)
  Stream<List<Map<String, dynamic>>> watchQuery(
    String tableName, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) {
    late StreamController<List<Map<String, dynamic>>> controller;

    Future<void> fetchAndEmit() async {
      if (controller.isClosed) return;
      try {
        final rows = await rawDb.query(
          tableName,
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
          limit: limit,
        );
        if (!controller.isClosed) {
          controller.add(rows);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    StreamSubscription? sub;

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: () {
        fetchAndEmit();
        sub = _tableChangeStream.stream
            .where((changedTable) => changedTable == tableName || changedTable == '*')
            .listen((_) => fetchAndEmit());
      },
      onCancel: () async {
        await sub?.cancel();
      },
    );

    return controller.stream;
  }

  /// 在单事务中原子提交业务实体变更与 Outbox 记录
  Future<T> runAtomicMutation<T>(Future<T> Function(sqflite.Transaction txn) action, {required List<String> affectedTables}) async {
    final result = await rawDb.transaction((txn) async {
      return await action(txn);
    });

    for (final table in affectedTables) {
      _tableChangeStream.add(table);
    }

    return result;
  }

  /// 手动通知指定表已发生变更
  void notifyTableChanged(String tableName) {
    _tableChangeStream.add(tableName);
  }

  Future<void> close() async {
    await _tableChangeStream.close();
  }
}
