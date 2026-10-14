import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xbb/core/auth/quick_login_manager.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/providers/server_health_provider.dart';
import 'package:xbb/presentation/widgets/modern_dialogs.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _quickLoginManager = QuickLoginManager();

  List<QuickLoginCredential> _quickAccounts = [];
  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberPassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuickAccounts();
  }

  void _loadQuickAccounts() {
    setState(() {
      _quickAccounts = _quickLoginManager.getCredentials();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final nickname = _nicknameController.text.trim();

    if (username.isEmpty) {
      setState(() => _errorMessage = '请输入用户名');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = '请输入密码');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        await ref.read(authProvider.notifier).registerWithCredentials(
          username,
          password,
          nickname: nickname.isNotEmpty ? nickname : null,
        );
      } else {
        await ref.read(authProvider.notifier).loginWithCredentials(
          username,
          password,
        );
      }

      // 如果勾选记住密码，保存到快速登录凭据库
      if (_rememberPassword) {
        final currentAuth = ref.read(authProvider);
        await _quickLoginManager.saveCredential(
          QuickLoginCredential(
            userId: currentAuth.userId,
            username: username,
            password: password,
            nickname: currentAuth.nickname.isNotEmpty ? currentAuth.nickname : username,
            avatar: currentAuth.avatar,
            lastLoginTime: DateTime.now(),
          ),
        );
      }

      if (mounted) {
        final from = GoRouterState.of(context).uri.queryParameters['from'];
        context.go((from != null && from.isNotEmpty && from != '/login') ? from : '/');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleQuickLogin(QuickLoginCredential cred) async {
    _usernameController.text = cred.username;
    _passwordController.text = cred.password;
    if (cred.password.isNotEmpty) {
      await _handleSubmit();
    }
  }

  Future<void> _deleteQuickAccount(String userId) async {
    final confirm = await showAdaptiveConfirmDialog(
      context,
      title: '移除历史凭据',
      message: '确定从本设备删除该账号的快捷登录凭据吗？',
      confirmText: '确认删除',
      isDanger: true,
    );

    if (confirm == true) {
      await _quickLoginManager.removeCredential(userId);
      _loadQuickAccounts();
    }
  }

  void _showEditServerDialog(String currentUrl) async {
    final newUrl = await showAdaptiveTextInputDialog(
      context,
      title: '配置同步服务器地址',
      subtitle: '请输入权威 Rust ChangeLog 服务的访问 BaseURL：',
      initialValue: currentUrl,
      labelText: '服务器 BaseURL',
      hintText: 'http://127.0.0.1:10101',
      prefixIcon: Icons.dns_outlined,
      confirmText: '保存并测速',
      cancelText: '取消',
    );

    if (newUrl != null && newUrl.isNotEmpty && mounted) {
      ref.read(serverHealthProvider.notifier).updateServerUrl(newUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final health = ref.watch(serverHealthProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ModernCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. 顶部服务器健康检测小圆点及快速切换
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: () => _showEditServerDialog(health.baseUrl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: health.state == ServerHealthState.available
                                      ? Colors.green
                                      : health.state == ServerHealthState.checking
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                health.state == ServerHealthState.available
                                    ? '服务在线 (${health.latencyMs}ms)'
                                    : health.state == ServerHealthState.checking
                                        ? '探测中...'
                                        : '服务不可用 (离线)',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: health.state == ServerHealthState.available
                                      ? Colors.green
                                      : health.state == ServerHealthState.checking
                                          ? Colors.orange
                                          : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                health.baseUrl,
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.edit_outlined, size: 12, color: theme.colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 2. 标题区
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.bolt, color: theme.colorScheme.primary, size: 30),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _isRegisterMode ? '创建 XBB 账号' : '欢迎登录 XBB',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '本地优先、权威日志同步架构工作区',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),

                  // 3. 历史已保存多账号快速登录卡片列表
                  if (!_isRegisterMode && _quickAccounts.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('快速登录历史账号', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('${_quickAccounts.length} 个账号', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _quickAccounts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final cred = _quickAccounts[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            onTap: () => _handleQuickLogin(cred),
                            onLongPress: () => _deleteQuickAccount(cred.userId),
                            child: Container(
                              width: 100,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.colorScheme.outlineVariant),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: theme.colorScheme.primaryContainer,
                                    child: Text(
                                      cred.nickname.isNotEmpty ? cred.nickname[0].toUpperCase() : 'U',
                                      style: TextStyle(fontSize: 13, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cred.nickname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '@${cred.username}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 9, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),

                  // 错误提示条
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  TextField(
                    controller: _usernameController,
                    decoration: ModernInputDecoration.field(
                      context,
                      labelText: '用户名',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                    ),
                  ),
                  if (_isRegisterMode) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _nicknameController,
                      decoration: ModernInputDecoration.field(
                        context,
                        labelText: '显示昵称 (可选)',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: ModernInputDecoration.field(
                      context,
                      labelText: '密码',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    onSubmitted: (_) => _handleSubmit(),
                  ),

                  // 记住密码复选框
                  if (!_isRegisterMode) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberPassword,
                          onChanged: (v) => setState(() => _rememberPassword = v ?? true),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        Text('记住密码与快捷登录', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isRegisterMode ? '立即注册并进入' : '登录 / 进入工作区'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isRegisterMode = !_isRegisterMode;
                                _errorMessage = null;
                              });
                            },
                      child: Text(_isRegisterMode ? '已有账号？返回登录' : '没有账号？立即注册'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
