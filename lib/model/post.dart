import 'package:sqflite/sqflite.dart';

enum PostStatus {
  draft,
  published,
}

class Post {
  // members that uploaded to the server
  String id;
  String title;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  String author; // user id
  String repoId;

  // members local
  PostStatus status;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    required this.repoId,
    this.status = PostStatus.draft,
  });

  Map<String, dynamic> toMap() {
    return {
      PostRepository._columnId: id,
      PostRepository._columnTitle: title,
      PostRepository._columnContent: content,
      PostRepository._columnCreatedAt: createdAt.toIso8601String(),
      PostRepository._columnUpdatedAt: updatedAt.toIso8601String(),
      PostRepository._columnAuthor: author,
      PostRepository._columnRepoId: repoId,
      PostRepository._columnStatus: status.toString()
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map[PostRepository._columnId],
      title: map[PostRepository._columnTitle],
      content: map[PostRepository._columnContent],
      createdAt: DateTime.parse(map[PostRepository._columnCreatedAt]),
      updatedAt: DateTime.parse(map[PostRepository._columnUpdatedAt]),
      author: map[PostRepository._columnAuthor],
      repoId: map[PostRepository._columnRepoId],
      status: PostStatus.values
          .firstWhere((e) => e.toString() == map[PostRepository._columnStatus]),
    );
  }
}

class PostRepository {
  static const String _tablePostName = 'posts';
  static const String _columnId = 'id';
  static const String _columnTitle = 'title';
  static const String _columnContent = 'content';
  static const String _columnCreatedAt = 'createdAt';
  static const String _columnUpdatedAt = 'updatedAt';
  static const String _columnAuthor = 'author';
  static const String _columnRepoId = 'repoId';

  // local
  static const String _columnStatus = 'status';

  static Database? _db;

  Future<Database> _getDb() async {
    _db ??= await openDatabase(
      'xbb_client.db',
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_tablePostName (
            $_columnId TEXT PRIMARY KEY,
            $_columnTitle TEXT NOT NULL,
            $_columnContent TEXT NOT NULL,
            $_columnCreatedAt TEXT NOT NULL,
            $_columnUpdatedAt TEXT NOT NULL,
            $_columnAuthor TEXT NOT NULL,
            $_columnRepoId TEXT NOT NULL,
            $_columnStatus TEXT NOT NULL
          )
        ''');
      },
    );

    return _db!;
  }

  Future<List<Post>> getRepoPosts(String repoId) async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      _tablePostName,
      where: '$_columnRepoId = ?',
      whereArgs: [repoId],
    );
    var result = List.generate(maps.length, (i) {
      return Post.fromMap(maps[i]);
    });

    return result;
  }

  Future<void> addPost(Post post) async {
    final db = await _getDb();
    await db.insert(_tablePostName, post.toMap());
  }
}
