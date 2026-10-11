import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/clipboard/model.dart';
import 'package:xbb/presentation/clipboard/clipboard_providers.dart';

class ClipboardBatchActionBar extends ConsumerStatefulWidget {
  const ClipboardBatchActionBar({super.key});

  @override
  ConsumerState<ClipboardBatchActionBar> createState() => _ClipboardBatchActionBarState();
}

class _ClipboardBatchActionBarState extends ConsumerState<ClipboardBatchActionBar> {
  bool _isProcessing = false;

  Future<void> _handleConfirmSync(BuildContext context, List<DataItem<ClipboardHistoryEntry>> selectedItems) async {
    if (_isProcessing || selectedItems.isEmpty) return;

    setState(() => _isProcessing = true);
    final repo = ref.read(clipboardRepositoryProvider);
    final result = await repo.syncSelectedToCloud(selectedItems);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.failedCount > 0) {
      ref.read(selectedClipboardIdsProvider.notifier).setFailedIds(result.failedIds);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已备份上云 ${result.syncedCount} 条，失败 ${result.failedCount} 条，跳过 ${result.skippedCount} 条已同步。失败项已保留。'),
        ),
      );
    } else {
      ref.read(selectedClipboardIdsProvider.notifier).clear();
      final msg = result.syncedCount > 0
          ? '已成功备份上云 ${result.syncedCount} 条${result.skippedCount > 0 ? '（跳过 ${result.skippedCount} 条已同步）' : ''}'
          : '所选 ${result.skippedCount} 条均已是云端同步状态';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _handleDeleteSelected(BuildContext context, List<DataItem<ClipboardHistoryEntry>> selectedItems) async {
    if (_isProcessing || selectedItems.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定删除选中的 ${selectedItems.length} 条剪贴板记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessing = true);
    final repo = ref.read(clipboardRepositoryProvider);
    final result = await repo.deleteSelected(selectedItems);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (result.failedCount > 0) {
      ref.read(selectedClipboardIdsProvider.notifier).setFailedIds(result.failedIds);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 ${result.deletedCount} 条，失败 ${result.failedCount} 条。失败项已保留。')),
      );
    } else {
      ref.read(selectedClipboardIdsProvider.notifier).clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已成功删除 ${result.deletedCount} 条记录')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIds = ref.watch(selectedClipboardIdsProvider);
    if (selectedIds.isEmpty) return const SizedBox.shrink();

    final allEntries = ref.watch(filteredClipboardEntriesProvider);
    final selectedItems = allEntries.where((e) => selectedIds.contains(e.id)).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: AppShadows.subtle(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              '已选择 ${selectedIds.length} 项',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: _isProcessing ? null : () => ref.read(selectedClipboardIdsProvider.notifier).clear(),
              child: const Text('清空选择'),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('批量删除'),
              onPressed: _isProcessing ? null : () => _handleDeleteSelected(context, selectedItems),
            ),
            const SizedBox(width: AppSpacing.xs),
            FilledButton.icon(
              icon: _isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text(_isProcessing ? '同步中...' : '批量备份上云'),
              onPressed: _isProcessing ? null : () => _handleConfirmSync(context, selectedItems),
            ),
          ],
        ),
      ),
    );
  }
}
