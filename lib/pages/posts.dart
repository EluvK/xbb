import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/components/post_card.dart';
import 'package:xbb/components/post_filter.dart';
import 'package:xbb/controller/repo.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/pages/drawer.dart';

class PostPage extends StatelessWidget {
  const PostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      drawer: DrawerPage(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56.0),
        child: PostPageAppBar(),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(2.0),
        child: Column(
          children: [
            PostFilter(),
            PostCard(),
          ],
        ),
      ),
    );
  }
}

class PostPageAppBar extends StatefulWidget {
  const PostPageAppBar({super.key});

  @override
  State<PostPageAppBar> createState() => _PostPageAppBarState();
}

class _PostPageAppBarState extends State<PostPageAppBar> {
  final settingController = Get.find<SettingController>();
  final repoController = Get.find<RepoController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return AppBar(
        title: Text(
            repoController.repoName(settingController.currentRepoId.value) ??
                '??'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add))],
      );
    });
  }
}
