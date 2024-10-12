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

  savePost(String title, String content, String repoId) async {
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
  }

  deletePost(String postId) async {
    await PostRepository().deletePost(postId);
    await loadPost(settingController.currentRepoId.value);
  }

  Future<Post> getPost(String postId) async {
    return await PostRepository().getPost(postId);
  }
}
