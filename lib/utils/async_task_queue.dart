import 'dart:async';

typedef TaskExecutor = Future<bool> Function(Map<String, dynamic> metadata);

class AsyncTaskQueue {
  final Map<String, _TaskQueue> _queues = {};

  Future<void> addTask(
      String key, Map<String, dynamic> metadata, TaskExecutor executor) async {
    _queues.putIfAbsent(key, () => _TaskQueue()).addTask(metadata, executor);
  }
}

class _TaskQueue {
  final List<_Task> _tasks = [];
  bool _isProcessing = false;

  void addTask(Map<String, dynamic> metadata, TaskExecutor executor) {
    _tasks.add(_Task(metadata, executor));
    if (!_isProcessing) {
      processNextTask();
    }
  }

  void processNextTask() {
    if (_tasks.isNotEmpty) {
      _isProcessing = true;
      final task = _tasks.first;
      task.executor(task.metadata).then((success) {
        if (success) {
          _tasks.removeAt(0);
          processNextTask();
        } else {
          Future.delayed(const Duration(seconds: 2), () {
            processNextTask();
          });
        }
      });
    } else {
      _isProcessing = false;
    }
  }
}

class _Task {
  final Map<String, dynamic> metadata;
  final TaskExecutor executor;

  _Task(this.metadata, this.executor);
}
