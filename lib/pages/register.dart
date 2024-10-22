import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/client/client.dart';
import 'package:xbb/controller/repo.dart';
import 'package:xbb/controller/setting.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

enum ServiceAvailability { available, notAvailable, checking, unknown }

enum UserNameAvailability { login, register, checking, unknown }

class _RegisterPageState extends State<RegisterPage> {
  bool _skVisible = false;

  String serviceAddress = 'https://';
  String userName = '';
  String userPassword = '';

  ServiceAvailability serviceAvailability = ServiceAvailability.unknown;
  UserNameAvailability userNameAvailability = UserNameAvailability.unknown;

  final settingController = Get.find<SettingController>();
  final repoController = Get.find<RepoController>();

  @override
  void initState() {
    serviceAddress = settingController.serverAddress.value;
    userName = settingController.currentUser.value;
    userPassword = settingController.currentUserPasswd.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register / Login'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Focus(
                        onFocusChange: (hasFocus) {
                          print('change: $hasFocus service $serviceAddress');
                          if (!hasFocus) {
                            // test service client
                            setState(() {
                              serviceAvailability =
                                  ServiceAvailability.checking;
                            });
                            validateServerAddress(serviceAddress).then((value) {
                              setState(() {
                                print('validateServerAddress result: $value');
                                serviceAvailability = value
                                    ? ServiceAvailability.available
                                    : ServiceAvailability.notAvailable;
                                if (serviceAvailability ==
                                    ServiceAvailability.available) {
                                  settingController
                                      .setServerAddress(serviceAddress);
                                }
                              });
                            });
                          }
                        },
                        child: TextField(
                          decoration: InputDecoration(
                              labelText: 'Service Address:Port',
                              prefixIcon: switch (serviceAvailability) {
                                ServiceAvailability.available => const Icon(
                                    Icons.check_box_rounded,
                                    color: Colors.green,
                                  ),
                                ServiceAvailability.notAvailable => const Icon(
                                    Icons.question_mark_outlined,
                                    color: Colors.red,
                                  ),
                                ServiceAvailability.checking => Transform.scale(
                                    scale: 0.5,
                                    child: const CircularProgressIndicator(),
                                  ),
                                ServiceAvailability.unknown => null
                              }),
                          controller:
                              TextEditingController(text: serviceAddress),
                          onChanged: (value) {
                            print("set serviceAddress $serviceAddress");
                            serviceAddress = value;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Focus(
                        onFocusChange: (hasFocus) {
                          print('change: $hasFocus name: $userName');
                          if (!hasFocus) {
                            // test user name exist
                            setState(() {
                              userNameAvailability =
                                  UserNameAvailability.checking;
                            });
                            validateUserNameExist(userName).then((value) {
                              setState(() {
                                print('validateUserNameExist result: $value');
                                userNameAvailability = value
                                    ? UserNameAvailability.login
                                    : UserNameAvailability.register;
                              });
                            });
                          }
                        },
                        child: TextField(
                          decoration: InputDecoration(
                              labelText: 'Name',
                              prefixIcon: switch (userNameAvailability) {
                                UserNameAvailability.register => const Icon(
                                    Icons.add_box_rounded,
                                  ),
                                UserNameAvailability.checking =>
                                  Transform.scale(
                                    scale: 0.5,
                                    child: const CircularProgressIndicator(),
                                  ),
                                UserNameAvailability.login =>
                                  const Icon(Icons.account_circle),
                                UserNameAvailability.unknown => null,
                              }),
                          onChanged: (value) {
                            userName = value;
                          },
                          controller: TextEditingController(text: userName),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(_skVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _skVisible = !_skVisible;
                              });
                            },
                          ),
                        ),
                        onChanged: (value) {
                          userPassword = value;
                        },
                        controller: TextEditingController(text: userPassword),
                        obscureText: !_skVisible,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                  onPressed: () async {
                    var res = await validateLogin(userName, userPassword);
                    if (res) {
                      print('login success');
                      settingController.setUserInfo(userName, userPassword);
                      await login(userName);
                      Get.toNamed('/');
                    } else {
                      print('login failed');
                      // todo alarm
                    }
                  },
                  child: switch (userNameAvailability) {
                    UserNameAvailability.login => const Text('Login'),
                    UserNameAvailability.register => const Text('Register'),
                    UserNameAvailability.checking =>
                      const Text('Register / Login'),
                    UserNameAvailability.unknown =>
                      const Text('Register / Login'),
                  }),
            ],
          ),
        ),
      ),
    );
  }

  login(String userName) async {
    await repoController.loadRepoLists();
  }
}
