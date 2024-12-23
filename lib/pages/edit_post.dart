import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/post_editor.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/utils/utils.dart';

class EditPostPage extends StatelessWidget {
  const EditPostPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    final postController = Get.find<PostController>();
    final args = Get.arguments;
    final String? postId = args?[0];

    if (postId == null) {
      return withPopAlert(
        context,
        Scaffold(
          appBar: AppBar(title: Text('new_post'.tr)),
          body: const PostEditor(post: null),
        ),
      );
    }

    return FutureBuilder(
      future: postController.getPostUnwrap(postId),
      builder: (context, postData) {
        if (!postData.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var post = postData.data!;
        return withPopAlert(
          context,
          Scaffold(
            appBar: AppBar(
                title: Text('edit_post'.trParams({'postName': post.title}))),
            body: PostEditor(post: post),
          ),
        );
      },
    );
  }
}
