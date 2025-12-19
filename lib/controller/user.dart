import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/constant.dart';
import 'package:xbb/controller/setting.dart';

class User {
  String id;
  String name;
  String avatarUrl;

  User({required this.id, required this.name, required this.avatarUrl});
}

// deprecated, use UserManagerController instead
// class UserController extends GetxController {
//   Map<String, User> users = {};

//   Future<void> loadUser(String userId) async {
//     if (!users.containsKey(userId)) {
//       var user = await getUserInfo(userId);
//       users[user.id] = user;
//     }
//   }

//   User getUserInfoLocalUnwrap(String userId) {
//     return users[userId] ?? User(id: userId, name: 'Unknown', avatarUrl: defaultAvatarLink);
//   }

//   Future<User> getUserInfo(String userId) async {
//     if (!users.containsKey(userId)) {
//       var user = await getUser(id: userId);
//       if (user != null) {
//         users[user.id] = User(id: user.id, name: user.name, avatarUrl: user.avatarUrl ?? defaultAvatarLink);
//       } else {
//         // error?
//         users[userId] = User(id: userId, name: 'Unknown', avatarUrl: defaultAvatarLink);
//       }
//     }
//     return users[userId]!;
//   }
// }

Future<void> reInitUserManagerController(SyncStoreClient client) async {
  if (Get.isRegistered<UserManagerController>()) {
    await Get.delete<UserManagerController>(force: true);
  }
  await Get.putAsync<UserManagerController>(() async {
    final ctrl = UserManagerController(client);
    await ctrl.ensureInitialization();
    return ctrl;
  });
}

class UserManagerController extends GetxController {
  final box = GetStorage(GET_STORAGE_FILE_KEY);
  final RxList<UserProfile> userProfiles = <UserProfile>[].obs;
  final RxList<String> friends = <String>[].obs;
  SyncStoreClient syncStoreClient;

  UserManagerController(this.syncStoreClient);
  final NewSettingController settingController = Get.find<NewSettingController>();

  @override
  Future<void> onInit() async {
    super.onInit();
    List<dynamic>? storedData = box.read(GET_STORAGE_USER_PROFILES_KEY);
    if (storedData != null) {
      userProfiles.value = storedData.map((e) => UserProfile.fromJson(e as Map<String, dynamic>)).toList();
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

  void addOrUpdateUserProfile(UserProfile profile) {
    int index = userProfiles.indexWhere((p) => p.userId == profile.userId);
    if (index != -1) {
      userProfiles[index] = profile;
    } else {
      userProfiles.add(profile);
    }
    // _saveToStorage();
  }

  // void removeUserProfile(String userId) {
  //   userProfiles.removeWhere((p) => p.userId == userId);
  //   _saveToStorage();
  // }

  void _saveToStorage() {
    List<Map<String, dynamic>> data = userProfiles.map((p) => p.toJson()).toList();
    box.write(GET_STORAGE_USER_PROFILES_KEY, data);
    box.write(GET_STORAGE_FRIENDS_KEY, friends.toList());
  }

  UserProfile getSelfProfile() {
    return userProfiles.firstWhere((p) => p.userId ==  settingController.userId );
  }

  Future<void> updateSelfProfile(UpdateUserProfileRequest newProfile) async {
    UserProfile updatedProfile = await syncStoreClient.updateProfile(settingController.userId, newProfile);
    addOrUpdateUserProfile(updatedProfile);
    settingController.updateUserInfo(userName: updatedProfile.name, userPassword: newProfile.password);
    _saveToStorage();
  }

  UserProfile? getUserProfile(String userId) {
    return userProfiles.firstWhereOrNull((p) => p.userId == userId);
  }

  Future<void> fetchAndUpdateUserProfiles() async {
    try {
      UserProfile self = await syncStoreClient.getProfile(settingController.userId);
      addOrUpdateUserProfile(self);
      List<UserProfile> profiles = await syncStoreClient.getFriends();
      for (var profile in profiles) {
        addOrUpdateUserProfile(profile);
      }
      friends.value = profiles.map((p) => p.userId).toList();
      _saveToStorage();
    } catch (e) {
      print('Error fetching user profiles: $e');
      // handle error
    }
  }
}
