import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:xbb/controller/post.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/model/repo.dart';

class RepoController extends GetxController {
  final repoList = <Repo>[].obs;
  final currentRepoId = "".obs;

  final settingController = Get.find<SettingController>();
  final postController = Get.find<PostController>();

  @override
  void onInit() async {
    await loadRepoLists();
    print("on init repos: ${repoList.length}");
    super.onInit();
  }

  loadRepoLists() async {
    repoList.value =
        await RepoRepository().listRepo(settingController.currentUser.value);
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

  void saveRepo(String? repoId, String name) async {
    print("on saveRepo: $repoId, $name");
    if (repoId == null) {
      // new onw
      var repo = Repo(
        id: const Uuid().v4(),
        name: name,
        owner: settingController.currentUser.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastSyncAt: DateTime.parse(neverSyncAt),
      );
      await RepoRepository().addRepo(repo);
    } else {
      // edit exist post
      var repo = await getRepo(repoId);
      repo.name = name;
      repo.updatedAt = DateTime.now();
      await RepoRepository().updateRepo(repo);
    }
    Get.toNamed('/');
    // reload
    await loadRepoLists();
  }

  Future<Repo> getRepo(String repoId) async {
    return await RepoRepository().getRepo(repoId);
  }

  // List<String> listRepoNames() {
  //   return repoList.map((element) => element.name).toList();
  // }
}
