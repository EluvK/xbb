import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xbb/core/desktop/desktop_title_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DesktopTitleBar (无边框桌面顶栏与 Overlay 防护测试)', () {
    testWidgets('在 MaterialApp.builder 中配合 Overlay.wrap 正常渲染，不抛出 No Overlay 异常且不发生溢出', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) {
            return Overlay.wrap(
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const DesktopTitleBar(),
                    Expanded(child: child ?? const SizedBox.shrink()),
                  ],
                ),
              ),
            );
          },
          home: const Scaffold(
            body: Center(child: Text('Main Content')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证标题正常显示
      expect(find.text('XBB Workspace'), findsOneWidget);
      expect(find.text('Main Content'), findsOneWidget);

      // 验证窗口最小化、最大化与关闭按钮均已正常构建
      expect(find.byIcon(Icons.minimize), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // 验证 Tooltip 在 Overlay 存在时正常挂载
      expect(find.byTooltip('最小化'), findsOneWidget);
      expect(find.byTooltip('最大化'), findsOneWidget);
      expect(find.byTooltip('关闭到托盘'), findsOneWidget);
    });

    testWidgets('当 Overlay 缺失时具备防崩溃回退机制，降级渲染按钮且不抛出断言错误', (tester) async {
      // 故意构建一个完全没有 Overlay 的树
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Theme(
            data: ThemeData.dark(),
            child: const DesktopTitleBar(),
          ),
        ),
      );

      // 无异常且窗口控制按钮依然可见
      expect(find.byIcon(Icons.minimize), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('支持自定义 leading、title 与 actions 控件扩展', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DesktopTitleBar(
              leading: Icon(Icons.star, key: Key('leading-star')),
              title: Text('Custom Workspace Title'),
              actions: [
                Icon(Icons.settings, key: Key('action-settings')),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('leading-star')), findsOneWidget);
      expect(find.text('Custom Workspace Title'), findsOneWidget);
      expect(find.byKey(const Key('action-settings')), findsOneWidget);
    });
  });
}
