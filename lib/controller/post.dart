import 'package:get/get.dart';
import 'package:xbb/client/client.dart';
import 'package:xbb/controller/comment.dart';
import 'package:xbb/controller/repo.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/sync.dart';
import 'package:xbb/model/post.dart';

enum PostViewFilter { all, unread, stars }

class PostController extends GetxController {
  final repoPostList = <Post>[].obs;
  final postListView = <Post>[].obs;

  final settingController = Get.find<SettingController>();
  final asyncController = Get.find<AsyncController>();
  late final commentController = Get.find<CommentController>();
  late final repoController = Get.find<RepoController>();

  final typeFilter = PostViewFilter.all.obs;
  final regexFilter = ''.obs;

  Future<void> loadPost(String repoId) async {
    repoPostList.value = await PostRepository().getRepoPosts(repoId);
    print('load repoId: $repoId, post ${repoPostList.length}');

    // reorganize postListView, sorted first by category, then by updatedAt
    filterPosts();
    postListView.sort((a, b) {
      if (a.category == b.category) {
        return b.updatedAt.compareTo(a.updatedAt);
      } else {
        return a.category.compareTo(b.category);
      }
    });
  }

  void filterPosts() {
    switch (typeFilter.value) {
      case PostViewFilter.all:
        postListView.value = repoPostList;
        break;
      case PostViewFilter.unread:
        postListView.value = repoPostList
            .where((element) =>
                element.status == PostStatus.newly ||
                element.status == PostStatus.updated)
            .toList();
        break;
      case PostViewFilter.stars:
        postListView.value = repoPostList
            .where((element) => element.selfAttitude == PostSelfAttitude.like)
            .toList();
        break;
    }
    if (regexFilter.value.isNotEmpty) {
      postListView.value = postListView
          .where((element) =>
              element.title.contains(regexFilter.value) ||
              element.category.contains(regexFilter.value) ||
              element.content.contains(regexFilter.value))
          .toList();
    }
  }

  setViewFilter({PostViewFilter? type, String? regex}) {
    if (type != null) {
      typeFilter.value = type;
    }
    if (regex != null) {
      regexFilter.value = regex;
    }
    filterPosts();
  }

  Future<Set<String>> fetchRepoPostCategories(String repoId) async {
    var repoPostList = await PostRepository().getRepoPosts(repoId);
    var categories = repoPostList.map((post) => post.category).toSet();
    if (!categories.contains('uncategorized')) {
      categories.add('uncategorized');
    }
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
    Get.offAllNamed('/');
  }

  deletePost(Post post) async {
    await PostRepository().deletePost(post.id);
    await loadPost(settingController.currentRepoId.value);
    if (post.repoId != '0' &&
        post.author == settingController.currentUserId.value &&
        post.status != PostStatus.detached) {
      asyncController.asyncPost(post, DataFlow.delete);
    }
  }

  markedAllAsRead() async {
    for (var post in postListView) {
      if (post.status == PostStatus.newly ||
          post.status == PostStatus.updated) {
        post.status = PostStatus.normal;
        await PostRepository().updatePost(post);
      }
    }
    await rebuildRepoStatus(settingController.currentRepoId.value);
  }

  editLocalPostStatus(Post post) async {
    await PostRepository().updatePost(post);
    await rebuildRepoStatus(post.repoId);
  }

  Future<void> rebuildRepoStatus(String repoId) async {
    List<Post> posts = await PostRepository().getRepoPosts(repoId);
    int newNumber = posts
        .where((element) =>
            element.status == PostStatus.newly ||
            element.status == PostStatus.updated)
        .length;
    print("rebuildRepoStatus $repoId, unread number: $newNumber");
    await repoController.editLocalRepoStatus(repoId, unreadCount: newNumber);
  }

  Future<List<int>> pullPosts(String repoId) async {
    int addCnt = 0, updateCnt = 0, deleteCnt = 0;
    List<PostSummary>? posts = await syncPullPosts(repoId);
    if (posts == null) {
      return [-0xffff, -0xffff, -0xffff];
    }
    for (PostSummary postSummary in posts) {
      commentController
          .syncComments(repoId, postSummary.id, postSummary.comments)
          .then((updated) {
        if (updated) {
          // todo add comments update label.
        }
      });
      Post? localPost = await PostRepository().getPost(postSummary.id);
      if (localPost == null) {
        Post? fetchPost = await syncPullPost(repoId, postSummary.id);
        if (fetchPost != null) {
          fetchPost.status = PostStatus.newly;
          print('add post ${fetchPost.title}');
          await PostRepository().addPost(fetchPost);
          addCnt++;
        }
        continue;
      }

      // post exists
      if (localPost.updatedAt == postSummary.updatedAt) {
        // no need to update
        print("no need to update post ${localPost.title}");
        if (localPost.status == PostStatus.notSynced ||
            localPost.status == PostStatus.detached) {
          localPost.status = PostStatus.normal;
          editLocalPostStatus(localPost);
        }
        continue;
      } else if (localPost.updatedAt.isAfter(postSummary.updatedAt)) {
        // server need to update?
        print(
            "server need to update post ${localPost.title} ${localPost.updatedAt} < server post ${postSummary.updatedAt}");
        localPost.status = PostStatus.notSynced;
        editLocalPostStatus(localPost);
        continue;
      } else {
        // need to pull from server
        Post? fetchPost = await syncPullPost(repoId, postSummary.id);
        if (fetchPost != null) {
          localPost = localPost.copyWith(
            category: fetchPost.category,
            title: fetchPost.title,
            content: fetchPost.content,
            updatedAt: fetchPost.updatedAt,
            repoId: fetchPost.repoId,
            status: localPost.status == PostStatus.newly
                ? PostStatus.newly
                : PostStatus.updated,
          );
          print('update post ${localPost!.title}');
          await PostRepository().updatePost(localPost);
          updateCnt++;
        } else {
          // deleted at server between pullPosts and pullPost
        }
      }
    }

    // deleted at server
    for (Post post in await PostRepository().getRepoPosts(repoId)) {
      if (!posts.any((element) => element.id == post.id)) {
        print('delete post ${post.title}');
        post.status = PostStatus.detached;
        await PostRepository().updatePost(post);
        deleteCnt++;
      }
    }
    await rebuildRepoStatus(repoId);
    return [addCnt, updateCnt, deleteCnt];
  }

  Future<Post> getPostUnwrap(String postId) async {
    return (await PostRepository().getPost(postId))!;
  }
}
