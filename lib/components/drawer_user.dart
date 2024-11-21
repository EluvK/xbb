import 'package:flutter/material.dart';
import 'dart:math';

import 'package:get/get.dart';
import 'package:xbb/controller/setting.dart';

class DrawerUser extends StatefulWidget {
  const DrawerUser({super.key});

  @override
  State<DrawerUser> createState() => _DrawerUserState();
}

class _DrawerUserState extends State<DrawerUser> {
  final settingController = Get.find<SettingController>();
  String _currentAvatarUrl =
      'https://avatars.githubusercontent.com/u/583231?v=4';

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
                          child: _showAvatarDialog(),
                        ),
                      ),
                    );
                  },
                );
              },
              child: CircleAvatar(
                radius: 30.0,
                backgroundImage: NetworkImage(_currentAvatarUrl),
              ),
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

  Widget _showAvatarDialog() {
    TextEditingController customUrlController = TextEditingController();

    return Column(
      children: [
        const Text('Select Avatar'),
        Container(
          padding: const EdgeInsets.all(8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double totalWidth = constraints.maxWidth;
              double cardWidth = 48.0;
              int maxCardCountPerRow = min((totalWidth / cardWidth).toInt(), 4);
              double spacing = (totalWidth - (maxCardCountPerRow * cardWidth)) /
                  (maxCardCountPerRow + 1);
              return Wrap(
                spacing: spacing,
                runSpacing: 12.0,
                alignment: WrapAlignment.start,
                children: [
                  'https://avatars.githubusercontent.com/u/583231?v=4',
                  'https://avatars.githubusercontent.com/u/1?v=4',
                  'https://avatars.githubusercontent.com/u/2?v=4',
                  'https://avatars.githubusercontent.com/u/3?v=4',
                ].map((url) {
                  return _avatarOption(url);
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: customUrlController,
          decoration: const InputDecoration(
            labelText: 'Enter custom URL',
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _currentAvatarUrl = customUrlController.text;
            });
            Navigator.of(context).pop();
          },
          child: const Text('Set Custom URL'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _avatarOption(String url) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentAvatarUrl = url;
        });
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          radius: 30.0,
          backgroundImage: NetworkImage(url),
        ),
      ),
    );
  }
}
