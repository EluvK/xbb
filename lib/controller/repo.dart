import 'package:get/get.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/sync.dart';
import 'package:xbb/model/repo.dart';

class RepoController extends GetxController {
  final repoList = <Repo>[].obs;
  final currentRepoId = "".obs;

  final settingController = Get.find<SettingController>();
  final postController = Get.find<PostController>();
  final syncController = Get.find<SyncController>();

  @override
  void onInit() async {
    await loadRepoLists();
    print("on init repos: ${repoList.length}");
    super.onInit();
  }

  loadRepoLists() async {
    repoList.value =
        await RepoRepository().listRepo(settingController.currentUserId.value);
    if (repoList.firstWhereOrNull(
          (repo) {
            return repo.id == settingController.currentRepoId.value;
          },
        ) !=
        null) {
      currentRepoId.value = settingController.currentRepoId.value;
    }
    setCurrentRepo("0"); // return to local
  }

  bool isCurrentRepo(String repoId) {
    return currentRepoId.value == repoId;
  }

  void setCurrentRepo(String repoId) {
    settingController.setCurrentRepo(repoId);
    settingController.currentRepoId.value = repoId;
    currentRepoId.value = repoId;
    postController.loadPost(repoId);
  }

  String? repoName(String repoId) {
    return repoList.firstWhereOrNull((element) => element.id == repoId)?.name;
  }

  void saveRepo(Repo repo) async {
    repo.updatedAt = DateTime.now().toUtc();
    print("on saveRepoNew: ${repo.id} ${repo.name}");
    syncController.syncRepo(repo, DataFlow.push);
    await RepoRepository().upsertRepo(repo);
    Get.toNamed('/');
    // reload
    await loadRepoLists();
  }

  Future<Repo> getRepoUnwrap(String repoId) async {
    return (await RepoRepository().getRepo(repoId))!;
  }

  // List<String> listRepoNames() {
  //   return repoList.map((element) => element.name).toList();
  // }
}
