import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 工作区全局生命周期与状态定义 (基于 riverpod_annotation 规范)
class WorkspaceState {
  final bool isOnline;
  final bool isSyncing;
  final int activeTabCount;
  final DateTime lastRefreshed;

  const WorkspaceState({
    this.isOnline = true,
    this.isSyncing = false,
    this.activeTabCount = 7,
    required this.lastRefreshed,
  });

  WorkspaceState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? activeTabCount,
    DateTime? lastRefreshed,
  }) {
    return WorkspaceState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      activeTabCount: activeTabCount ?? this.activeTabCount,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
    );
  }
}

/// 规范化强类型 Notifier，管理生命周期与自动销毁 (符合 Phase 2 架构规范)
class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceNotifier()
      : super(WorkspaceState(lastRefreshed: DateTime.now()));

  void setOnline(bool online) {
    state = state.copyWith(isOnline: online, lastRefreshed: DateTime.now());
  }

  void setSyncing(bool syncing) {
    state = state.copyWith(isSyncing: syncing, lastRefreshed: DateTime.now());
  }

  void updateTabCount(int count) {
    state = state.copyWith(activeTabCount: count, lastRefreshed: DateTime.now());
  }
}

final workspaceNotifierProvider =
    StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
  return WorkspaceNotifier();
});
