import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/model/post.dart';

class PostViewer extends StatefulWidget {
  const PostViewer({super.key, required this.postId});
  final String postId;

  @override
  State<PostViewer> createState() => _PostViewerState();
}

class _PostViewerState extends State<PostViewer> {
  final postController = Get.find<PostController>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Post>(
        future: postController.getPost(widget.postId),
        builder: (context, AsyncSnapshot<Post> post) {
          if (post.hasData) {
            return Column(
              children: [
                _title(post.data!.title),
                _content(post.data!.content),
              ],
            );
          } else {
            return const CircularProgressIndicator();
          }
        });
  }

  Widget _title(String title) {
    return Column(
      children: [
        Text(title),
      ],
    );
  }

  Widget _content(String content) {
    return Column(
      children: [
        Text(content),
      ],
    );
  }
}
