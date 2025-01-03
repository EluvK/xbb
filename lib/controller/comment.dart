import 'package:get/get.dart';
import 'package:xbb/model/comment.dart';

class CommentController extends GetxController {
  // final commentList = <Comment>[].obs;

  Future<List<Comment>> loadComments(String repoId, String postId) async {
    return await CommentRepository().getComments(repoId, postId);
  }
}
