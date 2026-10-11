import 'package:xbb/core/update/app_update_service.dart';

/// 检查更新辅助
Future<void> checkUpdate({bool forceCheck = false}) async {
  await AppUpdateService.check();
}
