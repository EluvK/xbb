// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Repo _$RepoFromJson(Map<String, dynamic> json) =>
    Repo(name: json['name'] as String, status: json['status'] as String, description: json['description'] as String?);

Map<String, dynamic> _$RepoToJson(Repo instance) => <String, dynamic>{
  'name': instance.name,
  'status': instance.status,
  'description': instance.description,
};

Post _$PostFromJson(Map<String, dynamic> json) => Post(
  title: json['title'] as String,
  category: json['category'] as String,
  content: json['content'] as String,
  repoId: json['repo_id'] as String,
);

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
  'title': instance.title,
  'category': instance.category,
  'content': instance.content,
  'repo_id': instance.repoId,
};

Comment _$CommentFromJson(Map<String, dynamic> json) => Comment(
  postId: json['post_id'] as String,
  content: json['content'] as String,
  parentId: json['parent_id'] as String?,
);

Map<String, dynamic> _$CommentToJson(Comment instance) => <String, dynamic>{
  'content': instance.content,
  'post_id': instance.postId,
  'parent_id': instance.parentId,
};

// **************************************************************************
// RepositoryGenerator
// **************************************************************************

extension LocalStoreRepo on Repo {
  static String get tableName => 'repo';

  static String get onCreateTableRepoSQL =>
      """
        CREATE TABLE $tableName (
          id TEXT PRIMARY KEY,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          owner TEXT NOT NULL,
          parent_id TEXT,
          "unique" TEXT,
          sync_status TEXT NOT NULL,
          body TEXT NOT NULL
        )
      """;

  static Future<Database> getDb() async {
    return await NotesDB().getDb();
  }
}

typedef RepoDataItem = DataItem<Repo>;

class RepoRepository {
  Future<void> addToLocalDb(RepoDataItem item) async {
    final db = await LocalStoreRepo.getDb();
    await db.insert(LocalStoreRepo.tableName, item.toJson((r) => json.encode(r.toJson())));
  }

  Future<RepoDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreRepo.getDb();
    final List<Map<String, dynamic>> maps = await db.query(LocalStoreRepo.tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return DataItem<Repo>.fromJson(maps.first, (jsonStr) => Repo.fromJson(json.decode(jsonStr as String)));
    }
    return null;
  }

  Future<List<RepoDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStoreRepo.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreRepo.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps
        .map((map) => DataItem<Repo>.fromJson(map, (jsonStr) => Repo.fromJson(json.decode(jsonStr as String))))
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreRepo.getDb();
    await db.delete(LocalStoreRepo.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToLocalDb(RepoDataItem item) async {
    final db = await LocalStoreRepo.getDb();
    await db.update(
      LocalStoreRepo.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(RepoDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}

extension LocalStorePost on Post {
  static String get tableName => 'post';

  static String get onCreateTablePostSQL =>
      """
        CREATE TABLE $tableName (
          id TEXT PRIMARY KEY,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          owner TEXT NOT NULL,
          parent_id TEXT,
          "unique" TEXT,
          sync_status TEXT NOT NULL,
          body TEXT NOT NULL
        )
      """;

  static Future<Database> getDb() async {
    return await NotesDB().getDb();
  }
}

typedef PostDataItem = DataItem<Post>;

class PostRepository {
  Future<void> addToLocalDb(PostDataItem item) async {
    final db = await LocalStorePost.getDb();
    await db.insert(LocalStorePost.tableName, item.toJson((r) => json.encode(r.toJson())));
  }

  Future<PostDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStorePost.getDb();
    final List<Map<String, dynamic>> maps = await db.query(LocalStorePost.tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return DataItem<Post>.fromJson(maps.first, (jsonStr) => Post.fromJson(json.decode(jsonStr as String)));
    }
    return null;
  }

  Future<List<PostDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStorePost.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStorePost.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps
        .map((map) => DataItem<Post>.fromJson(map, (jsonStr) => Post.fromJson(json.decode(jsonStr as String))))
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStorePost.getDb();
    await db.delete(LocalStorePost.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToLocalDb(PostDataItem item) async {
    final db = await LocalStorePost.getDb();
    await db.update(
      LocalStorePost.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(PostDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}

extension LocalStoreComment on Comment {
  static String get tableName => 'comment';

  static String get onCreateTableCommentSQL =>
      """
        CREATE TABLE $tableName (
          id TEXT PRIMARY KEY,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          owner TEXT NOT NULL,
          parent_id TEXT,
          "unique" TEXT,
          sync_status TEXT NOT NULL,
          body TEXT NOT NULL
        )
      """;

  static Future<Database> getDb() async {
    return await NotesDB().getDb();
  }
}

typedef CommentDataItem = DataItem<Comment>;

class CommentRepository {
  Future<void> addToLocalDb(CommentDataItem item) async {
    final db = await LocalStoreComment.getDb();
    await db.insert(LocalStoreComment.tableName, item.toJson((r) => json.encode(r.toJson())));
  }

  Future<CommentDataItem?> getFromLocalDb(String id) async {
    final db = await LocalStoreComment.getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreComment.tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DataItem<Comment>.fromJson(maps.first, (jsonStr) => Comment.fromJson(json.decode(jsonStr as String)));
    }
    return null;
  }

  Future<List<CommentDataItem>> listFromLocalDb({String? parentId}) async {
    final db = await LocalStoreComment.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      LocalStoreComment.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return maps
        .map((map) => DataItem<Comment>.fromJson(map, (jsonStr) => Comment.fromJson(json.decode(jsonStr as String))))
        .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await LocalStoreComment.getDb();
    await db.delete(LocalStoreComment.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToLocalDb(CommentDataItem item) async {
    final db = await LocalStoreComment.getDb();
    await db.update(
      LocalStoreComment.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb(CommentDataItem item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}
