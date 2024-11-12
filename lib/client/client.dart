import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:xbb/client/resp.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/model/post.dart';
import 'package:xbb/model/repo.dart';

enum ClientRequestResult { ok, reject, error }

class XbbClient {
  final String baseUrl;
  XbbClient({required this.baseUrl});

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
  Future<bool> validateUserNameExist(String name) async {
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
        return jsonResponse['exist'] == true;
      }
    } catch (e) {
      print("error: $e");
    }
    return false;
  }

  // POST `/user/validate-login`
  Future<bool> validateLogin(String name, String password) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      var body = jsonEncode({'name': name, "password": password});
      HttpClientRequest request =
          await client.postUrl(Uri.parse("$baseUrl/user/validate-login"));
      request.headers.set('content-type', 'application/json');
      request.write(body);
      // print('name: $name');
      // print('password: $password');
      // print('Basic ${base64.encode(utf8.encode('$name:$password'))}');
      // request.headers.set('Authorization',
      //     'Basic ${base64Encode(utf8.encode('$name:$password'))}');
      // print(request.headers);
      HttpClientResponse response = await request.close();
      print("validateLogin ${response.statusCode}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
    } catch (e) {
      print("error: $e");
    }
    return false;
  }

  Future<OpenApiGetUserResponse> getUser(String name, String auth) async {
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
        return OpenApiGetUserResponse.fromResp(jsonResponse);
      }
    } catch (e) {
      print("error: $e");
    }
    return OpenApiGetUserResponse(id: '', name: '');
  }

  Future<bool> pushRepo(Repo repo, String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      var body = jsonEncode(repo.toSyncRepoMap());
      HttpClientRequest request =
          await client.postUrl(Uri.parse("$baseUrl/repo"));
      request.headers.set('content-type', 'application/json');
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
      print("error: $e");
    }
    return false;
  }

  Future<List<Repo>> pullRepos(String auth) async {
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
        List<dynamic> jsonResponse = jsonDecode(responseBody);
        return jsonResponse.map((e) {
          return OpenApiGetRepoResponse.fromResp(e).toRepo();
        }).toList();
      } else {
        print("pullRepos error ${response.statusCode}");
      }
    } catch (e) {
      print("error: $e");
    }
    return [];
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

  Future<bool> pushPost(Post post, String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      var body = jsonEncode(post.toSyncPostMap());
      HttpClientRequest request =
          await client.postUrl(Uri.parse("$baseUrl/repo/${post.repoId}/post"));
      request.headers.set('content-type', 'application/json');
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

  Future<List<PostSummary>> pullPosts(String repoId, String auth) async {
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
      print("error: $e");
    }
    return [];
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
        print("responseBody: $responseBody");
        Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        return Post.fromMap(jsonResponse);
      } else {
        print("pullPostsSummary error ${response.statusCode}");
      }
    } catch (e) {
      print("error: $e");
    }
    return null;
  }

  Future<bool> deletePost(Post post, String auth) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback =
          ((X509Certificate cert, String host, int port) => true);
      HttpClientRequest request = await client
          .deleteUrl(Uri.parse("$baseUrl/repo/${post.repoId}/post/${post.id}"));
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
      request.headers.set('content-type', 'application/json');
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
}

/// Validate the server address
/// return true if the server is reachable
Future<bool> validateServerAddress(String serverAddress) async {
  XbbClient client = XbbClient(baseUrl: serverAddress);
  return await client.validateServerHealth();
}

/// Validate the user name exist
/// return true if exist
Future<bool> validateUserNameExist(String name) async {
  final settingController = Get.find<SettingController>();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.validateUserNameExist(name);
}

/// Validate Login user:password authorization
/// return true if success
Future<bool> validateLogin(String name, String password) async {
  final settingController = Get.find<SettingController>();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.validateLogin(name, password);
}

Future<OpenApiGetUserResponse> getUser(String name) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.getUser(name, auth);
}

// --- sync
Future<bool> syncPushRepo(Repo repo) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.pushRepo(repo, auth);
}

Future<List<Repo>> syncPullRepos() async {
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

Future<bool> syncPushPost(Post post) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.pushPost(post, auth);
}

Future<List<PostSummary>> syncPullPosts(String repoId) async {
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

Future<bool> syncDeletePost(Post post) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.deletePost(post, auth);
}

// --- subscribe
Future<Repo?> subscribeRepo(String sharedLink) async {
  final settingController = Get.find<SettingController>();
  var auth = settingController.getCurrentBaseAuth();
  var baseUrl = settingController.serverAddress.value;
  XbbClient client = XbbClient(baseUrl: baseUrl);
  return await client.subscribeRepo(sharedLink, auth);
}
