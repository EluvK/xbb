import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/post_editor.dart';
import 'package:xbb/utils/utils.dart';

class EditPostPage extends StatelessWidget {
  const EditPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final String? postId = args?[0];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final bool shouldPop = await showBackCheckDialog(context) ?? false;
        if (context.mounted && shouldPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('newPost')),
        body: PostEditor(
          postId: postId,
        ),
      ),
    );
  }
}
