import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/comment.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/model/comment.dart';
import 'package:xbb/utils/double_click.dart';
import 'package:xbb/utils/markdown.dart';
import 'package:xbb/utils/utils.dart';

class PostComment extends StatefulWidget {
  const PostComment({super.key, required this.repoId, required this.postId});
  final String repoId;
  final String postId;

  @override
  State<PostComment> createState() => _PostCommentState();
}

class _PostCommentState extends State<PostComment> {
  final commentController = Get.find<CommentController>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Comment>>(
      future: commentController.loadComments(widget.repoId, widget.postId),
      builder: (context, AsyncSnapshot<List<Comment>> getComments) {
        if (getComments.hasData) {
          return PostCommentInner(
            comments: getComments.data!,
            repoId: widget.repoId,
            postId: widget.postId,
          );
        } else {
          return const SizedBox(
            width: 50,
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}

class PostCommentInner extends StatefulWidget {
  const PostCommentInner(
      {super.key,
      required this.comments,
      required this.repoId,
      required this.postId});
  final List<Comment> comments;
  final String repoId;
  final String postId;
  @override
  State<PostCommentInner> createState() => _PostCommentInnerState();
}

class _PostCommentInnerState extends State<PostCommentInner> {
  late List<Comment> comments;
  final commentController = Get.find<CommentController>();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textControllerFocusNode = FocusNode();
  final TextEditingController _editController =
      TextEditingController(); // 用于编辑评论
  final FocusNode _editControllerFocusNode = FocusNode();
  String? _editingCommentId; // 当前正在编辑的评论 ID
  bool _isEditing = false; // 是否处于编辑模式
  String? _isReplyingToCommentId; // 回复的评论 ID

  @override
  void initState() {
    comments = widget.comments;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var inputComment = TextField(
      minLines: 1,
      maxLines: 5,
      controller: _textController,
      focusNode: _textControllerFocusNode,
      decoration: InputDecoration(
        labelText: _isReplyingToCommentId != null
            ? 'reply_comment'.trParams({'id': _isReplyingToCommentId!})
            : 'new_comment'.tr,
        prefixIcon: _isReplyingToCommentId != null
            ? IconButton(
                icon: const Icon(Icons.reply_rounded),
                tooltip: 'cancel_reply'.tr,
                onPressed: () {
                  setState(() {
                    _isReplyingToCommentId = null;
                  });
                },
              )
            : null,
        suffixIcon: IconButton(
          icon: const Icon(Icons.send_rounded),
          onPressed: () async {
            if (_textController.text.isNotEmpty) {
              var comment = (_isReplyingToCommentId != null)
                  ? await commentController.replyComment(
                      widget.repoId,
                      widget.postId,
                      _textController.text,
                      _isReplyingToCommentId!)
                  : await commentController.addNewComment(
                      widget.repoId,
                      widget.postId,
                      _textController.text,
                    );
              if (comment != null) {
                _textController.clear();
                setState(() {
                  _isReplyingToCommentId = null;
                  comments.add(comment);
                }); // 刷新评论列表
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
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text('comment_list'.tr),
              ),
            ),
            inputComment,
            const Divider(),
            CommentTree(
              comments: comments,
              isEditing: _isEditing,
              editingCommentId: _editingCommentId,
              replyingToCommentId: _isReplyingToCommentId,
              onEdit: (comment) {
                setState(() {
                  _isEditing = true;
                  _editingCommentId = comment.id;
                  _editController.text = comment.content;
                  _editControllerFocusNode.requestFocus();
                });
              },
              onSave: (commentId, newContent) async {
                final updatedComment = await commentController.editExistComment(
                  widget.repoId,
                  widget.postId,
                  commentId,
                  newContent,
                );
                if (updatedComment != null) {
                  setState(() {
                    _isEditing = false;
                    _editingCommentId = null;
                    comments = comments
                        .map((c) => c.id == commentId ? updatedComment : c)
                        .toList();
                  });
                }
              },
              onCancel: () {
                setState(() {
                  _isEditing = false;
                  _editingCommentId = null;
                });
              },
              onDelete: (comment) async {
                var success = await commentController.deleteExistComment(
                    comment.repoId, comment.postId, comment.id);
                if (success) {
                  setState(() {
                    comments =
                        comments.where((c) => c.id != comment.id).toList();
                  });
                }
              },
              onReply: (comment) {
                setState(() {
                  _isReplyingToCommentId = comment.id;
                  _textControllerFocusNode.requestFocus();
                });
              },
              editController: _editController,
              editControllerFocusNode: _editControllerFocusNode,
            ),
          ],
        ),
      ),
    );
  }
}

class CommentTree extends StatelessWidget {
  final List<Comment> comments;
  final bool isEditing;
  final String? editingCommentId;
  final String? replyingToCommentId;
  final Function(Comment) onEdit;
  final Function(String commentId, String newContent) onSave;
  final Function() onCancel;
  final Function(Comment) onDelete;
  final Function(Comment) onReply;
  final TextEditingController editController;
  final FocusNode editControllerFocusNode;

  const CommentTree({
    super.key,
    required this.comments,
    required this.isEditing,
    required this.editingCommentId,
    required this.replyingToCommentId,
    required this.onEdit,
    required this.onSave,
    required this.onCancel,
    required this.onDelete,
    required this.onReply,
    required this.editController,
    required this.editControllerFocusNode,
  });

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
          child: commentCard(comment),
        ),
        // 递归渲染子评论
        if (commentMap.containsKey(comment.id))
          ...commentMap[comment.id]!.map(
              (child) => _buildCommentWidget(child, commentMap, level + 1)),
      ],
    );
  }

  Widget commentCard(Comment comment) {
    final isCurrentEditing = isEditing && editingCommentId == comment.id;
    final isReplying = replyingToCommentId == comment.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shadowColor: isReplying ? Colors.lightBlue : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isReplying
              ? Colors.lightBlue.withOpacity(0.8)
              : Colors.grey.withOpacity(0.2),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // 横向拉伸
          children: [
            commentAuthor(comment),
            if (isCurrentEditing)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: editController,
                      focusNode: editControllerFocusNode,
                      maxLines: 15,
                      minLines: 1,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: onCancel,
                        child: Text(
                          'cancel'.tr,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          onSave(comment.id, editController.text);
                        },
                        child: Text('save'.tr),
                      ),
                    ],
                  ),
                ],
              )
            else
              MarkdownRenderer(data: comment.content),
          ],
        ),
      ),
    );
  }

  Widget commentAuthor(Comment comment) {
    final userController = Get.find<UserController>();
    final user = userController.getUserInfoLocalUnwrap(comment.author);
    final settingController = Get.find<SettingController>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(user.avatarUrl),
                radius: 16.0,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  // `updatedAt == createdAt` is not accurate as updated is written by server
                  comment.updatedAt
                          .subtract(const Duration(seconds: 1))
                          .isBefore(comment.createdAt)
                      ? readableDateStr(comment.createdAt)
                      : "${readableDateStr(comment.createdAt)}, edited at ${readableDateStr(comment.updatedAt)}",
                  style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                onReply(comment);
              },
              icon: const Icon(Icons.reply_rounded),
              tooltip: 'reply'.tr,
            ),
            Visibility(
              visible: settingController.currentUserId.value == comment.author,
              child: IconButton(
                onPressed: isEditing
                    ? null
                    : () {
                        onEdit(comment);
                      },
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'edit'.tr,
              ),
            ),
            Visibility(
              visible: settingController.currentUserId.value == comment.author,
              child: DoubleClickButton(
                buttonBuilder: (onPressed) => IconButton(
                  onPressed: isEditing ? null : onPressed,
                  icon: const Icon(Icons.delete_rounded),
                  tooltip: 'delete'.tr,
                ),
                onDoubleClick: () {
                  onDelete(comment);
                },
                firstClickHint: 'delete_comment'.tr,
                upperPosition: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
