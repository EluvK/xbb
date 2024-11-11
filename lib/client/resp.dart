import 'package:xbb/model/repo.dart';

class OpenApiGetUserResponse {
  String id;
  String name;
  String? avatarUrl;

  OpenApiGetUserResponse({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory OpenApiGetUserResponse.fromResp(Map<String, dynamic> map) {
    return OpenApiGetUserResponse(
      id: map["id"],
      name: map["name"],
      avatarUrl: map.containsKey("avatar_url") ? map["avatar_url"] : null,
    );
  }
}

class OpenApiGetRepoResponse {
  String id;
  String name;
  String owner; //owner user id
  String description;
  DateTime createdAt;
  DateTime updatedAt;

  OpenApiGetRepoResponse({
    required this.id,
    required this.name,
    required this.owner,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OpenApiGetRepoResponse.fromResp(Map<String, dynamic> map) {
    return OpenApiGetRepoResponse(
      id: map["id"],
      name: map["name"],
      owner: map["owner"],
      description: map["description"],
      createdAt: DateTime.parse(map["createdAt"]),
      updatedAt: DateTime.parse(map["updatedAt"]),
    );
  }

  Repo toRepo() {
    return Repo(
      id: id,
      name: name,
      owner: owner,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastSyncAt: DateTime.parse(neverSyncAt),
      remoteRepo: true,
      autoSync: true,
    );
  }
}
