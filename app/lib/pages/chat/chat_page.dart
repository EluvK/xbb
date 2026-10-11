import 'package:flutter/material.dart';
import 'package:xbb/presentation/chat/modern_chat_view.dart';

class ChatSessionPanel extends StatelessWidget {
  const ChatSessionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModernChatView();
  }
}
