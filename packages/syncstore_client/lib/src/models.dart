import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'models.g.dart';

// --- UserProfile ---

@JsonSerializable(fieldRename: FieldRename.snake)
class UserProfile {
  final String userId;
  final String name;
  final String? avatarUrl;
  final String publicKey;

  UserProfile({required this.userId, required this.name, this.avatarUrl, required this.publicKey});
  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UpdateUserProfileRequest {
  final String? name;
  final String? password;
  final String? avatarUrl;

  UpdateUserProfileRequest({this.name, this.password, this.avatarUrl});
  factory UpdateUserProfileRequest.fromJson(Map<String, dynamic> json) => _$UpdateUserProfileRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateUserProfileRequestToJson(this);
}

// --- Data Models ---

enum SyncStatus { failed, deleted, hidden, pending, syncing, synced, archived }

enum ColorTag { none, red, orange, yellow, green, blue, gray }

@JsonSerializable(fieldRename: FieldRename.snake, genericArgumentFactories: true)
class DataItem<T> {
  final String id; 
  final DateTime createdAt;
  final DateTime updatedAt;
  final String owner;
  final String? parentId;
  final String? unique;

  // below fields are client-side only, but since nothings happened even we do send it to server
  // it's ok to keep it here to make this usage easier, less type gymnastics.
  SyncStatus syncStatus;
  ColorTag colorTag;

  final T body;

  DataItem(
    this.id,
    this.createdAt,
    this.updatedAt,
    this.owner,
    this.parentId,
    this.unique, {
    required this.body,
    // the default is synced, as we usually fetch data from server, which is definitely ''synced''
    this.syncStatus = SyncStatus.synced,
    this.colorTag = ColorTag.none,
  });

  factory DataItem.localNew(String owner, T body, {String? parentId, String? unique}) {
    final id = Uuid().v4();
    final now = DateTime.now().toUtc();
    return DataItem<T>(id, now, now, owner, parentId, unique, body: body, syncStatus: SyncStatus.pending);
  }

  // ? what's the design philosophy here?
  DataItem<T> updatedBody(T newBody) {
    return DataItem<T>(
      id,
      createdAt,
      DateTime.now().toUtc(),
      owner,
      parentId,
      unique,
      body: newBody,
      // when updated, set to pending, since we need to sync it to server again.
      syncStatus: SyncStatus.pending,
      colorTag: colorTag,
    );
  }

  factory DataItem.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$DataItemFromJson(json, fromJsonT);
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => _$DataItemToJson(this, toJsonT);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class DataItemSummary {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String owner;
  final String? parentId;
  final String? unique;

  DataItemSummary(this.id, this.createdAt, this.updatedAt, this.owner, this.parentId, this.unique);
  factory DataItemSummary.fromJson(Map<String, dynamic> json) => _$DataItemSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$DataItemSummaryToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PageInfo {
  final int count;
  final String? nextMarker;

  PageInfo({required this.count, this.nextMarker});

  factory PageInfo.fromJson(Map<String, dynamic> json) => _$PageInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PageInfoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ListResponse {
  final List<DataItemSummary> items;
  final PageInfo pageInfo;

  ListResponse({required this.items, required this.pageInfo});

  factory ListResponse.fromJson(Map<String, dynamic> json) => _$ListResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ListResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, genericArgumentFactories: true)
class BatchGetResponse<T> {
  final List<DataItem<T>> items;
  final String? truncated;

  BatchGetResponse({required this.items, this.truncated});

  factory BatchGetResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$BatchGetResponseFromJson(json, fromJsonT);
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => _$BatchGetResponseToJson(this, toJsonT);

}

@JsonEnum(fieldRename: FieldRename.snake)
enum AccessLevel {
  none, // `none` only exist at client side to make UI easier
  read,
  read_append1,
  read_append2,
  read_append3,
  update,
  write,
  fullAccess,
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Permission {
  final String user;
  final AccessLevel accessLevel;

  Permission({required this.user, required this.accessLevel});

  factory Permission.fromJson(Map<String, dynamic> json) => _$PermissionFromJson(json);
  Map<String, dynamic> toJson() => _$PermissionToJson(this);
}

// --- ACL DataBase Requires ---
const String onCreateTableAcl = """
CREATE TABLE IF NOT EXISTS acl (
  data_id TEXT PRIMARY KEY,
  data_collection TEXT NOT NULL,
  permissions TEXT NOT NULL
);
""";

/// this part should keep the same as syncstore server implementation
class ACLMask {
  static const int readOnly = 0x01; // 000001
  static const int updateOnly = 0x02; // 000010
  static const int deleteOnly = 0x04; // 000100
  static const int append3Below = 0x08; // 001000
  static const int append2Below = 0x18; // 011000 (包含 bit 3)
  static const int append1Below = 0x38; // 111000 (包含 bit 3, 4)
  static const int fullAccess = 0x3F; // 111111

  static int fromAccessLevel(AccessLevel level) {
    switch (level) {
      case AccessLevel.read:
        return readOnly;
      case AccessLevel.read_append1:
        return readOnly | append1Below;
      case AccessLevel.read_append2:
        return readOnly | append2Below;
      case AccessLevel.read_append3:
        return readOnly | append3Below;
      case AccessLevel.update:
        return readOnly | updateOnly;
      case AccessLevel.write:
        return readOnly | updateOnly | append1Below;
      case AccessLevel.fullAccess:
        return fullAccess;
      case AccessLevel.none:
        return 0;
    }
  }

  static bool has(int currentMask, int requiredBit) {
    return (currentMask & requiredBit) == requiredBit;
  }
}
