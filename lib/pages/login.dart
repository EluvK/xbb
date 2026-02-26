import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/syncstore.dart';
import 'package:xbb/controller/user.dart';
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
  bool _passwordVisible = false;

  Timer? _serviceCheckTimer;
  bool _isChecking = false;
  bool _isLoggingIn = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // add a title, and maybe server status here.
        Text('login_page_title'.tr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        _buildStatusIndicator(),
        _nameEditor(),
        const SizedBox(height: 20),
        _passwordEditor(),
        const SizedBox(height: 40),
        _loginButton(),
        const SizedBox(height: 30),
        const Divider(),
        TextInputWidget(
          title: SyncStoreInputMetaEnum.address,
          initialValue: settingController.syncStoreUrl,
          onFinished: (value) async {
            // print('onFinished: $value');
            settingController.updateSyncStoreSetting(baseUrl: value);
            await reInitSyncStoreController();
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
            setState(() {});
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    focus.addListener(() {
      if (!focus.hasFocus && nameController.text.isNotEmpty) {
        if (settingController.userName == nameController.text) return;
        // settingController.userName = nameController.text;
        // todo check name?
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
    try {
      final result = await ssClient.checkHealth();
      setState(() {
        serviceAvailability = result ? ServiceAvailability.available : ServiceAvailability.notAvailable;
      });
    } catch (e) {
      setState(() {
        serviceAvailability = ServiceAvailability.notAvailable;
      });
    } finally {
      _isChecking = false;
    }
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

  Widget _loginButton() {
    return ElevatedButton(
      onPressed: _isLoggingIn ? null : __execLogin,
      child: _isLoggingIn ? const CircularProgressIndicator() : Text('login'.tr),
    );
  }

  __execLogin() async {
    final userName = nameController.text;
    final password = passwordController.text;

    try {
      setState(() => _isLoggingIn = true);
      final UserProfile userProfile = await ssClient.login(userName, password);
      final userController = Get.find<UserManagerController>();
      userController.selfProfile.value = userProfile;
      settingController.updateUserInfo(userName: userName, userPassword: password);
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
        setState(() => _isLoggingIn = false);
      }
    }
  }
}
