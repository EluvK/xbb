import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/controller/setting.dart';
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
  final settingController = Get.find<SettingController>();

  String _moreEditButtonId = "";
  String _moreContentButtonId = "";

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      var viewPost = postController.postListView;
      print("build post card post number: ${viewPost.length}");
      // for (var p in viewPost) {
      //   print("${p.id}, ${p.author}, ${p.title}, ${p.category}");
      // }
      return viewPost.isNotEmpty
          ? postsView(viewPost)
          : ListView(
              children: const [Center(child: Text('no post'))],
            );
    });
  }

  Widget postsView(List<Post> viewPosts) {
    final colorScheme = Theme.of(context).colorScheme;

    // for every post.category, create a expansion tile
    final Map<String, List<Post>> categorizedPosts = {};
    for (var post in viewPosts) {
      categorizedPosts.putIfAbsent(post.category, () => []).add(post);
    }

    return ListView(
      children: categorizedPosts.entries.map((entry) {
        return ExpansionTile(
          backgroundColor: colorScheme.surface,
          collapsedBackgroundColor: colorScheme.onSurface.withOpacity(0.05),
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
          childrenPadding: const EdgeInsets.only(bottom: 8.0),
          title: Text(entry.key),
          controlAffinity: ListTileControlAffinity.leading,
          children: entry.value
              .map((post) => Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 0.0, 0.0, 10.0),
                    child: postCard(post),
                  ))
              .toList(),
        );
      }).toList(),
    );
  }

  Widget postCard(Post post) {
    final colorScheme = Theme.of(context).colorScheme;

    var statusIcon = switch (post.status) {
      PostStatus.normal =>
        Icon(Icons.brightness_1_rounded, color: Colors.grey[400], size: 16.0),
      PostStatus.updated =>
        Icon(Icons.brightness_1_rounded, color: Colors.green[400], size: 16.0),
      PostStatus.newly =>
        Icon(Icons.brightness_1_rounded, color: Colors.red[400], size: 16.0),
    };

    var likeIcon = switch (post.selfAttitude) {
      PostSelfAttitude.none =>
        const Icon(Icons.star, color: Colors.transparent, size: 16.0),
      PostSelfAttitude.like =>
        Icon(Icons.star_rounded, color: Colors.yellow[400], size: 16.0),
      PostSelfAttitude.dislike =>
        Icon(Icons.thumb_down_rounded, color: Colors.grey[400], size: 16.0),
    };

    Widget postListTile = ListTile(
      onTap: () => {
        Get.toNamed('/view-post', arguments: [
          post.id,
          post.author == settingController.currentUserId.value
        ]),
      },
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [statusIcon, likeIcon],
      ),
      onLongPress: () {
        _moreContentButtonId = (_moreContentButtonId == post.id) ? "" : post.id;
        if (_moreContentButtonId == post.id && _moreEditButtonId == post.id) {
          _moreEditButtonId = "";
        }
        setState(() {});
      },
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          post.title,
          // style: const TextStyle(fontWeight: FontWeight.w100),
          textScaler: const TextScaler.linear(1.3),
        ),
      ),
      subtitle: Text(
        "updated at ${dateStr(post.updatedAt)}",
        textScaler: const TextScaler.linear(0.9),
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // IconButton(
          //   onPressed: () {
          //     _moreContentButtonId =
          //         (_moreContentButtonId == post.id) ? "" : post.id;
          //     if (_moreContentButtonId == post.id &&
          //         _moreEditButtonId == post.id) {
          //       _moreEditButtonId = "";
          //     }
          //     setState(() {});
          //   },
          //   icon: Icon(
          //       color: colorScheme.primary,
          //       post.id == _moreContentButtonId
          //           ? Icons.expand_less
          //           : Icons.expand_more),
          // ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text(
          post.content.length <= 365
              ? post.content
              : '${post.content.substring(0, 365)}...',
          textScaler: const TextScaler.linear(1.0),
        ),
      );
      // } else {
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
              postController.deletePost(post);
            },
            firstClickHint: '双击删除',
          ),
        ],
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          postListTile,
          Visibility(visible: moreContent != null, child: const Divider()),
          Visibility(
              visible: moreContent != null, child: moreContent ?? Container()),
        ],
      ),
    );
  }
}
