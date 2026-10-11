import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/notes/markdown_renderer.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/presentation/notes/comment_widgets.dart';
import 'package:xbb/presentation/notes/markdown_editor_toolbar.dart';
import 'package:xbb/presentation/notes/notes_providers.dart';
import 'package:xbb/presentation/notes/repo_acl_dialog.dart';
import 'package:xbb/presentation/notes/repo_quick_switcher.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';
import 'package:xbb/sync/v2/uuid_service.dart';
import 'package:xbb/utils/color_picker.dart';
import 'package:xbb/utils/translation.dart';

class ModernNotesView extends ConsumerStatefulWidget {
  const ModernNotesView({super.key});

  @override
  ConsumerState<ModernNotesView> createState() => _ModernNotesViewState();
}

class _ModernNotesViewState extends ConsumerState<ModernNotesView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isEditing = false;
  String _searchKeyword = '';
  DataItem<Comment>? _replyToComment;
  bool _myReposExpanded = true;
  bool _subscribedReposExpanded = true;
  bool _isAllCategoriesExpanded = true;
  final Map<String, bool> _expandedCategories = {};

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment(
    String content,
    String? parentId,
    String postId,
    String userId, {
    int? paragraphIndex,
    String? paragraphHash,
  }) async {
    final newId = UuidService.v7();
    final now = DateTime.now();
    final commentItem = DataItem<Comment>(
      newId,
      now,
      now,
      userId,
      postId,
      null,
      body: Comment(
        content: content,
        postId: postId,
        parentId: parentId,
        paragraphIndex: paragraphIndex,
        paragraphHash: paragraphHash,
      ),
      syncStatus: SyncStatus.pending,
    );
    await ref.read(notesRepositoryProvider).addComment(commentItem);
  }

  void _deleteComment(String commentId) {
    ref.read(notesRepositoryProvider).deleteComment(commentId);
  }

  void _saveCurrentPost(DataItem<Post> post) {
    final updated = post.updatedBody(
      post.body.copyWith(
        title: _titleController.text.trim().isEmpty ? 'notes_untitled'.tr : _titleController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? 'notes_default_category'.tr : _categoryController.text.trim(),
        content: _contentController.text,
      ),
    );
    ref.read(notesRepositoryProvider).savePost(updated);
    setState(() => _isEditing = false);
  }

  void _createNewPost(String repoId, String userId) {
    final newId = UuidService.v7();
    final now = DateTime.now();
    final defaultCat = _categoryController.text.trim().isNotEmpty
        ? _categoryController.text.trim()
        : 'notes_default_category'.tr;
    final newPost = DataItem<Post>(
      newId,
      now,
      now,
      userId,
      repoId,
      null,
      body: Post(
        title: 'notes_new_note_title'.tr,
        category: defaultCat,
        content: 'notes_new_note_content'.tr,
        repoId: repoId,
      ),
      syncStatus: SyncStatus.pending,
    );
    ref.read(notesRepositoryProvider).savePost(newPost);
    ref.read(selectedPostIdProvider.notifier).state = newId;
    _titleController.text = 'notes_new_note_title'.tr;
    _categoryController.text = defaultCat;
    _contentController.text = 'notes_new_note_content'.tr;
    setState(() => _isEditing = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postsAsync = ref.watch(postsStreamProvider);
    final currentPostAsync = ref.watch(currentPostStreamProvider);
    final selectedRepoId = ref.watch(selectedRepoIdProvider);
    final selectedPostId = ref.watch(selectedPostIdProvider);
    final userId = ref.watch(authProvider).userId;

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Row(
        children: [
          // 栏 1: 笔记本列表 (仅在桌面端或无选中文章时展开)
          if (isDesktop)
            SizedBox(
              width: 220,
              child: _buildRepoSidebar(selectedRepoId, userId),
            ),
          if (isDesktop) const VerticalDivider(width: 1),

          // 栏 2: 文章列表
          SizedBox(
            width: isDesktop ? 300 : (selectedPostId == null ? width : 0),
            child: selectedPostId == null || isDesktop
                ? _buildPostList(postsAsync, selectedRepoId, selectedPostId, userId)
                : const SizedBox.shrink(),
          ),
          if (isDesktop) const VerticalDivider(width: 1),

          // 栏 3: 正文预览与沉浸编辑
          Expanded(
            child: selectedPostId == null && !isDesktop
                ? const SizedBox.shrink()
                : _buildPostDetail(currentPostAsync, isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildRepoSidebar(
    String? selectedRepoId,
    String userId,
  ) {
    final theme = Theme.of(context);
    final myReposAsync = ref.watch(myReposStreamProvider);
    final subscribedReposAsync = ref.watch(subscribedReposStreamProvider);

    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'home_bar_title_notes'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.link, size: 20),
                      tooltip: 'subscribe_repo_btn'.tr,
                      onPressed: () => _showSubscribeRepoDialog(userId),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      tooltip: 'new_repo'.tr,
                      onPressed: () => _showCreateRepoDialog(userId),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              children: [
                // 卡片 1: 我的小本本
                _buildAccordionSection(
                  title: 'notes_my_repos_title'.tr,
                  icon: Icons.folder_outlined,
                  color: theme.colorScheme.primary,
                  isExpanded: _myReposExpanded,
                  onToggle: () => setState(() => _myReposExpanded = !_myReposExpanded),
                  asyncData: myReposAsync,
                  selectedRepoId: selectedRepoId,
                  emptyText: 'my_repos'.tr,
                ),
                const SizedBox(height: AppSpacing.sm),
                // 卡片 2: 订阅的小本本
                _buildAccordionSection(
                  title: 'notes_subscribed_repos_title'.tr,
                  icon: Icons.share_outlined,
                  color: theme.colorScheme.secondary,
                  isExpanded: _subscribedReposExpanded,
                  onToggle: () => setState(() => _subscribedReposExpanded = !_subscribedReposExpanded),
                  asyncData: subscribedReposAsync,
                  selectedRepoId: selectedRepoId,
                  emptyText: 'subscribe_repos'.tr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccordionSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required VoidCallback onToggle,
    required AsyncValue<List<DataItem<Repo>>> asyncData,
    required String? selectedRepoId,
    required String emptyText,
  }) {
    final theme = Theme.of(context);
    final count = asyncData.value?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6.0),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '$title ($count)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          asyncData.when(
            data: (repos) {
              if (repos.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  child: Text(emptyText, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                );
              }
              return Column(
                children: repos.map((repo) {
                  final isSelected = repo.id == selectedRepoId;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: ModernCard(
                      selected: isSelected,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      onTap: () {
                        ref.read(selectedRepoIdProvider.notifier).state = repo.id;
                        ref.read(selectedPostIdProvider.notifier).state = null;
                      },
                      child: Row(
                        children: [
                          if (repo.colorTag != ColorTag.none) ...[
                            Icon(Icons.brightness_1_rounded, color: repo.colorTag.toColor(), size: 10),
                            const SizedBox(width: AppSpacing.xs),
                          ],
                          Icon(icon, size: 16, color: color),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              repo.body.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined, size: 15),
                            tooltip: '协作与分享',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                            onPressed: () {
                              RepoAclDialog.show(
                                context,
                                repoId: repo.id,
                                repoName: repo.body.name,
                                ownerId: repo.owner,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('加载失败: $e', style: const TextStyle(fontSize: 11, color: Colors.red)),
            ),
          ),
      ],
    );
  }

  Widget _buildPostList(
    AsyncValue<List<DataItem<Post>>> postsAsync,
    String? selectedRepoId,
    String? selectedPostId,
    String userId,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  const RepoQuickSwitcher(),
                  const Spacer(),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add, size: 18),
                    tooltip: '新建文章',
                    onPressed: selectedRepoId == null ? null : () => _createNewPost(selectedRepoId, userId),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: ModernSearchField(
                      controller: _searchController,
                      hintText: '搜索文章...',
                      onChanged: (v) => setState(() => _searchKeyword = v.trim().toLowerCase()),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(_isAllCategoriesExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded, size: 20),
                    tooltip: _isAllCategoriesExpanded ? '全部收起' : '全部展开',
                    onPressed: () {
                      final posts = postsAsync.value ?? [];
                      final categories = posts.map((p) => p.body.category.trim().isEmpty ? 'notes_default_category'.tr : p.body.category.trim()).toSet();
                      setState(() {
                        _isAllCategoriesExpanded = !_isAllCategoriesExpanded;
                        for (final cat in categories) {
                          _expandedCategories[cat] = _isAllCategoriesExpanded;
                        }
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: postsAsync.when(
            data: (posts) {
              final filtered = _searchKeyword.isEmpty
                  ? posts
                  : posts.where((p) {
                      final kw = _searchKeyword;
                      return p.body.title.toLowerCase().contains(kw) ||
                          p.body.content.toLowerCase().contains(kw) ||
                          p.body.category.toLowerCase().contains(kw);
                    }).toList();

              if (filtered.isEmpty) {
                return const ModernEmptyState(
                  icon: Icons.article_outlined,
                  title: '没有文章',
                  subtitle: '点击上方 “+” 开始写下新文章',
                );
              }

              // 按 Category 分类分组
              final Map<String, List<DataItem<Post>>> groupedByCategory = {};
              for (final post in filtered) {
                final cat = post.body.category.trim().isEmpty ? 'notes_default_category'.tr : post.body.category.trim();
                groupedByCategory.putIfAbsent(cat, () => []).add(post);
              }

              final categories = groupedByCategory.keys.toList();

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.sm),
                itemCount: categories.length,
                itemBuilder: (context, catIndex) {
                  final category = categories[catIndex];
                  final categoryPosts = groupedByCategory[category]!;
                  final isExpanded = _expandedCategories[category] ?? true;
                  final hasUnread = categoryPosts.any((p) => p.syncStatus != SyncStatus.archived);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 分类折叠栏头部
                        InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          onTap: () {
                            setState(() {
                              _expandedCategories[category] = !isExpanded;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 6.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 15,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '$category (${categoryPosts.length})',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (hasUnread) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (hasUnread)
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    iconSize: 16,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                    tooltip: '全部标为已读',
                                    icon: const Icon(Icons.mark_email_read_outlined),
                                    onPressed: () {
                                      ref.read(notesRepositoryProvider).markPostsAsArchived(categoryPosts.map((p) => p.id).toList());
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('已将【$category】下的文章全部标为已读'), duration: const Duration(seconds: 1)),
                                      );
                                    },
                                  ),
                                Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  size: 16,
                                  color: theme.colorScheme.outline,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded)
                          ...categoryPosts.map((post) {
                            final isSelected = post.id == selectedPostId;
                            final isPostUnread = post.syncStatus != SyncStatus.archived;
                            return Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.xs),
                              child: ModernCard(
                                selected: isSelected,
                                onLongPress: () {
                                  final previewText = post.body.content.length <= 300
                                      ? post.body.content
                                      : '${post.body.content.substring(0, 300)}...';
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Row(
                                        children: [
                                          Icon(Icons.preview_rounded, size: 20, color: theme.colorScheme.primary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              post.body.title,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: SingleChildScrollView(
                                        child: Text(previewText, style: const TextStyle(fontSize: 13, height: 1.5)),
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
                                        FilledButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            ref.read(selectedPostIdProvider.notifier).state = post.id;
                                          },
                                          child: const Text('打开阅读'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onTap: () {
                                  ref.read(selectedPostIdProvider.notifier).state = post.id;
                                  _titleController.text = post.body.title;
                                  _categoryController.text = post.body.category;
                                  _contentController.text = post.body.content;
                                  setState(() {
                                    _isEditing = false;
                                    _replyToComment = null;
                                  });
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (post.colorTag != ColorTag.none) ...[
                                          Icon(Icons.brightness_1_rounded, color: post.colorTag.toColor(), size: 10),
                                          const SizedBox(width: AppSpacing.xs),
                                        ],
                                        Expanded(
                                          child: Text(
                                            post.body.title,
                                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isPostUnread) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      post.body.content.replaceAll(RegExp(r'[#*`\n]'), ' '),
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('错误: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildPostDetail(AsyncValue<DataItem<Post>?> currentPostAsync, bool isDesktop) {
    final theme = Theme.of(context);
    return currentPostAsync.when(
      data: (post) {
        if (post == null) {
          return const ModernEmptyState(
            icon: Icons.edit_note_rounded,
            title: '未选择文章',
            subtitle: '在左侧列表中点击选择文章以阅读或编辑',
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: !isDesktop
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => ref.read(selectedPostIdProvider.notifier).state = null,
                  )
                : null,
            title: _isEditing
                ? TextField(
                    controller: _titleController,
                    style: theme.textTheme.titleMedium,
                    decoration: const InputDecoration(border: InputBorder.none, hintText: '文章标题'),
                  )
                : Text(post.body.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            actions: [
              PaletteColorPickerButton(
                selectedTag: post.colorTag,
                onSelected: (newTag) {
                  ref.read(notesRepositoryProvider).updatePostColorTag(post.id, newTag);
                },
              ),
              IconButton(
                tooltip: '笔记本协作与分享',
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  final repos = ref.read(reposStreamProvider).value ?? [];
                  final repo = repos.where((r) => r.id == post.body.repoId).firstOrNull;
                  RepoAclDialog.show(
                    context,
                    repoId: post.body.repoId,
                    repoName: repo?.body.name ?? '笔记本',
                    ownerId: repo?.owner ?? post.owner,
                  );
                },
              ),
              IconButton(
                tooltip: _isEditing ? '完成' : '编辑',
                icon: Icon(_isEditing ? Icons.check : Icons.edit_outlined),
                onPressed: () {
                  if (_isEditing) {
                    _saveCurrentPost(post);
                  } else {
                    _titleController.text = post.body.title;
                    _contentController.text = post.body.content;
                    setState(() => _isEditing = true);
                  }
                },
              ),
              IconButton(
                tooltip: '删除',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('删除笔记'),
                      content: Text('确认删除笔记 "${post.body.title}" 吗？'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    ref.read(notesRepositoryProvider).deletePost(post.id);
                    ref.read(selectedPostIdProvider.notifier).state = null;
                  }
                },
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          body: _isEditing
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.folder_outlined, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: TextField(
                              controller: _categoryController,
                              style: theme.textTheme.bodySmall,
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'notes_category_hint'.tr,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: MarkdownEditorToolbar(
                        controller: _contentController,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '输入 Markdown 内容...',
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Consumer(
                  builder: (context, ref, _) {
                    final commentsAsync = ref.watch(commentsStreamProvider(post.id));
                    final userId = ref.watch(authProvider).userId;

                    return ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        if (post.body.category.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Row(
                              children: [
                                Icon(Icons.folder_outlined, size: 14, color: theme.colorScheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  post.body.category,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        commentsAsync.when(
                          data: (comments) => MarkdownWithComments(
                            data: post.body.content,
                            postId: post.id,
                            repoOwnedId: post.owner,
                            comments: comments,
                            currentUserId: userId,
                            onAddComment: (content, parentId, {paragraphIndex, paragraphHash}) => _submitComment(
                              content,
                              parentId,
                              post.id,
                              userId,
                              paragraphIndex: paragraphIndex,
                              paragraphHash: paragraphHash,
                            ),
                            onReplyComment: (comment) => setState(() => _replyToComment = comment),
                            onDeleteComment: (commentId) => _deleteComment(commentId),
                          ),
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (e, _) => Center(child: Text('加载评论失败: $e')),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CommentInputWidget(
                          replyToComment: _replyToComment,
                          onCancelReply: () => setState(() => _replyToComment = null),
                          onSubmit: (content, parentId) async {
                            await _submitComment(content, parentId, post.id, userId);
                          },
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    );
                  },
                ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('错误: $e')),
    );
  }

  void _showSubscribeRepoDialog(String userId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('subscribe_repo_dialog_title'.tr),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: 'subscribe_repo_dialog_hint'.tr,
            hintText: 'xbb-share://ownerId/repoId',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
          FilledButton(
            onPressed: () async {
              final link = ctrl.text.trim();
              if (link.isNotEmpty) {
                try {
                  await ref.read(notesRepositoryProvider).subscribeRepoByShareLink(link);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('subscribe_repo_success'.tr)),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                    );
                  }
                }
              }
            },
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  void _showCreateRepoDialog(String userId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建笔记本'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: '笔记本名称')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                final now = DateTime.now();
                final newRepo = DataItem<Repo>(
                  UuidService.v7(),
                  now,
                  now,
                  userId,
                  null,
                  null,
                  body: Repo(name: ctrl.text.trim(), status: 'active'),
                  syncStatus: SyncStatus.pending,
                );
                ref.read(notesRepositoryProvider).saveRepo(newRepo);
              }
              Navigator.pop(ctx);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}
