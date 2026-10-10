import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/chat/db.dart';
import 'package:xbb/models/chat/model.dart';
import 'package:xbb/models/notes/db.dart';
import 'package:xbb/models/notes/model.dart';

void main() {
  late Database notesDb;
  late Database chatDb;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = await getDatabasesPath();
    final notesDbPath = '$dbPath/test_notes_${DateTime.now().microsecondsSinceEpoch}.db';
    final chatDbPath = '$dbPath/test_chat_${DateTime.now().microsecondsSinceEpoch}.db';

    notesDb = await databaseFactory.openDatabase(
      notesDbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(LocalStoreRepo.onCreateTableRepoSQL);
          await db.execute(LocalStorePost.onCreateTablePostSQL);
          await db.execute(LocalStoreComment.onCreateTableCommentSQL);
        },
      ),
    );
    NotesDB.setMockDb(notesDb);

    chatDb = await databaseFactory.openDatabase(
      chatDbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(LocalStoreChatConversation.onCreateTableChatConversationSQL);
          await db.execute(LocalStoreChatMessage.onCreateTableChatMessageSQL);
        },
      ),
    );
    ChatDB.setMockDb(chatDb);
  });

  tearDownAll(() async {
    await notesDb.close();
    await chatDb.close();
  });

  setUp(() async {
    await notesDb.delete(LocalStoreRepo.tableName);
    await notesDb.delete(LocalStorePost.tableName);
    await notesDb.delete(LocalStoreComment.tableName);
    await chatDb.delete(LocalStoreChatConversation.tableName);
    await chatDb.delete(LocalStoreChatMessage.tableName);
  });

  group('TASK-4.1: 解除父子关系对网络层的依赖 (纯本地 SQL 查询)', () {

    test('笔记 Post 查询: 纯本地 SQL 根据 repoId 查询且按 created_at DESC 排序', () async {
      final postRepo = PostRepository();

      final t1 = DateTime.utc(2025, 1, 1, 10, 0, 0);
      final t2 = DateTime.utc(2025, 1, 1, 11, 0, 0);
      final t3 = DateTime.utc(2025, 1, 1, 12, 0, 0);

      // 插入 repo-A 的两篇笔记 (t1, t3)
      final postA1 = DataItem<Post>(
        'post-a1',
        t1,
        t1,
        'user-1',
        'repo-A',
        null,
        body: const Post(title: 'Post A1', category: 'General', content: 'Content A1', repoId: 'repo-A'),
      );
      final postA2 = DataItem<Post>(
        'post-a2',
        t3,
        t3,
        'user-1',
        'repo-A',
        null,
        body: const Post(title: 'Post A2 (newer)', category: 'General', content: 'Content A2', repoId: 'repo-A'),
      );

      // 插入 repo-B 的一篇笔记 (t2)
      final postB1 = DataItem<Post>(
        'post-b1',
        t2,
        t2,
        'user-1',
        'repo-B',
        null,
        body: const Post(title: 'Post B1', category: 'Work', content: 'Content B1', repoId: 'repo-B'),
      );

      await postRepo.addToLocalDb(postA1);
      await postRepo.addToLocalDb(postB1);
      await postRepo.addToLocalDb(postA2);

      // 纯本地 SQL 查询 repo-A: SELECT * FROM post WHERE parent_id = ? ORDER BY created_at DESC
      final postsA = await postRepo.listByParentIdFromLocalDb('repo-A');
      expect(postsA.length, equals(2));
      // 验证按时间倒序
      expect(postsA[0].id, equals('post-a2'));
      expect(postsA[1].id, equals('post-a1'));

      // 纯本地 SQL 查询 repo-B: 瞬间呈现，且与 repo-A 隔离
      final postsB = await postRepo.listByParentIdFromLocalDb('repo-B');
      expect(postsB.length, equals(1));
      expect(postsB[0].id, equals('post-b1'));
      expect(postsB[0].body.repoId, equals('repo-B'));
    });

    test('评论 Comment 查询: 纯本地 SQL 根据 postId 查询且按 created_at ASC 排序', () async {
      final commentRepo = CommentRepository();

      final t1 = DateTime.utc(2025, 1, 1, 10, 5, 0);
      final t2 = DateTime.utc(2025, 1, 1, 10, 15, 0);

      final c1 = DataItem<Comment>(
        'comment-1',
        t1,
        t1,
        'user-1',
        'post-1',
        null,
        body: const Comment(content: 'First comment', postId: 'post-1'),
      );
      final c2 = DataItem<Comment>(
        'comment-2',
        t2,
        t2,
        'user-2',
        'post-1',
        null,
        body: const Comment(content: 'Second comment', postId: 'post-1'),
      );
      final c3 = DataItem<Comment>(
        'comment-3',
        t1,
        t1,
        'user-1',
        'post-2',
        null,
        body: const Comment(content: 'Comment on other post', postId: 'post-2'),
      );

      await commentRepo.addToLocalDb(c1);
      await commentRepo.addToLocalDb(c2);
      await commentRepo.addToLocalDb(c3);

      final commentsPost1 = await commentRepo.listByParentIdFromLocalDb('post-1', desc: false);
      expect(commentsPost1.length, equals(2));
      expect(commentsPost1[0].id, equals('comment-1'));
      expect(commentsPost1[1].id, equals('comment-2'));

      final commentsPost2 = await commentRepo.listByParentIdFromLocalDb('post-2', desc: false);
      expect(commentsPost2.length, equals(1));
      expect(commentsPost2[0].id, equals('comment-3'));
    });

    test('聊天 ChatMessage 查询: 纯本地 SQL 根据 conversationId 查询且按时间升序排列', () async {
      final msgRepo = ChatMessageRepository();

      final t1 = DateTime.utc(2025, 1, 2, 8, 0, 0);
      final t2 = DateTime.utc(2025, 1, 2, 8, 1, 0);

      final msg1 = DataItem<ChatMessage>(
        'msg-1',
        t1,
        t1,
        'user-1',
        'conv-1',
        null,
        body: const ChatMessage(
          conversationId: 'conv-1',
          role: ChatMessageRole.user,
          text: 'Hello!',
        ),
      );
      final msg2 = DataItem<ChatMessage>(
        'msg-2',
        t2,
        t2,
        'user-1',
        'conv-1',
        null,
        body: const ChatMessage(
          conversationId: 'conv-1',
          role: ChatMessageRole.assistant,
          text: 'Hi there!',
        ),
      );

      await msgRepo.addToLocalDb(msg1);
      await msgRepo.addToLocalDb(msg2);

      final conv1Messages = await msgRepo.listByParentIdFromLocalDb('conv-1', desc: false);
      expect(conv1Messages.length, equals(2));
      expect(conv1Messages[0].id, equals('msg-1'));
      expect(conv1Messages[0].body.text, equals('Hello!'));
      expect(conv1Messages[1].id, equals('msg-2'));
      expect(conv1Messages[1].body.text, equals('Hi there!'));

      // 空会话查询结果为空列表，断网状态下瞬间返回无异常
      final conv2Messages = await msgRepo.listByParentIdFromLocalDb('conv-empty', desc: false);
      expect(conv2Messages, isEmpty);
    });
  });
}
