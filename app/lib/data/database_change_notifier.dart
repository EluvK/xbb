import 'dart:async';

/// 统一的本地数据库变更广播总线
class DatabaseChangeNotifier {
  final _controller = StreamController<String>.broadcast();

  /// 广播某张数据表已发生写入/更新/删除
  void notify(String tableName) {
    if (!_controller.isClosed) {
      _controller.add(tableName);
    }
  }

  /// 广播多张表
  void notifyAll(List<String> tableNames) {
    for (final t in tableNames) {
      notify(t);
    }
  }

  /// 监听特定数据表的变更流（附带初始触发事件，确保订阅时立即触发首轮拉取）
  Stream<String> watchTable(String tableName) async* {
    yield tableName;
    yield* _controller.stream.where((table) => table == tableName);
  }

  /// 监听多张数据表中的任何一张变更
  Stream<String> watchTables(List<String> tableNames) async* {
    if (tableNames.isNotEmpty) {
      yield tableNames.first;
    }
    yield* _controller.stream.where((table) => tableNames.contains(table));
  }

  void dispose() {
    _controller.close();
  }
}
