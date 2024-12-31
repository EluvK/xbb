import 'package:xbb/model/db.dart';

class Comment {
  final String id;
  final String repoId;
  final String postId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String author;
  final String? parentId;

  Comment({
    required this.id,
    required this.repoId,
    required this.postId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    this.parentId,
  });

  Map<String, dynamic> toMap() {
    return {
      tableCommentColumnId: id,
      tableCommentColumnRepoId: repoId,
      tableCommentColumnPostId: postId,
      tableCommentColumnContent: content,
      tableCommentColumnCreatedAt: createdAt.toIso8601String(),
      tableCommentColumnUpdatedAt: updatedAt.toIso8601String(),
      tableCommentColumnAuthor: author,
      tableCommentColumnParentId: parentId,
    };
  }

  // should not contains any local members
  Map<String, dynamic> toSyncCommentMap() {
    return {
      tableCommentColumnId: id,
      tableCommentColumnRepoId: repoId,
      tableCommentColumnPostId: postId,
      tableCommentColumnContent: content,
      tableCommentColumnCreatedAt: createdAt.toUtc().toIso8601String(),
      tableCommentColumnUpdatedAt: updatedAt.toUtc().toIso8601String(),
      tableCommentColumnAuthor: author,
      tableCommentColumnParentId: parentId,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map[tableCommentColumnId],
      repoId: map[tableCommentColumnRepoId],
      postId: map[tableCommentColumnPostId],
      content: map[tableCommentColumnContent],
      createdAt: DateTime.parse(map[tableCommentColumnCreatedAt]),
      updatedAt: DateTime.parse(map[tableCommentColumnUpdatedAt]),
      author: map[tableCommentColumnAuthor],
      parentId: map[tableCommentColumnParentId],
    );
  }

  Comment copyWith({
    String? id,
    String? repoId,
    String? postId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? author,
    String? parentId,
  }) {
    return Comment(
      id: id ?? this.id,
      repoId: repoId ?? this.repoId,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      author: author ?? this.author,
      parentId: parentId ?? this.parentId,
    );
  }
}

class CommentRepository {
  Future<void> addComment(Comment comment) async {
    final db = await DataBase().getDb();
    await db.insert(
      tableCommentName,
      comment.toMap(),
    );
  }

  Future<void> updateComment(Comment comment) async {
    final db = await DataBase().getDb();
    await db.update(
      tableCommentName,
      comment.toMap(),
      where: '$tableCommentColumnId = ?',
      whereArgs: [comment.id],
    );
  }

  Future<void> deleteComment(String id) async {
    final db = await DataBase().getDb();
    await db.delete(
      tableCommentName,
      where: '$tableCommentColumnId = ?',
      whereArgs: [id],
    );
  }

  Future<Comment?> getComment(String id) async {
    final db = await DataBase().getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      tableCommentName,
      where: '$tableCommentColumnId = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) {
      return null;
    }
    return Comment.fromMap(maps.first);
  }

  Future<List<Comment>> getComments(String repoId, String postId) async {
    final db = await DataBase().getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      tableCommentName,
      where: '$tableCommentColumnRepoId = ? AND $tableCommentColumnPostId = ?',
      whereArgs: [repoId, postId],
    );
    return List.generate(maps.length, (i) {
      return Comment.fromMap(maps[i]);
    });
  }
}
