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
      print("viewPost: $viewPost");
      return viewPost.isNotEmpty ? postView(viewPost) : const Text('no post');
    });
  }

  Widget postView(List<Post> viewPosts) {
    return Column(children: [
      const Divider(),
      Expanded(
        child: ListView.builder(
          itemCount: viewPosts.length,
          itemBuilder: (context, index) {
            return postCard(viewPosts[index]);
          },
        ),
      ),
    ]);
  }

  Widget postCard(Post post) {
    return Card(
      child: ListTile(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(post.title),
              IconButton(
                  onPressed: () {
                    postController.deletePost(post.id);
                  },
                  icon: const Icon(Icons.delete))
            ],
          ),
        ),
        // subtitle: Text(post.content),
      ),
    );
  }
}
