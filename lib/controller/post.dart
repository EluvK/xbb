import 'package:get/get.dart';
import 'package:xbb/client/client.dart';
import 'package:xbb/controller/repo.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/sync.dart';
import 'package:xbb/model/post.dart';

class PostController extends GetxController {
  final repoPostList = <Post>[].obs;
  final postListView = <Post>[].obs;

  final settingController = Get.find<SettingController>();
  final asyncController = Get.find<AsyncController>();
  late final repoController = Get.find<RepoController>();

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

  savePost(Post post) async {
    post.updatedAt = DateTime.now().toUtc();
    if (post.author != settingController.currentUserId.value) {
      print(
          "change author to ${settingController.currentUserId} ${settingController.currentUserName}");
      post.author = settingController.currentUserId.value;
    }
    print(
        "on savePost: ${post.id}, ${post.title}, ${post.content}, ${post.repoId}, ${post.category}, ${post.author}");
    if (post.repoId == '0') {
      PostRepository().getPost(post.id).then((oldPost) {
        if (oldPost != null && oldPost.repoId != '0') {
          asyncController.asyncPost(oldPost, DataFlow.delete);
        }
      });
    } else {
      asyncController.asyncPost(post, DataFlow.push);
    }
    await PostRepository().upsertPost(post);
    await repoController.setCurrentRepo(post.repoId);
    Get.offNamed('/');
  }

  deletePost(String postId) async {
    await PostRepository().deletePost(postId);
    await loadPost(settingController.currentRepoId.value);
  }

  pullPosts(String repoId) async {
    List<PostSummary> posts = await syncPullPosts(repoId);
    for (PostSummary postSummary in posts) {
      Post? localPost = await PostRepository().getPost(postSummary.id);
      if (localPost == null ||
          localPost.updatedAt.isBefore(postSummary.updatedAt)) {
        Post? fetchPost = await syncPullPost(repoId, postSummary.id);
        if (fetchPost != null) {
          await PostRepository().upsertPost(fetchPost);
        }
      } else {
        // no need to fetch post.
      }
    }

    await repoController.setCurrentRepo(repoId);
  }

  Future<Post> getPostUnwrap(String postId) async {
    return (await PostRepository().getPost(postId))!;
  }
}
