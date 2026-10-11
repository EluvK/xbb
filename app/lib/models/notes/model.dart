import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sync_annotation/sync_annotation.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/notes/db.dart';
import 'package:xbb/models/permission.dart';

part 'model.g.dart';
part 'model.freezed.dart';

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

@Repository(collectionName: 'xbb', tableName: 'repo', db: NotesDB)
@freezed
abstract class Repo with _$Repo {
  const factory Repo({required String name, required String status, String? description}) = _Repo;

  factory Repo.fromJson(Map<String, dynamic> json) => _$RepoFromJson(json);
}

@Repository(collectionName: 'xbb', tableName: 'post', db: NotesDB, parentIdField: 'repoId')
@freezed
abstract class Post with _$Post {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Post({
    required String title,
    required String category,
    required String content,
    required String repoId,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

@Repository(collectionName: 'xbb', tableName: 'comment', db: NotesDB, parentIdField: 'postId')
@freezed
abstract class Comment with _$Comment {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory Comment({
    required String content,
    required String postId,
    String? parentId,
    int? paragraphIndex,
    String? paragraphHash,
  }) = _Comment;

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
}
