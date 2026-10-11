import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_widget/markdown_widget.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/presentation/notes/comment_widgets.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';
import 'package:xbb/utils/code_wrapper.dart';
import 'package:xbb/utils/latex.dart';
import 'package:xbb/utils/text_similarity.dart';

class SimpleMarkdownRenderer extends StatelessWidget {
  final String data;

  const SimpleMarkdownRenderer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig;
    codeWrapper(child, text, language) => CodeWrapperWidget(child, text, language);
    return MarkdownBlock(
      data: data,
      generator: MarkdownGenerator(inlineSyntaxList: [LatexSyntax()], generators: [latexGenerator]),
      config: config.copy(
        configs: [
          isDark ? PreConfig.darkConfig.copy(wrapper: codeWrapper) : const PreConfig().copy(wrapper: codeWrapper),
        ],
      ),
    );
  }
}

/// 段落元数据实体
class _ParagraphItem {
  final int index;
  final String hash;
  final Widget widget;
  final String rawText;
  final bool canComment;

  _ParagraphItem({
    required this.index,
    required this.hash,
    required this.widget,
    required this.rawText,
    required this.canComment,
  });
}

/// 支持段落级行内批注与评论展开的现代化 Markdown 渲染器
class MarkdownWithComments extends StatefulWidget {
  final String data;
  final String postId;
  final String repoOwnedId;
  final List<Permission> permissions;
  final List<DataItem<Comment>> comments;
  final String currentUserId;
  final Future<void> Function(
    String content,
    String? parentId, {
    int? paragraphIndex,
    String? paragraphHash,
  }) onAddComment;
  final void Function(DataItem<Comment> comment) onReplyComment;
  final void Function(String commentId) onDeleteComment;

  const MarkdownWithComments({
    super.key,
    required this.data,
    required this.postId,
    required this.repoOwnedId,
    this.permissions = const [],
    this.comments = const [],
    required this.currentUserId,
    required this.onAddComment,
    required this.onReplyComment,
    required this.onDeleteComment,
  });

  @override
  State<MarkdownWithComments> createState() => _MarkdownWithCommentsState();
}

class _MarkdownWithCommentsState extends State<MarkdownWithComments> {
  // 当前处于行内激活评论输入的段落 index
  int? _activeInlineInputParagraphIndex;
  // 展开显示批注树的段落索引集合
  final Set<int> _expandedParagraphIndexes = {};
  // 段落行内输入控制器
  final TextEditingController _inlineInputController = TextEditingController();
  final FocusNode _inlineFocusNode = FocusNode();
  bool _isSubmittingInline = false;

  @override
  void dispose() {
    _inlineInputController.dispose();
    _inlineFocusNode.dispose();
    super.dispose();
  }

  void _openInlineInput(int index) {
    setState(() {
      _activeInlineInputParagraphIndex = index;
      _expandedParagraphIndexes.add(index);
    });
    Future.microtask(() => _inlineFocusNode.requestFocus());
  }

  void _closeInlineInput() {
    setState(() {
      _activeInlineInputParagraphIndex = null;
      _inlineInputController.clear();
    });
  }

  Future<void> _submitInlineComment(int index, String hash) async {
    final text = _inlineInputController.text.trim();
    if (text.isEmpty || _isSubmittingInline) return;

    setState(() => _isSubmittingInline = true);
    try {
      await widget.onAddComment(
        text,
        null,
        paragraphIndex: index,
        paragraphHash: hash,
      );
      _closeInlineInput();
    } finally {
      if (mounted) {
        setState(() => _isSubmittingInline = false);
      }
    }
  }

  List<_ParagraphItem> _parseParagraphs(BuildContext context, MarkdownConfig config) {
    if (widget.data.isEmpty) return [];

    final md.Document document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
      inlineSyntaxes: [LatexSyntax()],
    );
    final regExp = WidgetVisitor.defaultSplitRegExp;
    final List<String> lines = widget.data.split(regExp);
    final List<md.Node> nodes = document.parseLines(lines);
    final WidgetVisitor visitor = WidgetVisitor(config: config, generators: [latexGenerator], splitRegExp: regExp);
    final List<SpanNode> spans = visitor.visit(nodes);
    const supportTags = {'p', 'blockquote', 'pre', 'ul', 'ol', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'};

    final List<_ParagraphItem> items = [];
    for (int i = 0; i < spans.length; i++) {
      final span = spans[i];
      final node = i < nodes.length ? nodes[i] : null;
      final richText = Text.rich(span.build());
      final bool canComment = node is md.Element && supportTags.contains(node.tag);
      final rawText = node != null ? node.textContent : '';
      final hash = TextSimilarityHasher.computeSimHash(rawText).toString();

      items.add(_ParagraphItem(
        index: i,
        hash: hash,
        widget: richText,
        rawText: rawText,
        canComment: canComment,
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final config = (isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig).copy(
      configs: [
        isDark
            ? PreConfig.darkConfig.copy(wrapper: (child, text, lang) => CodeWrapperWidget(child, text, lang))
            : const PreConfig().copy(wrapper: (child, text, lang) => CodeWrapperWidget(child, text, lang)),
      ],
    );

    final paragraphs = _parseParagraphs(context, config);

    // 将全部评论按照段落进行聚合映射
    final Map<int, List<DataItem<Comment>>> paragraphCommentsMap = {};
    final List<DataItem<Comment>> generalOrphanComments = [];

    // 建立 hash -> paragraphIndex 查找表
    final Map<String, int> hashToIndexMap = {
      for (final p in paragraphs) p.hash: p.index,
    };

    for (final c in widget.comments) {
      final pIndex = c.body.paragraphIndex;
      final pHash = c.body.paragraphHash;

      if (pIndex != null && pIndex >= 0 && pIndex < paragraphs.length) {
        paragraphCommentsMap.putIfAbsent(pIndex, () => []).add(c);
      } else if (pHash != null && hashToIndexMap.containsKey(pHash)) {
        final matchedIndex = hashToIndexMap[pHash]!;
        paragraphCommentsMap.putIfAbsent(matchedIndex, () => []).add(c);
      } else {
        // 未指定段落，或对应段落已在正文变动中被删除/失效的孤儿评论
        generalOrphanComments.add(c);
      }
    }

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 逐个渲染段落及对应的段落批注行
          ...paragraphs.map((p) {
            final pComments = paragraphCommentsMap[p.index] ?? [];
            final isExpanded = _expandedParagraphIndexes.contains(p.index);
            final isInputActive = _activeInlineInputParagraphIndex == p.index;

            return _ParagraphRowWidget(
              paragraph: p,
              comments: pComments,
              isExpanded: isExpanded || isInputActive,
              isInputActive: isInputActive,
              currentUserId: widget.currentUserId,
              inlineController: _inlineInputController,
              inlineFocusNode: _inlineFocusNode,
              isSubmittingInline: _isSubmittingInline,
              onToggleExpand: () {
                setState(() {
                  if (_expandedParagraphIndexes.contains(p.index)) {
                    _expandedParagraphIndexes.remove(p.index);
                  } else {
                    _expandedParagraphIndexes.add(p.index);
                  }
                });
              },
              onTriggerAddComment: () => _openInlineInput(p.index),
              onCancelInlineInput: _closeInlineInput,
              onSubmitInlineComment: () => _submitInlineComment(p.index, p.hash),
              onReply: widget.onReplyComment,
              onDelete: widget.onDeleteComment,
            );
          }),

          const SizedBox(height: AppSpacing.xl),
          const Divider(),

          // 文末全局讨论区（展示全局评论与已失效段落的评论，绝不丢数据）
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.forum_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '全局讨论与历史批注',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: AppSpacing.xs),
                ModernBadge(
                  label: '${generalOrphanComments.length} 条',
                  color: generalOrphanComments.isEmpty ? theme.colorScheme.outlineVariant : theme.colorScheme.primary,
                ),
              ],
            ),
          ),

          if (generalOrphanComments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: Text(
                  '暂无文末全局讨论。你可以在上方任意段落旁边发表精准批注。',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            )
          else
            CommentListWidget(
              postId: widget.postId,
              comments: generalOrphanComments,
              currentUserId: widget.currentUserId,
              onReply: widget.onReplyComment,
              onDelete: widget.onDeleteComment,
            ),
        ],
      ),
    );
  }
}

/// 单个段落渲染包装行：正文 + 段落悬浮批注触发器 + 原位内嵌树状评论卡片
class _ParagraphRowWidget extends StatelessWidget {
  final _ParagraphItem paragraph;
  final List<DataItem<Comment>> comments;
  final bool isExpanded;
  final bool isInputActive;
  final String currentUserId;
  final TextEditingController inlineController;
  final FocusNode inlineFocusNode;
  final bool isSubmittingInline;
  final VoidCallback onToggleExpand;
  final VoidCallback onTriggerAddComment;
  final VoidCallback onCancelInlineInput;
  final VoidCallback onSubmitInlineComment;
  final void Function(DataItem<Comment> comment) onReply;
  final void Function(String commentId) onDelete;

  const _ParagraphRowWidget({
    required this.paragraph,
    required this.comments,
    required this.isExpanded,
    required this.isInputActive,
    required this.currentUserId,
    required this.inlineController,
    required this.inlineFocusNode,
    required this.isSubmittingInline,
    required this.onToggleExpand,
    required this.onTriggerAddComment,
    required this.onCancelInlineInput,
    required this.onSubmitInlineComment,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasComments = comments.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 正文段落与侧边悬浮批注触发按钮
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: paragraph.widget),
              if (paragraph.canComment) ...[
                const SizedBox(width: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasComments)
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onToggleExpand,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded, size: 12, color: theme.colorScheme.onPrimaryContainer),
                              const SizedBox(width: 3),
                              Text(
                                '${comments.length}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 15,
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      tooltip: '为此段落添加批注',
                      icon: Icon(
                        Icons.add_comment_outlined,
                        color: theme.colorScheme.outline.withAlpha(160),
                      ),
                      onPressed: onTriggerAddComment,
                    ),
                  ],
                ),
              ],
            ],
          ),

          // 段落行内输入框
          if (isInputActive) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: theme.colorScheme.primary.withAlpha(100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        '针对本段落的批注',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 14,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        icon: const Icon(Icons.close),
                        onPressed: onCancelInlineInput,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: inlineController,
                    focusNode: inlineFocusNode,
                    maxLines: 2,
                    style: theme.textTheme.bodySmall,
                    decoration: const InputDecoration(
                      hintText: '写下针对此段落的讨论或批注...',
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      onPressed: isSubmittingInline ? null : onSubmitInlineComment,
                      child: isSubmittingInline
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('发表批注', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 段落内嵌评论树
          if (hasComments && isExpanded) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              margin: const EdgeInsets.only(left: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(80)),
              ),
              child: CommentListWidget(
                postId: paragraph.rawText,
                comments: comments,
                currentUserId: currentUserId,
                onReply: onReply,
                onDelete: onDelete,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
