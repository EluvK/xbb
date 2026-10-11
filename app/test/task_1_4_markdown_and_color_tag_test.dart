import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/notes/markdown_renderer.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/repositories/notes_repository.dart';
import 'package:xbb/models/notes/model.dart';
import 'package:xbb/presentation/notes/markdown_editor_toolbar.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TASK-1.4: 升级全功能 Markdown 渲染与专业编辑工具栏', () {
    late Database db;
    late DatabaseChangeNotifier dbChangeNotifier;
    late NotesRepository notesRepo;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
      dbChangeNotifier = DatabaseChangeNotifier();
      notesRepo = NotesRepository(db: db, changeNotifier: dbChangeNotifier);
    });

    tearDown(() async {
      await db.close();
      SyncWorker.instance.stop();
    });

    test('Color Tag 分类绑定、存储与更新流测试', () async {
      final now = DateTime.now();

      // 1. 创建带有 ColorTag.blue 的 Repo
      final repo = DataItem<Repo>(
        'repo-color-1',
        now,
        now,
        'user-1',
        null,
        null,
        body: const Repo(name: '设计系统规范', status: 'active'),
        syncStatus: SyncStatus.synced,
        colorTag: ColorTag.blue,
      );
      await notesRepo.saveRepo(repo);

      // 验证 SQLite 记录
      final repoRows = await db.query('repo', where: 'id = ?', whereArgs: ['repo-color-1']);
      expect(repoRows.first['color_tag'], equals('blue'));

      // 验证 watchRepos 解析出正确枚举
      final repos = await notesRepo.watchRepos().first;
      expect(repos.first.colorTag, equals(ColorTag.blue));

      // 2. 创建带有 ColorTag.red 的 Post
      final post = DataItem<Post>(
        'post-color-1',
        now,
        now,
        'user-1',
        'repo-color-1',
        null,
        body: const Post(title: '紧急 Bug 记录', category: 'Dev', content: '...', repoId: 'repo-color-1'),
        syncStatus: SyncStatus.synced,
        colorTag: ColorTag.red,
      );
      await notesRepo.savePost(post);

      final postRows = await db.query('post', where: 'id = ?', whereArgs: ['post-color-1']);
      expect(postRows.first['color_tag'], equals('red'));

      final posts = await notesRepo.watchPostsByRepo('repo-color-1').first;
      expect(posts.first.colorTag, equals(ColorTag.red));

      // 3. 更新颜色标签
      await notesRepo.updatePostColorTag('post-color-1', ColorTag.yellow);
      final updatedPosts = await notesRepo.watchPostsByRepo('repo-color-1').first;
      expect(updatedPosts.first.colorTag, equals(ColorTag.yellow));

      await notesRepo.updateRepoColorTag('repo-color-1', ColorTag.green);
      final updatedRepos = await notesRepo.watchRepos().first;
      expect(updatedRepos.first.colorTag, equals(ColorTag.green));
    });

    testWidgets('MarkdownEditorToolbar 点击快捷插入与包裹语法', (tester) async {
      final controller = TextEditingController(text: 'Hello World');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownEditorToolbar(controller: controller),
          ),
        ),
      );

      // 1. 无选中时点击一级标题 (# )
      controller.selection = const TextSelection.collapsed(offset: 0);
      final h1Button = find.byTooltip('一级标题 (# )');
      expect(h1Button, findsOneWidget);
      await tester.tap(h1Button);
      await tester.pump();
      expect(controller.text, startsWith('# '));

      // 2. 选中 "World" 并点击加粗
      controller.text = 'Hello World';
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11);
      final boldButton = find.byTooltip('加粗 (**文本**)');
      expect(boldButton, findsOneWidget);
      await tester.tap(boldButton);
      await tester.pump();
      expect(controller.text, equals('Hello **World**'));

      // 3. 点击插入表格
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
      final tableButton = find.byTooltip('插入表格');
      expect(tableButton, findsOneWidget);
      await tester.tap(tableButton);
      await tester.pump();
      expect(controller.text, contains('| 标题 1 | 标题 2 |'));

      // 4. 点击插入 LaTeX 公式
      final latexButton = find.byTooltip('插入 LaTeX 数学公式 (\$\$)');
      expect(latexButton, findsOneWidget);
      await tester.tap(latexButton);
      await tester.pump();
      expect(controller.text, contains('\$\$'));
    });

    testWidgets('SimpleMarkdownRenderer 成功渲染包含代码块与 LaTeX 公式的 Markdown', (tester) async {
      const complexMarkdown = '''
# 算法分析与实现

下面是一个复杂度公式：
\$\$E = mc^2\$\$

以及行内公式 \$O(n \\log n)\$。

```dart
void main() {
  print("Hello, LaTeX & Markdown!");
}
```
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SimpleMarkdownRenderer(data: complexMarkdown),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 验证标题文字被渲染
      expect(find.textContaining('算法分析与实现'), findsOneWidget);
      // 验证代码块内容与语言被渲染
      expect(find.textContaining('Hello, LaTeX & Markdown!'), findsOneWidget);
    });
  });
}
