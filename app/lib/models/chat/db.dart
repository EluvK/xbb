import 'package:sqflite/sqflite.dart';
import 'package:xbb/sync/v2/local_first_db.dart';

class ChatDB {
  static Database? mockDb;
  static void setMockDb(Database? db) => mockDb = db;

  Future<Database> getDb() async {
    if (mockDb != null) {
      return mockDb!;
    }
    return await LocalFirstDB.getDb(userId: 'default');
  }
}
