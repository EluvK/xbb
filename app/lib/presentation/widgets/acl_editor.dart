import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xbb/core/acl/acl_repository.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/providers/friends_provider.dart';
import 'package:xbb/presentation/widgets/avatar_helper.dart';
import 'package:xbb/presentation/widgets/modern_dialogs.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

/// 全局通用的细粒度权限控制核心编辑器组件 (AclEditor)
class AclEditor extends ConsumerStatefulWidget {
  final String table;
  final String entityId;
  final String entityTitle;
  final String? ownerId;

  const AclEditor({
    super.key,
    required this.table,
    required this.entityId,
    required this.entityTitle,
    this.ownerId,
  });

  /// 便捷静态调用弹窗展示
  static Future<void> show(
    BuildContext context, {
    required String table,
    required String entityId,
    required String entityTitle,
    String? ownerId,
  }) {
    return showAdaptiveModal(
      context,
      maxWidth: 520,
      isDismissible: false,
      builder: (_) => AclEditor(
        table: table,
        entityId: entityId,
        entityTitle: entityTitle,
        ownerId: ownerId,
      ),
    );
  }

  @override
  ConsumerState<AclEditor> createState() => _AclEditorState();
}

class _AclEditorState extends ConsumerState<AclEditor> {
  late final AclRepository _aclRepo;
  List<EntityAclEntry> _collaborators = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final _manualUserIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final dbChangeNotifier = ref.read(dbChangeNotifierProvider);
    _aclRepo = AclRepository(dbChangeNotifier);
    _loadAcls();
  }

  @override
  void dispose() {
    _manualUserIdController.dispose();
    super.dispose();
  }

  Future<void> _loadAcls() async {
    final db = ref.read(databaseProvider);
    final list = await _aclRepo.getAcls(db, table: widget.table, entityId: widget.entityId);
    if (mounted) {
      setState(() {
        _collaborators = list;
        _isLoading = false;
      });
    }
  }

  void _addFromFriend(dynamic friend) {
    if (_collaborators.any((c) => c.userId == friend.id)) {
      AppFeedback.showInfo(context, '${friend.nickname} 已经在协作者列表中');
      return;
    }

    setState(() {
      _collaborators.add(
        EntityAclEntry(
          userId: friend.id,
          username: friend.username,
          nickname: friend.nickname,
          avatar: friend.avatar,
          role: EntityAclRole.subscribe,
        ),
      );
    });
  }

  void _addManualUser() {
    final userId = _manualUserIdController.text.trim();
    if (userId.isEmpty) return;

    if (_collaborators.any((c) => c.userId == userId)) {
      AppFeedback.showWarning(context, '该用户已在协作者列表中');
      return;
    }

    setState(() {
      _collaborators.add(
        EntityAclEntry(
          userId: userId,
          username: userId,
          nickname: userId,
          avatar: 'preset_avatar_1',
          role: EntityAclRole.subscribe,
        ),
      );
      _manualUserIdController.clear();
    });
  }

  void _removeCollaborator(String userId) {
    setState(() {
      _collaborators.removeWhere((c) => c.userId == userId);
    });
  }

  void _updateRole(String userId, EntityAclRole newRole) {
    setState(() {
      final index = _collaborators.indexWhere((c) => c.userId == userId);
      if (index != -1) {
        final old = _collaborators[index];
        _collaborators[index] = EntityAclEntry(
          userId: old.userId,
          username: old.username,
          nickname: old.nickname,
          avatar: old.avatar,
          role: newRole,
        );
      }
    });
  }

  Future<void> _saveAcls() async {
    setState(() => _isSaving = true);
    final db = ref.read(databaseProvider);

    try {
      // 1. 获取原协作者列表用于比对被移除者
      final originalList = await _aclRepo.getAcls(db, table: widget.table, entityId: widget.entityId);
      final currentMap = {for (final c in _collaborators) c.userId: c};

      // 2. 撤销已被移除的成员权限
      for (final old in originalList) {
        if (!currentMap.containsKey(old.userId)) {
          await _aclRepo.revokePermission(
            db: db,
            table: widget.table,
            entityId: widget.entityId,
            granteeId: old.userId,
          );
        }
      }

      // 3. 授予或更新现有成员权限
      for (final entry in _collaborators) {
        await _aclRepo.grantPermission(
          db: db,
          table: widget.table,
          entityId: widget.entityId,
          entry: entry,
        );
      }

      if (mounted) {
        AppFeedback.showSuccess(context, '协作者权限已成功保存并同步');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, '保存权限失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final friendsAsync = ref.watch(friendsProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 头部
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.md, AppSpacing.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.share, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '协作与权限配置',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '针对: ${widget.entityTitle} (${widget.table})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // 正文
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // 1. 从好友列表快速添加
                    Text('从好友列表添加协作者', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.xs),
                    friendsAsync.when(
                      loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (friends) {
                        final available = friends.where((f) => f.id != auth.userId).toList();
                        if (available.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                            child: Text('暂无已连接的好友，可使用下方 User ID 手动添加', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          );
                        }
                        return SizedBox(
                          height: 56,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: available.length,
                            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final friend = available[index];
                              final isAdded = _collaborators.any((c) => c.userId == friend.id);
                              return ActionChip(
                                avatar: UserAvatarWidget(avatar: friend.avatar, fallbackName: friend.nickname, radius: 12),
                                label: Text(friend.nickname),
                                onPressed: isAdded ? null : () => _addFromFriend(friend),
                              );
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.sm),
                    // 手动输入 User ID
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualUserIdController,
                            decoration: ModernInputDecoration.field(
                              context,
                              hintText: '输入协作者 User ID (user-xxx)',
                              prefixIcon: const Icon(Icons.person_add_alt, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton.tonal(
                          onPressed: _addManualUser,
                          child: const Text('添加'),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 2. 当前协作者列表
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('已配置协作者 (${_collaborators.length})', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('包含权限矩阵', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    if (_collaborators.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(
                          child: Text(
                            '当前仅所有者可见，尚未添加任何协作者。',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _collaborators.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final collab = _collaborators[index];
                          return ModernCard(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Row(
                              children: [
                                UserAvatarWidget(avatar: collab.avatar, fallbackName: collab.nickname, radius: 18),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        collab.nickname,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        '@${collab.username.isNotEmpty ? collab.username : collab.userId}',
                                        style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                      Text(
                                        collab.role.description,
                                        style: TextStyle(fontSize: 10, color: theme.colorScheme.primary),
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownButton<EntityAclRole>(
                                  value: collab.role,
                                  isDense: true,
                                  underline: const SizedBox.shrink(),
                                  items: EntityAclRole.values.map((role) {
                                    return DropdownMenuItem(
                                      value: role,
                                      child: Text(role.label, style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                  onChanged: (newRole) {
                                    if (newRole != null) {
                                      _updateRole(collab.userId, newRole);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                                  tooltip: '移除协作者',
                                  onPressed: () => _removeCollaborator(collab.userId),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
        ),

        const Divider(height: 1),
        // 底部保存
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveAcls,
                icon: _isSaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 16),
                label: const Text('保存并同步权限'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
