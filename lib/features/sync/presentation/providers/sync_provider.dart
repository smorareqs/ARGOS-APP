import 'package:argos_app/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:argos_app/features/sync/models/sync_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_provider.g.dart';

@riverpod
class Sync extends _$Sync {
  @override
  SyncState build() => const SyncState.idle();

  Future<void> startSync(SyncMode mode) async {
    state = SyncState(status: SyncStatus.inProgress, mode: mode);

    await for (final step in ref.read(syncRepositoryProvider).sync(mode: mode)) {
      state = step;
    }
  }

  void reset() {
    state = const SyncState.idle();
  }
}
