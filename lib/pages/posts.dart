import 'package:flutter/material.dart';
import 'package:xbb/components/post_card.dart';
import 'package:xbb/pages/repos.dart';

class PostPage extends StatelessWidget {
  const PostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Repos(),
      appBar: AppBar(
        title: const Text('<Repo Title T>'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add))],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(2.0),
        child: PostCard(),
      ),
    );
  }
}
