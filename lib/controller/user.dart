import 'package:get/get.dart';
import 'package:xbb/client/client.dart';
import 'package:xbb/utils/predefined.dart';

class User {
  String id;
  String name;
  String avatarUrl;

  User({required this.id, required this.name, required this.avatarUrl});
}

class UserController extends GetxController {
  Map<String, User> users = {};

  Future<void> loadUser(String userId) async {
    if (!users.containsKey(userId)) {
      var user = await getUserInfo(userId);
      users[user.id] = user;
    }
  }

  User getUserInfoLocalUnwrap(String userId) {
    return users[userId] ??
        User(
          id: userId,
          name: 'Unknown',
          avatarUrl: defaultAvatarLink,
        );
  }

  Future<User> getUserInfo(String userId) async {
    if (!users.containsKey(userId)) {
      var user = await getUser(id: userId);
      if (user != null) {
        users[user.id] = User(
          id: user.id,
          name: user.name,
          avatarUrl: user.avatarUrl ?? defaultAvatarLink,
        );
      } else {
        // error?
        users[userId] = User(
          id: userId,
          name: 'Unknown',
          avatarUrl: defaultAvatarLink,
        );
      }
    }
    return users[userId]!;
  }
}
