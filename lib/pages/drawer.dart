import 'package:flutter/material.dart';
import 'package:xbb/components/drawer_repos.dart';
import 'package:xbb/components/drawer_user.dart';

class DrawerPage extends StatelessWidget {
  const DrawerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: DrawerUser(),
        ),
        Divider(),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: DrawerRepos(),
        ),
      ],
    );
  }
}
