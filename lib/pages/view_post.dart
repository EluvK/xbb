import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/post_viewer.dart';

class ViewPostPage extends StatelessWidget {
  const ViewPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final String postId = args[0];
    final bool editable = args[1];
    return Scaffold(
      appBar: AppBar(
        title: const Text('viewPost'),
        actions: [
          Visibility(
            visible: editable,
            child: IconButton(
                onPressed: () {
                  Get.toNamed('/edit-post', arguments: [postId]);
                },
                icon: const Icon(Icons.edit)),
          ),
        ],
      ),
      body: PostViewer(postId: postId),
    );
  }
}
