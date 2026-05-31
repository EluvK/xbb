import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/chat/chat_message_card.dart';
import 'package:xbb/controller/chat.dart';

class ViewChatMessages extends StatefulWidget {
  const ViewChatMessages({super.key});

  @override
  State<ViewChatMessages> createState() => _ViewChatMessagesState();
}

class _ViewChatMessagesState extends State<ViewChatMessages> {
  ChatController? _controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ChatController>()) {
      _controller = Get.find<ChatController>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Obx(() {
      final messages = controller.messageList;
      if (messages.isEmpty) {
        return Center(child: Text('chat_no_messages'.tr));
      }
      return ListView.builder(
        reverse: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final item = messages[index];
          return ChatMessageCard(item: item, index: index, isLast: index == messages.length - 1);
        },
      );
    });
  }
}
