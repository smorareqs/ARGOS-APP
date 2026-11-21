import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_datasource.g.dart';

/// Biometría del sistema (huella o rostro) vía `local_auth`.
class BiometricDataSource {
  BiometricDataSource(this._auth);

  final LocalAuthentication _auth;

  /// El dispositivo admite biometría y tiene al menos una inscrita.
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Muestra el diálogo del sistema. Solo biometría: el PIN propio de ARGOS es
  /// la alternativa, no el código del teléfono.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      // Cancelado, bloqueado por intentos o sin hardware: no desbloquea.
      return false;
    }
  }
}

@Riverpod(keepAlive: true)
BiometricDataSource biometricDataSource(Ref ref) {
  return BiometricDataSource(LocalAuthentication());
}
