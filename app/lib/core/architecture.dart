/// 核心现代架构分层标识与导出
///
/// 遵循 Clean Local-First Architecture：
/// - Domain: 业务模型与领域逻辑（纯 Dart）
/// - Data: 响应式 Repository 与本地存储（SQLite + Outbox）
/// - Presentation: 状态管理（Riverpod）与现代化 UI（Material 3）
library architecture;

export 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:go_router/go_router.dart';
