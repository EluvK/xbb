import 'package:flutter/material.dart';
import 'package:xbb/components/drawer_repos.dart';
import 'package:xbb/components/drawer_user.dart';
import 'package:xbb/components/settings.dart';

class DrawerPage extends StatelessWidget {
  const DrawerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12.0, 30.0, 4.0, 12.0),
      decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              const BorderRadius.horizontal(right: Radius.circular(25)),
          boxShadow: [
            BoxShadow(color: colorScheme.shadow.withOpacity(0.3), blurRadius: 7)
          ]),
      constraints: const BoxConstraints(maxWidth: 350),
      child: const Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
            child: DrawerUser(),
          ),
          Divider(),
          Expanded(
            child: DrawerRepos(),
          ),
          Divider(),
          Settings(),
        ],
      ),
    );
  }
}
