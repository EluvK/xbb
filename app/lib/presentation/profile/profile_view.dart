import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xbb/core/network/auth_service.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/providers/friends_provider.dart';
import 'package:xbb/presentation/widgets/avatar_helper.dart';
import 'package:xbb/presentation/widgets/modern_dialogs.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _customAvatarController;

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedAvatar = 'preset_avatar_1';
  bool _isSavingProfile = false;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _nicknameController = TextEditingController(text: auth.nickname);
    _selectedAvatar = auth.avatar;
    _customAvatarController = TextEditingController(
      text: auth.avatar.startsWith('http') ? auth.avatar : '',
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _customAvatarController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    final nickname = _nicknameController.text.trim();
    final customUrl = _customAvatarController.text.trim();
    final avatarToSave = customUrl.isNotEmpty ? customUrl : _selectedAvatar;

    setState(() => _isSavingProfile = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
        nickname: nickname.isNotEmpty ? nickname : null,
        avatar: avatarToSave,
      );
      if (mounted) {
        AppFeedback.showSuccess(context, '个人资料已成功保存并同步到云端');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, '保存失败: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _handleChangePassword() async {
    final oldPassword = _oldPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      AppFeedback.showWarning(context, '请输入当前密码与新密码');
      return;
    }
    if (newPassword != confirm) {
      AppFeedback.showWarning(context, '两次输入的新密码不一致');
      return;
    }

    setState(() => _isChangingPassword = true);
    try {
      await AuthService().updatePassword(oldPassword, newPassword);
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (mounted) {
        AppFeedback.showSuccess(context, '密码修改成功，请牢记您的新密码');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, '修改失败: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final friendsAsync = ref.watch(friendsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '个人资料与好友',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // 1. 自身公开资料卡片
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatarWidget(
                      avatar: _customAvatarController.text.trim().isNotEmpty
                          ? _customAvatarController.text.trim()
                          : _selectedAvatar,
                      fallbackName: auth.nickname.isNotEmpty ? auth.nickname : auth.username,
                      radius: 32,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.nickname.isNotEmpty ? auth.nickname : auth.username,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${auth.username} (${auth.isLoggedIn ? "在线同步用户" : "离线访客"})',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: auth.userId));
                              AppFeedback.showSuccess(context, '已复制 User ID 到剪贴板');
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ID: ${auth.userId}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.copy, size: 12, color: theme.colorScheme.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xl),

                // 修改昵称
                Text('修改昵称', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _nicknameController,
                  decoration: ModernInputDecoration.field(
                    context,
                    hintText: '请输入新的显示昵称',
                    prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 选择预设矢量头像
                Text('选择预设矢量头像', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final item in kPresetAvatars)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedAvatar = item.key;
                            _customAvatarController.clear();
                          });
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedAvatar == item.key && _customAvatarController.text.isEmpty
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: item.backgroundColor,
                            child: Icon(item.icon, size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 自定义网络图片 URL 头像
                Text('自定义网络头像 URL (可选)', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _customAvatarController,
                  onChanged: (_) => setState(() {}),
                  decoration: ModernInputDecoration.field(
                    context,
                    hintText: 'https://example.com/avatar.png',
                    prefixIcon: const Icon(Icons.image_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _isSavingProfile ? null : _handleSaveProfile,
                    icon: _isSavingProfile
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 16),
                    label: const Text('保存修改并同步'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. 安全与修改密码
          if (auth.isLoggedIn) ...[
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('修改登录密码', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _oldPasswordController,
                    obscureText: true,
                    decoration: ModernInputDecoration.field(
                      context,
                      labelText: '当前密码',
                      prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: ModernInputDecoration.field(
                      context,
                      labelText: '新密码',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: ModernInputDecoration.field(
                      context,
                      labelText: '确认新密码',
                      prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: _isChangingPassword ? null : _handleChangePassword,
                      child: _isChangingPassword
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('更新登录密码'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // 3. 好友与协同成员 (Friend Profiles)
          ModernCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('好友与协同成员 (Friend Profiles)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 18),
                      tooltip: '刷新成员列表',
                      onPressed: () => ref.read(friendsProvider.notifier).refresh(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '展示系统内已注册的协同用户公开资料，可在权限配置中一键添加协作者。',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.md),

                friendsAsync.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.md), child: CircularProgressIndicator())),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text('加载好友列表失败: $e', style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                    ),
                  ),
                  data: (friends) {
                    final otherFriends = friends.where((f) => f.id != auth.userId).toList();
                    if (otherFriends.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text('暂无其他协同成员', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: otherFriends.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final friend = otherFriends[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: UserAvatarWidget(
                            avatar: friend.avatar,
                            fallbackName: friend.nickname,
                            radius: 20,
                          ),
                          title: Text(friend.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text('@${friend.username} • ID: ${friend.id}', style: const TextStyle(fontSize: 11)),
                          trailing: IconButton(
                            icon: const Icon(Icons.copy, size: 16),
                            tooltip: '复制协作者 ID',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: friend.id));
                              AppFeedback.showSuccess(context, '已复制 ${friend.nickname} 的 ID 到剪贴板');
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 4. 登出
          ModernCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('退出当前登录', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('退出后切换至本地离线模式', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                OutlinedButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  child: const Text('退出登录'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
