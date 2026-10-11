import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/presentation/notes/comment_widgets.dart';
import 'package:xbb/presentation/notes/notes_providers.dart';
import 'package:xbb/presentation/notes/repo_acl_dialog.dart';
import 'package:xbb/presentation/notes/repo_quick_switcher.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';
import 'package:xbb/sync/v2/uuid_service.dart';

class ModernNotesView extends ConsumerStatefulWidget {
  const ModernNotesView({super.key});

  @override
  ConsumerState<ModernNotesView> createState() => _ModernNotesViewState();
}

class _ModernNotesViewState extends ConsumerState<ModernNotesView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isEditing = false;
  String _searchKeyword = '';
  DataItem<Comment>? _replyToComment;
  bool _myReposExpanded = true;
  bool _subscribedReposExpanded = true;

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment(
    String content,
    String? parentId,
    String postId,
    String userId,
  ) async {
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
        title: _titleController.text.trim().isEmpty ? '无标题' : _titleController.text.trim(),
        content: _contentController.text,
      ),
    );
    ref.read(notesRepositoryProvider).savePost(updated);
    setState(() => _isEditing = false);
  }

  void _createNewPost(String repoId, String userId) {
    final newId = UuidService.v7();
    final now = DateTime.now();
    final newPost = DataItem<Post>(
      newId,
      now,
      now,
      userId,
      repoId,
      null,
      body: Post(
        title: '新建笔记',
        category: '默认',
        content: '# 新建笔记\n\n开始记录你的灵感...',
        repoId: repoId,
      ),
      syncStatus: SyncStatus.pending,
    );
    ref.read(notesRepositoryProvider).savePost(newPost);
    ref.read(selectedPostIdProvider.notifier).state = newId;
    _titleController.text = '新建笔记';
    _contentController.text = '# 新建笔记\n\n开始记录你的灵感...';
    setState(() => _isEditing = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reposAsync = ref.watch(reposStreamProvider);
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
                  '笔记本',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  tooltip: '新建笔记本',
                  onPressed: () => _showCreateRepoDialog(userId),
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
                  title: '我的小本本',
                  icon: Icons.folder_outlined,
                  color: theme.colorScheme.primary,
                  isExpanded: _myReposExpanded,
                  onToggle: () => setState(() => _myReposExpanded = !_myReposExpanded),
                  asyncData: myReposAsync,
                  selectedRepoId: selectedRepoId,
                  emptyText: '暂无自建笔记本',
                ),
                const SizedBox(height: AppSpacing.sm),
                // 卡片 2: 订阅的小本本
                _buildAccordionSection(
                  title: '订阅的小本本',
                  icon: Icons.share_outlined,
                  color: theme.colorScheme.secondary,
                  isExpanded: _subscribedReposExpanded,
                  onToggle: () => setState(() => _subscribedReposExpanded = !_subscribedReposExpanded),
                  asyncData: subscribedReposAsync,
                  selectedRepoId: selectedRepoId,
                  emptyText: '暂无订阅笔记本',
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
              ModernSearchField(
                controller: _searchController,
                hintText: '搜索文章...',
                onChanged: (v) => setState(() => _searchKeyword = v.trim().toLowerCase()),
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
                  : posts.where((p) => p.body.title.toLowerCase().contains(_searchKeyword)).toList();

              if (filtered.isEmpty) {
                return const ModernEmptyState(
                  icon: Icons.article_outlined,
                  title: '没有文章',
                  subtitle: '点击上方 “+” 开始写下新文章',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.sm),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final post = filtered[index];
                  final isSelected = post.id == selectedPostId;
                  return ModernCard(
                    selected: isSelected,
                    onTap: () {
                      ref.read(selectedPostIdProvider.notifier).state = post.id;
                      _titleController.text = post.body.title;
                      _contentController.text = post.body.content;
                      setState(() {
                        _isEditing = false;
                        _replyToComment = null;
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.body.title,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              ? Padding(
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
                )
              : Consumer(
                  builder: (context, ref, _) {
                    final commentsAsync = ref.watch(commentsStreamProvider(post.id));
                    final userId = ref.watch(authProvider).userId;

                    return ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        MarkdownWidget(
                          data: post.body.content,
                          shrinkWrap: true,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Row(
                            children: [
                              Icon(Icons.comment_outlined, size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '评论与讨论',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              commentsAsync.maybeWhen(
                                data: (comments) => Text(
                                  '${comments.length} 条评论',
                                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                                ),
                                orElse: () => const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                        commentsAsync.when(
                          data: (comments) => CommentListWidget(
                            postId: post.id,
                            comments: comments,
                            currentUserId: userId,
                            onReply: (comment) => setState(() => _replyToComment = comment),
                            onDelete: (commentId) => _deleteComment(commentId),
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
