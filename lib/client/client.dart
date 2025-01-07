import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:result_dart/result_dart.dart';
import 'package:xbb/client/err.dart';
import 'package:xbb/client/resp.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/model/comment.dart';
import 'package:xbb/model/post.dart';
import 'package:xbb/model/repo.dart';

enum ClientRequestResult { ok, reject, error }

class XbbClient {
  final String baseUrl;
  XbbClient({required this.baseUrl});

  // GET `/version/version`
  ClientResult<String> getLatestVersion(String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request =
          await client.getUrl(Uri.parse("$baseUrl/version"));
      request.headers.set('Authorization', auth);
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String responseBody = await response.transform(utf8.decoder).join();
        Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        return Success(jsonResponse['version']);
      } else {
        // print("getLastestVersion error ${response.statusCode}");
        return const Failure(ClientError.unexpectedError);
      }
    } catch (e) {
      print("error: $e");
      return const Failure(ClientError.internalError);
    }
  }

  // GET `/health`
  Future<bool> validateServerHealth() async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request =
          await client.getUrl(Uri.parse("$baseUrl/health"));
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print("error: $e");
    }
    return false;
  }

  // GET `/user/validate-name/$name`
  ClientResult<bool> validateUserNameExist(String name) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request =
          await client.getUrl(Uri.parse("$baseUrl/user/validate-name/$name"));
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String responseBody = await response.transform(utf8.decoder).join();
        Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        return Success(jsonResponse['exist']);
      } else {
        return const Success(false);
      }
    } catch (e) {
      print("error: $e");
      return const Failure(ClientError.internalError);
    }
  }

  // POST `/user/validate-login`
  ClientResult<OpenApiGetUserResponse> validateLogin(
      String name, String password) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      var body = jsonEncode({'name': name, "password": password});
      HttpClientRequest request =
          await client.postUrl(Uri.parse("$baseUrl/user/validate-login"));
      request.headers.set('content-type', 'application/json; charset=utf-8');
      request.write(body);
      HttpClientResponse response = await request.close();
      print("validateLogin ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        String responseBody = await response.transform(utf8.decoder).join();
        Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        return Success(OpenApiGetUserResponse.fromResp(jsonResponse));
      }
      return const Failure(ClientError.unexpectedError);
    } catch (e) {
      print("error: $e");
      return const Failure(ClientError.internalError);
    }
  }

  ClientResult<OpenApiGetUserResponse> getUser(String name, String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request =
          await client.getUrl(Uri.parse("$baseUrl/user/$name"));
      request.headers.set('Authorization', auth);
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String responseBody = await response.transform(utf8.decoder).join();
        Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        return Success(OpenApiGetUserResponse.fromResp(jsonResponse));
      } else {
        return const Failure(ClientError.unexpectedError);
      }
    } catch (e) {
      print("error: $e");
      return const Failure(ClientError.internalError);
    }
  }

  ClientResult<bool> updateUser(
    String id,
    String name,
    String password,
    String? avatarUrl,
    String auth,
  ) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      var body = jsonEncode(
          {'name': name, "password": password, "avatar_url": avatarUrl});
      HttpClientRequest request =
          await client.putUrl(Uri.parse("$baseUrl/user/$id"));
      request.headers.set('content-type', 'application/json; charset=utf-8');
      request.headers.set('Authorization', auth);
      request.write(body);
      HttpClientResponse response = await request.close();
      print("updateUser ${response.statusCode}");
      if (response.statusCode == 200) {
        return const Success(true);
      } else {
        return const Failure(ClientError.unexpectedError);
      }
    } catch (e) {
      print("updateUser error: $e");
      return const Failure(ClientError.internalError);
    }
  }

  Future<bool> pushRepo(Repo repo, String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      var body = jsonEncode(repo.toSyncRepoMap());
      HttpClientRequest request =
          await client.postUrl(Uri.parse("$baseUrl/repo"));
      request.headers.set('content-type', 'application/json; charset=utf-8');
      request.headers.set('Authorization', auth);
      request.write(body);
      print("body: $body");
      HttpClientResponse response = await request.close();
      print("syncRepo ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        String responseBody = await response.transform(utf8.decoder).join();
        print("syncRepo error $responseBody");
      }
    } catch (e) {
      print("pushRepo error: $e");
    }
    return false;
  }

  ClientResult<List<Repo>> pullRepos(String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request =
          await client.getUrl(Uri.parse("$baseUrl/repo"));
      request.headers.set('Authorization', auth);
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String responseBody = await response.transform(utf8.decoder).join();
        print("pullRepos $responseBody");
        List<dynamic> jsonResponse = jsonDecode(responseBody);
        return jsonResponse
            .map((e) {
              return OpenApiGetRepoResponse.fromResp(e).toRepo();
            })
            .toList()
            .toSuccess();
      } else {
        print("pullRepos error ${response.statusCode}");
        return const Failure(ClientError.unexpectedError);
      }
    } catch (e) {
      print("pullRepos error: $e");
      return const Failure(ClientError.internalError);
    }
  }

  Future<Repo?> pullRepo(String repoId, String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request =
          await client.getUrl(Uri.parse("$baseUrl/repo/$repoId"));
      request.headers.set('Authorization', auth);
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String responseBody = await response.transform(utf8.decoder).join();
        Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        return OpenApiGetRepoResponse.fromResp(jsonResponse).toRepo();
      } else {
        print("pullRepo error ${response.statusCode}");
      }
    } catch (e) {
      print("error: $e");
    }
    return null;
  }

  Future<bool> deleteRepo(String repoId, String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request =
          await client.deleteUrl(Uri.parse("$baseUrl/repo/$repoId"));
      request.headers.set('Authorization', auth);
      HttpClientResponse response = await request.close();
      print("deleteRepo ${response.statusCode}");
      if (response.statusCode == 204) {
        return true;
      } else {
        String responseBody = await response.transform(utf8.decoder).join();
        print("deleteRepo error $responseBody");
      }
    } catch (e) {
      print("error: $e");
    }
    return false;
  }

  Future<bool> pushPost(Post post, String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      var body = jsonEncode(post.toSyncPostMap());
      HttpClientRequest request =
          await client.postUrl(Uri.parse("$baseUrl/repo/${post.repoId}/post"));
      request.headers.set('content-type', 'application/json; charset=utf-8');
      request.headers.set('Authorization', auth);
      request.write(body);
      print("body: $body");
      HttpClientResponse response = await request.close();
      print("syncPost ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        String responseBody = await response.transform(utf8.decoder).join();
        print("syncPost error $responseBody");
      }
    } catch (e) {
      print("error: $e");
    }
    return false;
  }

  Future<List<PostSummary>?> pullPosts(String repoId, String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request =
          await client.getUrl(Uri.parse("$baseUrl/repo/$repoId/post"));
      request.headers.set('Authorization', auth);
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String responseBody = await response.transform(utf8.decoder).join();
        print("responseBody: $responseBody");
        List<dynamic> jsonResponse = jsonDecode(responseBody);
        return jsonResponse.map((e) {
          // return OpenApiGetPostResponse.fromResp(e).toPostSummary();
          return PostSummary.fromMap(e);
        }).toList();
      } else {
        print("pullPostsSummary error ${response.statusCode}");
      }
    } catch (e) {
      print("pullPosts error: $e");
    }
    return null;
  }

  Future<Post?> pullPost(String repoId, String postId, String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request =
          await client.getUrl(Uri.parse("$baseUrl/repo/$repoId/post/$postId"));
      request.headers.set('Authorization', auth);
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String responseBody = await response.transform(utf8.decoder).join();
        print("pullPost responseBody: $responseBody");
        Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        return Post.fromMap(jsonResponse);
      } else {
        print("pullPost error ${response.statusCode}");
      }
    } catch (e) {
      print("error: $e");
    }
    return null;
  }

  Future<bool> deletePost(String repoId, String postId, String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request = await client
          .deleteUrl(Uri.parse("$baseUrl/repo/$repoId/post/$postId"));
      request.headers.set('Authorization', auth);
      HttpClientResponse response = await request.close();
      print("deletePost ${response.statusCode}");
      if (response.statusCode == 204) {
        return true;
      } else {
        String responseBody = await response.transform(utf8.decoder).join();
        print("deletePost error $responseBody");
      }
    } catch (e) {
      print("error: $e");
    }
    return false;
  }

  Future<Repo?> subscribeRepo(String sharedLink, String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request =
          await client.postUrl(Uri.parse("$baseUrl/subscribe/"));
      request.headers.set('content-type', 'application/json; charset=utf-8');
      request.headers.set('Authorization', auth);
      request.write(jsonEncode({'link': sharedLink}));
      HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        String responseBody = await response.transform(utf8.decoder).join();
        // print(responseBody);
        Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        return OpenApiGetRepoResponse.fromResp(jsonResponse).toRepo();
      }
    } catch (e) {
      print("error: $e");
    }
    return null;
  }

  Future<void> unSubscribeRepo(String repoId, String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request =
          await client.deleteUrl(Uri.parse("$baseUrl/subscribe/?repo=$repoId"));
      request.headers.set('Authorization', auth);
      HttpClientResponse response = await request.close();

      if (response.statusCode == 204) {
        return;
      } else {
        String responseBody = await response.transform(utf8.decoder).join();
        print("${response.statusCode}, $responseBody");
      }
    } catch (e) {
      print("error: $e");
    }
    return;
  }

  Future<List<Repo>?> syncSubscribeRepos(String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request =
          await client.getUrl(Uri.parse("$baseUrl/subscribe/"));
      request.headers.set('content-type', 'application/json; charset=utf-8');
      request.headers.set('Authorization', auth);
      HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        String responseBody = await response.transform(utf8.decoder).join();
        print("syncSubscribeRepos $responseBody");
        List<dynamic> jsonResponse = jsonDecode(responseBody);
        return jsonResponse.map((e) {
          return OpenApiGetRepoResponse.fromResp(e).toRepo();
        }).toList();
      } else {
        print("syncSubscribeRepos error ${response.statusCode}");
      }
    } catch (e) {
      print("syncSubscribeRepos error: $e");
    }
    return null;
  }

  // --- comment
  ClientResult<Comment> postComment(
    String repoId,
    String postId,
    String content,
    String? commentId,
    String? parentId,
    String auth,
  ) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      var body = jsonEncode({
        'content': content,
        'parent_id': parentId,
        'id': commentId,
      });
      HttpClientRequest request = await client
          .postUrl(Uri.parse("$baseUrl/repo/$repoId/post/$postId/comment"));
      request.headers.set('content-type', 'application/json; charset=utf-8');
      request.headers.set('Authorization', auth);
      request.write(body);
      HttpClientResponse response = await request.close();
      print("postComment ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        String responseBody = await response.transform(utf8.decoder).join();
        // print("responseBody: $responseBody");
        Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        return Success(Comment.fromMap(jsonResponse));
      } else {
        return const Failure(ClientError.unexpectedError);
      }
    } catch (e) {
      print("postComment error: $e");
      return const Failure(ClientError.internalError);
    }
  }
}

ClientResult<String> getLatestVersion() async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.getLatestVersion(auth);
}

/// Validate the server address
/// return true if the server is reachable
Future<bool> validateServerAddress(String serverAddress) async {
  XbbClient client = XbbClient(baseUrl: serverAddress);
  return await client.validateServerHealth();
}

/// Validate the user name exist
/// return true if exist
ClientResult<bool> validateUserNameExist(String name) async {
  final settingController = Get.find<SettingController>();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.validateUserNameExist(name);
}

/// Validate Login user:password authorization
/// return true if success
ClientResult<OpenApiGetUserResponse> validateLogin(
    String name, String password) async {
  final settingController = Get.find<SettingController>();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return client.validateLogin(name, password);
}

ClientResult<OpenApiGetUserResponse> getUser(String name) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.getUser(name, auth);
}

Future<bool> updateUser(
    String id, String name, String password, String? avatarUrl) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return client
      .updateUser(id, name, password, avatarUrl, auth)
      .getOrDefault(false);
}

// --- sync
Future<bool> syncPushRepo(Repo repo) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.pushRepo(repo, auth);
}

ClientResult<List<Repo>> syncPullRepos() async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.pullRepos(auth);
}

Future<Repo?> syncPullRepo(String repoId) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.pullRepo(repoId, auth);
}

Future<bool> syncDeleteRepo(String repoId) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.deleteRepo(repoId, auth);
}

Future<bool> syncPushPost(Post post) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.pushPost(post, auth);
}

Future<List<PostSummary>?> syncPullPosts(String repoId) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.pullPosts(repoId, auth);
}

Future<Post?> syncPullPost(String repoId, String postId) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.pullPost(repoId, postId, auth);
}

Future<bool> syncDeletePost(String repoId, String postId) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.deletePost(repoId, postId, auth);
}

// --- subscribe
Future<Repo?> subscribeRepo(String sharedLink) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.subscribeRepo(sharedLink, auth);
}

Future<void> unsubscribeRepo(String repoId) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.unSubscribeRepo(repoId, auth);
}

Future<List<Repo>?> syncSubscribeRepos() async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.syncSubscribeRepos(auth);
}

// --- comment
ClientResult<Comment> addComment(
  String repoId,
  String postId,
  String content,
) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.postComment(repoId, postId, content, null, null, auth);
}

ClientResult<Comment> addReplyComment(
  String repoId,
  String postId,
  String content,
  String parentId,
) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.postComment(
      repoId, postId, content, null, parentId, auth);
}

ClientResult<Comment> editComment(
  String repoId,
  String postId,
  String commentId,
  String content,
) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.postComment(
      repoId, postId, commentId, null, content, auth);
}
