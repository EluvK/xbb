import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/common/permission.dart';
import 'package:xbb/components/notes/post_viewer.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/models/notes/model.dart';

class ViewPostPage extends StatelessWidget {
  const ViewPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final PostDataItem post = args[0];
    final RepoController repoController = Get.find<RepoController>();
    return Scaffold(
      appBar: AppBar(
        title: Text('view_post'.trParams({"postName": post.body.title})),
        actions: [
          PermissionBox(
            feature: NotesFeatureRequires.updatePost,
            ownerId: post.owner,
            acls: repoController.getAclCached(post.body.repoId),
            child: IconButton(
              onPressed: () {
                Get.toNamed('/notes/edit-post', arguments: [post]);
              },
              icon: const Icon(Icons.edit),
            ),
          ),
        ],
      ),
      body: PostViewer(postItem: post),
    );
  }
}
