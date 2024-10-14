import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/post_editor.dart';

class EditPostPage extends StatelessWidget {
  const EditPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final String? postId = args?[0];
    return Scaffold(
      appBar: AppBar(title: const Text('newPost')),
      body: PostEditor(
        postId: postId,
      ),
    );
  }
}
