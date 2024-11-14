import 'package:get/get.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/model/post.dart';
import 'package:xbb/model/repo.dart';
import 'package:xbb/utils/async_task_queue.dart';
import 'package:xbb/client/client.dart' as client;

enum DataFlow { push, pull, delete }

class AsyncController extends GetxController {
  late final postController = Get.find<PostController>();
  final settingController = Get.find<SettingController>();

  final _taskQueue = AsyncTaskQueue();

  Future<void> checkSyncInfo() async {
    var currentRepoId = settingController.currentRepoId.value;
    var currentUser = settingController.currentUserName.value;
    if (currentRepoId == "0") {
      // local repo no need to sync
      return;
    }
    // todo test delay (delete)
    await Future<void>.delayed(const Duration(seconds: 1));

    Repo currentRepo = (await RepoRepository().getRepo(currentRepoId))!;
    print(
        "try sync ${currentRepo.id} (${currentRepo.name}) for $currentUser, last sync at ${currentRepo.lastSyncAt}");

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

  Future<void> doSyncForwardsPost(Post post) async {}

  asyncRepo(Repo repo, DataFlow flow) {
    print("sync controller sync repo ${repo.id}");
    var metadata = {
      "flow": flow,
      "type": "repo",
      "data": repo,
    };
    _taskQueue.addTask(repo.id, metadata, (metadata) async {
      if (metadata["flow"] == DataFlow.delete) {
        return await client.syncDeleteRepo(repo.id);
      } else if (metadata["flow"] == DataFlow.push) {
        return await client.syncPushRepo(repo);
      }
      print("====== unknown flow: $metadata ========");
      return true;
    });
  }

  asyncPost(Post post, DataFlow flow) {
    print("sync controller sync post ${post.id}");
    var metadata = {
      "flow": flow,
      "type": "post",
      "data": post,
    };
    _taskQueue.addTask(post.id, metadata, (metadata) async {
      if (metadata["flow"] == DataFlow.delete) {
        return await client.syncDeletePost(post);
      } else if (metadata["flow"] == DataFlow.push) {
        return await client.syncPushPost(post);
      }
      print("====== unknown flow: $metadata ========");
      return true;
    });
  }
}
