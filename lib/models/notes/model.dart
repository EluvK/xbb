import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:sync_annotation/sync_annotation.dart';
import 'package:xbb/models/notes/db.dart';

part 'model.g.dart';

// @JsonEnum()
// enum RepoStatus {
//   normal,
//   deleted,
// }

@Repository(tableName: 'repo', db: NotesDB)
@JsonSerializable()
class Repo {
  String name;
  String status;
  String? description;

  // todo add more local fields?

  Repo({required this.name, required this.status, this.description});

  factory Repo.fromJson(Map<String, dynamic> json) => _$RepoFromJson(json);
  Map<String, dynamic> toJson() => _$RepoToJson(this);
}

@Repository(tableName: 'post', db: NotesDB)
@JsonSerializable(fieldRename: FieldRename.snake)
class Post {
  String title;
  String category;
  String content;
  String repoId;

  // todo more local fields?

  Post({required this.title, required this.category, required this.content, required this.repoId});

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}

@Repository(tableName: 'comment', db: NotesDB)
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
