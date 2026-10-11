import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xbb/sync/v2/sync_worker.dart';

enum SyncRunningState { idle, syncing, error }

class SyncStatus {
  final SyncRunningState state;
  final String? lastError;
  final DateTime? lastSyncTime;

  const SyncStatus({
    this.state = SyncRunningState.idle,
    this.lastError,
    this.lastSyncTime,
  });
}

class SyncNotifier extends StateNotifier<SyncStatus> {
  SyncNotifier() : super(const SyncStatus()) {
    SyncWorker.instance.onPushCompleted = (_) {
      state = SyncStatus(
        state: SyncRunningState.idle,
        lastSyncTime: DateTime.now(),
      );
    };
    SyncWorker.instance.onError = (e) {
      state = SyncStatus(
        state: SyncRunningState.error,
        lastError: e.toString(),
        lastSyncTime: state.lastSyncTime,
      );
    };
  }

  Future<void> triggerSync() async {
    state = SyncStatus(
      state: SyncRunningState.syncing,
      lastError: null,
      lastSyncTime: state.lastSyncTime,
    );
    try {
      await SyncWorker.instance.triggerSync();
      state = SyncStatus(
        state: SyncRunningState.idle,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = SyncStatus(
        state: SyncRunningState.error,
        lastError: e.toString(),
        lastSyncTime: state.lastSyncTime,
      );
    }
  }
}

final syncStatusProvider = StateNotifierProvider<SyncNotifier, SyncStatus>((ref) {
  return SyncNotifier();
});
