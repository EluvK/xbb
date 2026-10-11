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
    SyncWorker.instance.onStateChanged = (workerState, {error}) {
      state = SyncStatus(
        state: workerState == SyncWorkerState.syncing
            ? SyncRunningState.syncing
            : workerState == SyncWorkerState.error
                ? SyncRunningState.error
                : SyncRunningState.idle,
        lastError: error?.toString(),
        lastSyncTime: workerState == SyncWorkerState.idle ? DateTime.now() : state.lastSyncTime,
      );
    };

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
    await SyncWorker.instance.triggerSync();
  }
}

final syncStatusProvider = StateNotifierProvider<SyncNotifier, SyncStatus>((ref) {
  return SyncNotifier();
});
