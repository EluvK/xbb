import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/data/repositories/notes_repository.dart';
import 'package:xbb/presentation/widgets/acl_editor.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

/// 笔记本成员协作与分享对话框 (RepoAclDialog)
class RepoAclDialog extends ConsumerStatefulWidget {
  final String repoId;
  final String repoName;
  final String ownerId;

  const RepoAclDialog({
    super.key,
    required this.repoId,
    required this.repoName,
    required this.ownerId,
  });

  /// 便捷静态调用弹窗展示
  static Future<void> show(
    BuildContext context, {
    required String repoId,
    required String repoName,
    required String ownerId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
          child: RepoAclDialog(
            repoId: repoId,
            repoName: repoName,
            ownerId: ownerId,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<RepoAclDialog> createState() => _RepoAclDialogState();
}

class _RepoAclDialogState extends ConsumerState<RepoAclDialog> {
  late final String _shareLink;

  @override
  void initState() {
    super.initState();
    _shareLink = NotesRepository.generateShareLink(widget.ownerId, widget.repoId);
  }

  void _copyShareLink() {
    Clipboard.setData(ClipboardData(text: _shareLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已复制分享链接到剪贴板: $_shareLink'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // 顶部信息与分享链接区域
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.share_outlined, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '小本本协作与分享: ${widget.repoName}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ModernCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, size: 18, color: theme.colorScheme.outline),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _shareLink,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    FilledButton.tonalIcon(
                      onPressed: _copyShareLink,
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('复制链接'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // 嵌入复用 AclEditor 进行成员权限管理
        Expanded(
          child: AclEditor(
            table: 'repo',
            entityId: widget.repoId,
            entityTitle: widget.repoName,
            ownerId: widget.ownerId,
          ),
        ),
      ],
    );
  }
}
