import 'package:argos_app/core/errors/app_failure.dart';
import 'package:argos_app/core/storage/secure_storage_service.dart';
import 'package:argos_app/features/sync/domain/repositories/sync_repository.dart';
import 'package:argos_app/features/sync/models/sync_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_repository_impl.g.dart';

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(this._secureStorage);

  final SecureStorageService _secureStorage;

  static const _fullSyncSteps = [
    'Inicializando conexión',
    'Descargando catálogos',
    'Descargando configuración',
    'Validando datos',
    'Finalizando',
  ];

  static const _incrementalSyncSteps = [
    'Consultando cambios',
    'Aplicando actualizaciones',
    'Confirmando',
  ];

  SyncStep _step(String name, int current, int total) {
    return SyncStep(name: name, current: current, total: total);
  }

  @override
  Stream<SyncState> sync({required SyncMode mode}) async* {
    final steps = mode == SyncMode.full ? _fullSyncSteps : _incrementalSyncSteps;
    final total = steps.length;

    yield SyncState(
      status: SyncStatus.inProgress,
      mode: mode,
      currentStep: _step(steps.first, 0, total),
    );

    for (var i = 0; i < steps.length; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      yield SyncState(
        status: SyncStatus.inProgress,
        mode: mode,
        currentStep: _step(steps[i], i + 1, total),
      );
    }

    await _secureStorage.writeLastSyncDate(DateTime.now().toIso8601String());

    yield SyncState(
      status: SyncStatus.completed,
      mode: mode,
      currentStep: _step(steps.last, total, total),
    );
  }

  @override
  Future<Either<AppFailure, DateTime?>> getLastSyncDate() async {
    try {
      final raw = await _secureStorage.readLastSyncDate();
      if (raw == null) return right(null);
      return right(DateTime.tryParse(raw));
    } catch (_) {
      return left(const CacheFailure());
    }
  }
}

@Riverpod(keepAlive: true)
SyncRepository syncRepository(Ref ref) {
  return SyncRepositoryImpl(ref.watch(secureStorageServiceProvider));
}
