import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/base_repository.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';
import 'package:xbb/sync/v2/uuid_service.dart';

class NotesRepository {
  final Database db;
  final DatabaseChangeNotifier changeNotifier;

  NotesRepository({
    required this.db,
    required this.changeNotifier,
  });

  /// 监听所有笔记本 (Repo)
  Stream<List<DataItem<Repo>>> watchRepos() {
    return changeNotifier.watchTable('repo').asyncMap((_) async {
      final rows = await db.query('repo', orderBy: 'created_at DESC');
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final repo = Repo.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        return DataItem<Repo>(
          id: r['id'] as String,
          owner: r['owner'] as String? ?? 'default',
          body: repo,
          createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now(),
          syncStatus: SyncStatus.synced,
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
      return rows.map((r) {
        final bodyStr = r['body'] as String? ?? '{}';
        final post = Post.fromJson(jsonDecode(bodyStr) as Map<String, dynamic>);
        return DataItem<Post>(
          id: r['id'] as String,
          owner: r['owner'] as String? ?? 'default',
          parentId: repoId,
          body: post,
          createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
          updatedAt: DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now(),
          syncStatus: SyncStatus.synced,
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
      return DataItem<Post>(
        id: r['id'] as String,
        owner: r['owner'] as String? ?? 'default',
        parentId: r['parent_id'] as String?,
        body: post,
        createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(r['updated_at'] as String? ?? '') ?? DateTime.now(),
        syncStatus: SyncStatus.synced,
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
      'color_tag': 'default',
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
      'color_tag': 'default',
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
}
