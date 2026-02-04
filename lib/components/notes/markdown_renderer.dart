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
import 'package:xbb/utils/text_similarity.dart';
import 'package:xbb/utils/utils.dart';

class SimpleMarkdownRenderer extends StatelessWidget {
  final String data;

  const SimpleMarkdownRenderer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final config = isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig;
    codeWrapper(child, text, language) => CodeWrapperWidget(child, text, language);
    return MarkdownBlock(
      data: data,
      generator: MarkdownGenerator(inlineSyntaxList: [LatexSyntax()], generators: [latexGenerator]),
      config: config.copy(
        configs: [
          isDark ? PreConfig.darkConfig.copy(wrapper: codeWrapper) : const PreConfig().copy(wrapper: codeWrapper),
        ],
      ),
    );
  }
}

class MarkdownWithComments extends StatelessWidget {
  final String data;
  final String postId;

  const MarkdownWithComments({super.key, required this.data, required this.postId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    codeWrapper(child, text, language) => CodeWrapperWidget(child, text, language);
    final config = (isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig).copy(
      configs: [
        isDark ? PreConfig.darkConfig.copy(wrapper: codeWrapper) : const PreConfig().copy(wrapper: codeWrapper),
      ],
    );

    // must init CommentUIController here
    final _ = Get.put(CommentUIController(postId: postId));
    return _buildMarkdownWithComments(context, config);
  }

  Widget _buildMarkdownWithComments(BuildContext context, MarkdownConfig config) {
    List<_ParagraphData> paragraphList = [];

    final md.Document document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false, // important.
      inlineSyntaxes: [LatexSyntax()],
    );
    final regExp = WidgetVisitor.defaultSplitRegExp;
    final List<String> lines = data.split(regExp);
    final List<md.Node> nodes = document.parseLines(lines);
    final WidgetVisitor visitor = WidgetVisitor(config: config, generators: [latexGenerator], splitRegExp: regExp);
    final List<SpanNode> spans = visitor.visit(nodes);
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

      // TODO the figerprint id generation should be more robust
      // for now, some rawText may generate same fingerprint, need to improve later
      // by adding a extra unique paragraph index?
      // will effect the matching logic later
      final id = TextSimilarityHasher.computeSimHash(rawText).toString();
      print(
        "[build] paragraph id: $id, index: $index, canHaveComments: $canHaveComments}, rawText: ${rawText.replaceAll('\n', ' ').substring(0, rawText.length > 10 ? 10 : rawText.length)}",
      );
      paragraphList.add(_ParagraphData(id: id, widget: richText, rawText: rawText, canHaveComments: canHaveComments));
    });

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...paragraphList.map(
            (p) => ParagraphWrapper(
              id: p.canHaveComments ? p.id : null,
              postId: postId,
              content: p.widget,
              enableCommentFeature: p.canHaveComments,
            ),
          ),
          PostEndCommentWrapper(postId: postId),
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
  final bool enableCommentFeature;
  const ParagraphWrapper({
    super.key,
    required this.id,
    required this.postId,
    required this.content,
    required this.enableCommentFeature,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // some as linesMargin in `MarkdownGenerator` markdown_generator.dart
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          content,
          if (enableCommentFeature && id != null)
            GetBuilder<CommentUIController>(
              id: id,
              builder: (controller) {
                final comments = controller.commentsMap[id] ?? [];
                bool isAddingComment =
                    (controller.currentMode.value != CommentMode.none && controller.activeParagraphId.value == id);
                return Column(
                  children: [
                    isAddingComment
                        ? SharedCommentInput(postId: postId, paragraphId: id)
                        : CommentInputTrigger(paragraphId: id),
                    if (comments.isNotEmpty) CommentTree(paragraphId: id, comments: comments),
                  ],
                );
              },
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class PostEndCommentWrapper extends StatelessWidget {
  final String postId;
  const PostEndCommentWrapper({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("—— End of Post ——", style: TextStyle(color: Colors.grey.shade500)),
        const Divider(),
        Text("Comments", style: TextStyle(color: Colors.grey.shade500)),
        GetBuilder<CommentUIController>(
          id: 'post_end',
          builder: (controller) {
            final comments = controller.commentsMap[null] ?? [];
            bool isAddingComment =
                (controller.currentMode.value != CommentMode.none && controller.activeParagraphId.value == null);
            return Column(
              children: [
                isAddingComment
                    ? SharedCommentInput(postId: postId, paragraphId: null)
                    : const CommentInputTrigger(paragraphId: null, alwaysShow: true),
                if (comments.isNotEmpty) CommentTree(paragraphId: null, comments: comments),
              ],
            );
          },
        ),
      ],
    );
  }
}

class CommentInputTrigger extends StatefulWidget {
  // final VoidCallback? onTap;
  final String? paragraphId;
  final bool alwaysShow;
  const CommentInputTrigger({super.key, this.paragraphId, this.alwaysShow = false});

  @override
  State<CommentInputTrigger> createState() => _CommentInputTriggerState();
}

class _CommentInputTriggerState extends State<CommentInputTrigger> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    bool isMob = isMobile(); // 假设你已有此判断函数

    // 逻辑修正：
    // 1. 如果是移动端，透明度常驻为 0.2 (或你希望的低透明度)
    // 2. 如果是桌面端，根据悬停状态在 0.0 到 1.0 之间切换
    double targetOpacity;
    if (isMob) {
      targetOpacity = 0.2;
    } else {
      targetOpacity = _isHovering ? 1.0 : 0.0;
    }
    if (widget.alwaysShow) {
      targetOpacity = 1.0;
    }

    final commentUIController = Get.find<CommentUIController>();
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () => commentUIController.setController(
          mode: CommentMode.addComment,
          paragraphId: widget.paragraphId,
          label: 'New comment...',
        ),
        behavior: HitTestBehavior.opaque,
        // 使用 SizedBox 固定高度，防止出现和消失时撑开/压缩外部布局
        child: SizedBox(
          height: 32, // 固定高度，确保布局稳定
          child: AnimatedOpacity(
            opacity: targetOpacity,
            duration: const Duration(milliseconds: 200),
            child: Row(
              children: [
                Expanded(child: Container(height: 0.5, color: Colors.grey.shade300)),
                const SizedBox(width: 8),
                _buildTriggerButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTriggerButton() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
      child: Tooltip(
        message: widget.paragraphId != null
            ? 'Add comment to paragraph ${widget.paragraphId}'
            : 'Add comment to post end',
        child: Row(
          children: [
            Icon(Icons.add_comment_outlined, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text("评论", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

/// Comment mode enum
/// none: no comment input active
/// addComment: adding new comment to paragraph or entire post
/// replyComment: replying to an existing comment
/// editComment: editing an existing comment
///
/// Mapping of parameters:
/// ? means optional (can be null)
/// * means required (not null)
/// - means not applicable (should be null)
///
/// |             | none | add | reply | edit |
/// | paragraphId |  -   |  ?  |  ?    |  ?   |
/// |  commentId  |  -   |  -  |  -    |  *   |
/// |  parentId   |  -   |  -  |  *    |  ?   |
enum CommentMode { none, addComment, replyComment, editComment }

class CommentUIController extends GetxController {
  final editController = TextEditingController();
  final focusNode = FocusNode();
  final String postId;
  CommentUIController({required this.postId});

  var currentMode = CommentMode.none.obs;
  // use the optional string to make code more clear
  // null means no relevant paragraph/comment
  var activeParagraphId = Rxn<String>();
  var activeCommentId = Rxn<String>();
  var activeCommentParentId = Rxn<String>(); // when edit a comment, we may need it's parent id
  var activeLabel = 'New comment...'.obs;

  String _userDraft = "";

  var commentsMap = <String?, List<CommentDataItem>>{};

  @override
  void onInit() {
    super.onInit();

    final CommentController commentController = Get.find<CommentController>();

    // init commentsMap by registering filtered stream
    final registeredComments = commentController.registerFilterSubscription(
      filterKey: 'post_$postId',
      filters: [ParentIdFilter(postId)],
    );
    print('debug: setInitialComments, comments length: ${registeredComments.length}');
    var map = <String?, List<CommentDataItem>>{};
    for (var c in registeredComments) {
      final pid = c.body.paragraphId;
      map.putIfAbsent(pid, () => []).add(c);
    }
    commentsMap = map;

    debounce(registeredComments, (updatedComments) {
      print("debug: CommentUIController detected comment changes, try sync all");
      var newMap = <String?, List<CommentDataItem>>{};
      for (var c in updatedComments) {
        final pid = c.body.paragraphId;
        newMap.putIfAbsent(pid, () => []).add(c);
      }

      final allPossibleKeys = <String?>{...commentsMap.keys, ...newMap.keys};

      for (var key in allPossibleKeys) {
        final newList = newMap[key] ?? [];
        final oldList = commentsMap[key] ?? [];
        if (!_areCommentListsEqual(newList, oldList)) {
          commentsMap[key] = newList;
          print("精准刷新段落: ${key ?? 'post_end'}");
          update([key ?? 'post_end']);
        }
      }
    }, time: const Duration(milliseconds: 100));
  }

  bool _areCommentListsEqual(List<CommentDataItem> list1, List<CommentDataItem> list2) {
    if (list1.length != list2.length) {
      return false;
    }
    list1.sort((a, b) => a.id.compareTo(b.id));
    list2.sort((a, b) => a.id.compareTo(b.id));
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id ||
          list1[i].updatedAt != list2[i].updatedAt ||
          list1[i].body.content != list2[i].body.content) {
        return false;
      }
    }
    return true;
  }

  void setController({
    required CommentMode mode,
    required String label,
    String? paragraphId,
    String? commentId,
    String? commentParentId,
    String? initialText,
  }) {
    // validate parameters
    if (mode == CommentMode.addComment) {
      assert(commentId == null);
      assert(commentParentId == null);
    } else if (mode == CommentMode.replyComment) {
      assert(commentId == null);
      assert(commentParentId != null);
    } else if (mode == CommentMode.editComment) {
      assert(commentId != null);
    }

    print(
      "[CommentUIController] setController mode: $mode, paragraphId: $paragraphId, commentId: $commentId, initialText: ${initialText != null ? initialText.substring(0, initialText.length > 10 ? 10 : initialText.length) : 'null'}",
    );
    if (currentMode.value == CommentMode.addComment || currentMode.value == CommentMode.replyComment) {
      _userDraft = editController.text;
    }
    currentMode.value = mode;
    final String? oldActiveParagraphId = activeParagraphId.value;
    activeParagraphId.value = paragraphId;
    activeCommentId.value = commentId;
    activeCommentParentId.value = commentParentId;
    activeLabel.value = label;

    if (mode == CommentMode.editComment && initialText != null) {
      editController.text = initialText;
    } else if (mode == CommentMode.addComment || mode == CommentMode.replyComment) {
      editController.text = _userDraft;
    }
    // tell GetX to update UI
    update([oldActiveParagraphId ?? 'post_end', paragraphId ?? 'post_end']);

    Future.delayed(const Duration(milliseconds: 100), () => focusNode.requestFocus());
  }

  void cancel() {
    final String oldActiveParagraphId = activeParagraphId.value ?? 'post_end';
    currentMode.value = CommentMode.none;
    activeParagraphId.value = '';
    activeCommentId.value = '';
    activeCommentParentId.value = '';
    update([oldActiveParagraphId]);
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
          TextField(
            controller: commentUIController.editController,
            focusNode: commentUIController.focusNode,
            maxLines: null,
            decoration: InputDecoration(
              labelText: commentUIController.activeLabel.value,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
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

    String? parentId;
    String? paragraphId;
    bool isUpdate = false;
    switch (commentUIController.currentMode.value) {
      case CommentMode.addComment:
        assert(commentUIController.activeCommentParentId.value == null);
        print("postid: $postId");
        parentId = null;
        paragraphId = commentUIController.activeParagraphId.value;
      case CommentMode.replyComment:
        parentId = commentUIController.activeCommentParentId.value;
        paragraphId = commentUIController.activeParagraphId.value;
      case CommentMode.editComment:
        assert(commentUIController.activeCommentId.value != null);
        parentId = commentUIController.activeCommentParentId.value;
        paragraphId = commentUIController.activeParagraphId.value;
        isUpdate = true;
      case CommentMode.none:
        assert(false); // should not happen
    }
    final comment = Comment(content: text, postId: postId, parentId: parentId, paragraphId: paragraphId);
    if (isUpdate) {
      commentController.updateData(commentUIController.activeCommentId.value!, comment);
    } else {
      commentController.addData(comment);
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

    return Column(
      children: rootComments.map((comment) => _buildCommentWidget(context, comment, commentMap, 0)).toList(),
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
              SimpleMarkdownRenderer(data: comment.body.content),
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
                  commentParentId: comment.id,
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
                  commentParentId: comment.body.parentId,
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
