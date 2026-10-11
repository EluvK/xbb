import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xbb/data/drift/app_drift_database.dart';
import 'package:xbb/presentation/providers/workspace_notifier.dart';
import 'package:xbb/sync/v2/local_first_db.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Drift 响应式数据层与状态管理底座现代化测试 (Drift & Architecture Modernization)', () {
    late Database db;
    late AppDriftEngine driftEngine;

    setUp(() async {
      db = await LocalFirstDB.openInMemory();
      driftEngine = AppDriftEngine(db);
    });

    tearDown(() async {
      await driftEngine.close();
      await db.close();
    });

    test('AppDriftEngine.watchQuery 能够响应式发射当前快照并在事务变更后自动推送新数据', () async {
      final stream = driftEngine.watchQuery('check_list');
      final emissions = <List<Map<String, dynamic>>>[];

      final sub = stream.listen((data) {
        emissions.add(data);
      });

      // 等待初始快照发射
      await Future.delayed(const Duration(milliseconds: 50));
      expect(emissions.length, 1);
      expect(emissions.first, isEmpty);

      // 执行原子事务落盘并触发变更通知
      await driftEngine.runAtomicMutation(
        (txn) async {
          await txn.insert('check_list', {
            'id': 'test-list-1',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'owner': 'user-1',
            'parent_id': null,
            'sync_status': 'synced',
            'color_tag': 'default',
            'body': '{"items":[]}',
          });
        },
        affectedTables: ['check_list'],
      );

      // 等待响应式流推射最新数据
      await Future.delayed(const Duration(milliseconds: 50));
      expect(emissions.length, 2);
      expect(emissions.last.length, 1);
      expect(emissions.last.first['id'], 'test-list-1');

      await sub.cancel();
    });

    test('WorkspaceNotifier 状态机流转与强类型更新测试', () {
      final notifier = WorkspaceNotifier();
      expect(notifier.state.isOnline, isTrue);
      expect(notifier.state.isSyncing, isFalse);

      notifier.setSyncing(true);
      expect(notifier.state.isSyncing, isTrue);

      notifier.setOnline(false);
      expect(notifier.state.isOnline, isFalse);

      notifier.updateTabCount(5);
      expect(notifier.state.activeTabCount, 5);
    });
  });
}
