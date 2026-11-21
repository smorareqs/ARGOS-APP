import 'package:argos_app/features/auth/models/quick_unlock.dart';

/// Inicio rápido local: biometría o PIN que desbloquean el refresh token
/// guardado (A5, A6). Las operaciones no lanzan excepciones: ante un error de
/// almacenamiento el inicio rápido se considera desactivado.
abstract interface class QuickUnlockRepository {
  /// Intentos de PIN antes de exigir la contraseña.
  static const maxPinAttempts = 3;

  Future<QuickUnlockSettings> settings();

  /// Pide la biometría para confirmar y la activa. Devuelve si quedó activa.
  Future<bool> enableBiometric();

  Future<void> disableBiometric();

  Future<void> setPin(String pin);

  Future<void> removePin();

  Future<PinCheck> verifyPin(String pin);

  Future<bool> unlockWithBiometric();

  /// "Ahora no": no volver a ofrecerlo tras cada login.
  Future<void> markDeclined();

  /// Borra PIN, biometría y contador (al cerrar sesión).
  Future<void> reset();
}
