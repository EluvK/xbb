import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:xbb/client/resp.dart';
import 'package:xbb/controller/setting.dart';

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
