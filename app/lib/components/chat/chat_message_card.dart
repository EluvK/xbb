import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:xbb/components/notes/markdown_renderer.dart';
import 'package:xbb/controller/chat.dart';
import 'package:xbb/models/chat/model.dart';
import 'package:xbb/utils/utils.dart';

class ChatMessageCard extends StatelessWidget {
  const ChatMessageCard({super.key, required this.item, required this.index, required this.isLast});

  final ChatMessageDataItem item;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatController>();
    final theme = Theme.of(context);
    final role = item.body.role;
    final align = role == ChatMessageRole.user ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = switch (role) {
      ChatMessageRole.user => theme.colorScheme.primaryContainer,
      ChatMessageRole.assistant => theme.colorScheme.secondaryContainer,
      ChatMessageRole.system => theme.colorScheme.surfaceContainerHighest,
    };
    final borderColor = switch (role) {
      ChatMessageRole.user => theme.colorScheme.primary.withAlpha(90),
      ChatMessageRole.assistant => theme.colorScheme.secondary.withAlpha(90),
      ChatMessageRole.system => theme.colorScheme.outlineVariant.withAlpha(120),
    };
    final state = controller.messageStateOf(item.id);
    final reasoningText = item.body.reasoningText ?? '';
    final usage = item.body.usage;

    final showRetry =
        isLast &&
        role == ChatMessageRole.assistant &&
        (state == ChatLocalMessageState.error || state == ChatLocalMessageState.cancelled);

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Card(
          color: bubbleColor,
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_roleIcon(role), size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const Spacer(),
                    Text(
                      _stateLabel(state),
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (item.body.text.isEmpty)
                  SelectableText('chat_message_placeholder_empty'.tr)
                else
                  SimpleMarkdownRenderer(data: item.body.text),
                if (reasoningText.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Material(
                    color: theme.colorScheme.surface.withAlpha(140),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(120)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      dense: true,
                      backgroundColor: Colors.transparent,
                      collapsedBackgroundColor: Colors.transparent,
                      shape: const Border(),
                      collapsedShape: const Border(),
                      leading: Icon(Icons.psychology_alt_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
                      title: Text('chat_reasoning_title'.tr, style: theme.textTheme.labelMedium),
                      children: [
                        SelectableText(reasoningText, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _MetaPill(label: item.createdAt.toLocal().toString().substring(0, 19), icon: Icons.schedule_rounded),
                          if (usage != null)
                            _MetaPill(
                              label: 'chat_message_tokens'.trParams({'count': '${usage.totalTokens}'}),
                              icon: Icons.local_fire_department_outlined,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'clipboard_copy_action'.tr,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: item.body.text));
                        successSimpleFlushBar('clipboard_copy_done'.tr);
                      },
                    ),
                  ],
                ),
                if (showRetry) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: () async {
                        await controller.retryLastUserTurn();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text('refresh'.tr),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _roleIcon(ChatMessageRole role) {
    return switch (role) {
      ChatMessageRole.system => Icons.settings_suggest_rounded,
      ChatMessageRole.user => Icons.person_rounded,
      ChatMessageRole.assistant => Icons.smart_toy_rounded,
    };
  }

  String _stateLabel(ChatLocalMessageState state) {
    switch (state) {
      case ChatLocalMessageState.streaming:
        return 'chat_message_state_streaming'.tr;
      case ChatLocalMessageState.completed:
        return 'chat_message_state_completed'.tr;
      case ChatLocalMessageState.error:
        return 'chat_message_state_error'.tr;
      case ChatLocalMessageState.cancelled:
        return 'chat_message_state_cancelled'.tr;
    }
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(170),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
