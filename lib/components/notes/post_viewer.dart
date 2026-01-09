import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/new_markdown_renderer.dart';
import 'package:xbb/controller/user.dart';
// import 'package:xbb/components/post_comment.dart';
import 'package:xbb/models/notes/model.dart';
// import 'package:xbb/utils/markdown.dart';
import 'package:xbb/utils/utils.dart';

class PostViewer extends StatefulWidget {
  const PostViewer({super.key, required this.postItem});
  final PostDataItem postItem;

  @override
  State<PostViewer> createState() => _PostViewerState();
}

class _PostViewerState extends State<PostViewer> {
  final UserManagerController userManagerController = Get.find<UserManagerController>();
  final CommentController commentController = Get.find<CommentController>();

  @override
  Widget build(BuildContext context) {
    final Post post = widget.postItem.body;
    final bool isSelfPost = userManagerController.selfProfile.value?.userId == widget.postItem.owner;
    final String displayTitleUser = isSelfPost
        ? 'Me'
        : userManagerController.getUserProfile(widget.postItem.owner)?.name ?? widget.postItem.owner;

    // var body =
    return Obx(() {
      final comments = commentController.onViewComments(filters: [ParentIdFilter(widget.postItem.id)]);
      print("debug: comments length: ${comments.length}");
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // title:
            Text(
              "${post.category} | ${detailedDateStr(widget.postItem.updatedAt)} | Author: $displayTitleUser | ${post.content.length} chars",
              style: const TextStyle(fontSize: 13),
            ),
            const Divider(),
            // content:
            Expanded(
              child: ListView(
                children: [
                  NewMarkdownRenderer(postId: widget.postItem.id, data: post.content, comments: comments),
                  // MarkdownRenderer(data: post.content),
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
    });
  }
}
