import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/chat/model.dart';
import 'package:xbb/presentation/chat/chat_providers.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

class ModernChatView extends ConsumerStatefulWidget {
  const ModernChatView({super.key});

  @override
  ConsumerState<ModernChatView> createState() => _ModernChatViewState();
}

class _ModernChatViewState extends ConsumerState<ModernChatView> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(String convId, String userId) async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    _inputController.clear();
    setState(() => _isSending = true);

    final repo = ref.read(chatRepositoryProvider);
    // 保存用户消息
    await repo.saveMessage(
      conversationId: convId,
      role: ChatMessageRole.user,
      text: text,
      currentUserId: userId,
    );
    _scrollToBottom();

    // 模拟 DeepSeek-R1 思考过程与回答返回（生产环境可直接换接 deepseek_client）
    await Future.delayed(const Duration(milliseconds: 600));
    await repo.saveMessage(
      conversationId: convId,
      role: ChatMessageRole.assistant,
      text: '已收到你的问题："$text"。这是通过重构后现代架构流式生成的回答。',
      reasoningText: '思考过程：分析用户提出的具体需求，梳理对应上下文，验证架构约束并生成对应建议。',
      currentUserId: userId,
    );

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final convsAsync = ref.watch(chatConversationsStreamProvider);
    final messagesAsync = ref.watch(chatMessagesStreamProvider);
    final selectedConvId = ref.watch(selectedConversationIdProvider);
    final userId = ref.watch(authProvider).userId;

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('AI 助手对话', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: '新建对话',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () async {
              final repo = ref.read(chatRepositoryProvider);
              final assistantId = await repo.ensureDefaultAssistant(userId);
              final newConvId = await repo.createConversation(
                assistantId: assistantId,
                assistantName: '通用智能助理',
                currentUserId: userId,
              );
              ref.read(selectedConversationIdProvider.notifier).state = newConvId;
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Row(
        children: [
          // 会话侧边栏 (桌面端展开)
          if (isDesktop)
            SizedBox(
              width: 240,
              child: _buildConversationSidebar(convsAsync, selectedConvId),
            ),
          if (isDesktop) const VerticalDivider(width: 1),

          // 主对话流
          Expanded(
            child: selectedConvId == null
                ? const ModernEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: '未选择对话',
                    subtitle: '点击右上角 “+” 或在左侧选择会话开启智能交流',
                  )
                : Column(
                    children: [
                      Expanded(
                        child: messagesAsync.when(
                          data: (messages) {
                            if (messages.isEmpty) {
                              return const ModernEmptyState(
                                icon: Icons.auto_awesome_outlined,
                                title: '开始新的交谈',
                                subtitle: '输入任何问题、任务或想法，AI 将为你解答',
                              );
                            }
                            return ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              itemCount: messages.length,
                              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final msg = messages[index].body;
                                return _buildMessageBubble(msg);
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('加载失败: $e')),
                        ),
                      ),
                      // 底部输入栏
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLowest,
                          border: Border(
                            top: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(60)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _inputController,
                                onSubmitted: (_) => _handleSendMessage(selectedConvId, userId),
                                decoration: InputDecoration(
                                  hintText: '输入消息，支持 Markdown...',
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceContainerLow,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: AppRadius.roundedPill,
                                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(60)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: AppRadius.roundedPill,
                                    borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(60)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            IconButton.filled(
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.arrow_upward_rounded, size: 20),
                              onPressed: _isSending ? null : () => _handleSendMessage(selectedConvId, userId),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationSidebar(
    AsyncValue<List<dynamic>> convsAsync,
    String? selectedConvId,
  ) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerLowest,
      child: convsAsync.when(
        data: (convs) {
          if (convs.isEmpty) {
            return const Center(child: Text('暂无历史会话', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: convs.length,
            itemBuilder: (context, index) {
              final conv = convs[index];
              final isSelected = conv.id == selectedConvId;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: ModernCard(
                  selected: isSelected,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  onTap: () {
                    ref.read(selectedConversationIdProvider.notifier).state = conv.id;
                  },
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          conv.body.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16),
                        onPressed: () {
                          ref.read(chatRepositoryProvider).deleteConversation(conv.id);
                          if (isSelected) {
                            ref.read(selectedConversationIdProvider.notifier).state = null;
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final theme = Theme.of(context);
    final isUser = msg.role == ChatMessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.subtle(context),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DeepSeek-R1 思考链手风琴折叠展开卡片
            if (msg.reasoningText != null && msg.reasoningText!.isNotEmpty) ...[
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: const Icon(Icons.psychology_outlined, size: 16, color: Colors.grey),
                  title: Text(
                    '思考过程 (DeepSeek-R1)',
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
                        borderRadius: AppRadius.roundedSm,
                      ),
                      child: Text(
                        msg.reasoningText!,
                        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
            ],
            // 消息正文
            if (isUser)
              Text(
                msg.text,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              )
            : MarkdownWidget(
                data: msg.text,
                shrinkWrap: true,
              ),
          ],
        ),
      ),
    );
  }
}
