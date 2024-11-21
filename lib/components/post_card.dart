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
      // print("build post card post number: ${viewPost.length}");
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
                    padding: const EdgeInsets.fromLTRB(20.0, 0.0, 5.0, 10.0),
                    child: postCard(post),
                  ))
              .toList(),
        );
      }).toList(),
    );
  }

  Widget postCard(Post post) {
    final colorScheme = Theme.of(context).colorScheme;

    List<Icon> icons = [];
    switch (post.status) {
      case PostStatus.normal:
        break;
      case PostStatus.updated:
        icons.add(Icon(
          Icons.brightness_1_rounded,
          color: Colors.red[500],
          size: 16.0,
        ));
        break;
      case PostStatus.newly:
        icons.add(Icon(
          Icons.brightness_1_rounded,
          color: Colors.lightGreen[400],
          size: 16.0,
        ));
        break;
      case PostStatus.detached:
        icons.add(Icon(
          Icons.brightness_1_rounded,
          color: Colors.grey[400],
          size: 16.0,
        ));
        break;
      case PostStatus.notSynced:
        icons.add(Icon(
          Icons.sync_disabled_rounded,
          color: Colors.red[400],
          size: 16.0,
        ));
        break;
    }
    switch (post.selfAttitude) {
      case PostSelfAttitude.none:
        break;
      case PostSelfAttitude.like:
        icons.add(Icon(
          Icons.star_rounded,
          color: Colors.amber[400],
          size: 16.0,
        ));
        break;
      case PostSelfAttitude.dislike:
        icons.add(Icon(
          Icons.thumb_down_rounded,
          color: Colors.grey[400],
          size: 16.0,
        ));
        break;
    }

    Widget postListTile = ListTile(
      onTap: () {
        if (post.status == PostStatus.newly ||
            post.status == PostStatus.updated) {
          setState(() {
            post.status = PostStatus.normal;
          });
          postController.editLocalPostStatus(post);
        }
        Get.toNamed('/view-post', arguments: [
          post.id,
          post.author == settingController.currentUserId.value
        ]);
      },
      minLeadingWidth: 0,
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: icons,
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
          style: TextStyle(
            decoration: post.status == PostStatus.detached
                ? TextDecoration.lineThrough
                : null,
          ),
          textScaler: const TextScaler.linear(1.3),
        ),
      ),
      subtitle: Text(
        "updated at ${readableDateStr(post.updatedAt)}",
        textScaler: const TextScaler.linear(0.9),
        style: TextStyle(
          color: Colors.grey,
          decoration: post.status == PostStatus.detached
              ? TextDecoration.lineThrough
              : null,
        ),
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
      var editButton = IconButton(
        onPressed: () {
          Get.toNamed('/edit-post', arguments: [post.id]);
        },
        icon: const Icon(Icons.edit),
        tooltip: '编辑',
      );
      var deleteButton = DoubleClickButton(
        buttonBuilder: (onPressed) => IconButton(
          onPressed: onPressed,
          icon: const Icon(Icons.delete),
          tooltip: '删除',
        ),
        onDoubleClick: () {
          postController.deletePost(post);
        },
        firstClickHint: '双击删除',
      );
      var likeButton = IconButton(
        onPressed: () {
          setState(() {
            post.selfAttitude == PostSelfAttitude.like
                ? post.selfAttitude = PostSelfAttitude.none
                : post.selfAttitude = PostSelfAttitude.like;
          });
          postController.editLocalPostStatus(post);
        },
        icon: Icon(
          Icons.star_rounded,
          color: post.selfAttitude == PostSelfAttitude.like
              ? Colors.amber[400]
              : null,
        ),
        tooltip: '置顶',
      );
      var dislikeButton = IconButton(
        onPressed: () {
          setState(() {
            post.selfAttitude == PostSelfAttitude.dislike
                ? post.selfAttitude = PostSelfAttitude.none
                : post.selfAttitude = PostSelfAttitude.dislike;
          });
          postController.editLocalPostStatus(post);
        },
        icon: Icon(
          Icons.thumb_down_rounded,
          color: post.selfAttitude == PostSelfAttitude.dislike
              ? Colors.blue[400]
              : null,
        ),
        tooltip: '不关注',
      );
      var markUnreadButton = IconButton(
        onPressed: () {
          setState(() {
            if (post.status == PostStatus.normal) {
              post.status = PostStatus.updated;
            } else {
              post.status = PostStatus.normal;
            }
          });
          postController.editLocalPostStatus(post);
        },
        icon: post.status == PostStatus.normal
            ? const Icon(Icons.mark_email_unread_rounded)
            : const Icon(Icons.mark_email_read_rounded),
        tooltip: post.status == PostStatus.normal ? '标记未读' : '标记以读',
      );
      List<Widget> editButtonIcons = [];
      if (post.author == settingController.currentUserId.value) {
        editButtonIcons.addAll([editButton, likeButton, deleteButton]);
      } else {
        if (post.status == PostStatus.detached) {
          editButtonIcons.add(deleteButton);
        } else {
          editButtonIcons.add(markUnreadButton);
        }
        editButtonIcons.addAll([likeButton, dislikeButton]);
      }
      moreContent = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: editButtonIcons,
      );
    }

    return Card(
      shadowColor: post.status == PostStatus.newly
          ? Colors.lightGreen[400]
          : Colors.grey,
      elevation: post.status == PostStatus.newly ? 4.0 : 2.0,
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
