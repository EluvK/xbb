import 'package:flutter/material.dart';
import 'dart:math';

import 'package:get/get.dart';
import 'package:xbb/client/client.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/utils/predefined.dart';
import 'package:xbb/utils/utils.dart';

class DrawerUser extends StatefulWidget {
  const DrawerUser({super.key});

  @override
  State<DrawerUser> createState() => _DrawerUserState();
}

class _DrawerUserState extends State<DrawerUser> {
  final settingController = Get.find<SettingController>();
  TextEditingController customUrlController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _skVisible = false;

  @override
  void initState() {
    refreshController();
    super.initState();
  }

  void refreshController() {
    customUrlController.text = settingController.currentUserAvatarUrl.value;
    nameController.text = settingController.currentUserName.value;
    passwordController.text = settingController.currentUserPasswd.value;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return StatefulBuilder(
                        builder: (context, StateSetter setState) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        elevation: 16,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: screenWidth * 0.8,
                            height: screenHeight * 0.8,
                            child: _showEditUserInfoDialog(setState),
                          ),
                        ),
                      );
                    });
                  },
                );
              },
              child: _avatar(customUrlController.text),
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
        Column(
          children: [
            Text(settingController.currentUserName.value),
            Text(settingController.serverAddress.value),
          ],
        ),
      ],
    );
  }

  Widget _showEditUserInfoDialog(StateSetter setState) {
    return Column(
      children: [
        Text(settingController.currentUserId.value),
        const Divider(),
        const Text(
          'Select Avatar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: avatarMatrix(),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: TextField(
            controller: customUrlController,
            decoration: const InputDecoration(
              labelText: 'Enter custom URL',
            ),
            maxLines: 3,
            minLines: 1,
          ),
        ),
        const Divider(),
        const Text(
          'Update',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Update Name',
            ),
            controller: nameController,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Update Password',
              suffixIcon: IconButton(
                icon:
                    Icon(_skVisible ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _skVisible = !_skVisible),
              ),
            ),
            controller: passwordController,
            obscureText: !_skVisible,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  var id = settingController.currentUserId.value;
                  var name = nameController.text;
                  var password = passwordController.text;
                  var avatarUrl = customUrlController.text;
                  updateUser(id, name, password, avatarUrl).then((value) {
                    if (value) {
                      flushBar(FlushLevel.OK, 'Success', "Updated");
                      settingController.setUser(
                        settingController.currentUserId.value,
                        name: name,
                        password: password,
                        avatarUrl: avatarUrl,
                      );
                    } else {
                      refreshController();
                      flushBar(FlushLevel.WARNING, 'Failed', "something wrong");
                    }
                  });
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save Changes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }

  LayoutBuilder avatarMatrix() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double totalWidth = constraints.maxWidth;
        double cardWidth = 48.0;
        int maxCardCountPerRow = min((totalWidth / cardWidth).toInt(), 5);
        double spacing = (totalWidth - (maxCardCountPerRow * cardWidth)) /
            (maxCardCountPerRow + 1);
        return Wrap(
          spacing: spacing,
          runSpacing: 12.0,
          alignment: WrapAlignment.start,
          children: predefinedAvatar.map((avatar) {
            return InkWell(
              onTap: () {
                setState(() {
                  customUrlController.text = avatar.url;
                  settingController.setUser(
                    settingController.currentUserId.value,
                    avatarUrl: avatar.url,
                  );
                });
              },
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _avatar(avatar.url)),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _avatar(String url) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      backgroundColor: colorScheme.onSurface.withOpacity(0.1),
      radius: 30.0,
      backgroundImage: NetworkImage(url),
    );
  }
}
