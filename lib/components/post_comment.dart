import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/comment.dart';
import 'package:xbb/model/comment.dart';

class PostComment extends StatefulWidget {
  const PostComment({super.key, required this.repoId, required this.postId});
  final String repoId;
  final String postId;

  @override
  State<PostComment> createState() => _PostCommentState();
}

class _PostCommentState extends State<PostComment> {
  final commentController = Get.find<CommentController>();
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var commentTree = FutureBuilder<List<Comment>>(
      future: commentController.loadComments(widget.repoId, widget.postId),
      builder: (context, AsyncSnapshot<List<Comment>> getComments) {
        if (getComments.hasData) {
          return CommentTreeExample();
          // return CommentTree(
          //   comments: getComments.data!,
          // );
        } else {
          return const SizedBox(
            width: 50,
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );

    var inputComment = TextField(
      minLines: 1,
      maxLines: 5,
      controller: _textController,
      decoration: InputDecoration(
        hintText: 'Add a comment',
        suffixIcon: IconButton(
          icon: const Icon(Icons.send_rounded),
          onPressed: () async {
            if (_textController.text.isNotEmpty) {
              // todo
              var comment = await commentController.addNewComment(
                widget.repoId,
                widget.postId,
                _textController.text,
              );
              if (comment != null) {
                _textController.clear();
                setState(() {}); // 刷新评论列表
              }
            }
          },
        ),
      ),
    );

    return Center(
      child: SizedBox(
        width: 1200,
        child: Column(
          children: [
            const Center(child: Text('Comments')),
            inputComment,
            const Divider(),
            commentTree,
          ],
        ),
      ),
    );
  }
}

class CommentTree extends StatelessWidget {
  final List<Comment> comments;

  const CommentTree({super.key, required this.comments});

  // 构建评论树
  Map<String, List<Comment>> _buildCommentDataTree(List<Comment> comments) {
    final Map<String, List<Comment>> commentMap = {};

    for (var comment in comments) {
      final parentId = comment.parentId ?? 'root'; // 根评论的 parentId 为 'root'
      if (!commentMap.containsKey(parentId)) {
        commentMap[parentId] = [];
      }
      commentMap[parentId]!.add(comment);
    }

    return commentMap;
  }

  // 递归渲染评论树
  Widget _buildCommentWidget(
    Comment comment,
    Map<String, List<Comment>> commentMap,
    int level,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 当前评论
        Padding(
          padding: EdgeInsets.only(left: 16.0 * level), // 根据层级缩进
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // 横向拉伸
                children: [
                  Text(
                    comment.author,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4.0),
                  Text(comment.content),
                  const SizedBox(height: 4.0),
                  Text(
                    '${comment.createdAt}',
                    style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
        // 递归渲染子评论
        if (commentMap.containsKey(comment.id))
          ...commentMap[comment.id]!.map(
              (child) => _buildCommentWidget(child, commentMap, level + 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 按照时间排序，最新的在最上面
    comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 构建评论树
    final commentMap = _buildCommentDataTree(comments);

    // 渲染根评论（parentId 为 null 或 'root'）
    final rootComments = commentMap['root'] ?? [];

    return SingleChildScrollView(
      child: Column(
        children: rootComments
            .map((comment) => _buildCommentWidget(comment, commentMap, 0))
            .toList(),
      ),
    );
  }
}

// 使用示例
class CommentTreeExample extends StatelessWidget {
  final List<Comment> comments = [
    Comment(
      id: '1',
      repoId: 'repo1',
      postId: 'post1',
      content: 'This is the first comment. ',
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(Duration(hours: 2)),
      author: 'User1',
    ),
    Comment(
      id: '2',
      repoId: 'repo1',
      postId: 'post1',
      content: 'This is a reply to the first comment 2222222222222222222',
      createdAt: DateTime.now().subtract(Duration(hours: 1)),
      updatedAt: DateTime.now().subtract(Duration(hours: 1)),
      author: 'User2',
      parentId: '1',
    ),
    Comment(
      id: '3',
      repoId: 'repo1',
      postId: 'post1',
      content: 'This is another comment 333333333333333333333333333',
      createdAt: DateTime.now().subtract(Duration(hours: 3)),
      updatedAt: DateTime.now().subtract(Duration(hours: 3)),
      author: 'User3',
    ),
    Comment(
      id: '4',
      repoId: 'repo1',
      postId: 'post1',
      content:
          'This is a reply to the third comment 4444444444444444444444444333333333333333333333333333333333',
      createdAt: DateTime.now().subtract(Duration(minutes: 30)),
      updatedAt: DateTime.now().subtract(Duration(minutes: 30)),
      author: 'User4',
      parentId: '3',
    ),
    Comment(
      id: '5',
      repoId: 'repo1',
      postId: 'post1',
      content: 'This is a reply to the 2 comment 22222222222222222222222222',
      createdAt: DateTime.now().subtract(Duration(minutes: 200)),
      updatedAt: DateTime.now().subtract(Duration(minutes: 200)),
      author: 'User4',
      parentId: '2',
    ),
    Comment(
      id: '6',
      repoId: 'repo1',
      postId: 'post1',
      content: 'This is a now comment',
      createdAt: DateTime.now().subtract(Duration(minutes: 1)),
      updatedAt: DateTime.now().subtract(Duration(minutes: 1)),
      author: 'User4',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CommentTree(comments: comments);
  }
}
