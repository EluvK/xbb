import 'package:sqflite/sqflite.dart';
import 'package:xbb/model/repo.dart';

/// Repo
const String tableRepoName = "repo";
const String tableRepoColumnId = "id";
const String tableRepoColumnName = "name";
const String tableRepoColumnOwner = "owner";
const String tableRepoColumnCreatedAt = "createdAt";
const String tableRepoColumnUpdatedAt = "updatedAt";

/// POST
const String tablePostName = 'posts';
const String tablePostColumnId = 'id';
const String tablePostColumnCategory = 'category';
const String tablePostColumnTitle = 'title';
const String tablePostColumnContent = 'content';
const String tablePostColumnCreatedAt = 'createdAt';
const String tablePostColumnUpdatedAt = 'updatedAt';
const String tablePostColumnAuthor = 'author';
const String tablePostColumnRepoId = 'repoId';
// local
const String tablePostColumnStatus = 'status';

class DataBase {
  static Database? _db;

  Future<Database> getDb() async {
    _db ??= await openDatabase(
      'xbb_client.db',
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $tablePostName (
            $tablePostColumnId TEXT PRIMARY KEY,
            $tablePostColumnCategory TEXT NOT NULL,
            $tablePostColumnTitle TEXT NOT NULL,
            $tablePostColumnContent TEXT NOT NULL,
            $tablePostColumnCreatedAt TEXT NOT NULL,
            $tablePostColumnUpdatedAt TEXT NOT NULL,
            $tablePostColumnAuthor TEXT NOT NULL,
            $tablePostColumnRepoId TEXT NOT NULL,
            $tablePostColumnStatus TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $tableRepoName(
            $tableRepoColumnId TEXT PRIMARY KEY,
            $tableRepoColumnName TEXT NOT NULL,
            $tableRepoColumnOwner TEXT NOT NULL,
            $tableRepoColumnCreatedAt TEXT NOT NULL,
            $tableRepoColumnUpdatedAt TEXT NOT NULL
          )
        ''');
        var now = DateTime.now();
        var localRepo = Repo(
            id: '0',
            name: 'local',
            owner: 'local',
            createdAt: now,
            updatedAt: now);
        await db.insert(tableRepoName, localRepo.toMap());
      },
    );

    return _db!;
  }
}