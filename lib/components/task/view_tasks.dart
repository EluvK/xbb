import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart' show SyncStatus;
import 'package:uuid/uuid.dart';
import 'package:xbb/controller/task_widget.dart';
import 'package:xbb/models/task/model.dart';
import 'package:xbb/utils/utils.dart';

class ViewTasks extends StatefulWidget {
  const ViewTasks({super.key});

  @override
  State<ViewTasks> createState() => _ViewTasksState();
}

class _ViewTasksState extends State<ViewTasks> {
  static const Uuid _uuid = Uuid();
  static const String _allTasksFilterKey = 'view-tasks-all';

  bool _showDetails = false;
  bool _collapseArchived = false;
  bool _isInitializing = true;
  bool _isSaving = false;
  bool _isPersisting = false;
  int _archivedLoadCount = 0;
  bool _hasMoreArchived = false;
  static const int _archivedPageSizeDesktop = 1;
  static const int _archivedPageSizeMobile = 0;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode();
  CheckListController? _checkListController;
  RxList<CheckListDataItem>? _allCheckListsRx;
  Worker? _checkListWorker;
  late CheckList _activeCheckList;
  List<CheckListDataItem> _allArchived = <CheckListDataItem>[];
  final List<CheckListDataItem> _archivedSegments = <CheckListDataItem>[];
  List<TaskItem>? _pendingSaveTasks;
  List<TaskItem>? _debounceQueuedTasks;
  Timer? _debounceSaveTimer;
  Timer? _debounceArchiveTimer;
  final Set<String> _draftTaskIds = <String>{};
  String? _editingTaskId;
  List<String>? _editingOrderIds;
  String? _editingInitialContent;

  @override
  void initState() {
    super.initState();
    _activeCheckList = const CheckList(tasks: '[]', archived: false, archivedAt: null);
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
    _allCheckListsRx = _checkListController!.registerFilterSubscription(filterKey: _allTasksFilterKey);
    _checkListWorker = ever<List<CheckListDataItem>>(_allCheckListsRx!, (_) {
      _reloadFromController(ensureActive: false);
    });
    await _reloadFromController(ensureActive: false);

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _debounceSaveTimer?.cancel();
    _debounceArchiveTimer?.cancel();
    _checkListWorker?.dispose();
    _checkListController?.unregisterFilterSubscription(_allTasksFilterKey);
    _scrollController.dispose();
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  // Avoid resorting while editing to prevent cursor/focus interruption.
  List<TaskItem> get _activeTasks {
    final tasks = decodeTaskItems(_activeCheckList.tasks);
    final sorted = sortTaskItems(tasks);

    final frozenOrderIds = _editingOrderIds;
    if (_editingTaskId == null || frozenOrderIds == null) {
      return sorted;
    }

    final byId = {for (final task in sorted) task.id: task};
    final frozen = <TaskItem>[];
    for (final id in frozenOrderIds) {
      final task = byId.remove(id);
      if (task != null) {
        frozen.add(task);
      }
    }

    if (byId.isNotEmpty) {
      frozen.addAll(byId.values);
    }
    return frozen;
  }

  bool get _hasActiveTasks => _activeTasks.isNotEmpty;

  List<TaskItem> _normalizeSortOrder(List<TaskItem> tasks) {
    return [for (var i = 0; i < tasks.length; i++) tasks[i].copyWith(sortOrder: i)];
  }

  Future<void> _reloadFromController({required bool ensureActive}) async {
    final controller = _checkListController;
    if (controller == null) return;

    final allItems =
        _allCheckListsRx?.toList(growable: false) ?? controller.getCheckListDetails(selector: (item) => item);
    var activeCandidates = allItems.where((item) => item.body.archived == false).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final archivedCandidates = allItems.where((item) => item.body.archived).toList()
      ..sort(
        (a, b) => (a.body.archivedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          b.body.archivedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );

    if (mounted) {
      setState(() {
        _allArchived = archivedCandidates;
        _refreshArchivedWindow();
        if (activeCandidates.isNotEmpty) {
          final activeItem = activeCandidates.first;
          _activeCheckList = activeItem.body;
          _isSaving = _isPersisting || activeItem.syncStatus == SyncStatus.syncing;
        } else {
          _activeCheckList = const CheckList(tasks: '[]', archived: false, archivedAt: null);
          _isSaving = _isPersisting;
        }
      });
    }
  }

  void _refreshArchivedWindow() {
    final pageSize = isMobile() ? _archivedPageSizeMobile : _archivedPageSizeDesktop;
    final defaultLoaded = _allArchived.isNotEmpty ? pageSize : 0;
    final loadedCount = (defaultLoaded + (_archivedLoadCount * _archivedPageSizeDesktop)).clamp(0, _allArchived.length);
    final startIndex = (_allArchived.length - loadedCount).clamp(0, _allArchived.length);
    _archivedSegments
      ..clear()
      ..addAll(_allArchived.skip(startIndex));
    _hasMoreArchived = loadedCount < _allArchived.length;
  }

  Future<void> _updateActiveTasks(List<TaskItem> tasks) async {
    final controller = _checkListController;
    if (controller == null) return;

    final active = await _resolveActiveCheckList(createIfMissing: false);
    if (active == null) return;

    final updated = active.body.copyWith(tasks: encodeTaskItems(tasks));
    if (mounted) {
      setState(() {
        _activeCheckList = updated;
      });
    }
    try {
      controller.updateData(active.id, updated);
      TaskWidgetBridge.scheduleRefresh();
    } catch (_) {
      // A just-created local id may be swapped by server; refresh and retry once.
      await _reloadFromController(ensureActive: true);
      final retryActive = await _resolveActiveCheckList(createIfMissing: false);
      if (retryActive == null) return;
      controller.updateData(retryActive.id, retryActive.body.copyWith(tasks: encodeTaskItems(tasks)));
      TaskWidgetBridge.scheduleRefresh();
    }
  }

  Future<void> _persistActiveTasksSerial(List<TaskItem> tasks) async {
    if (_isPersisting) {
      _pendingSaveTasks = tasks;
      return;
    }

    _isPersisting = true;
    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    } else {
      _isSaving = true;
    }
    try {
      await _updateActiveTasks(tasks);
    } finally {
      _isPersisting = false;
    }

    if (_pendingSaveTasks != null) {
      final next = _pendingSaveTasks!;
      _pendingSaveTasks = null;
      await _persistActiveTasksSerial(next);
    }
  }

  void _schedulePersistActiveTasks(List<TaskItem> tasks, {Duration delay = const Duration(seconds: 1)}) {
    _debounceQueuedTasks = tasks;
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(delay, () async {
      final queued = _debounceQueuedTasks;
      _debounceQueuedTasks = null;
      if (queued == null) return;
      await _persistActiveTasksSerial(queued);
    });
  }

  void _beginEdit(TaskItem item) {
    final snapshotOrder = sortTaskItems(decodeTaskItems(_activeCheckList.tasks)).map((task) => task.id).toList();
    setState(() {
      _editingTaskId = item.id;
      _editingOrderIds = snapshotOrder;
      _editingInitialContent = item.content;
      _editController.text = item.content;
      _editController.selection = TextSelection.fromPosition(TextPosition(offset: _editController.text.length));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _editFocusNode.requestFocus();
      }
    });
  }

  void _applyEditingText(String value) {
    final editingId = _editingTaskId;
    if (editingId == null) return;

    final tasks = List<TaskItem>.of(_activeTasks);
    final index = tasks.indexWhere((task) => task.id == editingId);
    if (index < 0) return;

    tasks[index] = tasks[index].copyWith(content: value);
    setState(() {
      _activeCheckList = _activeCheckList.copyWith(tasks: encodeTaskItems(tasks));
    });
  }

  Future<void> _finishEdit() async {
    final editingId = _editingTaskId;
    if (editingId == null) return;

    final tasks = List<TaskItem>.of(_activeTasks);
    final index = tasks.indexWhere((task) => task.id == editingId);
    if (index >= 0) {
      final nextContent = tasks[index].content;
      final prevContent = _editingInitialContent ?? '';
      final isDraft = _draftTaskIds.contains(editingId);
      if (isDraft && nextContent.trim().isEmpty) {
        tasks.removeAt(index);
        _draftTaskIds.remove(editingId);
        if (mounted) {
          setState(() {
            _activeCheckList = _activeCheckList.copyWith(tasks: encodeTaskItems(tasks));
          });
        }
      } else if (nextContent != prevContent) {
        tasks[index] = tasks[index].copyWith(lastModifiedAt: DateTime.now());
        await _persistActiveTasksSerial(tasks);
        _draftTaskIds.remove(editingId);
      }
    }

    if (!mounted) return;
    setState(() {
      _editingTaskId = null;
      _editingOrderIds = null;
      _editingInitialContent = null;
    });
  }

  Future<void> _toggleTaskDone(int index, bool nextDone) async {
    final tasks = List<TaskItem>.of(_activeTasks);
    final item = tasks[index];
    final now = DateTime.now();
    tasks[index] = item.copyWith(done: nextDone, doneAt: nextDone ? now : null, lastModifiedAt: now);
    if (mounted) {
      setState(() {
        _activeCheckList = _activeCheckList.copyWith(tasks: encodeTaskItems(tasks));
      });
    }
    _schedulePersistActiveTasks(tasks);
  }

  Future<void> _reorderActiveTasks(int oldIndex, int newIndex) async {
    final tasks = List<TaskItem>.of(_activeTasks);
    if (oldIndex < 0 || oldIndex >= tasks.length) return;

    var targetIndex = newIndex;
    if (targetIndex > oldIndex) {
      targetIndex -= 1;
    }
    if (targetIndex < 0 || targetIndex >= tasks.length) return;

    final moved = tasks.removeAt(oldIndex);
    tasks.insert(targetIndex, moved);
    final reordered = _normalizeSortOrder(tasks);

    if (mounted) {
      setState(() {
        _activeCheckList = _activeCheckList.copyWith(tasks: encodeTaskItems(reordered));
      });
    }
    _schedulePersistActiveTasks(reordered, delay: const Duration(milliseconds: 300));
  }

  Future<void> _addTask() async {
    final active = await _resolveActiveCheckList(createIfMissing: true);
    if (active == null) return;

    final tasks = List<TaskItem>.of(_activeTasks);
    final now = DateTime.now();
    final newId = _uuid.v4();
    final nextSortOrder = tasks.isEmpty
        ? 0
        : tasks.map((task) => task.sortOrder).reduce((left, right) => left > right ? left : right) + 1;
    final created = TaskItem(id: newId, content: '', done: false, lastModifiedAt: now, sortOrder: nextSortOrder);
    tasks.add(created);
    _draftTaskIds.add(newId);
    if (mounted) {
      setState(() {
        _activeCheckList = _activeCheckList.copyWith(tasks: encodeTaskItems(tasks));
      });
    }
    _beginEdit(created);
  }

  Future<void> _archiveCurrentTasks() async {
    final controller = _checkListController;
    if (controller == null) return;
    if (!_hasActiveTasks) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('task_no_archivable_items'.tr)));
      return;
    }

    final active = await _resolveActiveCheckList(createIfMissing: false);
    if (active == null) return;
    final archivedAt = DateTime.now();

    _debounceArchiveTimer?.cancel();
    _debounceArchiveTimer = Timer(const Duration(seconds: 1), () {
      controller.updateData(active.id, active.body.copyWith(archived: true, archivedAt: archivedAt));
      controller.addData(const CheckList(tasks: '[]', archived: false, archivedAt: null));
      TaskWidgetBridge.scheduleRefresh();
      if (mounted) {
        setState(() {
          _archivedLoadCount = 0;
        });
      }
    });
  }

  Future<bool> _confirmAction({required String titleKey, required String contentKey}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titleKey.tr),
          content: Text(contentKey.tr),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('cancel'.tr)),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text('confirm'.tr)),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> _confirmAndArchiveWorkspace() async {
    final confirmed = await _confirmAction(
      titleKey: 'task_confirm_archive_title',
      contentKey: 'task_confirm_archive_content',
    );
    if (!confirmed) return;
    await _archiveCurrentTasks();
  }

  Future<void> _confirmAndDeleteTask(int index) async {
    final tasks = List<TaskItem>.of(_activeTasks);
    if (index < 0 || index >= tasks.length) return;
    final confirmed = await _confirmAction(
      titleKey: 'task_confirm_delete_title',
      contentKey: 'task_confirm_delete_content',
    );
    if (!confirmed) return;

    final deletingId = tasks[index].id;
    tasks.removeAt(index);
    _draftTaskIds.remove(deletingId);
    if (_editingTaskId == deletingId) {
      _editingTaskId = null;
      _editingOrderIds = null;
      _editingInitialContent = null;
      _editController.clear();
    }
    if (mounted) {
      setState(() {
        _activeCheckList = _activeCheckList.copyWith(tasks: encodeTaskItems(tasks));
      });
    }
    _schedulePersistActiveTasks(tasks);
  }

  Future<void> _confirmAndDeleteArchivedSegment(CheckListDataItem archivedItem) async {
    final confirmed = await _confirmAction(
      titleKey: 'task_confirm_delete_history_title',
      contentKey: 'task_confirm_delete_history_content',
    );
    if (!confirmed) return;

    final controller = _checkListController;
    if (controller == null) return;
    controller.deleteData(archivedItem.id, deleteFromServer: true);
  }

  Future<CheckListDataItem?> _resolveActiveCheckList({required bool createIfMissing}) async {
    final controller = _checkListController;
    if (controller == null) return null;

    var active =
        controller.getCheckListDetails(selector: (item) => item).where((item) => item.body.archived == false).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (active.isEmpty && createIfMissing) {
      controller.addData(const CheckList(tasks: '[]', archived: false, archivedAt: null));
      TaskWidgetBridge.scheduleRefresh();
      active =
          controller.getCheckListDetails(selector: (item) => item).where((item) => item.body.archived == false).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    if (active.isEmpty) return null;

    _activeCheckList = active.first.body;
    return active.first;
  }

  Future<void> _loadMoreArchived() async {
    if (!_hasMoreArchived) return;
    // Local-only pagination window: this does not fetch from network.
    setState(() {
      _collapseArchived = false;
      _archivedLoadCount += 1;
      _refreshArchivedWindow();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    final archivedSorted = List<CheckListDataItem>.of(_archivedSegments)
      ..sort(
        (a, b) => (a.body.archivedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          b.body.archivedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
    final showHistoryEntryLabel = isMobile() && archivedSorted.isEmpty && _allArchived.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            children: [
              if (_allArchived.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text('task_section_history'.tr, style: Theme.of(context).textTheme.titleSmall),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _hasMoreArchived ? _loadMoreArchived : null,
                        icon: const Icon(Icons.unfold_more, size: 16),
                        label: Text(
                          _hasMoreArchived
                              ? (showHistoryEntryLabel
                                    ? 'task_action_show_history'.tr
                                    : 'task_action_load_more_history'.tr)
                              : 'task_action_history_loaded_all'.tr,
                        ),
                      ),
                    ],
                  ),
                ),
              if (!_collapseArchived)
                ...archivedSorted.map(
                  (segmentItem) => _ArchivedSegmentCard(
                    segment: segmentItem.body,
                    showDetails: _showDetails,
                    onDelete: () => _confirmAndDeleteArchivedSegment(segmentItem),
                  ),
                ),
              // if (_collapseArchived && archivedSorted.isNotEmpty)
              //   const Padding(
              //     padding: EdgeInsets.symmetric(vertical: 6),
              //     child: Text('Archived 已收起'),
              //   ),
              const SizedBox(height: 8),
              _TaskSectionDivider(
                showArchivedToggle: _allArchived.isNotEmpty,
                collapsed: _collapseArchived,
                onToggleArchived: () {
                  setState(() {
                    _collapseArchived = !_collapseArchived;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 8),
                child: Row(
                  children: [
                    Text('task_section_workspace'.tr, style: Theme.of(context).textTheme.titleSmall),
                    if (_isSaving)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(
                          children: [
                            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: 6),
                            Text('task_saving'.tr, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_activeTasks.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text('task_empty_workspace_hint'.tr),
                        ),
                      if (_activeTasks.isNotEmpty)
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: _activeTasks.length,
                          onReorder: _reorderActiveTasks,
                          itemBuilder: (context, index) {
                            final task = _activeTasks[index];
                            return _ActiveTaskRow(
                              key: ValueKey('active-task-${task.id}'),
                              item: task,
                              showDetails: _showDetails,
                              isEditing: _editingTaskId == task.id,
                              editController: _editController,
                              editFocusNode: _editFocusNode,
                              onTapEdit: () => _beginEdit(task),
                              onToggleDone: (nextDone) => _toggleTaskDone(index, nextDone),
                              onDelete: () => _confirmAndDeleteTask(index),
                              onChanged: _applyEditingText,
                              onSubmit: _finishEdit,
                              dragHandle: ReorderableDelayedDragStartListener(
                                index: index,
                                child: Icon(
                                  Icons.drag_indicator,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _hasActiveTasks ? () => _confirmAndArchiveWorkspace() : null,
                  icon: const Icon(Icons.archive_outlined),
                  label: Text('task_action_archive_workspace'.tr),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      _showDetails = !_showDetails;
                    });
                  },
                  child: Text(_showDetails ? 'task_action_hide_details'.tr : 'task_action_show_details'.tr),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => _addTask(),
                  icon: const Icon(Icons.add),
                  label: Text('task_action_add'.tr),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskSectionDivider extends StatelessWidget {
  const _TaskSectionDivider({
    required this.showArchivedToggle,
    required this.collapsed,
    required this.onToggleArchived,
  });

  final bool showArchivedToggle;
  final bool collapsed;
  final VoidCallback onToggleArchived;

  @override
  Widget build(BuildContext context) {
    if (!showArchivedToggle) {
      return const Divider(height: 24);
    }

    final label = collapsed ? 'task_expand_archived'.tr : 'task_collapse_archived'.tr;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Expanded(child: Divider(height: 24)),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              minimumSize: const Size(10, 24),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onToggleArchived,
            child: Text(label),
          ),
          const Expanded(child: Divider(height: 24)),
        ],
      ),
    );
  }
}

class _ArchivedSegmentCard extends StatelessWidget {
  const _ArchivedSegmentCard({required this.segment, required this.showDetails, required this.onDelete});

  final CheckList segment;
  final bool showDetails;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tasks = sortTaskItems(decodeTaskItems(segment.tasks));
    final archivedLabel = segment.archivedAt == null ? 'task_time_unknown'.tr : readableDateStr(segment.archivedAt!);
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(archivedLabel, style: Theme.of(context).textTheme.labelMedium)),
                IconButton(
                  tooltip: 'task_delete_history'.tr,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (tasks.isEmpty) Text('task_empty_history_segment'.tr),
            ...tasks.map(
              (item) => _ActiveTaskRow(
                key: ValueKey('archived-task-${item.id}'),
                item: item,
                showDetails: showDetails,
                readOnly: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTaskRow extends StatelessWidget {
  const _ActiveTaskRow({
    super.key,
    required this.item,
    required this.showDetails,
    this.readOnly = false,
    this.isEditing = false,
    this.editController,
    this.editFocusNode,
    this.onTapEdit,
    this.onToggleDone,
    this.onDelete,
    this.onChanged,
    this.onSubmit,
    this.dragHandle,
  });

  final TaskItem item;
  final bool showDetails;
  final bool readOnly;
  final bool isEditing;
  final TextEditingController? editController;
  final FocusNode? editFocusNode;
  final VoidCallback? onTapEdit;
  final ValueChanged<bool>? onToggleDone;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onChanged;
  final Future<void> Function()? onSubmit;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final isCompactLayout = isMobile();
    final isDesktopPlatform = !GetPlatform.isMobile;
    final statusLabel = item.done ? 'task_status_done'.tr : 'task_status_todo'.tr;
    final statusBackground = item.done
        ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.55)
        : Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.55);
    final rowDecoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest.withValues(alpha: 0.14),
      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.24)),
      borderRadius: BorderRadius.circular(10),
    );

    final editor = Focus(
      onKeyEvent: (node, event) {
        if (!isDesktopPlatform || event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.enter && HardwareKeyboard.instance.isShiftPressed) {
          onSubmit?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: editController,
        focusNode: editFocusNode,
        onChanged: onChanged,
        onTapOutside: (_) => onSubmit?.call(),
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        minLines: 1,
        maxLines: null,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
    );

    final canEdit = !readOnly && isEditing && editController != null && editFocusNode != null;

    final content = canEdit
        ? editor
        : (readOnly
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    item.content,
                    style: TextStyle(decoration: item.done ? TextDecoration.lineThrough : TextDecoration.none),
                  ),
                )
              : InkWell(
                  onTap: onTapEdit,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text(
                      item.content.isEmpty ? 'task_tap_to_edit_hint'.tr : item.content,
                      style: TextStyle(
                        decoration: item.done ? TextDecoration.lineThrough : TextDecoration.none,
                        color: item.content.isEmpty ? Theme.of(context).hintColor : null,
                      ),
                    ),
                  ),
                ));

    final actionControls = readOnly
        ? Checkbox(value: item.done, onChanged: null)
        : _TaskActionControls(done: item.done, onToggleDone: onToggleDone, dragHandle: dragHandle, onDelete: onDelete);

    final fullWidthContent = SizedBox(width: double.infinity, child: content);

    if (isCompactLayout) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        decoration: rowDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusBackground, borderRadius: BorderRadius.circular(999)),
                  child: Text(statusLabel, style: Theme.of(context).textTheme.labelSmall),
                ),
                const Spacer(),
                actionControls,
              ],
            ),
            fullWidthContent,
            if (showDetails)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _TaskDetailBlock(item: item),
              ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: rowDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 8),
              actionControls,
            ],
          ),
          if (showDetails)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _TaskDetailBlock(item: item),
            ),
        ],
      ),
    );
  }
}

class _TaskActionControls extends StatelessWidget {
  const _TaskActionControls({
    required this.done,
    required this.onToggleDone,
    required this.dragHandle,
    required this.onDelete,
  });

  final bool done;
  final ValueChanged<bool>? onToggleDone;
  final Widget? dragHandle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: done, onChanged: onToggleDone == null ? null : (value) => onToggleDone!(value ?? false)),
        if (dragHandle != null) Padding(padding: const EdgeInsets.only(left: 4), child: dragHandle!),
        if (onDelete != null)
          IconButton(tooltip: 'delete'.tr, onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
      ],
    );
  }
}

class _TaskDetailBlock extends StatelessWidget {
  const _TaskDetailBlock({required this.item});

  final TaskItem item;

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'task_time_empty'.tr;
    return '${readableDateStr(dt)} (${detailedDateStr(dt)})';
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${'task_detail_done_at'.tr}: ${_formatDate(item.doneAt)}', style: textStyle),
          Text('${'task_detail_updated_at'.tr}: ${_formatDate(item.lastModifiedAt)}', style: textStyle),
        ],
      ),
    );
  }
}
