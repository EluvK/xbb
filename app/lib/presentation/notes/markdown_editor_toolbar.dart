import 'package:flutter/material.dart';
import 'package:xbb/core/theme/tokens.dart';

/// 现代化 Markdown 快捷编辑工具栏
class MarkdownEditorToolbar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;

  const MarkdownEditorToolbar({
    super.key,
    required this.controller,
    this.focusNode,
  });

  void _wrapSelection({
    required String prefix,
    required String suffix,
    String defaultText = '',
  }) {
    final text = controller.text;
    final selection = controller.selection;

    if (selection.isCollapsed) {
      final cursor = selection.baseOffset < 0 ? text.length : selection.baseOffset;
      final inserted = '$prefix$defaultText$suffix';
      final newText = text.replaceRange(cursor, cursor, inserted);
      final newCursor = cursor + prefix.length + (defaultText.isNotEmpty ? defaultText.length : 0);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
    } else {
      final selectedText = text.substring(selection.start, selection.end);
      final wrapped = '$prefix$selectedText$suffix';
      final newText = text.replaceRange(selection.start, selection.end, wrapped);
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: selection.start,
          extentOffset: selection.start + wrapped.length,
        ),
      );
    }
    focusNode?.requestFocus();
  }

  void _insertAtLineStart(String prefix) {
    final text = controller.text;
    final selection = controller.selection;
    final cursor = selection.baseOffset < 0 ? 0 : selection.baseOffset;

    final lineStart = cursor == 0 ? 0 : text.lastIndexOf('\n', cursor - 1) + 1;
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + prefix.length),
    );
    focusNode?.requestFocus();
  }

  void _insertTable() {
    const tableTemplate =
        '\n| 标题 1 | 标题 2 |\n| --- | --- |\n| 内容 1 | 内容 2 |\n';
    final text = controller.text;
    final selection = controller.selection;
    final cursor = selection.baseOffset < 0 ? text.length : selection.baseOffset;
    final newText = text.replaceRange(cursor, cursor, tableTemplate);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor + tableTemplate.length),
    );
    focusNode?.requestFocus();
  }

  void _insertLink() {
    final selection = controller.selection;
    final text = controller.text;
    if (!selection.isCollapsed) {
      final selected = text.substring(selection.start, selection.end);
      _wrapSelection(prefix: '[', suffix: '](url)');
    } else {
      _wrapSelection(prefix: '[', suffix: '](url)', defaultText: '链接文字');
    }
  }

  void _insertLatex() {
    _wrapSelection(prefix: '\n\$\$\n', suffix: '\n\$\$\n', defaultText: 'E = mc^2');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(60)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题 H1, H2, H3
            _ToolbarButton(
              icon: Icons.title,
              tooltip: '一级标题 (# )',
              onPressed: () => _insertAtLineStart('# '),
            ),
            _ToolbarButton(
              icon: Icons.format_size,
              tooltip: '二级标题 (## )',
              onPressed: () => _insertAtLineStart('## '),
            ),
            const _ToolbarDivider(),

            // 粗体、斜体、删除线
            _ToolbarButton(
              icon: Icons.format_bold,
              tooltip: '加粗 (**文本**)',
              onPressed: () => _wrapSelection(prefix: '**', suffix: '**', defaultText: '加粗'),
            ),
            _ToolbarButton(
              icon: Icons.format_italic,
              tooltip: '斜体 (*文本*)',
              onPressed: () => _wrapSelection(prefix: '*', suffix: '*', defaultText: '斜体'),
            ),
            const _ToolbarDivider(),

            // 引用
            _ToolbarButton(
              icon: Icons.format_quote,
              tooltip: '引用 (> )',
              onPressed: () => _insertAtLineStart('> '),
            ),

            // 代码块与行内代码
            _ToolbarButton(
              icon: Icons.code,
              tooltip: '代码块 (```)',
              onPressed: () => _wrapSelection(prefix: '\n```\n', suffix: '\n```\n', defaultText: '// code'),
            ),
            const _ToolbarDivider(),

            // 列表
            _ToolbarButton(
              icon: Icons.format_list_bulleted,
              tooltip: '无序列表 (- )',
              onPressed: () => _insertAtLineStart('- '),
            ),
            _ToolbarButton(
              icon: Icons.format_list_numbered,
              tooltip: '有序列表 (1. )',
              onPressed: () => _insertAtLineStart('1. '),
            ),
            _ToolbarButton(
              icon: Icons.check_box_outlined,
              tooltip: '任务复选框 (- [ ] )',
              onPressed: () => _insertAtLineStart('- [ ] '),
            ),
            const _ToolbarDivider(),

            // 表格
            _ToolbarButton(
              icon: Icons.table_chart_outlined,
              tooltip: '插入表格',
              onPressed: _insertTable,
            ),

            // 链接
            _ToolbarButton(
              icon: Icons.link,
              tooltip: '插入链接 [文本](url)',
              onPressed: _insertLink,
            ),

            // LaTeX 公式
            _ToolbarButton(
              icon: Icons.functions_rounded,
              tooltip: '插入 LaTeX 数学公式 (\$\$)',
              onPressed: _insertLatex,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: onPressed,
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Theme.of(context).dividerColor.withAlpha(100),
    );
  }
}
