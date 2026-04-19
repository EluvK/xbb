import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/common/ping_latency_inline.dart';
import 'package:xbb/components/utils.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/syncstore.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/utils/double_click.dart';
import 'package:xbb/utils/text_input.dart';
import 'package:xbb/utils/utils.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('XBB')),
      body: const Center(child: SizedBox(width: 340, child: LoginBody())),
    );
  }
}

enum ServiceAvailability { available, notAvailable, checking, unknown }

enum UserNameAvailability { login, register, checking, unknown }

class LoginBody extends StatefulWidget {
  const LoginBody({super.key});

  @override
  State<LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<LoginBody> {
  // controller might be rebuild during this page's lifecycle,
  // so we should use the get sugar to find the latest one.
  SyncStoreControl get ssClient => Get.find<SyncStoreControl>();
  SettingController get settingController => Get.find<SettingController>();
  UserManagerController get userManagerController => Get.find<UserManagerController>();

  ServiceAvailability serviceAvailability = ServiceAvailability.unknown;
  UserNameAvailability userNameAvailability = UserNameAvailability.unknown;

  late final nameController = TextEditingController(text: settingController.userName);
  final passwordController = TextEditingController();
  final focus = FocusNode();
  bool _saveForQuickLogin = false;
  bool _passwordVisible = false;

  Timer? _serviceCheckTimer;
  bool _isChecking = false;
  bool _isLoggingIn = false;
  bool _isPinging = false;
  int? _pingLatencyMs;
  bool _showManualLogin = false;
  String? _quickLoginUserId;

  @override
  Widget build(BuildContext context) {
    final hasQuickLogins = settingController.quickLogins.value.quickLoginMap.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('login_page_title'.tr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          _buildStatusIndicator(),
          const SizedBox(height: 20),
          if (hasQuickLogins) ...[
            _buildQuickLoginList(),
            const SizedBox(height: 12),
            _buildManualLoginToggle(),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _buildManualLoginForm(),
              crossFadeState: _showManualLogin ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ] else ...[
            _buildManualLoginForm(),
          ],
          const SizedBox(height: 8),
          _buildServerSettings(),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    focus.addListener(() {
      if (!focus.hasFocus && nameController.text.isNotEmpty) {
        if (settingController.userName == nameController.text) return;
        setState(() {});
      }
    });
    checkServiceAvailability();
    _serviceCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) => checkServiceAvailability());
  }

  @override
  void dispose() {
    _serviceCheckTimer?.cancel();
    super.dispose();
  }

  void checkServiceAvailability() async {
    if (_isChecking) return;
    _isChecking = true;
    setState(() {
      serviceAvailability = ServiceAvailability.checking;
    });
    final latency = await ssClient.pingLatencyMs();
    if (!mounted) {
      return;
    }
    setState(() {
      _pingLatencyMs = latency >= 0 ? latency : null;
      serviceAvailability = latency >= 0 ? ServiceAvailability.available : ServiceAvailability.notAvailable;
      _isChecking = false;
    });
  }

  Future<void> testPingLatency() async {
    if (_isPinging) {
      return;
    }
    setState(() {
      _isPinging = true;
    });
    final latency = await ssClient.pingLatencyMs();
    if (!mounted) {
      return;
    }
    setState(() {
      _pingLatencyMs = latency >= 0 ? latency : null;
      serviceAvailability = latency >= 0 ? ServiceAvailability.available : ServiceAvailability.notAvailable;
      _isPinging = false;
    });
  }

  Widget _buildManualLoginToggle() {
    return InkWell(
      onTap: () => setState(() => _showManualLogin = !_showManualLogin),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showManualLogin ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'login_with_different_account'.tr,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualLoginForm() {
    return Column(
      children: [
        _nameEditor(),
        const SizedBox(height: 10),
        _passwordEditor(),
        const SizedBox(height: 20),
        _loginButton(),
      ],
    );
  }

  Widget _buildServerSettings() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings, size: 16),
            const SizedBox(width: 6),
            Text('syncstore_setting'.tr, style: const TextStyle(fontSize: 14)),
          ],
        ),
        tilePadding: EdgeInsets.zero,
        children: [
          TextInputWidget(
            title: SyncStoreInputMetaEnum.address,
            initialValue: settingController.syncStoreUrl,
            onFinished: (value) async {
              settingController.updateSyncStoreSetting(baseUrl: value);
              await reInitSyncStoreController();
              _pingLatencyMs = null;
              checkServiceAvailability();
              setState(() {});
            },
          ),
          BoolSelectorInputWidget(
            title: SyncStoreInputMetaEnum.enableTunnel,
            initialValue: settingController.syncStoreHpkeEnabled,
            onChanged: (value) async {
              print('value: $value');
              settingController.updateSyncStoreSetting(enableHpke: value);
              await reInitSyncStoreController();
              _pingLatencyMs = null;
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color color;
    String text;

    switch (serviceAvailability) {
      case ServiceAvailability.available:
        color = Colors.green;
        text = 'service_status_ok'.tr;
        break;
      case ServiceAvailability.notAvailable:
        color = Colors.red;
        text = 'service_status_not_available'.tr;
        break;
      case ServiceAvailability.unknown:
      default:
        color = Colors.grey;
        text = 'service_status_checking'.tr;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color, fontSize: 12)),
        if (_isChecking) ...[
          const SizedBox(width: 8),
          const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)),
        ],
        const SizedBox(width: 8),
        PingLatencyInline(
          isLoading: _isPinging,
          latencyMs: _pingLatencyMs,
          onRefresh: _isPinging ? null : testPingLatency,
        ),
      ],
    );
  }

  Widget _nameEditor() {
    return TextField(
      focusNode: focus,
      controller: nameController,
      decoration: InputDecoration(labelText: 'user_name'.tr),
      onChanged: (value) => setState(() {}),
      onSubmitted: (String name) {
        focus.unfocus();
        setState(() {});
      },
    );
  }

  Widget _passwordEditor() {
    return TextField(
      controller: passwordController,
      decoration: InputDecoration(
        labelText: 'password'.tr,
        suffixIcon: IconButton(
          icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
        ),
      ),
      obscureText: !_passwordVisible,
      onChanged: (value) => setState(() {}),
    );
  }

  execLogin() async {
    final userName = nameController.text;
    final password = passwordController.text;

    try {
      setState(() => _isLoggingIn = true);
      final UserProfile userProfile = await ssClient.login(userName, password);
      final userController = Get.find<UserManagerController>();
      userController.selfProfile.value = userProfile;
      settingController.updateUserInfo(userName: userName, userPassword: password);
      if (_saveForQuickLogin) {
        settingController.updateQuickLoginInfo(
          userId: userProfile.userId,
          userInfo: UserInfo.fromProfile(userProfile, password: password),
        );
      }
      // fetch and update user profiles after login
      // things like this if grows bigger can be moved specifically to a service class
      await userManagerController.fetchAndUpdateUserProfiles();
      await reInitSyncStoreController();
      if (mounted) {
        Get.offAllNamed('/');
        successSimpleFlushBar('login_success_message'.trParams({'userName': userProfile.name}));
      }
    } catch (e) {
      print('login error: $e');
      flushBar(FlushLevel.WARNING, 'login_failed'.tr, 'login_failed_message'.tr);
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
          _quickLoginUserId = null;
        });
      }
    }
  }

  Widget _loginButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _isLoggingIn ? null : execLogin,
          child: _isLoggingIn ? const CircularProgressIndicator() : Text('login'.tr),
        ),
        InkWell(
          onTap: () => setState(() => _saveForQuickLogin = !_saveForQuickLogin),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(visualDensity: VisualDensity.compact, value: _saveForQuickLogin, onChanged: null),
                ),
                const SizedBox(width: 8),
                Text('save_for_quick_login_hint'.tr, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLoginList() {
    final quickLogins = settingController.quickLogins.value.quickLoginMap;
    if (quickLogins.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Text('quick_login_hint'.tr, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 20,
          runSpacing: 14,
          children: quickLogins.entries.map((entry) {
            final UserInfo info = entry.value;
            return Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: _isLoggingIn
                          ? null
                          : () {
                              nameController.text = info.name;
                              passwordController.text = info.password;
                              _saveForQuickLogin = true;
                              setState(() => _quickLoginUserId = info.id);
                              execLogin();
                            },
                      child: Container(
                        padding: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _quickLoginUserId == info.id
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: _quickLoginUserId == info.id ? 0.35 : 1.0,
                              child: buildUserAvatar(context, info.avatarUrl, size: 48, selected: false),
                            ),
                            if (_quickLoginUserId == info.id)
                              const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: DoubleClickButton(
                        buttonBuilder: (onPressed) => IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onPressed,
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                        ),
                        onDoubleClick: () {
                          settingController.updateQuickLoginInfo(userId: info.id, userInfo: null);
                        },
                        firstClickHint: 'delete_quick_login_message'.trParams({'userName': info.name}),
                        upperPosition: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(info.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
