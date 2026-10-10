import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/chat/chat_input.dart';
import 'package:xbb/components/chat/chat_session_list.dart';
import 'package:xbb/components/chat/view_chat_messages.dart';
import 'package:xbb/controller/chat.dart';

class ChatSessionPanel extends StatelessWidget {
  const ChatSessionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatSessionList();
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!Get.isRegistered<ChatController>()) {
      await reInitChatController();
    }
    Get.find<ChatController>();
    if (mounted) {
      setState(() {
        _ready = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    return const Column(
      children: [
        Expanded(child: ViewChatMessages()),
        Divider(height: 1),
        ChatInput(),
      ],
    );
  }
}
