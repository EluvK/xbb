// todo this file contents current markdown post rendering and comment rendering.
// while comment is only used in notes module, so we should move it inside accordingly.
// but markdown rendering is more general, so we keep it here.
// thus we may need to split this file into two parts later, but how to organize the comment parameter passing?

// contains classes
// - NewMarkdownRenderer
// - ParagraphWrapper
//  - CommentInputTrigger
//  - SharedCommentInput
//  - CommentTree
// - CommentUIController

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:markdown_widget/markdown_widget.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/utils.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/utils/code_wrapper.dart';
import 'package:xbb/utils/double_click.dart';
import 'package:xbb/utils/latex.dart';
import 'package:xbb/utils/markdown.dart';
import 'package:xbb/utils/utils.dart';

class NewMarkdownRenderer extends StatelessWidget {
  final String postId;
  final String data;
  final List<CommentDataItem> comments;

  const NewMarkdownRenderer({super.key, required this.postId, required this.data, this.comments = const []});

  @override
  Widget build(BuildContext context) {
    // todo? should move outside?
    final _ = Get.put(CommentUIController());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    codeWrapper(child, text, language) => CodeWrapperWidget(child, text, language);

    // noted: hand write `MarkdownGenerator` parsing to get nodes, thus we can map comments to paragraphs
    // final generator = MarkdownGenerator(inlineSyntaxList: [LatexSyntax()], generators: [latexGenerator]);
    // final List<Widget> contents = generator.buildWidgets(data, config: config);
    final config = (isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig).copy(
      configs: [
        isDark ? PreConfig.darkConfig.copy(wrapper: codeWrapper) : const PreConfig().copy(wrapper: codeWrapper),
      ],
    );

    List<_ParagraphData> paragraphList = [];

    final WidgetVisitor visitor = WidgetVisitor(config: config, generators: [latexGenerator]);
    final nodes = md.Document(
      extensionSet: md.ExtensionSet.gitHubWeb,
      inlineSyntaxes: [LatexSyntax()],
    ).parseLines(data.split(WidgetVisitor.defaultSplitRegExp));
    final spans = visitor.visit(nodes);
    // the length of nodes and spans should be equal
    // print("nodes length: ${nodes.length}, spans length: ${spans.length}");
    spans.asMap().forEach((index, span) {
      final richText = Text.rich(span.build());
      final node = nodes[index];
      final bool canHaveComments =
          node is md.Element && (node.tag == 'p' || node.tag == 'blockquote' || node.tag == 'pre');
      if (!canHaveComments) {
        print("[skip] node tag: ${node is md.Element ? node.tag : 'Not Element'}, index: $index");
      }
      final rawText = node.textContent;
      final id = rawText.hashCode.toString(); // todo better fingerprint
      print(
        "[build] paragraph id: $id, index: $index, canHaveComments: $canHaveComments}, rawText: ${rawText.replaceAll('\n', ' ').substring(0, rawText.length > 10 ? 10 : rawText.length)}",
      );
      paragraphList.add(_ParagraphData(id: id, widget: richText, rawText: rawText, canHaveComments: canHaveComments));
    });

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...paragraphList.asMap().entries.map((entry) {
            // print("[data] ${entry.value.id} => ${entry.value.rawText}");
            // todo find the corresponding comment for this entry
            // then wrap it together
            final id = entry.value.canHaveComments ? entry.value.id : null;
            final List<CommentDataItem> subComments = entry.value.canHaveComments
                ? comments.where((element) => element.body.paragraphId == entry.value.id).toList()
                : [];
            return ParagraphWrapper(
              id: id,
              postId: postId,
              content: entry.value.widget,
              comments: subComments,
              enableCommentFeature: entry.value.canHaveComments,
            );
          }),
        ],
      ),
    );
  }
}

class _ParagraphData {
  final String id; // fingerprint id
  final Widget widget;
  final String rawText;
  final bool canHaveComments;

  _ParagraphData({required this.id, required this.widget, required this.rawText, required this.canHaveComments});
}

class ParagraphWrapper extends StatelessWidget {
  final String? id; // we need to identify paragraph for comment mapping
  final String postId;
  final Widget content;
  final List<CommentDataItem> comments;
  final bool enableCommentFeature;
  const ParagraphWrapper({
    super.key,
    required this.id,
    required this.postId,
    required this.content,
    required this.comments,
    required this.enableCommentFeature,
  });

  @override
  Widget build(BuildContext context) {
    final CommentUIController commentUIController = Get.find<CommentUIController>();
    return Padding(
      // some as linesMargin in `MarkdownGenerator` markdown_generator.dart
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          content,
          Obx(() {
            final mode = commentUIController.currentMode.value;
            final activeId = commentUIController.activeParagraphId.value;
            if (!enableCommentFeature) return const SizedBox.shrink();
            final bool isAddingComment = (mode != CommentMode.none && activeId == (id ?? ''));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isAddingComment) SharedCommentInput(postId: postId, paragraphId: id),
                if (comments.isNotEmpty) CommentTree(paragraphId: id, comments: comments),
                if (!isAddingComment) CommentInputTrigger(paragraphId: id),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class CommentInputTrigger extends StatefulWidget {
  // final VoidCallback? onTap;
  final String? paragraphId;
  const CommentInputTrigger({super.key, this.paragraphId});

  @override
  State<CommentInputTrigger> createState() => _CommentInputTriggerState();
}

class _CommentInputTriggerState extends State<CommentInputTrigger> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // todo detect platform?
    bool isMobile =
        Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.android;
    // isMobile = true;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.paragraphId != null
            ? () {
                final commentUIController = Get.find<CommentUIController>();
                commentUIController.setController(mode: CommentMode.addComment, paragraphId: widget.paragraphId);
              }
            : null,
        behavior: HitTestBehavior.opaque,
        // 使用 SizedBox 固定高度，防止出现和消失时撑开/压缩外部布局
        child: SizedBox(
          height: 32, // 固定高度，确保布局稳定
          child: AnimatedOpacity(
            opacity: _isHovering ? 1.0 : (isMobile ? 0.2 : 0.0),
            duration: const Duration(milliseconds: 200),
            child: Row(
              children: [
                Expanded(child: Container(height: 0.5, color: Colors.grey.shade300)),
                const SizedBox(width: 8),
                _buildTriggerButton(isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTriggerButton(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Icon(Icons.add_comment_outlined, size: 14, color: Colors.grey.shade600),
          if (_isHovering || isMobile) ...[
            const SizedBox(width: 4),
            Text("评论", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }
}

enum CommentMode { none, addComment, replyComment, editComment }

class CommentUIController extends GetxController {
  final editController = TextEditingController();
  final focusNode = FocusNode();

  var currentMode = CommentMode.none.obs;
  var activeParagraphId = ''.obs;
  var activeCommentId = ''.obs;
  var activeCommentParentId = ''.obs; // when edit a comment, we may need it's parent id
  var activeLabel = 'New comment...'.obs;

  String _userDraft = "";

  void setController({
    required CommentMode mode,
    String? paragraphId,
    String? commentId,
    String? commentParentId,
    String? initialText,
    String? label,
  }) {
    print(
      "[CommentUIController] setController mode: $mode, paragraphId: $paragraphId, commentId: $commentId, initialText: ${initialText != null ? initialText.substring(0, initialText.length > 10 ? 10 : initialText.length) : 'null'}",
    );
    if (currentMode.value == CommentMode.addComment || currentMode.value == CommentMode.replyComment) {
      _userDraft = editController.text;
    }
    currentMode.value = mode;
    activeParagraphId.value = paragraphId ?? '';
    activeCommentId.value = commentId ?? '';
    activeCommentParentId.value = commentParentId ?? '';
    activeLabel.value = label ?? 'New comment...';

    if (mode == CommentMode.editComment && initialText != null) {
      editController.text = initialText;
    } else if (mode == CommentMode.addComment || mode == CommentMode.replyComment) {
      editController.text = _userDraft;
    }

    Future.delayed(const Duration(milliseconds: 100), () => focusNode.requestFocus());
  }

  void cancel() {
    currentMode.value = CommentMode.none;
    activeParagraphId.value = '';
    activeCommentId.value = '';
    activeCommentParentId.value = '';
  }

  @override
  void onClose() {
    editController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}

class SharedCommentInput extends StatelessWidget {
  final String postId;
  final String? paragraphId;
  const SharedCommentInput({super.key, required this.postId, this.paragraphId});

  @override
  Widget build(BuildContext context) {
    final commentUIController = Get.find<CommentUIController>();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(13),
        border: Border.all(color: Colors.blue.withAlpha(77)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Obx(() {
            return TextField(
              controller: commentUIController.editController,
              focusNode: commentUIController.focusNode,
              maxLines: null,
              decoration: InputDecoration(
                labelText: commentUIController.activeLabel.value,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            );
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => commentUIController.cancel(), child: const Text("取消")),
              ElevatedButton(
                onPressed: () {
                  sendComment(commentUIController.editController.text);
                  commentUIController.cancel();
                },
                child: const Text("发送"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void sendComment(String text) {
    final CommentController commentController = Get.find<CommentController>();
    final CommentUIController commentUIController = Get.find<CommentUIController>();

    switch (commentUIController.currentMode.value) {
      case CommentMode.addComment:
        commentController.addData(
          Comment(
            content: text,
            postId: postId,
            parentId: null,
            paragraphId: commentUIController.activeParagraphId.value,
          ),
        );
      case CommentMode.replyComment:
        commentController.addData(
          Comment(
            content: text,
            postId: postId,
            parentId: commentUIController.activeCommentId.value,
            paragraphId: commentUIController.activeParagraphId.value,
          ),
        );
      case CommentMode.editComment:
        assert(commentUIController.activeCommentId.value.isNotEmpty);
        commentController.updateData(
          commentUIController.activeCommentId.value,
          Comment(
            content: text,
            postId: postId,
            parentId: commentUIController.activeCommentParentId.value.isNotEmpty
                ? commentUIController.activeCommentParentId.value
                : null,
            paragraphId: commentUIController.activeParagraphId.value,
          ),
        );
      case CommentMode.none:
        assert(false); // should not happen
      // do nothing
    }
  }
}

class CommentTree extends StatelessWidget {
  final String? paragraphId;
  final List<CommentDataItem> comments;

  const CommentTree({super.key, required this.paragraphId, required this.comments});

  // 构建评论树
  Map<String, List<CommentDataItem>> _buildCommentDataTree(List<CommentDataItem> comments) {
    final Map<String, List<CommentDataItem>> commentMap = {};

    for (CommentDataItem comment in comments) {
      final parentId = comment.body.parentId ?? 'root'; // 根评论的 parentId 为 'root'
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
        children: rootComments.map((comment) => _buildCommentWidget(context, comment, commentMap, 0)).toList(),
      ),
    );
  }

  // 递归渲染评论树
  Widget _buildCommentWidget(
    BuildContext context,
    CommentDataItem comment,
    Map<String, List<CommentDataItem>> commentMap,
    int level,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 当前评论
        Padding(
          padding: EdgeInsets.only(left: 16.0 * level), // 根据层级缩进
          child: commentCard(context, comment),
        ),
        // 递归渲染子评论
        if (commentMap.containsKey(comment.id))
          ...commentMap[comment.id]!.map((child) => _buildCommentWidget(context, child, commentMap, level + 1)),
      ],
    );
  }

  Widget commentCard(BuildContext context, CommentDataItem comment) {
    return Obx(() {
      final CommentUIController commentUIController = Get.find<CommentUIController>();
      final shouldHighlight = commentUIController.activeCommentId.value == comment.id;
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        shadowColor: shouldHighlight ? Colors.lightBlue : null,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: shouldHighlight ? Colors.lightBlue.withAlpha(180) : Colors.grey.withAlpha(50),
            width: shouldHighlight ? 1.5 : 1.2,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 横向拉伸
            children: [
              commentAuthor(context, comment),
              MarkdownRenderer(data: comment.body.content),
            ],
          ),
        ),
      );
    });
  }

  Widget commentAuthor(BuildContext context, CommentDataItem comment) {
    final UserManagerController userManagerController = Get.find<UserManagerController>();
    final UserProfile userProfile = userManagerController.selfProfile.value?.userId == comment.owner
        ? userManagerController.selfProfile.value!
        : userManagerController.getUserProfile(comment.owner) ??
              UserProfile(userId: comment.owner, name: 'Unknown User', avatarUrl: '', publicKey: '');
    final CommentUIController commentUIController = Get.find<CommentUIController>();
    final CommentController commentController = Get.find<CommentController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            buildUserAvatar(context, userProfile.avatarUrl, size: 16, selected: true),
            const SizedBox(width: 12.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userProfile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  // `updatedAt == createdAt` is not accurate as updated is written by server
                  comment.updatedAt.subtract(const Duration(seconds: 1)).isBefore(comment.createdAt)
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
                commentUIController.setController(
                  mode: CommentMode.replyComment,
                  paragraphId: paragraphId,
                  commentId: comment.id,
                  label:
                      'Reply to ${userProfile.name}\'s `${comment.body.content.length > 6 ? '${comment.body.content.substring(0, 6)}...' : comment.body.content}`',
                );
              },
              icon: const Icon(Icons.reply_rounded),
              tooltip: 'reply'.tr,
            ),
            // todo add permission check visibility
            IconButton(
              onPressed: () {
                commentUIController.setController(
                  mode: CommentMode.editComment,
                  paragraphId: paragraphId,
                  commentId: comment.id,
                  initialText: comment.body.content,
                  label: 'Edit comment...',
                );
              },
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'edit'.tr,
            ),
            // todo add permission check visibility
            DoubleClickButton(
              buttonBuilder: (onPressed) =>
                  IconButton(onPressed: onPressed, icon: const Icon(Icons.delete_rounded), tooltip: 'delete'.tr),
              onDoubleClick: () {
                commentController.deleteData(comment.id);
              },
              firstClickHint: 'delete_comment'.tr,
              upperPosition: true,
            ),
          ],
        ),
      ],
    );
  }
}
