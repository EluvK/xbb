import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/syncstore.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('XBB')),
      body: const LoginBody(),
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

  ServiceAvailability serviceAvailability = ServiceAvailability.unknown;
  UserNameAvailability userNameAvailability = UserNameAvailability.unknown;

  late final nameController = TextEditingController(text: ssClient.tokenStorage.getUserName());
  final passwordController = TextEditingController();
  final focus = FocusNode();
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // add a title, and maybe server status here.
            const Text('Connecting...', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            _nameEditor(),
            const SizedBox(height: 20),
            _passwordEditor(),
            const SizedBox(height: 40),
            _loginButton(),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    focus.addListener(() {
      if (!focus.hasFocus && nameController.text.isNotEmpty) {
        if (ssClient.tokenStorage.getUserName() == nameController.text) return;
        ssClient.tokenStorage.setUserName(nameController.text);
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
          final settingController = Get.find<SettingController>();
          settingController.setUser(
            userProfile.userId,
            name: userName,
            password: password,
            avatarUrl: userProfile.avatarUrl,
          );
          Get.offAllNamed('/');
        } catch (e) {
          print('login error: $e');
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('login_failed'.tr)));
        }
      },
      child: Text('login'.tr),
    );
  }
}
