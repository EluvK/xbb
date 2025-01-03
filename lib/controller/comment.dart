import 'package:get/get.dart';
import 'package:xbb/client/client.dart';
import 'package:xbb/model/comment.dart';

class CommentController extends GetxController {
  // final commentList = <Comment>[].obs;

  Future<List<Comment>> loadComments(String repoId, String postId) async {
    return await CommentRepository().getComments(repoId, postId);
  }

  Future<Comment?> addNewComment(
    String repoId,
    String postId,
    String content,
  ) async {
    Comment? result = (await addComment(repoId, postId, content)).fold(
      (Comment comment) {
        CommentRepository().addComment(comment);
        return comment;
      },
      (error) {
        return null;
      },
    );
    return result;
  }

  Future<Comment?> replyComment(
    String repoId,
    String postId,
    String content,
    String parentId,
  ) async {
    // todo
    // var comment =
    // return await CommentRepository().replyComment(repoId, postId, content, parentId);
    return null;
  }
}
