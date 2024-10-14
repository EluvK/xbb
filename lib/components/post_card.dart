import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/model/post.dart';
import 'package:xbb/utils/double_click.dart';
import 'package:xbb/utils/utils.dart';

class PostCard extends StatefulWidget {
  const PostCard({super.key});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final postController = Get.find<PostController>();

  int _moreEditButtonIndex = -1;
  int _moreContentButtonIndex = -1;

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
            return Card(
              child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: postCard(viewPosts[index], index)),
            );
          },
        ),
      ),
    ]);
  }

  Widget postCard(Post post, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget postCard = ListTile(
      onTap: () => {
        Get.toNamed('/view-post', arguments: [post.id]),
      },
      title: Text(
        post.title,
        style: const TextStyle(fontWeight: FontWeight.w100),
        textScaler: const TextScaler.linear(1.3),
      ),
      subtitle: Text(
        "updated at ${dateStr(post.updatedAt)}",
        textScaler: const TextScaler.linear(0.9),
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              _moreContentButtonIndex =
                  (_moreContentButtonIndex == index) ? -1 : index;
              if (_moreContentButtonIndex == index &&
                  _moreEditButtonIndex == index) {
                _moreEditButtonIndex = -1;
              }
              setState(() {});
            },
            icon: Icon(
                color: colorScheme.primary,
                index == _moreContentButtonIndex
                    ? Icons.expand_less
                    : Icons.expand_more),
          ),
          IconButton(
            onPressed: () {
              _moreEditButtonIndex =
                  (_moreEditButtonIndex == index) ? -1 : index;
              if (_moreContentButtonIndex == index &&
                  _moreEditButtonIndex == index) {
                _moreContentButtonIndex = -1;
              }
              setState(() {});
            },
            icon: Icon(color: colorScheme.primary, Icons.more_horiz),
          ),
        ],
      ),
    );

    Widget? moreContent;
    if (index == _moreContentButtonIndex) {
      moreContent = Container(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          post.content,
          textScaler: const TextScaler.linear(1.0),
        ),
      );
    }
    if (index == _moreEditButtonIndex) {
      moreContent = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () {
              Get.toNamed('/edit-post', arguments: [post.id]);
            },
            icon: const Icon(Icons.edit),
            tooltip: '编辑',
          ),
          DoubleClickButton(
            buttonBuilder: (onPressed) => IconButton(
              onPressed: onPressed,
              icon: const Icon(Icons.delete),
              tooltip: '删除',
            ),
            onDoubleClick: () {
              postController.deletePost(post.id);
            },
            firstClickHint: '双击删除',
          ),
        ],
      );
    }

    if (moreContent == null) {
      return postCard;
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [postCard, const Divider(), moreContent],
      );
    }
  }
}
