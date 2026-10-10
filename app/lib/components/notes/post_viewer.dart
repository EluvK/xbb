import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/notes/markdown_renderer.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/utils.dart';

class PostViewer extends StatelessWidget {
  const PostViewer({super.key, required this.postItem});
  final PostDataItem postItem;

  @override
  Widget build(BuildContext context) {
    final userManagerController = Get.find<UserManagerController>();
    final repoController = Get.find<RepoController>();
    final Post post = postItem.body;
    final bool isSelfPost = userManagerController.selfProfile.value?.userId == postItem.owner;
    final String displayTitleUser = isSelfPost
        ? 'Me'
        : userManagerController.getUserProfile(postItem.owner)?.name ?? postItem.owner;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title:
          Text(
            "${post.category} | ${detailedDateStr(postItem.updatedAt)} | Author: $displayTitleUser | ${post.content.length} chars",
            style: const TextStyle(fontSize: 13),
          ),
          const Divider(),
          // content:
          Expanded(
            child: ListView(
              children: [
                MarkdownWithComments(
                  postId: postItem.id,
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
