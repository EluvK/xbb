import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/models/task/model.dart';

class ViewTaskOverview extends StatefulWidget {
  const ViewTaskOverview({super.key});

  @override
  State<ViewTaskOverview> createState() => _ViewTaskOverviewState();
}

class _ViewTaskOverviewState extends State<ViewTaskOverview> {
  static const String _overviewFilterKey = 'view-task-overview-all';

  CheckListController? _checkListController;
  RxList<CheckListDataItem>? _allCheckListsRx;
  Worker? _checkListWorker;
  bool _isInitializing = true;
  int _totalCount = 0;
  int _doneCount = 0;

  int get _todoCount => _totalCount - _doneCount;
  double get _doneRatio => _totalCount == 0 ? 0.0 : _doneCount / _totalCount;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (!Get.isRegistered<CheckListController>()) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
      return;
    }

    _checkListController = Get.find<CheckListController>();
    await _checkListController!.ensureInitialization();
    _allCheckListsRx = _checkListController!.registerFilterSubscription(filterKey: _overviewFilterKey);
    _checkListWorker = ever<List<CheckListDataItem>>(_allCheckListsRx!, (_) {
      _refreshStats();
    });
    _refreshStats();

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _refreshStats() {
    final controller = _checkListController;
    if (controller == null) return;

    final allItems =
        _allCheckListsRx?.toList(growable: false) ?? controller.getCheckListDetails(selector: (item) => item);
    final activeCandidates = allItems.where((item) => item.body.archived == false).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final (total, done) = switch (activeCandidates) {
      [] => (0, 0),
      _ => () {
        final tasks = decodeTaskItems(activeCandidates.first.body.tasks);
        return (tasks.length, tasks.where((task) => task.done).length);
      }(),
    };

    if (!mounted) return;
    setState(() {
      _totalCount = total;
      _doneCount = done;
    });
  }

  @override
  void dispose() {
    _checkListWorker?.dispose();
    _checkListController?.unregisterFilterSubscription(_overviewFilterKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    final donePercentText = '${(_doneRatio * 100).toStringAsFixed(0)}%';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('task_overview_title'.tr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text('task_overview_subtitle'.tr),
                const SizedBox(height: 14),
                LinearProgressIndicator(value: _doneRatio),
                const SizedBox(height: 8),
                Text('task_overview_done_ratio'.trParams({'percent': donePercentText})),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(label: 'task_overview_total'.tr, value: _totalCount),
                    _StatChip(label: 'task_overview_done'.tr, value: _doneCount),
                    _StatChip(label: 'task_overview_todo'.tr, value: _todoCount),
                  ],
                ),
                if (_totalCount == 0)
                  Padding(padding: const EdgeInsets.only(top: 12), child: Text('task_overview_empty'.tr)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 8),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
