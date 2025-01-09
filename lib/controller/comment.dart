import 'package:get/get.dart';
import 'package:xbb/client/client.dart';
import 'package:xbb/controller/user.dart';
import 'package:xbb/model/comment.dart';
import 'package:xbb/model/post.dart';

class CommentController extends GetxController {
  final UserController userController = Get.find<UserController>();

  Future<PostCommentStatus> syncComments(
    String repoId,
    String postId,
    List<CommentSummary> remoteComments,
  ) async {
    PostCommentStatus result = PostCommentStatus.normal;
    var comments = await CommentRepository().getComments(repoId, postId);
    for (var comment in comments) {
      if (remoteComments.indexWhere((element) => element.id == comment.id) ==
          -1) {
        // delete local comment
        CommentRepository().deleteComment(comment.id);
      }
    }

    for (var remoteComment in remoteComments) {
      var localComment = await CommentRepository().getComment(remoteComment.id);
      if (localComment == null) {
        // add local comment
        Comment? fetchComment =
            (await getComment(repoId, postId, remoteComment.id)).getOrNull();
        if (fetchComment != null) {
          CommentRepository().addComment(fetchComment);
          result = PostCommentStatus.newly;
        }
      } else if (localComment.updatedAt.isBefore(remoteComment.updatedAt)) {
        // update local comment
        Comment? fetchComment =
            (await getComment(repoId, postId, remoteComment.id)).getOrNull();
        if (fetchComment != null) {
          CommentRepository().updateComment(fetchComment);
          result = PostCommentStatus.updated;
        }
      }
    }
    return result;
  }

  Future<List<Comment>> loadComments(String repoId, String postId) async {
    // todo load from server?

    var comments = await CommentRepository().getComments(repoId, postId);
    // ensure user info loaded
    for (var comment in comments) {
      await userController.loadUser(comment.author);
    }
    return comments;
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
        (await editComment(repoId, postId, content, commentId)).fold(
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

  Future<bool> deleteExistComment(
      String repoId, String postId, String commentId) async {
    return (await deleteComment(repoId, postId, commentId)).fold(
      (value) {
        CommentRepository().deleteComment(commentId);
        return true;
      },
      (error) {
        return false;
      },
    );
  }
}
