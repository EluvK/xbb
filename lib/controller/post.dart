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

    // reorganize postListView, sorted first by category, then by updatedAt
    postListView.value = repoPostList;
    postListView.sort((a, b) {
      if (a.category == b.category) {
        return b.updatedAt.compareTo(a.updatedAt);
      } else {
        return a.category.compareTo(b.category);
      }
    });
  }

  Future<Set<String>> fetchRepoPostCategories(String repoId) async {
    var repoPostList = await PostRepository().getRepoPosts(repoId);
    var categories = repoPostList.map((post) => post.category).toSet();
    return categories;
  }

  Future<List<Post>> fetchRepoPosts(String repoId) async {
    var posts = await PostRepository().getRepoPosts(repoId);
    return posts;
  }

  savePost(String? postId, String title, String content, String repoId,
      String category) async {
    print("on savePost: $postId, $title, $content, $repoId, $category");
    if (postId == null) {
      // new one
      var post = Post(
        id: const Uuid().v4(),
        category: category,
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        author: settingController.currentUser.value,
        repoId: repoId,
      );
      await PostRepository().addPost(post);
      await loadPost(settingController.currentRepoId.value);
      Get.toNamed('/');
    } else {
      // edit exist post
      var post = await getPost(postId);
      post.title = title;
      post.content = content;
      post.repoId = repoId;
      post.category = category;
      post.updatedAt = DateTime.now();
      await PostRepository().updatePost(post);
      await loadPost(settingController.currentRepoId.value);
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
