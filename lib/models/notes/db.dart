import 'dart:io';

import 'model.dart';

import 'package:path/path.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class NotesDB {
  static Database? _db;

  Future<Database> getDb() async {
    if (_db != null) return _db!;

    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'notes.db');

    _db ??= await databaseFactoryFfi.openDatabase(
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

    return _db!;
  }
}
