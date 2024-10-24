import 'package:get/get.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/model/post.dart';
import 'package:xbb/model/repo.dart';

class SyncController extends GetxController {
  final postController = Get.find<PostController>();
  final settingController = Get.find<SettingController>();

  Future<void> checkSyncInfo() async {
    var currentRepoId = settingController.currentRepoId.value;
    var currentUser = settingController.currentUser.value;
    if (currentRepoId == "0") {
      // local repo no need to sync
      return;
    }
    print("try sync $currentRepoId for $currentUser");

    Repo currentRepo = await RepoRepository().getRepo(currentRepoId);
    List<Post> currentPosts =
        await postController.fetchRepoPosts(currentRepoId);
    DateTime latestUpdateAt = currentPosts.fold<DateTime>(
        DateTime.parse("2024-10-24T00:00:00.000000"), (prev, post) {
      return post.updatedAt.isAfter(prev) ? post.updatedAt : prev;
    });

    DateTime repoLastSyncAt = currentRepo.lastSyncAt;
    if (repoLastSyncAt.isBefore(latestUpdateAt)) {
      // need to sync forwards
      await _trySyncForwards(currentRepo, currentPosts);
    }
    // always need to sync backwards
    await _trySyncBackwards(currentRepo, currentPosts);
  }

  // pull / download
  Future<void> _trySyncBackwards(Repo repo, List<Post> posts) async {
    print(" - try sync ${repo.id} from server");
    // todo
  }

  // push / upload
  Future<void> _trySyncForwards(Repo repo, List<Post> posts) async {
    print(" - try sync ${repo.id} to server");
    // todo
  }

  Future<void> doSyncForwardsPost(Post post) async {
    
  }
}
