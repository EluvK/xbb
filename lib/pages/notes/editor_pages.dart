import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/notes/post_editor.dart';
import 'package:xbb/components/notes/repo_editor.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/utils.dart';

PopScope withPopAlert(BuildContext context, Scaffold child) {
  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (bool didPop, Object? result) async {
      if (didPop) {
        return;
      }
      final bool shouldPop = await showBackCheckDialog(context) ?? false;
      if (context.mounted && shouldPop) {
        Navigator.pop(context);
      }
    },
    child: child,
  );
}

class EditPostPage extends StatelessWidget {
  const EditPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    // final postController = Get.find<PostController>();
    final args = Get.arguments;
    final PostDataItem? post = args?[0];

    if (post == null) {
      return withPopAlert(
        context,
        Scaffold(
          appBar: AppBar(title: Text('new_post'.tr)),
          body: const PostEditor(postItem: null),
        ),
      );
    }
    return withPopAlert(
      context,
      Scaffold(
        appBar: AppBar(title: Text('edit_post'.trParams({'postName': post.body.title}))),
        body: PostEditor(postItem: post),
      ),
    );
  }
}

class EditRepoPage extends StatelessWidget {
  const EditRepoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final RepoDataItem? repo = args?[0];
    if (repo == null) {
      return withPopAlert(
        context,
        Scaffold(
          appBar: AppBar(title: Text('new_repo'.tr)),
          body: RepoEditor(repoItem: null),
        ),
      );
    }
    return withPopAlert(
      context,
      Scaffold(
        appBar: AppBar(title: Text('edit_repo'.trParams({'repoName': repo.body.name}))),
        body: RepoEditor(repoItem: repo),
      ),
    );
  }
}
