import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/controller/syncstore.dart';

class User {
  String id;
  String name;
  String avatarUrl;

  User({required this.id, required this.name, required this.avatarUrl});
}

Future<void> reInitUserManagerController() async {
  if (Get.isRegistered<UserManagerController>()) {
    await Get.delete<UserManagerController>(force: true);
  }
  await Get.putAsync<UserManagerController>(() async {
    final ctrl = UserManagerController();
    await ctrl.ensureInitialization();
    return ctrl;
  }, permanent: true);
}

class UserManagerController extends GetxController {
  final box = GetStorage(GET_STORAGE_FILE_KEY);
  final RxList<UserProfile> userProfiles = <UserProfile>[].obs;
  final Rx<UserProfile?> selfProfile = Rx<UserProfile?>(null);
  final RxList<String> friends = <String>[].obs;
  final SyncStoreControl syncStoreControl = Get.find<SyncStoreControl>();

  UserManagerController();
  final SettingController settingController = Get.find<SettingController>();

  @override
  Future<void> onInit() async {
    super.onInit();
    List<dynamic>? storedData = box.read(GET_STORAGE_USER_PROFILES_KEY);
    if (storedData != null) {
      userProfiles.value = storedData.map((e) => UserProfile.fromJson(e as Map<String, dynamic>)).toList();
      selfProfile.value = userProfiles.firstWhereOrNull((p) => p.userId == settingController.userId);
      userProfiles.removeWhere((p) => p.userId == settingController.userId);
    }
    List<dynamic>? storedFriends = box.read(GET_STORAGE_FRIENDS_KEY);
    if (storedFriends != null) {
      friends.value = storedFriends.cast<String>();
    }

    _initialized = true;
  }

  bool _initialized = false;
  Future<void> ensureInitialization() async {
    while (!_initialized) {
      await onInit();
    }
    return;
  }

  // void removeUserProfile(String userId) {
  //   userProfiles.removeWhere((p) => p.userId == userId);
  //   _saveToStorage();
  // }

  void _saveToStorage() {
    List<Map<String, dynamic>> data = userProfiles.map((p) => p.toJson()).toList();
    data.addIf(selfProfile.value != null, selfProfile.value!.toJson());
    box.write(GET_STORAGE_USER_PROFILES_KEY, data);
    box.write(GET_STORAGE_FRIENDS_KEY, friends.toList());
  }

  // UserProfile get selfProfile => userProfiles.firstWhere((p) => p.userId == settingController.userId);

  Future<void> updateSelfProfile(UpdateUserProfileRequest newProfile) async {
    UserProfile updatedProfile = await syncStoreControl.syncStoreClient.updateProfile(
      settingController.userId,
      newProfile,
    );
    selfProfile.value = updatedProfile;
    settingController.updateUserInfo(userName: updatedProfile.name, userPassword: newProfile.password);
    settingController.updateQuickLoginInfoIfExist(updatedProfile.userId, updatedProfile);
    _saveToStorage();
  }

  UserProfile? getUserProfile(String userId) {
    return userProfiles.firstWhereOrNull((p) => p.userId == userId);
  }

  Future<void> fetchAndUpdateUserProfiles() async {
    try {
      UserProfile self = await syncStoreControl.syncStoreClient.getProfile(settingController.userId);
      selfProfile.value = self;
      List<UserProfile> profiles = await syncStoreControl.syncStoreClient.getFriends();
      userProfiles.value = profiles;
      // userProfiles.removeWhere((p) => p.userId == settingController.userId);
      // userProfiles.removeWhere((p) => !profiles.any((f) => f.userId == p.userId));
      // for (var profile in profiles) {
      //   int index = userProfiles.indexWhere((p) => p.userId == profile.userId);
      //   if (index != -1) {
      //     userProfiles[index] = profile;
      //   } else {
      //     userProfiles.add(profile);
      //   }
      // }

      friends.value = profiles.map((p) => p.userId).toList();
      _saveToStorage();
    } catch (e) {
      print('Error fetching user profiles: $e');
      // handle error
    }
  }

  bool checkPermission(
    FeaturePermission permission,
    String resourceOwnerId,
    List<Permission> resourceAcls, {
    String? resourceRootOwnerId,
  }) {
    if (selfProfile.value == null) {
      return false; // Not initialized, deny access
    }
    if (selfProfile.value!.userId == resourceOwnerId || selfProfile.value!.userId == resourceRootOwnerId) {
      print('debug: user is owner, grant access');
      return true;
    }
    Permission? userPermission = resourceAcls.firstWhereOrNull((p) => p.user == selfProfile.value!.userId);
    if (userPermission == null) {
      print('debug: no specific permission found for user, deny access');
      return false;
    }
    int userAclMask = ACLMask.fromAccessLevel(userPermission.accessLevel);
    bool granted = ACLMask.has(userAclMask, permission.requiredAclMask);
    print(
      'debug: user permission level: ${userPermission.accessLevel}, required level: ${permission.requiredAclMask} (mask: $userAclMask), access granted: $granted',
    );
    return granted;
  }
}

abstract class FeaturePermission {
  int get requiredAclMask;
}

// todo maybe move somewhere else?
enum NotesFeatureRequires implements FeaturePermission {
  updateRepo(ACLMask.updateOnly),
  updatePost(ACLMask.updateOnly),
  deleteRepo(ACLMask.deleteOnly),
  deletePost(ACLMask.deleteOnly),
  newComment(ACLMask.append2Below),
  replyComment(ACLMask.append2Below),
  editComment(ACLMask.updateOnly),
  deleteComment(ACLMask.deleteOnly),
  fullAccess(ACLMask.fullAccess);

  @override
  final int requiredAclMask;

  const NotesFeatureRequires(this.requiredAclMask);
}
