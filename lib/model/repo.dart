import 'package:xbb/model/db.dart';

const String neverSyncAt = '2024-10-24T00:00:00.000000';

class Repo {
  String id;
  String name;
  String owner; //owner user id
  String description;
  DateTime createdAt;
  DateTime updatedAt;
  // local
  DateTime lastSyncAt;
  bool remoteRepo;
  bool autoSync;

  Repo({
    required this.id,
    required this.name,
    required this.owner,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSyncAt,
    required this.remoteRepo,
    required this.autoSync,
  });

  Map<String, dynamic> toMap() {
    return {
      tableRepoColumnId: id,
      tableRepoColumnName: name,
      tableRepoColumnOwner: owner,
      tableRepoColumnDescription: description,
      tableRepoColumnCreatedAt: createdAt.toIso8601String(),
      tableRepoColumnUpdatedAt: updatedAt.toIso8601String(),
      tableRepoColumnLastSyncAt: lastSyncAt.toIso8601String(),
      tableRepoColumnRemoteRepo: remoteRepo ? 1 : 0,
      tableRepoColumnAutoSync: autoSync ? 1 : 0
    };
  }

  // should not contains any local members
  Map<String, dynamic> toSyncRepoMap() {
    return {
      tableRepoColumnId: id,
      tableRepoColumnName: name,
      tableRepoColumnOwner: owner,
      tableRepoColumnDescription: description,
      tableRepoColumnCreatedAt: createdAt.toUtc().toIso8601String(),
      tableRepoColumnUpdatedAt: updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Repo.fromMap(Map<String, dynamic> map) {
    return Repo(
      id: map[tableRepoColumnId],
      name: map[tableRepoColumnName],
      owner: map[tableRepoColumnOwner],
      description: map[tableRepoColumnDescription],
      createdAt: DateTime.parse(map[tableRepoColumnCreatedAt]),
      updatedAt: DateTime.parse(map[tableRepoColumnUpdatedAt]),
      lastSyncAt: DateTime.parse(map[tableRepoColumnLastSyncAt]),
      remoteRepo: map[tableRepoColumnRemoteRepo] == 1 ? true : false,
      autoSync: map[tableRepoColumnAutoSync] == 1 ? true : false,
    );
  }
}

class RepoRepository {
  Future<List<Repo>> listRepo(String user) async {
    final db = await DataBase().getDb();
    final List<Map<String, dynamic>> maps = await db.query(tableRepoName);
    var result = List.generate(maps.length, (i) {
      return Repo.fromMap(maps[i]);
    }).where((repo) {
      // todo add shared
      return repo.owner == user || repo.id == "0";
    }).toList();
    return result;
  }

  Future<void> addRepo(Repo repo) async {
    final db = await DataBase().getDb();
    await db.insert(tableRepoName, repo.toMap());
  }

  Future<Repo?> getRepo(String repoId) async {
    final db = await DataBase().getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      tableRepoName,
      where: '$tableRepoColumnId = ?',
      whereArgs: [repoId],
    );
    if (maps.isNotEmpty) {
      return Repo.fromMap(maps.first);
    }
    return null;
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

  Future<void> upsertRepo(Repo repo) async {
    if (await getRepo(repo.id) == null) {
      await addRepo(repo);
    } else {
      await updateRepo(repo);
    }
  }
}
