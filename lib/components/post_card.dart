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

  String _moreEditButtonId = "";
  String _moreContentButtonId = "";

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var viewPost = postController.postListView;
      print("viewPost: $viewPost");
      return viewPost.isNotEmpty ? postsView(viewPost) : const Text('no post');
    });
  }

  Widget postsView(List<Post> viewPosts) {
    // for every post.category, create a expansion tile
    final Map<String, List<Post>> categorizedPosts = {};

    for (var post in viewPosts) {
      categorizedPosts.putIfAbsent(post.category, () => []).add(post);
    }

    return ListView(
      children: categorizedPosts.entries.map((entry) {
        return ExpansionTile(
          initiallyExpanded: true,
          title: Text(
            entry.key.isNotEmpty ? entry.key : "Uncategorized",
            style: const TextStyle(fontWeight: FontWeight.w300),
            textScaler: const TextScaler.linear(1.4),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          children: entry.value
              .map((post) => Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: postCard(post),
                  ))
              .toList(),
        );
      }).toList(),
    );
  }

  Widget postCard(Post post) {
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
              _moreContentButtonId =
                  (_moreContentButtonId == post.id) ? "" : post.id;
              if (_moreContentButtonId == post.id &&
                  _moreEditButtonId == post.id) {
                _moreEditButtonId = "";
              }
              setState(() {});
            },
            icon: Icon(
                color: colorScheme.primary,
                post.id == _moreContentButtonId
                    ? Icons.expand_less
                    : Icons.expand_more),
          ),
          IconButton(
            onPressed: () {
              _moreEditButtonId = (_moreEditButtonId == post.id) ? "" : post.id;
              if (_moreContentButtonId == post.id &&
                  _moreEditButtonId == post.id) {
                _moreContentButtonId = "";
              }
              setState(() {});
            },
            icon: Icon(color: colorScheme.primary, Icons.more_horiz),
          ),
        ],
      ),
    );

    Widget? moreContent;
    if (post.id == _moreContentButtonId) {
      moreContent = Container(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          post.content,
          textScaler: const TextScaler.linear(1.0),
        ),
      );
    }
    if (post.id == _moreEditButtonId) {
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
