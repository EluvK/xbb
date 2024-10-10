import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:xbb/controller/setting.dart';

class DrawerUser extends StatefulWidget {
  const DrawerUser({super.key});

  @override
  State<DrawerUser> createState() => _DrawerUserState();
}

class _DrawerUserState extends State<DrawerUser> {
  final settingController = Get.find<SettingController>();

  @override
  Widget build(BuildContext context) {
    return _info();
  }

  Row _info() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            const CircleAvatar(
              radius: 30.0,
              // todo
              backgroundImage: NetworkImage(
                  'https://avatars.githubusercontent.com/u/583231?v=4'),
            ),
            // button to change user
            TextButton(
              onPressed: () {
                Get.toNamed('/login');
              },
              child: const Text('Change User'),
            ),
          ],
        ),
        // user info and server info
        // todo
        Column(
          children: [
            Text(settingController.currentUser.value),
            Text(settingController.serverAddress.value),
          ],
        ),
      ],
    );
  }
}
