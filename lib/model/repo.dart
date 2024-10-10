import 'package:sqflite/sqflite.dart';

class Repo {
  String id;
  String name;
  String owner; //owner user id
  DateTime createdAt;
  DateTime updatedAt;

  Repo({
    required this.id,
    required this.name,
    required this.owner,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      RepoRepository._columnId: id,
      RepoRepository._columnName: name,
      RepoRepository._columnOwner: owner,
      RepoRepository._columnCreatedAt: createdAt.toIso8601String(),
      RepoRepository._columnUpdatedAt: updatedAt.toIso8601String(),
    };
  }

  factory Repo.fromMap(Map<String, dynamic> map) {
    return Repo(
      id: map[RepoRepository._columnId],
      name: map[RepoRepository._columnName],
      owner: map[RepoRepository._columnOwner],
      createdAt: DateTime.parse(map[RepoRepository._columnCreatedAt]),
      updatedAt: DateTime.parse(map[RepoRepository._columnUpdatedAt]),
    );
  }
}

class RepoRepository {
  static const String _tableRepoName = "repo";
  static const String _columnId = "id";
  static const String _columnName = "name";
  static const String _columnOwner = "owner";
  static const String _columnCreatedAt = "createdAt";
  static const String _columnUpdatedAt = "updatedAt";

  static Database? _db;

  Future<Database> _getDb() async {
    _db ??= await openDatabase(
      'xbb_client.db',
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_tableRepoName(
            $_columnId TEXT PRIMARY KEY,
            $_columnName TEXT NOT NULL,
            $_columnOwner TEXT NOT NULL,
            $_columnCreatedAt TEXT NOT NULL,
            $_columnUpdatedAt TEXT NOT NULL
          )
        ''');
        var now = DateTime.now();
        var localRepo = Repo(
            id: '0',
            name: 'local',
            owner: 'local',
            createdAt: now,
            updatedAt: now);
        await db.insert(_tableRepoName, localRepo.toMap());
      },
    );
    return _db!;
  }

  Future<List<Repo>> listRepo() async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.query(_tableRepoName);
    var result = List.generate(maps.length, (i) {
      return Repo.fromMap(maps[i]);
    });

    return result;
  }

  Future<void> addRepo(Repo repo) async {
    final db = await _getDb();
    await db.insert(_tableRepoName, repo.toMap());
  }
}
