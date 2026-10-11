import 'package:sqflite/sqflite.dart';
import 'package:xbb/core/core.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/sync/v2/local_first_db.dart';

class ChatDB {
  static Database? mockDb;
  static void setMockDb(Database? db) => mockDb = db;

  Future<Database> getDb() async {
    if (mockDb != null) {
      return mockDb!;
    }
    final setting = Get.findOrNull<SettingController>();
    final userId = setting != null && setting.userId.isNotEmpty ? setting.userId : 'default';
    return await LocalFirstDB.getDb(userId: userId);
  }
}
