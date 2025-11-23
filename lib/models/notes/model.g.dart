// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Repo _$RepoFromJson(Map<String, dynamic> json) =>
    Repo(name: json['name'] as String, description: json['description'] as String);

Map<String, dynamic> _$RepoToJson(Repo instance) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
};

Post _$PostFromJson(Map<String, dynamic> json) => Post(
  category: json['category'] as String,
  title: json['title'] as String,
  content: json['content'] as String,
  repoId: json['repo_id'] as String,
);

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
  'category': instance.category,
  'title': instance.title,
  'content': instance.content,
  'repo_id': instance.repoId,
};

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
  postId: json['post_id'] as String,
  content: json['content'] as String,
  parentId: json['parent_id'] as String?,
);

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
  'content': instance.content,
  'post_id': instance.postId,
  'parent_id': instance.parentId,
};
