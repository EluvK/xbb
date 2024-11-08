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

    String repoId = repoList.firstWhereOrNull((repo) {
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

  String? repoName(String repoId) {
    return repoList.firstWhereOrNull((element) => element.id == repoId)?.name;
  }

  void saveRepo(Repo repo) async {
    repo.updatedAt = DateTime.now().toUtc();
    print("on saveRepoNew: ${repo.id} ${repo.name}");
    syncController.syncRepo(repo, DataFlow.push);
    await RepoRepository().upsertRepo(repo);
    // reload
    await loadRepoLists();
    Get.toNamed('/');
  }

  Future<Repo> getRepoUnwrap(String repoId) async {
    return (await RepoRepository().getRepo(repoId))!;
  }
}
