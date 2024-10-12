import 'package:flutter/material.dart';
import 'package:xbb/components/post_editor.dart';

class EditPostPage extends StatelessWidget {
  const EditPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('newPost')),
      body: const PostEditor(),
    );
  }
}
