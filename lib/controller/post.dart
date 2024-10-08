import 'package:get/get.dart';
import 'package:xbb/model/post.dart';

class PostController extends GetxController {
  final postList = <Post>[].obs;

  Future<void> loadPost(String repoId) async {
    postList.value = await PostRepository().getRepoPosts(repoId);
  }
}
