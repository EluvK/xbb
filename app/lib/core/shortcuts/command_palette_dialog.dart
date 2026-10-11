import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xbb/core/theme/tokens.dart';

class CommandPaletteItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? shortcutHint;
  final VoidCallback onExecute;

  const CommandPaletteItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.shortcutHint,
    required this.onExecute,
  });
}

/// 桌面端全局命令面板 (Command Palette - Cmd/Ctrl + K)
class CommandPaletteDialog extends StatefulWidget {
  final List<CommandPaletteItem> items;

  const CommandPaletteDialog({
    super.key,
    required this.items,
  });

  static Future<void> show(BuildContext context, {required List<CommandPaletteItem> items}) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CommandPaletteDialog(items: items),
    );
  }

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<CommandPaletteItem> get _filteredItems {
    if (_query.isEmpty) return widget.items;
    final q = _query.toLowerCase();
    return widget.items.where((item) {
      return item.title.toLowerCase().contains(q) || item.subtitle.toLowerCase().contains(q);
    }).toList();
  }

  void _executeSelected(List<CommandPaletteItem> items) {
    if (items.isEmpty) return;
    final index = _selectedIndex.clamp(0, items.length - 1);
    Navigator.of(context).pop();
    items[index].onExecute();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredItems;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 460),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: AppRadius.roundedLg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 搜索栏
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, size: 22, color: theme.colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent) {
                            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                              setState(() {
                                if (filtered.isNotEmpty) {
                                  _selectedIndex = (_selectedIndex + 1) % filtered.length;
                                }
                              });
                            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                              setState(() {
                                if (filtered.isNotEmpty) {
                                  _selectedIndex = (_selectedIndex - 1 + filtered.length) % filtered.length;
                                }
                              });
                            } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                              _executeSelected(filtered);
                            }
                          }
                        },
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onChanged: (val) {
                            setState(() {
                              _query = val.trim();
                              _selectedIndex = 0;
                            });
                          },
                          onSubmitted: (_) => _executeSelected(filtered),
                          decoration: const InputDecoration(
                            hintText: '键入命令或检索功能 (按回车执行，ESC 退出)...',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: AppRadius.roundedSm,
                      ),
                      child: Text(
                        'ESC',
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 命令结果列表
              Flexible(
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          '未找到匹配命令',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final isSelected = index == _selectedIndex;

                          return InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              item.onExecute();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                              color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45) : Colors.transparent,
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 20,
                                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        Text(
                                          item.subtitle,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (item.shortcutHint != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        borderRadius: AppRadius.roundedSm,
                                      ),
                                      child: Text(
                                        item.shortcutHint!,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
