import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/task/model.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/task/task_history_view.dart';
import 'package:xbb/presentation/task/task_overview_card.dart';
import 'package:xbb/presentation/task/task_providers.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

class ModernTaskView extends ConsumerStatefulWidget {
  const ModernTaskView({super.key});

  @override
  ConsumerState<ModernTaskView> createState() => _ModernTaskViewState();
}

class _ModernTaskViewState extends ConsumerState<ModernTaskView> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showArchived = false;
  bool _showDetails = false;
  bool _isOverviewCollapsed = false;

  // 任务原位就地编辑与防失焦锁定状态
  String? _editingTaskId;
  List<String>? _frozenOrderIds;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitNewTask() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final userId = ref.read(authProvider).userId;
    ref.read(taskRepositoryProvider).addTask(text, userId);
    _textController.clear();
    _focusNode.requestFocus();
  }

  /// 进入编辑态，冻结当前任务项渲染顺序，防止排序重排导致输入跳动与失焦
  void _startEditing(TaskItem task, List<TaskItem> currentOrderedList) {
    setState(() {
      _editingTaskId = task.id;
      _frozenOrderIds = currentOrderedList.map((t) => t.id).toList();
    });
  }

  /// 取消就地编辑
  void _cancelEditing() {
    setState(() {
      _editingTaskId = null;
      _frozenOrderIds = null;
    });
  }

  /// 提交并保存就地编辑
  void _submitEditing(String taskId, String newContent, String userId) {
    final trimmed = newContent.trim();
    if (trimmed.isNotEmpty) {
      ref.read(taskRepositoryProvider).updateTaskContent(taskId, trimmed, userId);
    }
    setState(() {
      _editingTaskId = null;
      _frozenOrderIds = null;
    });
  }

  /// 获取当前显示的有序任务列表（若处于编辑态，则使用冻结的 ID 顺序）
  List<TaskItem> _getOrderedTasks(List<TaskItem> tasks) {
    final frozenIds = _frozenOrderIds;
    if (_editingTaskId == null || frozenIds == null) {
      return tasks;
    }
    final byId = {for (final t in tasks) t.id: t};
    final ordered = <TaskItem>[];
    for (final id in frozenIds) {
      final t = byId.remove(id);
      if (t != null) {
        ordered.add(t);
      }
    }
    // 若有后台新流入的任务项，追加至末尾
    if (byId.isNotEmpty) {
      ordered.addAll(byId.values);
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = ref.watch(activeTaskItemsProvider);
    final orderedTasks = _getOrderedTasks(tasks);
    final userId = ref.watch(authProvider).userId;

    final doneCount = tasks.where((t) => t.done).length;
    final totalCount = tasks.length;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _showArchived ? '已归档清单' : '待办事项',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: _showArchived ? '查看进行中' : '查看归档历史',
            icon: Icon(_showArchived ? Icons.checklist_rounded : Icons.archive_outlined),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
          if (!_showArchived)
            IconButton(
              tooltip: _showDetails ? '隐藏任务详情' : '显示任务详情',
              icon: Icon(_showDetails ? Icons.visibility_rounded : Icons.visibility_outlined),
              onPressed: () => setState(() => _showDetails = !_showDetails),
            ),
          if (!_showArchived && doneCount > 0)
            IconButton(
              tooltip: '归档已完成任务',
              icon: const Icon(Icons.archive),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('归档任务清单'),
                    content: Text('确认将当前已完成的 $doneCount 项任务归档吗？未完成任务将保留至新清单。'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                      FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('归档')),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(taskRepositoryProvider).archiveActiveCheckList(userId);
                }
              },
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: _showArchived
          ? const TaskHistoryView()
          : Column(
              children: [
                // 顶部输入条与快速添加
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          onSubmitted: (_) => _submitNewTask(),
                          decoration: InputDecoration(
                            hintText: '添加新任务，按回车快速保存...',
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerLow,
                            prefixIcon: const Icon(Icons.add_circle_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                              onPressed: _submitNewTask,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.roundedMd,
                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(60)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.roundedMd,
                              borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(60)),
                            ),
                          ),
                        ),
                      ),
                      if (totalCount > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        ModernBadge(
                          label: '$doneCount / $totalCount',
                          color: doneCount == totalCount ? Colors.green : theme.colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
                // 活跃任务概览统计卡片
                if (totalCount > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: TaskOverviewCard(
                      totalCount: totalCount,
                      doneCount: doneCount,
                      isCollapsed: _isOverviewCollapsed,
                      onToggleCollapse: () => setState(() => _isOverviewCollapsed = !_isOverviewCollapsed),
                    ),
                  ),
                // 任务列表
                Expanded(
                  child: orderedTasks.isEmpty
                      ? const ModernEmptyState(
                          icon: Icons.checklist_rounded,
                          title: '没有待办任务',
                          subtitle: '在上方输入框添加新任务，保持专注与高效',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: orderedTasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, index) {
                            final task = orderedTasks[index];
                            final isEditing = _editingTaskId == task.id;
                            return InlineTaskTile(
                              key: ValueKey('task-${task.id}'),
                              task: task,
                              isEditing: isEditing,
                              onTapEdit: () => _startEditing(task, orderedTasks),
                              onSubmitted: (newContent) => _submitEditing(task.id, newContent, userId),
                              onCancel: _cancelEditing,
                              onToggleDone: (val) {
                                ref.read(taskRepositoryProvider).toggleTaskDone(task.id, userId);
                              },
                              onDelete: () {
                                if (_editingTaskId == task.id) {
                                  _cancelEditing();
                                }
                                ref.read(taskRepositoryProvider).deleteTask(task.id, userId);
                              },
                              showDetails: _showDetails,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

/// 支持原位就地编辑与展示双状态的任务项组件
class InlineTaskTile extends StatefulWidget {
  final TaskItem task;
  final bool isEditing;
  final VoidCallback onTapEdit;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCancel;
  final ValueChanged<bool> onToggleDone;
  final VoidCallback onDelete;
  final bool showDetails;

  const InlineTaskTile({
    super.key,
    required this.task,
    required this.isEditing,
    required this.onTapEdit,
    required this.onSubmitted,
    required this.onCancel,
    required this.onToggleDone,
    required this.onDelete,
    this.showDetails = false,
  });

  @override
  State<InlineTaskTile> createState() => _InlineTaskTileState();
}

class _InlineTaskTileState extends State<InlineTaskTile> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.content);
    _focusNode = FocusNode();
    if (widget.isEditing) {
      _requestEditFocus();
    }
  }

  @override
  void didUpdateWidget(covariant InlineTaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isEditing && oldWidget.isEditing) {
      _controller.text = widget.task.content;
    } else if (widget.isEditing && !oldWidget.isEditing) {
      _controller.text = widget.task.content;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      _requestEditFocus();
    } else if (widget.task.content != oldWidget.task.content && !widget.isEditing) {
      _controller.text = widget.task.content;
    }
  }

  void _requestEditFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSave() {
    widget.onSubmitted(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: widget.task.done,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: widget.isEditing
                    ? null
                    : (val) => widget.onToggleDone(val ?? false),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: widget.isEditing
                    ? Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                            widget.onCancel();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onSubmitted: (_) => _handleSave(),
                          onTapOutside: (_) => _handleSave(),
                          autofocus: true,
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: '任务内容...',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.roundedSm,
                              borderSide: BorderSide(color: theme.colorScheme.primary),
                            ),
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: widget.onTapEdit,
                        borderRadius: AppRadius.roundedSm,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            widget.task.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              decoration: widget.task.done ? TextDecoration.lineThrough : null,
                              color: widget.task.done
                                  ? theme.colorScheme.onSurfaceVariant.withAlpha(120)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
              ),
              if (widget.isEditing) ...[
                IconButton(
                  tooltip: '保存',
                  icon: const Icon(Icons.check, size: 18, color: Colors.green),
                  onPressed: _handleSave,
                ),
                IconButton(
                  tooltip: '取消',
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: widget.onCancel,
                ),
              ] else ...[
                IconButton(
                  tooltip: '修改任务',
                  icon: Icon(Icons.edit_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant.withAlpha(120)),
                  onPressed: widget.onTapEdit,
                ),
                IconButton(
                  tooltip: '删除任务',
                  icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error.withAlpha(160)),
                  onPressed: widget.onDelete,
                ),
              ],
            ],
          ),
          if (widget.showDetails)
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 4, bottom: 2),
              child: _TaskDetailBlock(task: widget.task),
            ),
        ],
      ),
    );
  }
}

class _TaskDetailBlock extends StatelessWidget {
  final TaskItem task;

  const _TaskDetailBlock({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
    );
    final doneAtStr = task.doneAt?.toLocal().toString().split('.').first ?? '未完成';
    final modAtStr = task.lastModifiedAt.toLocal().toString().split('.').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ID: ${task.id} (序号: ${task.sortOrder})', style: textStyle),
        Text('完成时间: $doneAtStr', style: textStyle),
        Text('更新时间: $modAtStr', style: textStyle),
      ],
    );
  }
}
