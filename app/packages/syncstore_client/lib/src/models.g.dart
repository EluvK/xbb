// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  userId: json['user_id'] as String,
  name: json['name'] as String,
  avatarUrl: json['avatar_url'] as String?,
  publicKey: json['public_key'] as String,
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) => <String, dynamic>{
  'user_id': instance.userId,
  'name': instance.name,
  'avatar_url': instance.avatarUrl,
  'public_key': instance.publicKey,
};

UpdateUserProfileRequest _$UpdateUserProfileRequestFromJson(Map<String, dynamic> json) => UpdateUserProfileRequest(
  name: json['name'] as String?,
  password: json['password'] as String?,
  avatarUrl: json['avatar_url'] as String?,
);

Map<String, dynamic> _$UpdateUserProfileRequestToJson(UpdateUserProfileRequest instance) => <String, dynamic>{
  'name': instance.name,
  'password': instance.password,
  'avatar_url': instance.avatarUrl,
};

DataItem<T> _$DataItemFromJson<T>(Map<String, dynamic> json, T Function(Object? json) fromJsonT) => DataItem<T>(
  json['id'] as String,
  DateTime.parse(json['created_at'] as String),
  DateTime.parse(json['updated_at'] as String),
  json['owner'] as String,
  json['parent_id'] as String?,
  json['unique'] as String?,
  body: fromJsonT(json['body']),
  syncStatus: $enumDecodeNullable(_$SyncStatusEnumMap, json['sync_status']) ?? SyncStatus.synced,
  colorTag: $enumDecodeNullable(_$ColorTagEnumMap, json['color_tag']) ?? ColorTag.none,
);

Map<String, dynamic> _$DataItemToJson<T>(DataItem<T> instance, Object? Function(T value) toJsonT) => <String, dynamic>{
  'id': instance.id,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'owner': instance.owner,
  'parent_id': instance.parentId,
  'unique': instance.unique,
  'sync_status': _$SyncStatusEnumMap[instance.syncStatus]!,
  'color_tag': _$ColorTagEnumMap[instance.colorTag]!,
  'body': toJsonT(instance.body),
};

const _$SyncStatusEnumMap = {
  SyncStatus.failed: 'failed',
  SyncStatus.deleted: 'deleted',
  SyncStatus.hidden: 'hidden',
  SyncStatus.pending: 'pending',
  SyncStatus.syncing: 'syncing',
  SyncStatus.synced: 'synced',
  SyncStatus.archived: 'archived',
};

const _$ColorTagEnumMap = {
  ColorTag.none: 'none',
  ColorTag.red: 'red',
  ColorTag.orange: 'orange',
  ColorTag.yellow: 'yellow',
  ColorTag.green: 'green',
  ColorTag.blue: 'blue',
  ColorTag.gray: 'gray',
};

DataItemSummary _$DataItemSummaryFromJson(Map<String, dynamic> json) => DataItemSummary(
  json['id'] as String,
  DateTime.parse(json['created_at'] as String),
  DateTime.parse(json['updated_at'] as String),
  json['owner'] as String,
  json['parent_id'] as String?,
  json['unique'] as String?,
);

Map<String, dynamic> _$DataItemSummaryToJson(DataItemSummary instance) => <String, dynamic>{
  'id': instance.id,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'owner': instance.owner,
  'parent_id': instance.parentId,
  'unique': instance.unique,
};

PageInfo _$PageInfoFromJson(Map<String, dynamic> json) =>
    PageInfo(count: (json['count'] as num).toInt(), nextMarker: json['next_marker'] as String?);

Map<String, dynamic> _$PageInfoToJson(PageInfo instance) => <String, dynamic>{
  'count': instance.count,
  'next_marker': instance.nextMarker,
};

ListResponse _$ListResponseFromJson(Map<String, dynamic> json) => ListResponse(
  items: (json['items'] as List<dynamic>).map((e) => DataItemSummary.fromJson(e as Map<String, dynamic>)).toList(),
  pageInfo: PageInfo.fromJson(json['page_info'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ListResponseToJson(ListResponse instance) => <String, dynamic>{
  'items': instance.items,
  'page_info': instance.pageInfo,
};

BatchGetResponse<T> _$BatchGetResponseFromJson<T>(Map<String, dynamic> json, T Function(Object? json) fromJsonT) =>
    BatchGetResponse<T>(
      items: (json['items'] as List<dynamic>)
          .map((e) => DataItem<T>.fromJson(e as Map<String, dynamic>, (value) => fromJsonT(value)))
          .toList(),
      truncated: json['truncated'] as String?,
    );

Map<String, dynamic> _$BatchGetResponseToJson<T>(BatchGetResponse<T> instance, Object? Function(T value) toJsonT) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson((value) => toJsonT(value))).toList(),
      'truncated': instance.truncated,
    };

Permission _$PermissionFromJson(Map<String, dynamic> json) =>
    Permission(user: json['user'] as String, accessLevel: $enumDecode(_$AccessLevelEnumMap, json['access_level']));

Map<String, dynamic> _$PermissionToJson(Permission instance) => <String, dynamic>{
  'user': instance.user,
  'access_level': _$AccessLevelEnumMap[instance.accessLevel]!,
};

const _$AccessLevelEnumMap = {
  AccessLevel.none: 'none',
  AccessLevel.read: 'read',
  AccessLevel.read_append1: 'read_append1',
  AccessLevel.read_append2: 'read_append2',
  AccessLevel.read_append3: 'read_append3',
  AccessLevel.update: 'update',
  AccessLevel.write: 'write',
  AccessLevel.fullAccess: 'full_access',
};
