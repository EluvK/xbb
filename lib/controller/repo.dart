import 'package:get/get.dart';
import 'package:xbb/client/client.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/sync.dart';
import 'package:xbb/model/repo.dart';
import 'package:xbb/utils/utils.dart';

class RepoController extends GetxController {
  final allRepoList = <Repo>[].obs;
  final myRepoList = <Repo>[].obs;
  final subscribeRepoList = <Repo>[].obs;
  final currentRepoId = "0".obs;

  final settingController = Get.find<SettingController>();
  final postController = Get.find<PostController>();
  final asyncController = Get.find<AsyncController>();

  @override
  void onInit() async {
    await loadRepoLists();
    print("on init repos: ${allRepoList.length}");
    super.onInit();
  }

  loadRepoLists() async {
    // print('loadRepoLists --- start');
    var userId = settingController.currentUserId.value;
    allRepoList.value = await RepoRepository().listRepo(userId, RepoType.all);
    myRepoList.value = await RepoRepository().listRepo(userId, RepoType.owned);
    subscribeRepoList.value =
        await RepoRepository().listRepo(userId, RepoType.shared);
    print(
        "loadRepoLists current user id: $userId all/my/sub ${allRepoList.length}, ${myRepoList.length}, ${subscribeRepoList.length}");

    String repoId = allRepoList.firstWhereOrNull((repo) {
          return repo.id == settingController.currentRepoId.value;
        })?.id ??
        '0';
    print('set current repo to $repoId');
    await setCurrentRepo(repoId);
    // print('loadRepoLists --- end');
  }

  Future<void> setCurrentRepo(String repoId) async {
    settingController.setCurrentRepo(repoId);
    settingController.currentRepoId.value = repoId;
    currentRepoId.value = repoId;
    await postController.loadPost(repoId);
  }

  Future<void> saveRepo(Repo repo) async {
    print("on saveRepoNew: ${repo.id} ${repo.name}");
    asyncController.asyncRepo(repo, DataFlow.push);
    await RepoRepository().upsertRepo(repo);
    // reload
    await loadRepoLists();
  }

  Future<void> deleteRepo(Repo repo) async {
    print("on deleteRepo: ${repo.id} ${repo.name}");
    asyncController.asyncRepo(repo, DataFlow.delete);
    await RepoRepository().deleteRepo(repo.id);
    // reload
    await loadRepoLists();
  }

  Future<Repo?> doSubscribeRepo(String sharedLink) async {
    Repo? repo = await subscribeRepo(sharedLink);
    if (repo != null) {
      repo.sharedTo = settingController.currentUserId.value;
      repo.sharedLink = sharedLink;
      print("on saveRepoNew: ${repo.id} ${repo.name}");
      await RepoRepository().upsertRepo(repo);
      // reload
      await loadRepoLists();
    }
    return repo;
  }

  Future<void> doUnsubscribeRepo(String repoId) async {
    Repo repo = await getRepoUnwrap(repoId);
    await unsubscribeRepo(repoId);
    repo.sharedLink = null;
    repo.sharedTo = null;
    await RepoRepository().upsertRepo(repo);
    // reload
    await loadRepoLists();
    return;
  }

  Future<void> pullRepos() async {
    List<int> sumDiff = [0, 0, 0];
    List<Repo> repos = (await syncPullRepos()).fold((list) {
      return list;
    }, (err) {
      flushDiff("update_failed".tr, [-1, -1, -1]);
      return [];
    });
    for (var repo in repos) {
      Repo? localRepo = await RepoRepository().getRepo(repo.id);
      if (localRepo == null) {
        await RepoRepository().addRepo(repo);
      } else {
        localRepo = localRepo.copyWith(
          name: repo.name,
          description: repo.description,
          updatedAt: repo.updatedAt,
        );
        await RepoRepository().updateRepo(localRepo!);
      }
      if (repo.id != '0') {
        List<int> diff = await postController.pullPosts(repo.id);
        for (int i = 0; i < 3; i++) {
          sumDiff[i] += diff[i];
        }
        print('pullRepos diff $sumDiff');
      }
    }
    flushDiff("my_repo_update".tr, sumDiff);

    await loadRepoLists();
  }

  Future<void> pullSubscribeRepos() async {
    List<int> sumDiff = [0, 0, 0];
    List<Repo>? repos = await syncSubscribeRepos();
    if (repos == null) {
      flushDiff("update_failed".tr, [-1, -1, -1]);
      return;
    }
    for (var repo in repos) {
      repo.sharedTo = settingController.currentUserId.value;
      repo.sharedLink = sharedLink(repo.owner, repo.id);
      // Repo? localRepo = await RepoRepository().getRepo(repo.id);
      await RepoRepository().upsertRepo(repo);
      List<int> diff = await postController.pullPosts(repo.id);
      for (int i = 0; i < 3; i++) {
        sumDiff[i] += diff[i];
      }
      print('pullSubscribeRepos diff $sumDiff');
    }
    flushDiff("subscribe_repo_update".tr, sumDiff);
    await loadRepoLists();
  }

  Future<Repo> getRepoUnwrap(String repoId) async {
    return (await RepoRepository().getRepo(repoId))!;
  }

  editLocalRepoStatus(String repoId, {int? unreadCount}) async {
    Repo repo = await getRepoUnwrap(repoId);
    repo = repo.copyWith(unreadCount: unreadCount);
    await RepoRepository().updateRepo(repo);
    await loadRepoLists();
  }
}
