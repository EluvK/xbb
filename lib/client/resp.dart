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
