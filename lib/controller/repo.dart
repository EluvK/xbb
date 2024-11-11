import 'package:get/get.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/sync.dart';
import 'package:xbb/model/repo.dart';

class RepoController extends GetxController {
  final allRepoList = <Repo>[].obs;
  final myRepoList = <Repo>[].obs;
  final subscribeRepoList = <Repo>[].obs;
  final currentRepoId = "0".obs;

  final settingController = Get.find<SettingController>();
  final postController = Get.find<PostController>();
  final syncController = Get.find<SyncController>();

  @override
  void onInit() async {
    await loadRepoLists();
    print("on init repos: ${allRepoList.length}");
    super.onInit();
  }

  loadRepoLists() async {
    var userId = settingController.currentUserId.value;
    allRepoList.value = await RepoRepository().listRepo(userId, RepoType.all);
    myRepoList.value = await RepoRepository().listRepo(userId, RepoType.owned);
    subscribeRepoList.value =
        await RepoRepository().listRepo(userId, RepoType.shared);

    String repoId = allRepoList.firstWhereOrNull((repo) {
          return repo.id == settingController.currentRepoId.value;
        })?.id ??
        '0';
    print('set current repo to $repoId');
    await setCurrentRepo(repoId);
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
    syncController.syncRepo(repo, DataFlow.push);
    await RepoRepository().upsertRepo(repo);
    // reload
    await loadRepoLists();
  }

  void subscribeRepo(Repo repo) async {
    print("on saveRepoNew: ${repo.id} ${repo.name}");
    await RepoRepository().upsertRepo(repo);
    // reload
    await loadRepoLists();
  }

  Future<Repo> getRepoUnwrap(String repoId) async {
    return (await RepoRepository().getRepo(repoId))!;
  }
}
