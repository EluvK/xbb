import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/chat.dart';
import 'package:xbb/models/chat/model.dart';

class ChatMessageCard extends StatelessWidget {
  const ChatMessageCard({super.key, required this.item, required this.index, required this.isLast});

  final ChatMessageDataItem item;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatController>();
    final role = item.body.role;
    final align = role == ChatMessageRole.user ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = switch (role) {
      ChatMessageRole.user => Theme.of(context).colorScheme.primaryContainer,
      ChatMessageRole.assistant => Theme.of(context).colorScheme.secondaryContainer,
      ChatMessageRole.system => Theme.of(context).colorScheme.surfaceContainerHighest,
    };
    final state = controller.messageStateOf(item.id);

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
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _roleTitle(role),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                SelectableText(item.body.text.isEmpty ? 'chat_message_placeholder_empty'.tr : item.body.text),
                if ((item.body.reasoningText ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(item.body.reasoningText!, style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.createdAt.toLocal().toString().substring(0, 19),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Text(_stateLabel(state), style: Theme.of(context).textTheme.labelSmall),
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

  String _roleTitle(ChatMessageRole role) {
    switch (role) {
      case ChatMessageRole.system:
        return 'chat_role_system'.tr;
      case ChatMessageRole.user:
        return 'chat_role_user'.tr;
      case ChatMessageRole.assistant:
        return 'chat_role_assistant'.tr;
    }
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
