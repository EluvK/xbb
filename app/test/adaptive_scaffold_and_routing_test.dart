import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/data/database_change_notifier.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/data/repositories/notes_repository.dart';
import 'package:xbb/data/repositories/task_repository.dart';
import 'package:xbb/presentation/notes/modern_notes_view.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/task/modern_task_view.dart';
import 'package:xbb/sync/v2/local_first_db.dart';
import 'package:xbb/sync/v2/sync_worker.dart';
import 'package:xbb/utils/translation.dart';

class _TestAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _TestAuthNotifier() : super(const AuthState(userId: 'test-user', isLoggedIn: true));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    Translation.setLocale('zh_CN');
  });

  group('多端自适应布局与路由解耦测试 (Adaptive Layout & Workspace)', () {
    late Database db;
    late DatabaseChangeNotifier dbChangeNotifier;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
      dbChangeNotifier = DatabaseChangeNotifier();
    });

    tearDown(() async {
      await db.close();
      SyncWorker.instance.stop();
    });

    testWidgets('Notes 移动端提供笔记本侧边栏抽屉与层级返回，桌面端展开多栏工作区', (tester) async {
      // 1. 模拟移动端屏幕尺寸 (400 x 800)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            authProvider.overrideWith((ref) => _TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: ModernNotesView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 移动端应该提供笔记本列表入口按钮 (menu_book_outlined)
      final drawerBtn = find.byIcon(Icons.menu_book_outlined);
      expect(drawerBtn, findsOneWidget);

      // 点击打开侧边抽屉
      await tester.tap(drawerBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 验证抽屉内包含 "我的仓库" 和 "订阅的仓库"
      expect(find.textContaining('我的仓库'), findsOneWidget);
      expect(find.textContaining('订阅的仓库'), findsOneWidget);

      // 2. 模拟桌面大屏尺寸 (1200 x 800)
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            authProvider.overrideWith((ref) => _TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: ModernNotesView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 桌面端三栏常驻，无需侧滑抽屉按钮，直接同屏展示
      expect(find.textContaining('我的仓库'), findsOneWidget);
      expect(find.textContaining('订阅的仓库'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
    });

    testWidgets('Task 模块在桌面大屏上同屏呈现活跃清单与近期归档段落', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            authProvider.overrideWith((ref) => _TestAuthNotifier()),
          ],
          child: const MaterialApp(
            home: ModernTaskView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 验证桌面大屏同屏展示活跃列表与归档列表
      expect(find.text('待办事项'), findsOneWidget);
      expect(find.text('已归档清单'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 11));
    });
  });
}
