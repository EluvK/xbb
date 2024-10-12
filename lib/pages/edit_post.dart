import 'package:flutter/material.dart';
import 'package:xbb/components/post_editor.dart';

class EditPostPage extends StatelessWidget {
  const EditPostPage({super.key, this.postId});
  final String? postId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('newPost')),
      body: PostEditor(
        postId: postId,
      ),
    );
  }
}
