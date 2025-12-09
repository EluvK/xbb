import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/notes/post_viewer.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/models/notes/model.dart';

class ViewPostPage extends StatelessWidget {
  const ViewPostPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final PostDataItem post = args[0];
    final settingController = Get.find<SettingController>();
    bool editable = (post.owner == settingController.currentUserId.value);
    // todo
    editable = true;
    return Scaffold(
      appBar: AppBar(
        title: Text('view_post'.trParams({"postName": post.body.title})),
        actions: [
          Visibility(
            visible: editable,
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
