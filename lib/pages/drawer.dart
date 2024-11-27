import 'package:flutter/material.dart';
import 'package:xbb/components/drawer_repos.dart';
import 'package:xbb/components/drawer_user.dart';
import 'package:xbb/utils/utils.dart';

class DrawerPage extends StatelessWidget {
  const DrawerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12.0, 30.0, 4.0, 20.0),
      decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              const BorderRadius.horizontal(right: Radius.circular(25)),
          boxShadow: [
            BoxShadow(color: colorScheme.shadow.withOpacity(0.3), blurRadius: 7)
          ]),
      constraints: const BoxConstraints(maxWidth: 350),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: DrawerUser(),
          ),
          const Divider(),
          const Expanded(
            child: DrawerRepos(),
          ),
          const Divider(),
          Transform.scale(
            scale: 0.9,
            child: ListTile(
              title: Row(
                children: [
                  const Text('XBB version $VERSION'),
                  Visibility(
                    visible: false, // todo
                    child: IconButton(
                      onPressed: () async {
                        launchRepo();
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  )
                ],
              ),
              leading: const Icon(Icons.info_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
