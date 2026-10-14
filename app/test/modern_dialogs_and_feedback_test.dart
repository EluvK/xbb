import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xbb/presentation/widgets/modern_dialogs.dart';

void main() {
  group('ModernDialogs & AppFeedback 自适应弹窗与交互设计测试', () {
    testWidgets('showAdaptiveConfirmDialog 能够渲染并正确返回确认/取消结果', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showAdaptiveConfirmDialog(
                    context,
                    title: '测试确认',
                    message: '确认执行该操作吗？',
                    confirmText: '确定',
                    cancelText: '取消',
                    isDanger: true,
                  );
                },
                child: const Text('打开确认弹窗'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开确认弹窗'));
      await tester.pumpAndSettle();

      expect(find.text('测试确认'), findsOneWidget);
      expect(find.text('确认执行该操作吗？'), findsOneWidget);
      expect(find.text('确定'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);

      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('测试确认'), findsNothing);

      await tester.tap(find.text('打开确认弹窗'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.text('测试确认'), findsNothing);
    });

    testWidgets('showAdaptiveTextInputDialog 能够获取输入文本并返回', (tester) async {
      String? enteredText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  enteredText = await showAdaptiveTextInputDialog(
                    context,
                    title: '新建项目',
                    labelText: '名称',
                    hintText: '请输入项目名称',
                    confirmText: '创建',
                    cancelText: '取消',
                  );
                },
                child: const Text('打开输入弹窗'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开输入弹窗'));
      await tester.pumpAndSettle();

      expect(find.text('新建项目'), findsOneWidget);
      expect(find.text('名称'), findsOneWidget);
      expect(find.text('创建'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '我的新项目');
      await tester.pump();

      await tester.tap(find.text('创建'));
      await tester.pumpAndSettle();

      expect(enteredText, equals('我的新项目'));
      expect(find.text('新建项目'), findsNothing);
    });

    testWidgets('showAdaptiveModal 能够作为自适应容器正确承载内容与操作项', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showAdaptiveModal(
                    context,
                    builder: (ctx) => AdaptiveModalContainer(
                      title: '模态标题',
                      subtitle: '副标题说明文案',
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('关闭'),
                        ),
                      ],
                      child: const Text('自适应主体内容区域'),
                    ),
                  );
                },
                child: const Text('打开自适应模态'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('打开自适应模态'));
      await tester.pumpAndSettle();

      expect(find.text('模态标题'), findsOneWidget);
      expect(find.text('副标题说明文案'), findsOneWidget);
      expect(find.text('自适应主体内容区域'), findsOneWidget);
      expect(find.text('关闭'), findsOneWidget);

      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();

      expect(find.text('模态标题'), findsNothing);
    });

    testWidgets('AppFeedback showSuccess, showError, showInfo 能够展示浮动反馈', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => AppFeedback.showSuccess(context, '操作成功完成'),
                    child: const Text('成功提示'),
                  ),
                  ElevatedButton(
                    onPressed: () => AppFeedback.showError(context, '操作失败'),
                    child: const Text('失败提示'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('成功提示'));
      await tester.pump();

      expect(find.text('操作成功完成'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      await tester.tap(find.text('失败提示'));
      await tester.pump();

      expect(find.text('操作失败'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });
}
