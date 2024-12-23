import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/model/post.dart';
import 'package:xbb/utils/markdown.dart';
import 'package:xbb/utils/utils.dart';

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
        future: postController.getPostUnwrap(widget.postId),
        builder: (context, AsyncSnapshot<Post> getPost) {
          if (getPost.hasData) {
            var post = getPost.data!;
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title:
                  Text(
                    "${post.category} | ${detailedDateStr(post.updatedAt)}",
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Divider(),
                  // content:
                  Expanded(
                    child: ListView(
                      children: [MarkdownRenderer(data: post.content)],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const CircularProgressIndicator();
          }
        });
  }

  // Widget _title(Post post) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         post.title,
  //         style: const TextStyle(fontSize: 22),
  //       ),
  //       Text(
  //         "${post.category} | ${detailedDateStr(post.updatedAt)}",
  //         style: const TextStyle(fontSize: 13),
  //       ),
  //     ],
  //   );
  // }

  // Widget _content(String content) {
  //   return ListView(children: [MarkdownRenderer(data: content)]);
  // }
}
