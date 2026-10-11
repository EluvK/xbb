import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/presentation/clipboard/clipboard_batch_action_bar.dart';
import 'package:xbb/presentation/clipboard/clipboard_date_group_view.dart';
import 'package:xbb/presentation/clipboard/clipboard_overview_card.dart';
import 'package:xbb/presentation/clipboard/clipboard_providers.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';
import 'package:xbb/utils/translation.dart';

class ModernClipboardView extends ConsumerWidget {
  const ModernClipboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groups = ref.watch(groupedClipboardEntriesProvider);
    final collapsedDates = ref.watch(collapsedClipboardDatesProvider);
    final entriesAsync = ref.watch(clipboardEntriesStreamProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'clipboard_appbar_title'.tr,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'clipboard_clear_tooltip'.tr,
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('clipboard_clear_dialog_title'.tr),
                  content: Text('clipboard_clear_dialog_content'.tr),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('clipboard_clear_btn'.tr)),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(clipboardRepositoryProvider).clearAll();
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          // 搜索过滤栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: ModernSearchField(
              hintText: 'clipboard_search_hint'.tr,
              onChanged: (v) => ref.read(clipboardSearchQueryProvider.notifier).state = v,
            ),
          ),
          // 概览统计卡片
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: ClipboardOverviewCard(),
          ),
          // 列表内容（按日期分组并支持折叠/展开）
          Expanded(
            child: entriesAsync.isLoading
                ? const Center(child: CircularProgressIndicator())
                : groups.isEmpty
                    ? ModernEmptyState(
                        icon: Icons.content_paste_off_rounded,
                        title: 'clipboard_empty_title'.tr,
                        subtitle: 'clipboard_empty_desc'.tr,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          final isCollapsed = collapsedDates.contains(group.dateKey);
                          return ClipboardDateGroupView(
                            group: group,
                            isCollapsed: isCollapsed,
                          );
                        },
                      ),
          ),
          const ClipboardBatchActionBar(),
        ],
      ),
    );
  }
}
