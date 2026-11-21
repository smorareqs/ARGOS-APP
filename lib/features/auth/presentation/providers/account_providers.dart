import 'package:argos_app/core/errors/app_failure.dart';
import 'package:argos_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:argos_app/features/auth/data/repositories/quick_unlock_repository_impl.dart';
import 'package:argos_app/features/auth/models/account.dart';
import 'package:argos_app/features/auth/models/quick_unlock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_providers.g.dart';

/// Convierte el `Either` del repositorio en el valor o en un error del
/// [AsyncValue] (el error es el [AppFailure], con su mensaje para la UI).
T _unwrap<T>(Either<AppFailure, T> result) =>
    result.fold((failure) => throw failure, (value) => value);

AppFailure? _failureOf(Either<AppFailure, void> result) =>
    result.fold((failure) => failure, (_) => null);

/// B18 · Sesiones activas.
@riverpod
class ActiveSessions extends _$ActiveSessions {
  @override
  Future<List<DeviceSession>> build() async =>
      _unwrap(await ref.read(authRepositoryProvider).activeSessions());

  Future<AppFailure?> revoke(String id) async {
    final failure = _failureOf(
      await ref.read(authRepositoryProvider).revokeSession(id),
    );
    if (failure == null) ref.invalidateSelf();
    return failure;
  }

  Future<AppFailure?> revokeOthers() async {
    final failure = _failureOf(
      await ref.read(authRepositoryProvider).revokeOtherSessions(),
    );
    if (failure == null) ref.invalidateSelf();
    return failure;
  }
}

/// A7 y "Cambiar contraseña".
@riverpod
class PasswordActions extends _$PasswordActions {
  @override
  void build() {}

  Future<AppFailure?> requestReset(String email) async =>
      _failureOf(await ref.read(authRepositoryProvider).requestPasswordReset(email));

  Future<AppFailure?> change({
    required String currentPassword,
    required String newPassword,
  }) async => _failureOf(
    await ref
        .read(authRepositoryProvider)
        .changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
  );
}

/// A8 · Datos de la invitación.
@riverpod
Future<InvitationInfo> invitationInfo(Ref ref, String token) async =>
    _unwrap(await ref.read(authRepositoryProvider).invitation(token));

/// A5 · Configuración del inicio rápido y sus acciones.
@riverpod
class QuickUnlockController extends _$QuickUnlockController {
  @override
  Future<QuickUnlockSettings> build() =>
      ref.read(quickUnlockRepositoryProvider).settings();

  /// Devuelve si la biometría quedó activa (el usuario pudo cancelar).
  Future<bool> enableBiometric() async {
    final enabled = await ref.read(quickUnlockRepositoryProvider).enableBiometric();
    ref.invalidateSelf();
    return enabled;
  }

  Future<void> disableBiometric() async {
    await ref.read(quickUnlockRepositoryProvider).disableBiometric();
    ref.invalidateSelf();
  }

  Future<void> setPin(String pin) async {
    await ref.read(quickUnlockRepositoryProvider).setPin(pin);
    ref.invalidateSelf();
  }

  Future<void> removePin() async {
    await ref.read(quickUnlockRepositoryProvider).removePin();
    ref.invalidateSelf();
  }

  Future<void> decline() async {
    await ref.read(quickUnlockRepositoryProvider).markDeclined();
    ref.invalidateSelf();
  }
}
