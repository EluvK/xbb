import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/model/post.dart';

class PostController extends GetxController {
  final repoPostList = <Post>[].obs;
  final postListView = <Post>[].obs;

  final settingController = Get.find<SettingController>();

  Future<void> loadPost(String repoId) async {
    repoPostList.value = await PostRepository().getRepoPosts(repoId);
    print('load repoId: $repoId, post ${repoPostList.length}');
    postListView.value = repoPostList; // to be implemented more.
  }

  savePost(String? postId, String title, String content, String repoId) async {
    if (postId == null) {
      // new one
      var post = Post(
        id: const Uuid().v4(),
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        author: settingController.currentUser.value,
        repoId: repoId,
      );
      await PostRepository().addPost(post);
      if (repoId == settingController.currentRepoId.value) {
        await loadPost(repoId);
      }
      Get.toNamed('/');
    } else {
      // edit exist post
      var post = await getPost(postId);
      post.title = title;
      post.content = content;
      post.updatedAt = DateTime.now();
      await PostRepository().updatePost(post);
      if (repoId == settingController.currentRepoId.value) {
        await loadPost(repoId);
      }

      // strange, but it works... should be better.
      Get.offNamed('/');
      Get.toNamed('/view-post', arguments: [post.id]);

      // missing pop back button:
      // Get.offAllNamed('/view-post', arguments: [post.id]);

      // todo
      print("update repo");
    }
  }

  deletePost(String postId) async {
    await PostRepository().deletePost(postId);
    await loadPost(settingController.currentRepoId.value);
  }

  Future<Post> getPost(String postId) async {
    return await PostRepository().getPost(postId);
  }
}
