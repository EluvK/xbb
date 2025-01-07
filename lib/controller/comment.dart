import 'package:get/get.dart';
import 'package:xbb/client/client.dart';
import 'package:xbb/model/comment.dart';

class CommentController extends GetxController {
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

  Future<Comment?> editExistComment(
    String repoId,
    String postId,
    String commentId,
    String content,
  ) async {
    Comment? result =
        (await editComment(repoId, postId, commentId, content)).fold(
      (Comment comment) {
        CommentRepository().updateComment(comment);
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
    Comment? result =
        (await addReplyComment(repoId, postId, content, parentId)).fold(
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
}
