import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sync_annotation/sync_annotation.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/models/notes/db.dart';

part 'model.g.dart';
part 'model.freezed.dart';

Future<void> reInitNotesSync(SyncStoreClient client) async {
  await reInit<RepoController>(() => RepoController(client), (c) => c.ensureInitialization());
  await reInit<PostController>(() => PostController(client), (c) => c.ensureInitialization());
  await reInit<CommentController>(() => CommentController(client), (c) => c.ensureInitialization());

  final RepoController repoController = Get.find<RepoController>();
  final SettingController settingController = Get.find<SettingController>();
  if (settingController.notesLastOpenedRepoId != null) {
    repoController.onSelectRepo(settingController.notesLastOpenedRepoId!);
  }
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
  }, permanent: true);
  if (initializer != null) {
    await initializer(controller);
  }
}

@Repository(collectionName: 'xbb', tableName: 'repo', db: NotesDB, withAcls: true)
@freezed
abstract class Repo with _$Repo {
  const factory Repo({required String name, required String status, String? description}) = _Repo;

  factory Repo.fromJson(Map<String, dynamic> json) => _$RepoFromJson(json);
}

@Repository(collectionName: 'xbb', tableName: 'post', db: NotesDB)
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

@Repository(collectionName: 'xbb', tableName: 'comment', db: NotesDB)
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
