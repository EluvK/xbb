import 'package:flutter/material.dart';
import 'package:xbb/components/post_editor.dart';

class NewPost extends StatelessWidget {
  const NewPost({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('newPost')),
      body: const PostEditor(),
    );
  }
}
