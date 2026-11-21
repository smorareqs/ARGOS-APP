/// Configuración del inicio rápido en este dispositivo (A5).
class QuickUnlockSettings {
  const QuickUnlockSettings({
    this.biometricAvailable = false,
    this.biometricEnabled = false,
    this.pinEnabled = false,
    this.declined = false,
  });

  /// El dispositivo tiene biometría inscrita.
  final bool biometricAvailable;
  final bool biometricEnabled;
  final bool pinEnabled;

  /// El usuario eligió "Ahora no" tras iniciar sesión.
  final bool declined;

  bool get enabled => biometricEnabled || pinEnabled;
}

/// Resultado de verificar el PIN (A6).
sealed class PinCheck {
  const PinCheck();
}

final class PinAccepted extends PinCheck {
  const PinAccepted();
}

final class PinRejected extends PinCheck {
  const PinRejected(this.remainingAttempts);

  final int remainingAttempts;
}

/// Se agotaron los intentos: la sesión exige contraseña.
final class PinLockedOut extends PinCheck {
  const PinLockedOut();
}
