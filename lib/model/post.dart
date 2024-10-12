import 'package:xbb/model/db.dart';

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
      tablePostColumnId: id,
      tablePostColumnTitle: title,
      tablePostColumnContent: content,
      tablePostColumnCreatedAt: createdAt.toIso8601String(),
      tablePostColumnUpdatedAt: updatedAt.toIso8601String(),
      tablePostColumnAuthor: author,
      tablePostColumnRepoId: repoId,
      tablePostColumnStatus: status.toString()
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map[tablePostColumnId],
      title: map[tablePostColumnTitle],
      content: map[tablePostColumnContent],
      createdAt: DateTime.parse(map[tablePostColumnCreatedAt]),
      updatedAt: DateTime.parse(map[tablePostColumnUpdatedAt]),
      author: map[tablePostColumnAuthor],
      repoId: map[tablePostColumnRepoId],
      status: PostStatus.values
          .firstWhere((e) => e.toString() == map[tablePostColumnStatus]),
    );
  }
}

class PostRepository {
  Future<List<Post>> getRepoPosts(String repoId) async {
    final db = await DataBase().getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      tablePostName,
      where: '$tablePostColumnRepoId = ?',
      whereArgs: [repoId],
    );
    var result = List.generate(maps.length, (i) {
      return Post.fromMap(maps[i]);
    });

    return result;
  }

  Future<Post> getPost(String postId) async {
    final db = await DataBase().getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      tablePostName,
      where: '$tablePostColumnId = ?',
      whereArgs: [postId],
    );
    return Post.fromMap(maps.first);
  }

  Future<void> addPost(Post post) async {
    final db = await DataBase().getDb();
    await db.insert(tablePostName, post.toMap());
  }

  Future<void> deletePost(String postId) async {
    final db = await DataBase().getDb();
    await db.delete(tablePostName,
        where: '$tablePostColumnId = ?', whereArgs: [postId]);
  }
}
