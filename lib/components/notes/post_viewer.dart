import 'package:flutter/material.dart';
// import 'package:xbb/components/post_comment.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/markdown.dart';
import 'package:xbb/utils/utils.dart';

class PostViewer extends StatefulWidget {
  const PostViewer({super.key, required this.postItem});
  final PostDataItem postItem;

  @override
  State<PostViewer> createState() => _PostViewerState();
}

class _PostViewerState extends State<PostViewer> {
  @override
  Widget build(BuildContext context) {
    final Post post = widget.postItem.body;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title:
          Text(
            "${post.category} | ${detailedDateStr(widget.postItem.updatedAt)}",
            style: const TextStyle(fontSize: 13),
          ),
          const Divider(),
          // content:
          Expanded(
            child: ListView(
              children: [
                MarkdownRenderer(data: post.content),
                const Divider(),
                const Divider(),
                // todo future need to inline comments, together with content rendering
                // PostComment(repoId: post.repoId, postId: post.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
