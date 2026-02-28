import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/notes/markdown_renderer.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/utils.dart';

class PostViewer extends StatefulWidget {
  const PostViewer({super.key, required this.postItem});
  final PostDataItem postItem;

  @override
  State<PostViewer> createState() => _PostViewerState();
}

class _PostViewerState extends State<PostViewer> {
  final UserManagerController userManagerController = Get.find<UserManagerController>();
  final RepoController repoController = Get.find<RepoController>();
  final CommentController commentController = Get.find<CommentController>();

  @override
  Widget build(BuildContext context) {
    final Post post = widget.postItem.body;
    final bool isSelfPost = userManagerController.selfProfile.value?.userId == widget.postItem.owner;
    final String displayTitleUser = isSelfPost
        ? 'Me'
        : userManagerController.getUserProfile(widget.postItem.owner)?.name ?? widget.postItem.owner;

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
                MarkdownWithComments(
                  postId: widget.postItem.id,
                  data: post.content,
                  repoOwnedId: repoController.getRepo(post.repoId)!.owner,
                  permissions: repoController.getAclCached(post.repoId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
