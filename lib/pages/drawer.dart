import 'package:flutter/material.dart';
import 'package:xbb/components/drawer_repos.dart';
import 'package:xbb/components/drawer_user.dart';

class DrawerPage extends StatelessWidget {
  const DrawerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              const BorderRadius.horizontal(right: Radius.circular(25)),
          boxShadow: [
            BoxShadow(color: colorScheme.shadow.withOpacity(0.3), blurRadius: 7)
          ]),
      constraints: const BoxConstraints(maxWidth: 400),
      child: const Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: DrawerUser(),
          ),
          Divider(),
          Expanded(
            child: DrawerRepos(),
          ),
          Divider(),
          Placeholder(
            // for settings
            fallbackHeight: 100,
          ),
          Text('settings? info? maybe'),
        ],
      ),
    );
  }
}
