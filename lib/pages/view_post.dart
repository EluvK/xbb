import 'package:flutter/material.dart';
import 'package:xbb/components/post_viewer.dart';

class ViewPostPage extends StatelessWidget {
  const ViewPostPage({super.key, required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('viewPost')),
      body: PostViewer(postId: postId),
    );
  }
}
