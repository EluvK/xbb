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
  SyncStoreControl ssClient = Get.find<SyncStoreControl>();
  SettingController settingController = Get.find<SettingController>();
  UserManagerController userManagerController = Get.find<UserManagerController>();

  ServiceAvailability serviceAvailability = ServiceAvailability.unknown;
  UserNameAvailability userNameAvailability = UserNameAvailability.unknown;

  late final nameController = TextEditingController(text: settingController.userName);
  final passwordController = TextEditingController();
  final focus = FocusNode();
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // add a title, and maybe server status here.
        const Text('Connecting...', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
          onChanged: (value) {
            settingController.updateSyncStoreSetting(baseUrl: value);
            setState(() {
              reInitSyncStoreController();
            });
          },
        ),
        BoolSelectorInputWidget(
          title: SyncStoreInputMetaEnum.enableTunnel,
          initialValue: settingController.syncStoreHpkeEnabled,
          onChanged: (value) {
            print('value: $value');
            settingController.updateSyncStoreSetting(enableHpke: value);
            setState(() {
              reInitSyncStoreController();
            });
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    focus.addListener(() {
      if (!focus.hasFocus && nameController.text.isNotEmpty) {
        if (settingController.userName == nameController.text) return;
        // settingController.userName = nameController.text;
        // todo check name?
        setState(() {});
      }
    });
    super.initState();
  }

  Widget _nameEditor() {
    return TextField(
      focusNode: focus,
      controller: nameController,
      decoration: InputDecoration(labelText: 'userName'.tr),
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
      onPressed: () async {
        final userName = nameController.text;
        final password = passwordController.text;

        try {
          final UserProfile userProfile = await ssClient.login(userName, password);
          final userController = Get.find<UserManagerController>();
          userController.selfProfile.value = userProfile;
          settingController.updateUserInfo(userName: userName, userPassword: password);
          // fetch and update user profiles after login
          // things like this if grows bigger can be moved specifically to a service class
          await userManagerController.fetchAndUpdateUserProfiles();
          await reInitSyncStoreController();
          Get.offAllNamed('/');
        } catch (e) {
          print('login error: $e');
          flushBar(FlushLevel.INFO, 'login_failed'.tr, 'Please check your username and password.');
          // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('login_failed'.tr)));
        }
      },
      child: Text('login'.tr),
    );
  }
}
