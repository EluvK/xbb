import 'package:get/get.dart';
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

  // List<String> listRepoNames() {
  //   return repoList.map((element) => element.name).toList();
  // }
}
