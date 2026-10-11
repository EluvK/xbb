import 'package:flutter_test/flutter_test.dart';
import 'package:xbb/controller/clipboard_tray.dart';
import 'package:xbb/core/desktop/desktop_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DesktopManager (window_manager + tray_manager 集成测试)', () {
    test('在测试环境中安全初始化并降级，不抛出原生通道未实现异常', () async {
      final manager = DesktopManager.instance;
      expect(manager.isTestEnvironment, isTrue);

      await manager.init(minimizeToTrayOnClose: true);
      expect(manager, isNotNull);

      // 菜单刷新测试
      await manager.updateTrayMenu();

      // 窗口显示与隐藏测试
      await manager.showMainWindow();

      // 托盘监听状态联动
      await ClipboardTrayService.instance.setListeningEnabled(true);
      expect(ClipboardTrayService.instance.isListeningActive, isTrue);

      await ClipboardTrayService.instance.setListeningEnabled(false);
      expect(ClipboardTrayService.instance.isListeningActive, isFalse);

      await manager.dispose();
    });
  });
}
