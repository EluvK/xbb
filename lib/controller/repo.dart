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
    print('loadRepoLists --- start');
    var userId = settingController.currentUserId.value;
    allRepoList.value = await RepoRepository().listRepo(userId, RepoType.all);
    myRepoList.value = await RepoRepository().listRepo(userId, RepoType.owned);
    subscribeRepoList.value =
        await RepoRepository().listRepo(userId, RepoType.shared);
    print(
        "all/my/sub ${allRepoList.length}, ${myRepoList.length}, ${subscribeRepoList.length}");

    String repoId = allRepoList.firstWhereOrNull((repo) {
          return repo.id == settingController.currentRepoId.value;
        })?.id ??
        '0';
    print('set current repo to $repoId');
    await setCurrentRepo(repoId);
    print('loadRepoLists --- end');
  }

  bool isCurrentRepo(String repoId) {
    return currentRepoId.value == repoId;
  }

  Future<void> setCurrentRepo(String repoId) async {
    settingController.setCurrentRepo(repoId);
    settingController.currentRepoId.value = repoId;
    currentRepoId.value = repoId;
    await postController.loadPost(repoId);
  }

  void saveRepo(Repo repo) async {
    print("on saveRepoNew: ${repo.id} ${repo.name}");
    asyncController.asyncRepo(repo, DataFlow.push);
    await RepoRepository().upsertRepo(repo);
    // reload
    await loadRepoLists();
  }

  Future<Repo?> pushSubscribeRepo(String sharedLink) async {
    Repo? repo = await subscribeRepo(sharedLink);
    if (repo != null) {
      repo.sharedTo = settingController.currentUserId.value;
      repo.sharedTo = sharedLink;
      print("on saveRepoNew: ${repo.id} ${repo.name}");
      await RepoRepository().upsertRepo(repo);
      // reload
      await loadRepoLists();
    }
    return repo;
  }

  Future<void> pullRepos() async {
    List<Repo> repos = await syncPullRepos();
    for (var repo in repos) {
      Repo? localRepo = await RepoRepository().getRepo(repo.id);
      if (localRepo == null) {
        await RepoRepository().addRepo(repo);
      } else {
        localRepo.name = repo.name;
        localRepo.description = repo.description;
        localRepo.updatedAt = repo.updatedAt;
        await RepoRepository().updateRepo(localRepo);
      }
      // todo sync posts maybe async way
    }

    await loadRepoLists();
  }

  Future<void> pullSubscribeRepos() async {
    List<Repo> repos = await syncSubscribeRepos();
    for (var repo in repos) {
      repo.sharedTo = settingController.currentUserId.value;
      repo.sharedLink = sharedLink(repo.owner, repo.id);
      Repo? localRepo = await RepoRepository().getRepo(repo.id);
      if (localRepo == null ||
          localRepo.sharedTo != settingController.currentUserId.value) {
        await RepoRepository().upsertRepo(repo);
        // todo sync posts maybe async way
      }
    }
    await loadRepoLists();
  }

  Future<Repo> getRepoUnwrap(String repoId) async {
    return (await RepoRepository().getRepo(repoId))!;
  }
}
