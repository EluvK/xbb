import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xbb/models/task/model.dart';
import 'package:xbb/presentation/task/modern_task_view.dart';
import 'package:xbb/presentation/task/task_overview_card.dart';

void main() {
  group('TASK-2.3: 恢复任务详情模式与活跃概览统计卡片', () {
    testWidgets('TaskOverviewCard 正确计算完成率百分比并展示总数/已完成/待处理', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TaskOverviewCard(
              totalCount: 4,
              doneCount: 1,
            ),
          ),
        ),
      );

      // 验证百分比徽标 (1/4 = 25%)
      expect(find.text('25%'), findsOneWidget);

      // 验证卡片标题
      expect(find.text('任务概览与进度'), findsOneWidget);

      // 验证统计指标
      expect(find.text('总任务'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('已完成'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('待处理'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('TaskOverviewCard 在全部完成时显示 100% 并支持折叠切换', (tester) async {
      bool isCollapsed = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: TaskOverviewCard(
                  totalCount: 5,
                  doneCount: 5,
                  isCollapsed: isCollapsed,
                  onToggleCollapse: () {
                    setState(() => isCollapsed = !isCollapsed);
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('待处理'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);

      // 点击折叠按钮
      await tester.tap(find.byTooltip('收起概览'));
      await tester.pump();

      // 折叠后指标 Box 不再渲染
      expect(find.text('待处理'), findsNothing);

      // 点击展开按钮
      await tester.tap(find.byTooltip('展开概览'));
      await tester.pump();

      // 展开后恢复渲染
      expect(find.text('待处理'), findsOneWidget);
    });

    testWidgets('InlineTaskTile 在详情模式下正确展示 ID、序号、完成时间与更新时间', (tester) async {
      final now = DateTime(2026, 3, 31, 15, 30);
      final doneTime = DateTime(2026, 3, 31, 15, 35);

      final undoneTask = TaskItem(
        id: 'task-undone-1',
        content: '未完成任务',
        done: false,
        lastModifiedAt: now,
        sortOrder: 2,
      );

      final doneTask = TaskItem(
        id: 'task-done-2',
        content: '已完成任务',
        done: true,
        doneAt: doneTime,
        lastModifiedAt: doneTime,
        sortOrder: 3,
      );

      // 1. 关闭详情模式时，不显示元数据详情
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineTaskTile(
              task: undoneTask,
              isEditing: false,
              showDetails: false,
              onTapEdit: () {},
              onSubmitted: (_) {},
              onCancel: () {},
              onToggleDone: (_) {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('ID: task-undone-1'), findsNothing);
      expect(find.textContaining('完成时间:'), findsNothing);

      // 2. 开启详情模式展示未完成任务详情
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineTaskTile(
              task: undoneTask,
              isEditing: false,
              showDetails: true,
              onTapEdit: () {},
              onSubmitted: (_) {},
              onCancel: () {},
              onToggleDone: (_) {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('ID: task-undone-1 (序号: 2)'), findsOneWidget);
      expect(find.textContaining('完成时间: 未完成'), findsOneWidget);
      expect(find.textContaining('更新时间: 2026-03-31 15:30:00'), findsOneWidget);

      // 3. 开启详情模式展示已完成任务详情
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineTaskTile(
              task: doneTask,
              isEditing: false,
              showDetails: true,
              onTapEdit: () {},
              onSubmitted: (_) {},
              onCancel: () {},
              onToggleDone: (_) {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('ID: task-done-2 (序号: 3)'), findsOneWidget);
      expect(find.textContaining('完成时间: 2026-03-31 15:35:00'), findsOneWidget);
    });
  });
}
