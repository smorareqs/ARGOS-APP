import 'package:argos_app/core/errors/app_failure.dart';
import 'package:argos_app/features/sync/models/sync_state.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class SyncRepository {
  Stream<SyncState> sync({required SyncMode mode});

  Future<Either<AppFailure, DateTime?>> getLastSyncDate();
}
