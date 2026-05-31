import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/chat.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({super.key});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatController>();
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Obx(() {
          final canSend =
              !controller.waitingForResponse.value &&
              controller.currentConversationId.value != null &&
              !controller.syncingConversationIds.contains(controller.currentConversationId.value!);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  minLines: 1,
                  maxLines: 6,
                  enabled: controller.currentConversationId.value != null,
                  decoration: InputDecoration(
                    hintText: 'chat_input_hint'.tr,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) async {
                    if (!canSend) return;
                    await _send(controller);
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (controller.waitingForResponse.value)
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await controller.cancelCurrentStreamingByUser();
                  },
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text('cancel'.tr),
                )
              else
                FilledButton.icon(
                  onPressed: canSend
                      ? () async {
                          await _send(controller);
                        }
                      : null,
                  icon: const Icon(Icons.send_rounded),
                  label: Text('chat_send'.tr),
                ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _send(ChatController controller) async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    await controller.sendUserMessage(text);
  }
}
