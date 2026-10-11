import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/core/acl/acl_repository.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

class NotesRepository {
  final Database db;
  final DatabaseChangeNotifier changeNotifier;

  NotesRepository({
    required this.db,
    required this.changeNotifier,
  });

  /// 辅助解析 SQLite color_tag 字段
  static ColorTag parseColorTag(String? raw) {
    if (raw == null || raw.isEmpty || raw == 'default' || raw == 'none') {
      return ColorTag.none;
    }
    for (final tag in ColorTag.values) {
      if (tag.name.toLowerCase() == raw.toLowerCase()) return tag;
    }
    return ColorTag.none;
  }

  /// 监听所有笔记本 (Repo)
  Stream<List<DataItem<Repo>>> watchRepos() {
    return changeNotifier.watchTable('repo').asyncMap((_) async {
      final rows = await db.query('repo', orderBy: 'created_at DESC');
      final now = DateTime.now();
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final repo = Repo.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        return DataItem<Repo>(
          r['id'] as String,
          DateTime.tryParse(r['created_at'] as String? ?? '') ?? now,
          DateTime.tryParse(r['updated_at'] as String? ?? '') ?? now,
          r['owner'] as String? ?? 'default',
          null,
          null,
          body: repo,
          syncStatus: SyncStatus.synced,
          colorTag: parseColorTag(r['color_tag'] as String?),
        );
      }).toList();
    });
  }

  /// 监听当前用户自建的笔记本 (我的小本本)
  Stream<List<DataItem<Repo>>> watchMyRepos(String userId) {
    return changeNotifier.watchTable('repo').asyncMap((_) async {
      final rows = await db.query(
        'repo',
        where: 'owner = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      final now = DateTime.now();
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final repo = Repo.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        return DataItem<Repo>(
          r['id'] as String,
          DateTime.tryParse(r['created_at'] as String? ?? '') ?? now,
          DateTime.tryParse(r['updated_at'] as String? ?? '') ?? now,
          r['owner'] as String? ?? 'default',
          null,
          null,
          body: repo,
          syncStatus: SyncStatus.synced,
          colorTag: parseColorTag(r['color_tag'] as String?),
        );
      }).toList();
    });
  }

  /// 监听订阅他人的笔记本 (订阅小本本)
  Stream<List<DataItem<Repo>>> watchSubscribedRepos(String userId) {
    return changeNotifier.watchTable('repo').asyncMap((_) async {
      final rows = await db.query(
        'repo',
        where: 'owner != ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );
      final now = DateTime.now();
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final repo = Repo.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        return DataItem<Repo>(
          r['id'] as String,
          DateTime.tryParse(r['created_at'] as String? ?? '') ?? now,
          DateTime.tryParse(r['updated_at'] as String? ?? '') ?? now,
          r['owner'] as String? ?? 'default',
          null,
          null,
          body: repo,
          syncStatus: SyncStatus.synced,
          colorTag: parseColorTag(r['color_tag'] as String?),
        );
      }).toList();
    });
  }

  /// 监听特定笔记本下的所有文章 (Post)
  Stream<List<DataItem<Post>>> watchPostsByRepo(String? repoId) {
    return changeNotifier.watchTable('post').asyncMap((_) async {
      if (repoId == null || repoId.isEmpty) return <DataItem<Post>>[];
      final rows = await db.query(
        'post',
        where: 'parent_id = ?',
        whereArgs: [repoId],
        orderBy: 'created_at DESC',
      );
      final now = DateTime.now();
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final post = Post.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        return DataItem<Post>(
          r['id'] as String,
          DateTime.tryParse(r['created_at'] as String? ?? '') ?? now,
          DateTime.tryParse(r['updated_at'] as String? ?? '') ?? now,
          r['owner'] as String? ?? 'default',
          repoId,
          null,
          body: post,
          syncStatus: SyncStatus.synced,
          colorTag: parseColorTag(r['color_tag'] as String?),
        );
      }).toList();
    });
  }

  /// 监听特定文章详情
  Stream<DataItem<Post>?> watchPostById(String? postId) {
    return changeNotifier.watchTable('post').asyncMap((_) async {
      if (postId == null || postId.isEmpty) return null;
      final rows = await db.query(
        'post',
        where: 'id = ?',
        whereArgs: [postId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final r = rows.first;
      final bodyStr = r['body'] as String? ?? '{}';
      final post = Post.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
      final now = DateTime.now();
      return DataItem<Post>(
        r['id'] as String,
        DateTime.tryParse(r['created_at'] as String? ?? '') ?? now,
        DateTime.tryParse(r['updated_at'] as String? ?? '') ?? now,
        r['owner'] as String? ?? 'default',
        r['parent_id'] as String?,
        null,
        body: post,
        syncStatus: SyncStatus.synced,
        colorTag: parseColorTag(r['color_tag'] as String?),
      );
    });
  }

  /// 保存笔记本 (Repo)
  Future<void> saveRepo(DataItem<Repo> item) async {
    final nowIso = DateTime.now().toIso8601String();
    final row = <String, dynamic>{
      'id': item.id,
      'created_at': nowIso,
      'updated_at': nowIso,
      'owner': item.owner,
      'parent_id': null,
      'sync_status': 'pending',
      'color_tag': item.colorTag != ColorTag.none ? item.colorTag.name : 'default',
      'body': jsonEncode(item.body.toJson()),
    };
    await LocalFirstDB.persistPutRaw(
      db: db,
      tableName: 'repo',
      entityId: item.id,
      entityRow: row,
    );
    changeNotifier.notify('repo');
    SyncWorker.instance.notifyLocalWrite();
  }

  /// 保存文章 (Post)
  Future<void> savePost(DataItem<Post> item) async {
    final nowIso = DateTime.now().toIso8601String();
    final row = <String, dynamic>{
      'id': item.id,
      'created_at': nowIso,
      'updated_at': nowIso,
      'owner': item.owner,
      'parent_id': item.body.repoId,
      'sync_status': 'pending',
      'color_tag': item.colorTag != ColorTag.none ? item.colorTag.name : 'default',
      'body': jsonEncode(item.body.toJson()),
    };
    await LocalFirstDB.persistPutRaw(
      db: db,
      tableName: 'post',
      entityId: item.id,
      entityRow: row,
    );
    changeNotifier.notify('post');
    SyncWorker.instance.notifyLocalWrite();
  }

  /// 更新笔记本的颜色标签
  Future<void> updateRepoColorTag(String repoId, ColorTag colorTag) async {
    final nowIso = DateTime.now().toIso8601String();
    await db.update(
      'repo',
      {
        'color_tag': colorTag != ColorTag.none ? colorTag.name : 'default',
        'updated_at': nowIso,
      },
      where: 'id = ?',
      whereArgs: [repoId],
    );
    changeNotifier.notify('repo');
    SyncWorker.instance.notifyLocalWrite();
  }

  /// 更新文章的颜色标签
  Future<void> updatePostColorTag(String postId, ColorTag colorTag) async {
    final nowIso = DateTime.now().toIso8601String();
    await db.update(
      'post',
      {
        'color_tag': colorTag != ColorTag.none ? colorTag.name : 'default',
        'updated_at': nowIso,
      },
      where: 'id = ?',
      whereArgs: [postId],
    );
    changeNotifier.notify('post');
    SyncWorker.instance.notifyLocalWrite();
  }

  /// 删除文章
  Future<void> deletePost(String id) async {
    await LocalFirstDB.persistDeleteRaw(
      db: db,
      tableName: 'post',
      entityId: id,
    );
    changeNotifier.notify('post');
    SyncWorker.instance.notifyLocalWrite();
  }

  /// 删除笔记本
  Future<void> deleteRepo(String id) async {
    await LocalFirstDB.persistDeleteRaw(
      db: db,
      tableName: 'repo',
      entityId: id,
    );
    changeNotifier.notify('repo');
    SyncWorker.instance.notifyLocalWrite();
  }

  /// 监听特定文章下的所有评论 (Comment)
  Stream<List<DataItem<Comment>>> watchComments(String? postId) {
    return changeNotifier.watchTable('comment').asyncMap((_) async {
      if (postId == null || postId.isEmpty) return <DataItem<Comment>>[];
      final rows = await db.query(
        'comment',
        where: 'parent_id = ?',
        whereArgs: [postId],
        orderBy: 'created_at ASC',
      );
      final now = DateTime.now();
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final comment = Comment.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        return DataItem<Comment>(
          r['id'] as String,
          DateTime.tryParse(r['created_at'] as String? ?? '') ?? now,
          DateTime.tryParse(r['updated_at'] as String? ?? '') ?? now,
          r['owner'] as String? ?? 'default',
          postId,
          null,
          body: comment,
          syncStatus: SyncStatus.synced,
        );
      }).toList();
    });
  }

  /// 保存/发表评论 (Comment)
  Future<void> addComment(DataItem<Comment> item) async {
    final nowIso = DateTime.now().toIso8601String();
    final row = <String, dynamic>{
      'id': item.id,
      'created_at': nowIso,
      'updated_at': nowIso,
      'owner': item.owner,
      'parent_id': item.body.postId,
      'sync_status': 'pending',
      'color_tag': 'default',
      'body': jsonEncode(item.body.toJson()),
    };
    await LocalFirstDB.persistPutRaw(
      db: db,
      tableName: 'comment',
      entityId: item.id,
      entityRow: row,
    );
    changeNotifier.notify('comment');
    SyncWorker.instance.notifyLocalWrite();
  }

  /// 删除评论 (Comment)
  Future<void> deleteComment(String id) async {
    await LocalFirstDB.persistDeleteRaw(
      db: db,
      tableName: 'comment',
      entityId: id,
    );
    changeNotifier.notify('comment');
    SyncWorker.instance.notifyLocalWrite();
  }

  /// 获取知识库成员权限列表
  Future<List<EntityAclEntry>> getRepoAcls(String repoId) async {
    final aclRepo = AclRepository(changeNotifier);
    return aclRepo.getAcls(db, table: 'repo', entityId: repoId);
  }

  /// 监听知识库成员权限列表
  Stream<List<EntityAclEntry>> watchRepoAcls(String repoId) {
    final aclRepo = AclRepository(changeNotifier);
    return aclRepo.watchAcls(db, table: 'repo', entityId: repoId);
  }

  /// 为知识库添加或更新成员权限 (本地记录、Outbox 变更与远端同步)
  Future<void> grantRepoPermission(String repoId, EntityAclEntry entry) async {
    final aclRepo = AclRepository(changeNotifier);
    await aclRepo.grantPermission(
      db: db,
      table: 'repo',
      entityId: repoId,
      entry: entry,
    );
  }

  /// 为知识库移除成员权限
  Future<void> revokeRepoPermission(String repoId, String granteeId) async {
    final aclRepo = AclRepository(changeNotifier);
    await aclRepo.revokePermission(
      db: db,
      table: 'repo',
      entityId: repoId,
      granteeId: granteeId,
    );
  }

  /// 生成标准分享口令 / URL
  static String generateShareLink(String ownerId, String repoId) {
    return 'xbb-share://$ownerId/$repoId';
  }

  /// 解析分享口令 / URL
  static ({String ownerId, String repoId})? parseShareLink(String link) {
    final trimmed = link.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme == 'xbb-share') {
      final owner = uri.host;
      final pathSegments = uri.pathSegments;
      if (owner.isNotEmpty && pathSegments.isNotEmpty) {
        return (ownerId: owner, repoId: pathSegments.first);
      }
    }
    final regex = RegExp(r'^xbb-share:\/\/([^/]+)\/(.+)$');
    final match = regex.firstMatch(trimmed);
    if (match != null) {
      return (ownerId: match.group(1)!, repoId: match.group(2)!);
    }
    return null;
  }

  /// 通过分享口令 / URL 订阅他人知识库
  Future<void> subscribeRepoByShareLink(String link, {String? repoName}) async {
    final parsed = parseShareLink(link);
    if (parsed == null) {
      throw Exception('无效的分享口令或链接');
    }
    final existing = await db.query('repo', where: 'id = ?', whereArgs: [parsed.repoId], limit: 1);
    if (existing.isNotEmpty) {
      return; // 已经存在
    }
    final now = DateTime.now();
    final newRepo = DataItem<Repo>(
      parsed.repoId,
      now,
      now,
      parsed.ownerId,
      null,
      null,
      body: Repo(name: repoName ?? '订阅小本本', status: 'active'),
      syncStatus: SyncStatus.synced,
    );
    await saveRepo(newRepo);
    SyncWorker.instance.triggerSync();
  }
}

/// 独立的评论仓储抽象，便于特定模块注入与解耦
class NotesCommentRepository {
  final NotesRepository _notesRepo;

  NotesCommentRepository(this._notesRepo);

  Stream<List<DataItem<Comment>>> watchComments(String? postId) =>
      _notesRepo.watchComments(postId);

  Future<void> addComment(DataItem<Comment> item) =>
      _notesRepo.addComment(item);

  Future<void> deleteComment(String id) =>
      _notesRepo.deleteComment(id);
}
