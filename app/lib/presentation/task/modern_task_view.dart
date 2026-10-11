import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/task/model.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = ref.watch(activeTaskItemsProvider);
    final archivedAsync = ref.watch(archivedCheckListsProvider);
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
          ? _buildArchivedView(archivedAsync)
          : Column(
              children: [
                // 顶部输入条与进度
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
                // 任务列表
                Expanded(
                  child: tasks.isEmpty
                      ? const ModernEmptyState(
                          icon: Icons.checklist_rounded,
                          title: '没有待办任务',
                          subtitle: '在上方输入框添加新任务，保持专注与高效',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: tasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return _buildTaskTile(task, userId);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTaskTile(TaskItem task, String userId) {
    final theme = Theme.of(context);
    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Checkbox(
            value: task.done,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (_) {
              ref.read(taskRepositoryProvider).toggleTaskDone(task.id, userId);
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              task.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: task.done ? TextDecoration.lineThrough : null,
                color: task.done ? theme.colorScheme.onSurfaceVariant.withAlpha(120) : theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error.withAlpha(160)),
            onPressed: () {
              ref.read(taskRepositoryProvider).deleteTask(task.id, userId);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedView(AsyncValue<List<dynamic>> archivedAsync) {
    return archivedAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return const ModernEmptyState(
            icon: Icons.archive_outlined,
            title: '无归档记录',
            subtitle: '当活动清单包含完成任务并点击归档后，将展示在此处',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final item = list[index];
            final tasks = decodeTaskItems(item.body.tasks);
            return ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '归档时间: ${item.body.archivedAt?.toLocal().toString().split('.').first ?? "未知"}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      ModernBadge(label: '${tasks.length} 项任务'),
                    ],
                  ),
                  const Divider(height: 16),
                  for (final t in tasks)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          Icon(t.done ? Icons.check_circle : Icons.circle_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.content,
                              style: TextStyle(
                                decoration: t.done ? TextDecoration.lineThrough : null,
                                color: t.done ? Colors.grey : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败: $e')),
    );
  }
}
