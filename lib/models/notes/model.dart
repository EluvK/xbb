import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sync_annotation/sync_annotation.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/notes/db.dart';

part 'model.g.dart';

Future<void> reInitNotesSync(SyncStoreClient client) async {
  await reInit<RepoController>(() => RepoController(client), (c) => c.ensureInitialization());
  await reInit<PostController>(() => PostController(client), (c) => c.ensureInitialization());
  await reInit<CommentController>(() => CommentController(client), (c) => c.ensureInitialization());
}

Future<void> reInit<T extends GetxController>(
  FutureOr<T> Function() creator,
  FutureOr<void> Function(T controller)? initializer,
) async {
  if (Get.isRegistered<T>()) {
    await Get.delete<T>(force: true);
  }
  final controller = await Get.putAsync<T>(() async {
    return await creator();
  });
  if (initializer != null) {
    await initializer(controller);
  }
}

@Repository(collectionName: 'xbb', tableName: 'repo', db: NotesDB)
@JsonSerializable()
class Repo {
  String name;
  String status;
  String? description;

  Repo({required this.name, required this.status, this.description});

  factory Repo.fromJson(Map<String, dynamic> json) => _$RepoFromJson(json);
  Map<String, dynamic> toJson() => _$RepoToJson(this);
}

@Repository(collectionName: 'xbb', tableName: 'post', db: NotesDB)
@JsonSerializable(fieldRename: FieldRename.snake)
class Post {
  String title;
  String category;
  String content;
  String repoId;

  Post({required this.title, required this.category, required this.content, required this.repoId});

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}

@Repository(collectionName: 'xbb', tableName: 'comment', db: NotesDB)
@JsonSerializable(fieldRename: FieldRename.snake)
class Comment {
  String content;
  String postId;
  String? parentId;

  Comment({required this.postId, required this.content, this.parentId});

  factory Comment.fromJson(Map<String, dynamic> json) => _$CommentFromJson(json);
  Map<String, dynamic> toJson() => _$CommentToJson(this);
}
