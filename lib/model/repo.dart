import 'package:xbb/model/db.dart';

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
      tableRepoColumnId: id,
      tableRepoColumnName: name,
      tableRepoColumnOwner: owner,
      tableRepoColumnCreatedAt: createdAt.toIso8601String(),
      tableRepoColumnUpdatedAt: updatedAt.toIso8601String(),
    };
  }

  factory Repo.fromMap(Map<String, dynamic> map) {
    return Repo(
      id: map[tableRepoColumnId],
      name: map[tableRepoColumnName],
      owner: map[tableRepoColumnOwner],
      createdAt: DateTime.parse(map[tableRepoColumnCreatedAt]),
      updatedAt: DateTime.parse(map[tableRepoColumnUpdatedAt]),
    );
  }
}

class RepoRepository {
  Future<List<Repo>> listRepo() async {
    final db = await DataBase().getDb();
    final List<Map<String, dynamic>> maps = await db.query(tableRepoName);
    var result = List.generate(maps.length, (i) {
      return Repo.fromMap(maps[i]);
    });

    return result;
  }

  Future<void> addRepo(Repo repo) async {
    final db = await DataBase().getDb();
    await db.insert(tableRepoName, repo.toMap());
  }

  Future<Repo> getRepo(String repoId) async {
    final db = await DataBase().getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      tableRepoName,
      where: '$tableRepoColumnId = ?',
      whereArgs: [repoId],
    );
    return Repo.fromMap(maps.first);
  }

  Future<void> deleteRepo(String repoId) async {
    final db = await DataBase().getDb();
    await db.delete(
      tableRepoName,
      where: '$tableRepoColumnId = ?',
      whereArgs: [repoId],
    );
  }

  Future<void> updateRepo(Repo repo) async {
    final db = await DataBase().getDb();
    await db.update(
      tableRepoName,
      repo.toMap(),
      where: '$tableRepoColumnId = ?',
      whereArgs: [repo.id],
    );
  }
}
