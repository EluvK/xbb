import 'package:flutter/material.dart';
import 'package:xbb/components/post_viewer.dart';
import 'package:xbb/pages/edit_post.dart';

class ViewPostPage extends StatelessWidget {
  const ViewPostPage({super.key, required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('viewPost'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPostPage(postId: postId),
                    ));
              },
              icon: const Icon(Icons.edit)),
          // IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        ],
      ),
      body: PostViewer(postId: postId),
    );
  }
}
