import 'package:json_annotation/json_annotation.dart';

part 'model.g.dart';

// @JsonEnum()
// enum RepoStatus {
//   normal,
//   deleted,
// }

@JsonSerializable()
class Repo {
  String name;
  String description;

  // todo add more local fields?

  Repo({required this.name, required this.description});

  factory Repo.fromJson(Map<String, dynamic> json) => _$RepoFromJson(json);
  Map<String, dynamic> toJson() => _$RepoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Post {
  String category;
  String title;
  String content;
  String repoId;

  // todo more local fields?

  Post({required this.category, required this.title, required this.content, required this.repoId});

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Comment {
  String content;
  String postId;
  String? parentId;

  // todo more local fields?

  Comment({required this.postId, required this.content, this.parentId});

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);
}
