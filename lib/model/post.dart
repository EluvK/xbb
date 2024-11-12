import 'package:xbb/model/db.dart';

enum PostStatus {
  draft,
  published,
}

class PostSummary {
  String id;
  String title;
  String category;
  DateTime updatedAt;

  PostSummary({
    required this.id,
    required this.title,
    required this.category,
    required this.updatedAt,
  });

  factory PostSummary.fromMap(Map<String, dynamic> map) {
    return PostSummary(
      id: map[tablePostColumnId],
      title: map[tablePostColumnTitle],
      category: map[tablePostColumnCategory],
      updatedAt: DateTime.parse(map[tablePostColumnUpdatedAt]),
    );
  }
}

class Post {
  // members that uploaded to the server
  String id;
  String category;
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
    required this.category,
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
      tablePostColumnCategory: category,
      tablePostColumnTitle: title,
      tablePostColumnContent: content,
      tablePostColumnCreatedAt: createdAt.toIso8601String(),
      tablePostColumnUpdatedAt: updatedAt.toIso8601String(),
      tablePostColumnAuthor: author,
      tablePostColumnRepoId: repoId,
      tablePostColumnStatus: status.toString()
    };
  }

  // should not contains any local members
  Map<String, dynamic> toSyncPostMap() {
    return {
      tablePostColumnId: id,
      tablePostColumnCategory: category,
      tablePostColumnTitle: title,
      tablePostColumnContent: content,
      tablePostColumnCreatedAt: createdAt.toUtc().toIso8601String(),
      tablePostColumnUpdatedAt: updatedAt.toUtc().toIso8601String(),
      tablePostColumnAuthor: author,
      tablePostColumnRepoId: repoId
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map[tablePostColumnId],
      category: map[tablePostColumnCategory],
      title: map[tablePostColumnTitle],
      content: map[tablePostColumnContent],
      createdAt: DateTime.parse(map[tablePostColumnCreatedAt]),
      updatedAt: DateTime.parse(map[tablePostColumnUpdatedAt]),
      author: map[tablePostColumnAuthor],
      repoId: map[tablePostColumnRepoId],
      status: PostStatus.values.firstWhere(
        (e) => e.toString() == map[tablePostColumnStatus],
        orElse: () {
          return PostStatus.draft; // todo change to read/unread marker
        },
      ),
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

  Future<Post?> getPost(String postId) async {
    final db = await DataBase().getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      tablePostName,
      where: '$tablePostColumnId = ?',
      whereArgs: [postId],
    );
    if (maps.isNotEmpty) {
      return Post.fromMap(maps.first);
    }
    return null;
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

  Future<void> updatePost(Post post) async {
    final db = await DataBase().getDb();
    await db.update(tablePostName, post.toMap(),
        where: '$tablePostColumnId = ?', whereArgs: [post.id]);
  }

  Future<void> upsertPost(Post post) async {
    if (await getPost(post.id) == null) {
      await addPost(post);
    } else {
      await updatePost(post);
    }
  }
}
