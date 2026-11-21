import 'package:argos_app/core/security/pin_hasher.dart';
import 'package:argos_app/core/storage/secure_storage_service.dart';
import 'package:argos_app/features/auth/data/datasources/biometric_datasource.dart';
import 'package:argos_app/features/auth/domain/repositories/quick_unlock_repository.dart';
import 'package:argos_app/features/auth/models/quick_unlock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'quick_unlock_repository_impl.g.dart';

class QuickUnlockRepositoryImpl implements QuickUnlockRepository {
  QuickUnlockRepositoryImpl({
    required SecureStorageService storage,
    required BiometricDataSource biometrics,
    PinHasher hasher = const PinHasher(),
  }) : _storage = storage,
       _biometrics = biometrics,
       _hasher = hasher;

  final SecureStorageService _storage;
  final BiometricDataSource _biometrics;
  final PinHasher _hasher;

  static const _enableReason = 'Confirma tu identidad para activar el inicio rápido';
  static const _unlockReason = 'Desbloquea ARGOS';

  @override
  Future<QuickUnlockSettings> settings() async {
    try {
      final available = await _biometrics.isAvailable();
      return QuickUnlockSettings(
        biometricAvailable: available,
        // Si la biometría se quitó del teléfono deja de contar como activa.
        biometricEnabled: available && await _storage.readBiometricEnabled(),
        pinEnabled: await _storage.readPinHash() != null,
        declined: await _storage.readQuickUnlockDeclined(),
      );
    } catch (_) {
      return const QuickUnlockSettings();
    }
  }

  @override
  Future<bool> enableBiometric() async {
    if (!await _biometrics.authenticate(_enableReason)) return false;
    return _try(() => _storage.writeBiometricEnabled(true));
  }

  @override
  Future<void> disableBiometric() =>
      _try(() => _storage.writeBiometricEnabled(false));

  @override
  Future<void> setPin(String pin) => _try(() async {
    await _storage.writePinHash(_hasher.hash(pin));
    await _storage.writePinFailures(0);
  });

  @override
  Future<void> removePin() => _try(() async {
    await _storage.deletePinHash();
    await _storage.writePinFailures(0);
  });

  @override
  Future<PinCheck> verifyPin(String pin) async {
    try {
      final hash = await _storage.readPinHash();
      if (hash == null) return const PinLockedOut();
      if (_hasher.verify(pin, hash)) {
        await _storage.writePinFailures(0);
        return const PinAccepted();
      }
      final failures = await _storage.readPinFailures() + 1;
      if (failures >= QuickUnlockRepository.maxPinAttempts) {
        await reset();
        return const PinLockedOut();
      }
      await _storage.writePinFailures(failures);
      return PinRejected(QuickUnlockRepository.maxPinAttempts - failures);
    } catch (_) {
      return const PinLockedOut();
    }
  }

  @override
  Future<bool> unlockWithBiometric() async {
    if (!(await settings()).biometricEnabled) return false;
    return _biometrics.authenticate(_unlockReason);
  }

  @override
  Future<void> markDeclined() =>
      _try(() => _storage.writeQuickUnlockDeclined(true));

  @override
  Future<void> reset() => _try(() async {
    await _storage.deletePinHash();
    await _storage.writePinFailures(0);
    await _storage.writeBiometricEnabled(false);
    await _storage.writeQuickUnlockDeclined(false);
  });

  Future<bool> _try(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      return false;
    }
  }
}

@Riverpod(keepAlive: true)
QuickUnlockRepository quickUnlockRepository(Ref ref) {
  return QuickUnlockRepositoryImpl(
    storage: ref.watch(secureStorageServiceProvider),
    biometrics: ref.watch(biometricDataSourceProvider),
  );
}
