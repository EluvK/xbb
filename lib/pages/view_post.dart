import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/post_viewer.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/model/post.dart';

class ViewPostPage extends StatelessWidget {
  const ViewPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final Post post = args[0];
    final settingController = Get.find<SettingController>();
    // todo
    bool editable = (post.author == settingController.currentUserId.value);
    return Scaffold(
      appBar: AppBar(
        title: Text('view_post'.trParams({"postName": post.title})),
        actions: [
          Visibility(
            visible: editable,
            child: IconButton(
              onPressed: () {
                Get.toNamed('/edit-post', arguments: [post.id]);
              },
              icon: const Icon(Icons.edit),
            ),
          ),
        ],
      ),
      body: PostViewer(postId: post.id),
    );
  }
}
