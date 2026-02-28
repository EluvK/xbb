import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:markdown_widget/markdown_widget.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/common/permission.dart';
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
  final String repoOwnedId;
  final List<Permission> permissions;

  const MarkdownWithComments({
    super.key,
    required this.data,
    required this.postId,
    required this.repoOwnedId,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    codeWrapper(child, text, language) => CodeWrapperWidget(child, text, language);
    final config = (isDark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig).copy(
      configs: [
        isDark ? PreConfig.darkConfig.copy(wrapper: codeWrapper) : const PreConfig().copy(wrapper: codeWrapper),
      ],
    );
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

      final hash = TextSimilarityHasher.computeSimHash(rawText);
      print(
        "[build] paragraph hash: $hash, index: $index, canHaveComments: $canHaveComments}, rawText: ${rawText.replaceAll('\n', ' ').substring(0, rawText.length > 10 ? 10 : rawText.length)}",
      );
      paragraphList.add(_ParagraphData(index, hash, richText, rawText, canHaveComments));
    });

    // must init CommentUIController before building UI
    final _ = Get.put(
      CommentUIController(
        postId: postId,
        repoOwnedId: repoOwnedId,
        paragraphHashes: paragraphList.map((e) => e.hash.toString()).toList(),
        permissions: permissions,
      ),
    );
    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...paragraphList.map((p) => _ParagraphWrapper(p, postId)),
          PostEndCommentWrapper(postId: postId),
        ],
      ),
    );
  }
}

class _ParagraphData {
  final int index;
  final int hash;
  final Widget widget;
  final String rawText;
  final bool canHaveComments;

  _ParagraphData(this.index, this.hash, this.widget, this.rawText, this.canHaveComments);
}

class _ParagraphWrapper extends StatelessWidget {
  final _ParagraphData data;
  final String postId;
  const _ParagraphWrapper(this.data, this.postId);

  @override
  Widget build(BuildContext context) {
    final pid = paragraphId(data.index, data.hash.toString());
    return Padding(
      // some as linesMargin in `MarkdownGenerator` markdown_generator.dart
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          data.widget,
          if (data.canHaveComments) ...[
            GetBuilder<CommentUIController>(
              id: "unmatched_${data.hash}",
              builder: (controller) {
                final unmatchedEntry = controller.commentsUnmatched[data.hash.toString()];
                if (unmatchedEntry == null) {
                  return const SizedBox.shrink();
                }
                final comments = unmatchedEntry.$1;
                final originalHash = unmatchedEntry.$2;
                final distance = unmatchedEntry.$3;
                print(
                  "[render unmatched] paragraph id: $pid, originalHash: $originalHash, distance: $distance, comments length: ${comments.length}",
                );
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(10),
                    border: Border.all(color: Colors.red.withAlpha(50)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8, // 水平间距
                        runSpacing: 4, // 垂直间距（如果换行）
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red.shade400),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  "这些评论似乎是属于这个段落的（相似度：${similarityFromDistance(distance)}），但原始段落已被修改。",
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton.icon(
                                onPressed: () => controller.migrateComments(
                                  comments: comments,
                                  targetPid: pid, // pid 是当前段落的 ID
                                ),
                                icon: const Icon(Icons.auto_fix_high, size: 14),
                                label: const Text("修正到此段"),
                                // style: TextButton.styleFrom(foregroundColor: Colors.blue),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: () => controller.migrateComments(
                                  comments: comments,
                                  targetPid: null, // 迁移为文末普通评论
                                ),
                                icon: const Icon(Icons.arrow_downward, size: 14),
                                label: const Text("转为通用评论"),
                                // style: TextButton.styleFrom(foregroundColor: Colors.blue),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      CommentTree(paragraphId: pid, comments: comments),
                    ],
                  ),
                );
              },
            ),
            GetBuilder<CommentUIController>(
              id: pid,
              builder: (controller) {
                final comments = controller.commentsMap[pid] ?? [];
                bool isAddingComment =
                    (controller.currentMode.value != CommentMode.none && controller.activeParagraphId.value == pid);
                return Column(
                  children: [
                    isAddingComment
                        ? SharedCommentInput(postId: postId, paragraphId: pid)
                        : CommentInputTriggerInline(paragraphId: pid),
                    if (comments.isNotEmpty) CommentTree(paragraphId: pid, comments: comments),
                  ],
                );
              },
            ),
          ] else
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
    final commentUIController = Get.find<CommentUIController>();
    return Column(
      children: [
        Text("—— End of Post ——", style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 10),
        GetBuilder<CommentUIController>(
          id: 'no_close_match',
          builder: (controller) {
            final entry = controller.commentsUnmatched[null];
            if (entry == null || entry.$1.isEmpty) return const SizedBox.shrink();

            final comments = entry.$1;
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withAlpha(15), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Expanded(child: Text("以下评论所属段落已消失或改动过大")),
                      FilledButton.icon(
                        onPressed: () => controller.migrateComments(
                          comments: comments,
                          targetPid: null, // 迁移为文末普通评论
                        ),
                        label: const Text("转为通用评论"),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                    ],
                  ),
                  CommentTree(paragraphId: null, comments: comments),
                  const Divider(),
                ],
              ),
            );
          },
        ),
        GetBuilder<CommentUIController>(
          id: 'post_end',
          builder: (controller) {
            final comments = controller.commentsMap[null] ?? [];
            bool isAddingComment =
                (controller.currentMode.value != CommentMode.none && controller.activeParagraphId.value == null);
            Widget newCommitInputWidget = isAddingComment
                ? SharedCommentInput(postId: postId, paragraphId: null)
                : ElevatedButton.icon(
                    onPressed: () {
                      commentUIController.setController(
                        mode: CommentMode.addComment,
                        paragraphId: null,
                        label: 'New comment...',
                      );
                    },
                    label: const Text("写条新评论~", style: TextStyle(fontSize: 14)),
                    icon: const Icon(Icons.add_comment_outlined, size: 14),
                  );
            return Column(
              children: [
                commentUIController.canNewComment ? newCommitInputWidget : const SizedBox.shrink(),
                const SizedBox(height: 10),
                const Divider(),
                if (comments.isNotEmpty) CommentTree(paragraphId: null, comments: comments),
              ],
            );
          },
        ),
      ],
    );
  }
}

class CommentInputTriggerInline extends StatefulWidget {
  // final VoidCallback? onTap;
  final String paragraphId;
  const CommentInputTriggerInline({super.key, required this.paragraphId});

  @override
  State<CommentInputTriggerInline> createState() => _CommentInputTriggerInlineState();
}

class _CommentInputTriggerInlineState extends State<CommentInputTriggerInline> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    bool isMob = isMobile(); // 假设你已有此判断函数

    // 逻辑修正：
    // 1. 如果是移动端，透明度常驻为 0.4 (或你希望的低透明度)
    // 2. 如果是桌面端，根据悬停状态在 0.0 到 1.0 之间切换
    double targetOpacity;
    if (isMob) {
      targetOpacity = 0.4;
    } else {
      targetOpacity = _isHovering ? 1.0 : 0.0;
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
        message: 'Add comment to paragraph ${widget.paragraphId}',
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

String paragraphId(int index, String hash) => "${index}_$hash";

String similarityFromDistance(int distance) {
  if (distance >= 64) return "0%";
  double similarity = (64 - distance) / 64;
  return "${(similarity * 100).toStringAsFixed(2)}%";
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
  final String repoOwnedId;
  final List<String> paragraphHashes;
  final List<Permission> permissions;
  CommentUIController({
    required this.postId,
    required this.repoOwnedId,
    required this.paragraphHashes,
    required this.permissions,
  });

  var currentMode = CommentMode.none.obs;
  // use the optional string to make code more clear
  // null means no relevant paragraph/comment
  var activeParagraphId = Rxn<String>();
  var activeCommentId = Rxn<String>();
  var activeCommentParentId = Rxn<String>(); // when edit a comment, we may need it's parent id
  var activeLabel = 'New comment...'.obs;

  String _userDraft = "";

  var commentsMap = <String?, List<CommentDataItem>>{};
  // Key: 当前文章中存在的 paragraphHash (closestHash)
  // Value: List 包含 (评论列表, 原始评论中的错误cHash, 距离)
  var commentsUnmatched = <String?, (List<CommentDataItem> comments, String originalHash, int distance)>{};

  final CommentController commentController = Get.find<CommentController>();
  RxList<CommentDataItem> registeredComments = <CommentDataItem>[].obs;

  @override
  void dispose() {
    editController.dispose();
    focusNode.dispose();
    commentController.unregisterFilterSubscription('post_$postId');
    super.dispose();
  }

  late final bool canNewComment;
  Map<String, bool> canDeleteComment = {};
  Map<String, bool> canReplyComment = {};
  Map<String, bool> canEditComment = {};

  @override
  void onInit() {
    super.onInit();
    registeredComments = commentController.registerFilterSubscription(
      filterKey: 'post_$postId',
      filters: [ParentIdFilter(postId)],
    );
    print('debug: setInitialComments, comments length: ${registeredComments.length}');
    print('debug: repoOwnedId: $repoOwnedId, permissions: ${permissions.map((p) => p.accessLevel).toList()}');

    // new comment with ownerId would skip permission check, so just put a dummy id here
    canNewComment = oncePermissionCheck(NotesFeatureRequires.newComment, '', permissions, repoOwnedId);
    for (var o in registeredComments.map((c) => c.owner).toSet()) {
      canDeleteComment[o] = oncePermissionCheck(NotesFeatureRequires.deleteComment, o, permissions, repoOwnedId);
      canReplyComment[o] = oncePermissionCheck(NotesFeatureRequires.replyComment, o, permissions, repoOwnedId);
      canEditComment[o] = oncePermissionCheck(NotesFeatureRequires.editComment, o, permissions, repoOwnedId);
    }
    print(
      'debug: canNewComment: $canNewComment, canDeleteComment: $canDeleteComment, canReplyComment: $canReplyComment, canEditComment: $canEditComment',
    );

    var (map, unmatchedComments) = _updateComments(registeredComments);
    commentsMap = map;
    commentsUnmatched = unmatchedComments;

    debounce(registeredComments, (updatedComments) {
      print("debug: CommentUIController detected comment changes, try sync all");
      var (newMap, unmatchedComments) = _updateComments(updatedComments);

      final allPossibleKeys = <String?>{...commentsMap.keys, ...newMap.keys};
      // final allPossibleKeys = <String?>{...commentsMap.keys, ...newMap.keys};
      for (var key in allPossibleKeys) {
        if (!_areCommentListsEqual(newMap[key] ?? [], commentsMap[key] ?? [])) {
          commentsMap[key] = newMap[key] ?? [];
          print("精准刷新段落: ${key ?? 'post_end'}");
          update([key ?? 'post_end']);
        }
      }

      // 对于所有未匹配评论当前的吸附段落，直接整体刷新，因为数量通常不多
      final allUnmatchedKeys = <String?>{...commentsUnmatched.keys, ...unmatchedComments.keys}.toSet();
      commentsUnmatched = unmatchedComments;
      for (var key in allUnmatchedKeys) {
        if (key != null) {
          update(["unmatched_$key"]);
        } else {
          update(['no_close_match']);
        }
      }
      for (var o in updatedComments.map((c) => c.owner).toSet()) {
        canDeleteComment[o] = oncePermissionCheck(NotesFeatureRequires.deleteComment, o, permissions, repoOwnedId);
        canReplyComment[o] = oncePermissionCheck(NotesFeatureRequires.replyComment, o, permissions, repoOwnedId);
        canEditComment[o] = oncePermissionCheck(NotesFeatureRequires.editComment, o, permissions, repoOwnedId);
      }
    }, time: const Duration(milliseconds: 100));
  }

  _updateComments(List<CommentDataItem> allComments) {
    var newMap = <String?, List<CommentDataItem>>{};
    var newUnmatched = <String?, (List<CommentDataItem>, String, int)>{};

    for (var c in allComments) {
      final cIndex = c.body.paragraphIndex;
      final cHash = c.body.paragraphHash;

      if (cIndex != null && cHash != null) {
        if (paragraphHashes.contains(cHash)) {
          // here can't use cIndex to build pid directly,
          // because when new index is added, the old comments may need to remap to new pid
          // so we need to find this current index from paragraphHashes, rebuild pid
          final actualPid = paragraphId(paragraphHashes.indexOf(cHash), cHash);
          newMap.putIfAbsent(actualPid, () => []).add(c);
        } else {
          String closestHash = '';
          int closestDistance = 65;

          // 寻找最接近的当前段落
          for (var ph in paragraphHashes) {
            final distance = TextSimilarityHasher.getHammingDistance(int.parse(cHash), int.parse(ph));
            if (distance < closestDistance) {
              closestDistance = distance;
              closestHash = ph;
            }
          }

          if (closestHash.isNotEmpty && closestDistance <= 10) {
            if (!newUnmatched.containsKey(closestHash)) {
              newUnmatched[closestHash] = ([c], cHash, closestDistance);
            } else {
              final existing = newUnmatched[closestHash]!;
              newUnmatched[closestHash] = ([...existing.$1, c], existing.$2, existing.$3);
            }
          } else {
            // no close match found, put all to post end
            newUnmatched[null] = ([...(newUnmatched[null]?.$1 ?? []), c], cHash, closestDistance);
          }
        }
      } else {
        newMap.putIfAbsent(null, () => []).add(c);
      }
    }
    print("newMap keys: ${newMap.keys.toList()}");
    print("newUnmatched keys: ${newUnmatched.keys.toList()}");
    return (newMap, newUnmatched);
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

  void clearDraft() {
    _userDraft = "";
    editController.clear();
  }

  /// 批量迁移评论到指定段落
  /// [targetPid] 如果为 null，表示迁移到文章末尾
  Future<void> migrateComments({required List<CommentDataItem> comments, String? targetPid}) async {
    final CommentController commentController = Get.find<CommentController>();

    int? newIndex;
    String? newHash;

    if (targetPid != null) {
      final parts = targetPid.split('_');
      newIndex = int.tryParse(parts[0]);
      newHash = parts[1];
    }

    // 批量更新
    for (var c in comments) {
      // 保持原有内容，仅更新定位信息
      final updatedComment = Comment(
        content: c.body.content,
        postId: postId,
        parentId: c.body.parentId,
        paragraphIndex: newIndex,
        paragraphHash: newHash,
      );
      commentController.updateData(c.id, updatedComment);
    }

    flushBar(FlushLevel.OK, "迁移成功", "已将 ${comments.length} 条评论同步至 ${targetPid == null ? '文章末尾' : '新段落'}");
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
    int? paragraphIndex;
    String? paragraphHash;
    bool isUpdate = false;
    switch (commentUIController.currentMode.value) {
      case CommentMode.addComment:
        assert(commentUIController.activeCommentParentId.value == null);
        print("postid: $postId");
        parentId = null;
      case CommentMode.replyComment:
        parentId = commentUIController.activeCommentParentId.value;
      case CommentMode.editComment:
        assert(commentUIController.activeCommentId.value != null);
        parentId = commentUIController.activeCommentParentId.value;
        isUpdate = true;
      case CommentMode.none:
        assert(false); // should not happen
    }
    if (commentUIController.activeParagraphId.value != null) {
      final parts = commentUIController.activeParagraphId.value!.split('_');
      paragraphIndex = int.tryParse(parts[0]);
      paragraphHash = parts[1];
    }
    final comment = Comment(
      content: text,
      postId: postId,
      parentId: parentId,
      paragraphIndex: paragraphIndex,
      paragraphHash: paragraphHash,
    );
    if (isUpdate) {
      commentController.updateData(commentUIController.activeCommentId.value!, comment);
    } else {
      commentController.addData(comment);
    }
    commentUIController.clearDraft();
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
    comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final Set<String> allIds = comments.map((c) => c.id).toSet();
    final commentMap = _buildCommentDataTree(comments);
    final List<Widget> rootWidgets = [];
    for (var comment in comments) {
      final pId = comment.body.parentId;
      if (pId == null || pId == 'root') {
        rootWidgets.add(_buildCommentWidget(context, comment, commentMap, 0));
      } else if (!allIds.contains(pId)) {
        rootWidgets.add(_buildCommentWidget(context, comment, commentMap, 1, isOrphan: true));
      }
    }

    return Column(children: rootWidgets);
  }

  // 递归渲染评论树
  Widget _buildCommentWidget(
    BuildContext context,
    CommentDataItem comment,
    Map<String, List<CommentDataItem>> commentMap,
    int level, {
    bool isOrphan = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isOrphan)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  const Icon(Icons.link_off_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    "original_comment_unavailable".tr,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
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
    final CommentUIController commentUIController = Get.find<CommentUIController>();

    // todo it's not the same comments that updated...
    if (comment.syncStatus == SyncStatus.synced) {
      Future.delayed(const Duration(seconds: 3), () {
        print('[Auto-Archive] Comment ${comment.id} is now archived');
        // comment.syncStatus == SyncStatus.archived;
        Get.find<CommentController>().onUpdateLocalField(comment.id, syncStatus: SyncStatus.archived);
        Get.find<PostController>().rebuildLocal();
        // commentController.rebuildLocal();
      });
    }

    return Obx(() {
      final isEdit =
          commentUIController.currentMode.value == CommentMode.editComment &&
          commentUIController.activeCommentId.value == comment.id;
      final isReply =
          commentUIController.currentMode.value == CommentMode.replyComment &&
          commentUIController.activeCommentParentId.value == comment.id;
      final isNew = comment.syncStatus == SyncStatus.synced;
      Color borderColor = Colors.grey.withAlpha(50);
      double borderWidth = 1.2;
      Color shadowColor = Colors.transparent;
      if (isNew) {
        shadowColor = Colors.lightGreen.withAlpha(100);
        borderColor = Colors.lightGreen.withAlpha(180);
        borderWidth = 1.5;
      }
      if (isEdit || isReply) {
        shadowColor = Colors.lightBlue.withAlpha(100);
        borderColor = Colors.lightBlue.withAlpha(180);
        borderWidth = 1.5;
      }
      // todo animated container to smoothly transition between states
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        shadowColor: shadowColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor, width: borderWidth),
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
        Flexible(
          child: Row(
            children: [
              // Text(comment.syncStatus.toString()),
              // ElevatedButton(
              //   onPressed: () {
              //     commentController.onUpdateLocalField(comment.id, syncStatus: SyncStatus.synced);
              //     commentController.rebuildLocal();
              //   },
              //   child: Text('test'),
              // ),
              buildUserAvatar(context, userProfile.avatarUrl, size: 16, selected: true),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userProfile.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      // `updatedAt == createdAt` is not accurate as updated is written by server
                      comment.updatedAt.subtract(const Duration(seconds: 1)).isBefore(comment.createdAt)
                          ? readableDateStr(comment.createdAt)
                          : "${readableDateStr(comment.createdAt)}, edited at ${readableDateStr(comment.updatedAt)}",
                      style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            (commentUIController.canReplyComment[comment.owner] ?? false)
                ? IconButton(
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
                  )
                : const SizedBox.shrink(),

            (commentUIController.canEditComment[comment.owner] ?? false)
                ? IconButton(
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
                  )
                : const SizedBox.shrink(),
            (commentUIController.canDeleteComment[comment.owner] ?? false)
                ? DoubleClickButton(
                    buttonBuilder: (onPressed) =>
                        IconButton(onPressed: onPressed, icon: const Icon(Icons.delete_rounded), tooltip: 'delete'.tr),
                    onDoubleClick: () {
                      commentController.deleteData(comment.id);
                    },
                    firstClickHint: 'delete_comment'.tr,
                    upperPosition: true,
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }
}
