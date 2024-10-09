import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/model/post.dart';

class PostCard extends StatefulWidget {
  const PostCard({super.key});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final postController = Get.find<PostController>();
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var viewPost = postController.postListView;
      return viewPost.isNotEmpty ? postView(viewPost) : const Placeholder();
    });
  }

  Widget postView(List<Post> viewPosts) {
    return ListView.builder(
      itemCount: viewPosts.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            title: Text(viewPosts[index].title),
            subtitle: Text(viewPosts[index].content),
          ),
        );
      },
    );
  }
}
