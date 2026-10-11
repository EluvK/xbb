import 'package:flutter/material.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

/// 评论节点数据包装，用于支持树状层级渲染
class CommentTreeNode {
  final DataItem<Comment> comment;
  final List<CommentTreeNode> children;

  CommentTreeNode({
    required this.comment,
    this.children = const [],
  });
}

/// 现代化评论列表组件
class CommentListWidget extends StatefulWidget {
  final String postId;
  final List<DataItem<Comment>> comments;
  final String currentUserId;
  final void Function(DataItem<Comment> comment) onReply;
  final void Function(String commentId) onDelete;

  const CommentListWidget({
    super.key,
    required this.postId,
    required this.comments,
    required this.currentUserId,
    required this.onReply,
    required this.onDelete,
  });

  @override
  State<CommentListWidget> createState() => _CommentListWidgetState();
}

class _CommentListWidgetState extends State<CommentListWidget> {
  final Set<String> _collapsedCommentIds = {};

  List<CommentTreeNode> _buildCommentTree(List<DataItem<Comment>> comments) {
    final Map<String, List<DataItem<Comment>>> childrenMap = {};
    final List<DataItem<Comment>> roots = [];

    final commentMap = {for (final c in comments) c.id: c};

    for (final c in comments) {
      final pId = c.body.parentId;
      if (pId == null || pId.isEmpty || !commentMap.containsKey(pId)) {
        roots.add(c);
      } else {
        childrenMap.putIfAbsent(pId, () => []).add(c);
      }
    }

    CommentTreeNode buildNode(DataItem<Comment> item) {
      final children = childrenMap[item.id] ?? [];
      return CommentTreeNode(
        comment: item,
        children: children.map(buildNode).toList(),
      );
    }

    return roots.map(buildNode).toList();
  }

  void _toggleCollapse(String commentId) {
    setState(() {
      if (_collapsedCommentIds.contains(commentId)) {
        _collapsedCommentIds.remove(commentId);
      } else {
        _collapsedCommentIds.add(commentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tree = _buildCommentTree(widget.comments);

    if (tree.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 32,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '暂无评论，留下第一条评论吧',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tree.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        return _buildNodeWidget(tree[index], level: 0);
      },
    );
  }

  Widget _buildNodeWidget(CommentTreeNode node, {int level = 0}) {
    final comment = node.comment;
    final isCollapsed = _collapsedCommentIds.contains(comment.id);
    final hasChildren = node.children.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(left: (level * 20.0).clamp(0.0, 60.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentCard(
            comment: comment,
            isSelf: comment.owner == widget.currentUserId,
            hasChildren: hasChildren,
            isCollapsed: isCollapsed,
            childCount: node.children.length,
            onToggleCollapse: () => _toggleCollapse(comment.id),
            onReply: () => widget.onReply(comment),
            onDelete: () => widget.onDelete(comment.id),
          ),
          if (hasChildren && !isCollapsed) ...[
            const SizedBox(height: AppSpacing.xs),
            ...node.children.map((child) => _buildNodeWidget(child, level: level + 1)),
          ],
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final DataItem<Comment> comment;
  final bool isSelf;
  final bool hasChildren;
  final bool isCollapsed;
  final int childCount;
  final VoidCallback onToggleCollapse;
  final VoidCallback onReply;
  final VoidCallback onDelete;

  const _CommentCard({
    required this.comment,
    required this.isSelf,
    required this.hasChildren,
    required this.isCollapsed,
    required this.childCount,
    required this.onToggleCollapse,
    required this.onReply,
    required this.onDelete,
  });

  String _formatDate(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m-$d $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authorName = isSelf ? '${comment.owner} (我)' : comment.owner;
    final initial = comment.owner.isNotEmpty ? comment.owner[0].toUpperCase() : '?';

    return ModernCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：头像、作者、时间、操作
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  initial,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      authorName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _formatDate(comment.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              // 回复按钮
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                tooltip: '回复',
                icon: const Icon(Icons.reply_rounded),
                onPressed: onReply,
              ),
              // 删除按钮 (作者自身或管理)
              if (isSelf)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: '删除',
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('删除评论'),
                        content: const Text('确定要删除这条评论吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('取消'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('删除'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      onDelete();
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // 评论正文
          SelectableText(
            comment.body.content,
            style: theme.textTheme.bodyMedium,
          ),
          // 折叠/展开子回复条目
          if (hasChildren) ...[
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: onToggleCollapse,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCollapsed ? Icons.expand_more : Icons.expand_less,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      isCollapsed ? '展开 $childCount 条回复' : '收起回复',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 现代化评论输入框组件
class CommentInputWidget extends StatefulWidget {
  final DataItem<Comment>? replyToComment;
  final VoidCallback onCancelReply;
  final Future<void> Function(String content, String? parentId) onSubmit;

  const CommentInputWidget({
    super.key,
    this.replyToComment,
    required this.onCancelReply,
    required this.onSubmit,
  });

  @override
  State<CommentInputWidget> createState() => _CommentInputWidgetState();
}

class _CommentInputWidgetState extends State<CommentInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void didUpdateWidget(covariant CommentInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyToComment != null && widget.replyToComment != oldWidget.replyToComment) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(text, widget.replyToComment?.id);
      _controller.clear();
      if (widget.replyToComment != null) {
        widget.onCancelReply();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final replyTo = widget.replyToComment;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 如果处于回复模式，展示正在回复标签
          if (replyTo != null) ...[
            Row(
              children: [
                Icon(Icons.reply_rounded, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '回复 @${replyTo.owner}: "${replyTo.body.content.length > 20 ? '${replyTo.body.content.substring(0, 20)}...' : replyTo.body.content}"',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: widget.onCancelReply,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Icon(Icons.close, size: 14, color: theme.colorScheme.outline),
                  ),
                ),
              ],
            ),
            const Divider(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 3,
                  minLines: 1,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: replyTo != null ? '输入回复内容...' : '写下你的评论...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton.filled(
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                onPressed: _isSubmitting ? null : _handleSend,
                tooltip: '发送',
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
