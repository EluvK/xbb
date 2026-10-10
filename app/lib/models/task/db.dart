import 'dart:io';

import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/models/task/model.dart';

class TaskDB {
  static final Map<String, Database> _dbCache = {};

  Future<Database> getDb() async {
    final userId = Get.find<SettingController>().userId;
    if (_dbCache.containsKey(userId)) {
      return _dbCache[userId]!;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, userId, 'task.db');

    _dbCache[userId] ??= await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(LocalStoreCheckList.onCreateTableCheckListSQL);
        },
      ),
    );

    return _dbCache[userId]!;
  }
}
