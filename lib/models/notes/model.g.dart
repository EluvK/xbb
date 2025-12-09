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
          color_tag TEXT NOT NULL,
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

class RepoController extends GetxController {
  final SyncStoreClient client;
  final _RepoSyncEngine _syncEngine;
  RepoController(this.client) : _syncEngine = _RepoSyncEngine(client);

  final RxList<RepoDataItem> _items = <RepoDataItem>[].obs;
  final Rx<String?> currentRepoId = Rx<String?>(null);

  @override
  Future<void> onInit() async {
    await rebuildLocal();
    super.onInit();
    _initialized = true;
  }

  bool _initialized = false;
  Future<void> ensureInitialization() async {
    while (!_initialized) {
      await onInit();
    }
    return;
  }

  Future<void> rebuildLocal() async {
    _items.value = await RepoRepository().listFromLocalDb();
  }

  void onSelectRepo(String id) {
    currentRepoId.value = id;
  }

  List<RepoDataItem> onViewRepos({List<DataItemFilter> filters = const []}) {
    if (filters.isEmpty) {
      return _items;
    }
    return _items.where((item) => filters.every((filter) => filter.apply(item))).toList();
  }

  Future<void> trySyncAll() async {
    await _syncEngine.syncAll();
    await rebuildLocal();
  }

  void _replaceLocal(String id, RepoDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    // print('Replaced local Repo with id: $id, new id: ${fetchedItem.id}');
    if (currentRepoId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentRepoId.value = fetchedItem.id;
    }
  }

  void addData(Repo newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = RepoDataItem.localNew(owner, newData);
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _syncEngine.create(newItem).then((fetchedItem) {
      _replaceLocal(newItem.id, fetchedItem);
    });
  }

  void updateData(String id, Repo updatedData) {
    final item = _items.firstWhere((item) => item.id == id);
    // todo maybe rewrite this update body method...
    final updatedItem = item.updatedBody(updatedData);
    _items[_items.indexOf(item)] = updatedItem;
    _syncEngine.update(updatedItem).then((fetchedItem) {
      _replaceLocal(updatedItem.id, fetchedItem);
    });
  }

  void updateColorLocal(String id, ColorTag color) {
    final item = _items.firstWhere((item) => item.id == id);
    final updatedItem = item.updatedColorTag(color);
    _items[_items.indexOf(item)] = updatedItem;
  }

  void deleteData(String id) {
    _items.removeWhere((item) => item.id == id);
    if (currentRepoId.value == id) {
      currentRepoId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    _syncEngine.delete(id, status != SyncStatus.deleted);
  }
}

class _RepoSyncEngine {
  final SyncStoreClient client;
  _RepoSyncEngine(this.client);

  Future<RepoDataItem> create(RepoDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await RepoRepository().addToLocalDb(local);

    RepoDataItem createdItem;
    try {
      final newId = await client.create('xbb', 'repo', local.body.toJson());
      createdItem = await client.get<Repo>('xbb', 'repo', newId, Repo.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await RepoRepository().updateToLocalDb(local);
      rethrow;
    }
    createdItem.syncStatus = SyncStatus.archived;
    createdItem.colorTag = local.colorTag;

    await RepoRepository().deleteFromLocalDb(local.id);
    await RepoRepository().addToLocalDb(createdItem);
    return createdItem;
  }

  Future<RepoDataItem> update(RepoDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await RepoRepository().updateToLocalDb(local);

    RepoDataItem updatedItem;
    try {
      await client.update('xbb', 'repo', local.id, local.body.toJson());
      updatedItem = await client.get<Repo>('xbb', 'repo', local.id, Repo.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await RepoRepository().updateToLocalDb(local);
      rethrow;
    }
    updatedItem.syncStatus = SyncStatus.archived;
    updatedItem.colorTag = local.colorTag;

    await RepoRepository().updateToLocalDb(updatedItem);
    return updatedItem;
  }

  void delete(String id, bool deleteFromServer) {
    RepoRepository().deleteFromLocalDb(id);
    if (!deleteFromServer) {
      return;
    }
    try {
      client.delete('xbb', 'repo', id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncAll() async {
    try {
      var nextMarker = null;
      final serviceIds = <String>{};
      do {
        final ListResponse resp = await client.list('xbb', 'repo', limit: 50, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final RepoDataItem? localItem = await RepoRepository().getFromLocalDb(summary.id);
          if (localItem == null) {
            // new from server
            final RepoDataItem item = await client.get<Repo>('xbb', 'repo', summary.id, Repo.fromJson);
            await RepoRepository().addToLocalDb(item);
          } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
            // update local data.
            final RepoDataItem item = await client.get<Repo>('xbb', 'repo', summary.id, Repo.fromJson);
            await RepoRepository().updateToLocalDb(item);
          } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
            // local data is newer, need to sync to server
            localItem.syncStatus = SyncStatus.failed;
            await RepoRepository().updateToLocalDb(localItem);
          }
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await RepoRepository().listFromLocalDb();
      for (RepoDataItem localItem in localItems) {
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await RepoRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
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
          color_tag TEXT NOT NULL,
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

class PostController extends GetxController {
  final SyncStoreClient client;
  final _PostSyncEngine _syncEngine;
  PostController(this.client) : _syncEngine = _PostSyncEngine(client);

  final RxList<PostDataItem> _items = <PostDataItem>[].obs;
  final Rx<String?> currentPostId = Rx<String?>(null);

  @override
  Future<void> onInit() async {
    await rebuildLocal();
    super.onInit();
    _initialized = true;
  }

  bool _initialized = false;
  Future<void> ensureInitialization() async {
    while (!_initialized) {
      await onInit();
    }
    return;
  }

  Future<void> rebuildLocal() async {
    _items.value = await PostRepository().listFromLocalDb();
  }

  void onSelectPost(String id) {
    currentPostId.value = id;
  }

  List<PostDataItem> onViewPosts({List<DataItemFilter> filters = const []}) {
    if (filters.isEmpty) {
      return _items;
    }
    return _items.where((item) => filters.every((filter) => filter.apply(item))).toList();
  }

  Future<void> trySyncAll() async {
    await _syncEngine.syncAll();
    await rebuildLocal();
  }

  void _replaceLocal(String id, PostDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    // print('Replaced local Post with id: $id, new id: ${fetchedItem.id}');
    if (currentPostId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentPostId.value = fetchedItem.id;
    }
  }

  void addData(Post newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = PostDataItem.localNew(owner, newData);
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _syncEngine.create(newItem).then((fetchedItem) {
      _replaceLocal(newItem.id, fetchedItem);
    });
  }

  void updateData(String id, Post updatedData) {
    final item = _items.firstWhere((item) => item.id == id);
    // todo maybe rewrite this update body method...
    final updatedItem = item.updatedBody(updatedData);
    _items[_items.indexOf(item)] = updatedItem;
    _syncEngine.update(updatedItem).then((fetchedItem) {
      _replaceLocal(updatedItem.id, fetchedItem);
    });
  }

  void updateColorLocal(String id, ColorTag color) {
    final item = _items.firstWhere((item) => item.id == id);
    final updatedItem = item.updatedColorTag(color);
    _items[_items.indexOf(item)] = updatedItem;
  }

  void deleteData(String id) {
    _items.removeWhere((item) => item.id == id);
    if (currentPostId.value == id) {
      currentPostId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    _syncEngine.delete(id, status != SyncStatus.deleted);
  }
}

class _PostSyncEngine {
  final SyncStoreClient client;
  _PostSyncEngine(this.client);

  Future<PostDataItem> create(PostDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await PostRepository().addToLocalDb(local);

    PostDataItem createdItem;
    try {
      final newId = await client.create('xbb', 'post', local.body.toJson());
      createdItem = await client.get<Post>('xbb', 'post', newId, Post.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await PostRepository().updateToLocalDb(local);
      rethrow;
    }
    createdItem.syncStatus = SyncStatus.archived;
    createdItem.colorTag = local.colorTag;

    await PostRepository().deleteFromLocalDb(local.id);
    await PostRepository().addToLocalDb(createdItem);
    return createdItem;
  }

  Future<PostDataItem> update(PostDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await PostRepository().updateToLocalDb(local);

    PostDataItem updatedItem;
    try {
      await client.update('xbb', 'post', local.id, local.body.toJson());
      updatedItem = await client.get<Post>('xbb', 'post', local.id, Post.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await PostRepository().updateToLocalDb(local);
      rethrow;
    }
    updatedItem.syncStatus = SyncStatus.archived;
    updatedItem.colorTag = local.colorTag;

    await PostRepository().updateToLocalDb(updatedItem);
    return updatedItem;
  }

  void delete(String id, bool deleteFromServer) {
    PostRepository().deleteFromLocalDb(id);
    if (!deleteFromServer) {
      return;
    }
    try {
      client.delete('xbb', 'post', id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncAll() async {
    try {
      var nextMarker = null;
      final serviceIds = <String>{};
      do {
        final ListResponse resp = await client.list('xbb', 'post', limit: 50, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final PostDataItem? localItem = await PostRepository().getFromLocalDb(summary.id);
          if (localItem == null) {
            // new from server
            final PostDataItem item = await client.get<Post>('xbb', 'post', summary.id, Post.fromJson);
            await PostRepository().addToLocalDb(item);
          } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
            // update local data.
            final PostDataItem item = await client.get<Post>('xbb', 'post', summary.id, Post.fromJson);
            await PostRepository().updateToLocalDb(item);
          } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
            // local data is newer, need to sync to server
            localItem.syncStatus = SyncStatus.failed;
            await PostRepository().updateToLocalDb(localItem);
          }
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await PostRepository().listFromLocalDb();
      for (PostDataItem localItem in localItems) {
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await PostRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
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
          color_tag TEXT NOT NULL,
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

class CommentController extends GetxController {
  final SyncStoreClient client;
  final _CommentSyncEngine _syncEngine;
  CommentController(this.client) : _syncEngine = _CommentSyncEngine(client);

  final RxList<CommentDataItem> _items = <CommentDataItem>[].obs;
  final Rx<String?> currentCommentId = Rx<String?>(null);

  @override
  Future<void> onInit() async {
    await rebuildLocal();
    super.onInit();
    _initialized = true;
  }

  bool _initialized = false;
  Future<void> ensureInitialization() async {
    while (!_initialized) {
      await onInit();
    }
    return;
  }

  Future<void> rebuildLocal() async {
    _items.value = await CommentRepository().listFromLocalDb();
  }

  void onSelectComment(String id) {
    currentCommentId.value = id;
  }

  List<CommentDataItem> onViewComments({List<DataItemFilter> filters = const []}) {
    if (filters.isEmpty) {
      return _items;
    }
    return _items.where((item) => filters.every((filter) => filter.apply(item))).toList();
  }

  Future<void> trySyncAll() async {
    await _syncEngine.syncAll();
    await rebuildLocal();
  }

  void _replaceLocal(String id, CommentDataItem fetchedItem) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = fetchedItem;
    }
    // print('Replaced local Comment with id: $id, new id: ${fetchedItem.id}');
    if (currentCommentId.value == id && fetchedItem.id != id) {
      // update current selected id if changed by server generated id
      currentCommentId.value = fetchedItem.id;
    }
  }

  void addData(Comment newData) {
    // generate a local uuid before successfully created on server
    final owner = client.currentUserId();
    final newItem = CommentDataItem.localNew(owner, newData);
    // it's a temporary memory data, not even in local db yet.
    _items.add(newItem);
    _syncEngine.create(newItem).then((fetchedItem) {
      _replaceLocal(newItem.id, fetchedItem);
    });
  }

  void updateData(String id, Comment updatedData) {
    final item = _items.firstWhere((item) => item.id == id);
    // todo maybe rewrite this update body method...
    final updatedItem = item.updatedBody(updatedData);
    _items[_items.indexOf(item)] = updatedItem;
    _syncEngine.update(updatedItem).then((fetchedItem) {
      _replaceLocal(updatedItem.id, fetchedItem);
    });
  }

  void updateColorLocal(String id, ColorTag color) {
    final item = _items.firstWhere((item) => item.id == id);
    final updatedItem = item.updatedColorTag(color);
    _items[_items.indexOf(item)] = updatedItem;
  }

  void deleteData(String id) {
    _items.removeWhere((item) => item.id == id);
    if (currentCommentId.value == id) {
      currentCommentId.value = null;
    }
    final status = _items.firstWhereOrNull((item) => item.id == id)?.syncStatus;
    _syncEngine.delete(id, status != SyncStatus.deleted);
  }
}

class _CommentSyncEngine {
  final SyncStoreClient client;
  _CommentSyncEngine(this.client);

  Future<CommentDataItem> create(CommentDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await CommentRepository().addToLocalDb(local);

    CommentDataItem createdItem;
    try {
      final newId = await client.create('xbb', 'comment', local.body.toJson());
      createdItem = await client.get<Comment>('xbb', 'comment', newId, Comment.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await CommentRepository().updateToLocalDb(local);
      rethrow;
    }
    createdItem.syncStatus = SyncStatus.archived;
    createdItem.colorTag = local.colorTag;

    await CommentRepository().deleteFromLocalDb(local.id);
    await CommentRepository().addToLocalDb(createdItem);
    return createdItem;
  }

  Future<CommentDataItem> update(CommentDataItem local) async {
    local.syncStatus = SyncStatus.syncing;
    await CommentRepository().updateToLocalDb(local);

    CommentDataItem updatedItem;
    try {
      await client.update('xbb', 'comment', local.id, local.body.toJson());
      updatedItem = await client.get<Comment>('xbb', 'comment', local.id, Comment.fromJson);
    } catch (e) {
      local.syncStatus = SyncStatus.failed;
      await CommentRepository().updateToLocalDb(local);
      rethrow;
    }
    updatedItem.syncStatus = SyncStatus.archived;
    updatedItem.colorTag = local.colorTag;

    await CommentRepository().updateToLocalDb(updatedItem);
    return updatedItem;
  }

  void delete(String id, bool deleteFromServer) {
    CommentRepository().deleteFromLocalDb(id);
    if (!deleteFromServer) {
      return;
    }
    try {
      client.delete('xbb', 'comment', id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncAll() async {
    try {
      var nextMarker = null;
      final serviceIds = <String>{};
      do {
        final ListResponse resp = await client.list('xbb', 'comment', limit: 50, marker: nextMarker);
        nextMarker = resp.pageInfo.nextMarker;
        for (var summary in resp.items) {
          serviceIds.add(summary.id);
          final CommentDataItem? localItem = await CommentRepository().getFromLocalDb(summary.id);
          if (localItem == null) {
            // new from server
            final CommentDataItem item = await client.get<Comment>('xbb', 'comment', summary.id, Comment.fromJson);
            await CommentRepository().addToLocalDb(item);
          } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
            // update local data.
            final CommentDataItem item = await client.get<Comment>('xbb', 'comment', summary.id, Comment.fromJson);
            await CommentRepository().updateToLocalDb(item);
          } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
            // local data is newer, need to sync to server
            localItem.syncStatus = SyncStatus.failed;
            await CommentRepository().updateToLocalDb(localItem);
          }
        }
      } while (nextMarker != null);
      // clean up local data that are deleted from server
      final localItems = await CommentRepository().listFromLocalDb();
      for (CommentDataItem localItem in localItems) {
        if (!serviceIds.contains(localItem.id)) {
          localItem.syncStatus = SyncStatus.deleted;
          await CommentRepository().updateToLocalDb(localItem);
        }
      }
    } catch (e) {
      // todo more error handling?
      rethrow;
    }
  }
}
