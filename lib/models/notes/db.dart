import 'dart:io';

import 'package:get/get.dart';
import 'package:xbb/controller/setting.dart';

import 'model.dart';

import 'package:path/path.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class NotesDB {
  // static Database? _db;
  static Map<String, Database> _dbCache = {};

  Future<Database> getDb() async {
    final userId = Get.find<NewSettingController>().userId;
    if (_dbCache.containsKey(userId)) {
      return _dbCache[userId]!;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }


    final dbPath = await getDatabasesPath();
    final path = join(dbPath, userId, 'notes.db');

    _dbCache[userId] ??= await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(LocalStoreRepo.onCreateTableRepoSQL);
          await db.execute(LocalStorePost.onCreateTablePostSQL);
          await db.execute(LocalStoreComment.onCreateTableCommentSQL);
          await db.execute(onCreateTableAcl);
        },
      ),
    );

    return _dbCache[userId]!;
  }
}
