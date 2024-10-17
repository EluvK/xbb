import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:xbb/components/repo_editor.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/model/repo.dart';

class RepoController extends GetxController {
  final repoList = <Repo>[].obs;
  final currentRepo = "".obs;

  final settingController = Get.find<SettingController>();

  @override
  void onInit() async {
    repoList.value = await RepoRepository().listRepo();
    currentRepo.value = settingController.currentRepoId.value.isEmpty
        ? 'local'
        : settingController.currentRepoId.value;
    print("on init repos: ${repoList.length}");
    super.onInit();
  }

  void setCurrentRepo(String repoId) {
    settingController.setCurrentRepo(repoId);
    settingController.currentRepoId.value = repoId;
    currentRepo.value = repoId;
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
    repoList.value = await RepoRepository().listRepo();
  }

  Future<Repo> getRepo(String repoId) async {
    return await RepoRepository().getRepo(repoId);
  }

  // List<String> listRepoNames() {
  //   return repoList.map((element) => element.name).toList();
  // }
}
