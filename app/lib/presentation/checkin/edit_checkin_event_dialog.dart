import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/checkin/model.dart';
import 'package:xbb/presentation/checkin/checkin_providers.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';

const List<Color> kPresetEventColors = [
  Colors.teal,
  Colors.blue,
  Colors.indigo,
  Colors.purple,
  Colors.deepPurple,
  Colors.pink,
  Colors.red,
  Colors.deepOrange,
  Colors.orange,
  Colors.amber,
  Colors.green,
  Colors.cyan,
];

class EditCheckinEventDialog extends ConsumerStatefulWidget {
  const EditCheckinEventDialog({
    super.key,
    this.eventItem,
    this.onSave,
    this.onDelete,
  });

  final DataItem<CheckinEvent>? eventItem;
  final Future<void> Function(String name, String desc, int color)? onSave;
  final Future<void> Function()? onDelete;

  static Future<void> show(BuildContext context, {DataItem<CheckinEvent>? eventItem}) {
    return showDialog(
      context: context,
      builder: (_) => EditCheckinEventDialog(eventItem: eventItem),
    );
  }

  @override
  ConsumerState<EditCheckinEventDialog> createState() => _EditCheckinEventDialogState();
}

class _EditCheckinEventDialogState extends ConsumerState<EditCheckinEventDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late Color _selectedColor;

  bool get _isEditing => widget.eventItem != null;

  @override
  void initState() {
    super.initState();
    final event = widget.eventItem?.body;
    _nameCtrl = TextEditingController(text: event?.name ?? '');
    _descCtrl = TextEditingController(text: event?.description ?? '');
    _selectedColor = event != null ? Color(event.colorValue) : kPresetEventColors.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('习惯名称不能为空')),
      );
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    final desc = _descCtrl.text.trim();
    final color = _selectedColor.value;

    if (widget.onSave != null) {
      await widget.onSave!(name, desc, color);
      return;
    }

    final userId = ref.read(authProvider).userId;
    final repo = ref.read(checkinRepositoryProvider);

    if (_isEditing) {
      await repo.updateEvent(
        eventId: widget.eventItem!.id,
        name: name,
        description: desc,
        colorValue: color,
        currentUserId: userId,
      );
    } else {
      await repo.createEvent(
        name: name,
        description: desc,
        colorValue: color,
        currentUserId: userId,
      );
    }
  }

  void _confirmDelete() {
    final event = widget.eventItem!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除打卡事件'),
        content: Text('确定删除「${event.body.name}」吗？\n所有历史打卡记录也将被级联清理，操作不可撤销！'),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
            },
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop(); // 关闭确认弹窗
              if (Navigator.of(context).canPop()) Navigator.of(context).pop(); // 关闭编辑弹窗
              if (widget.onDelete != null) {
                await widget.onDelete!();
              } else {
                await ref.read(checkinRepositoryProvider).deleteEvent(event.id);
              }
            },
            child: const Text('危险删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? '编辑习惯项目' : '新建习惯项目'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '习惯名称',
                hintText: '如：晨跑、阅读、深蹲',
                isDense: true,
              ),
              autofocus: !_isEditing,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: '描述或目标 (可选)',
                hintText: '如：每天 30 分钟',
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '专属色彩',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kPresetEventColors.map((color) {
                final isSelected = _selectedColor.value == color.value;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actionsAlignment: _isEditing ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
      actions: [
        if (_isEditing)
          TextButton.icon(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('删除'),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          ),
        TextButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          },
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _handleSave,
          child: Text(_isEditing ? '保存' : '创建'),
        ),
      ],
    );
  }
}
