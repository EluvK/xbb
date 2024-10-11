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
    postListView.value = repoPostList; // to be implemented more.
  }

  savePost(String title, String content, String repoId) {
    var post = Post(
      id: const Uuid().v4(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      author: settingController.currentUser.value,
      repoId: repoId,
    );
    PostRepository().addPost(post);
  }
}
