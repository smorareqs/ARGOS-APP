import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Hash del PIN de inicio rápido con PBKDF2-HMAC-SHA256 y sal aleatoria.
///
/// El PIN es una barrera local: el refresh token ya está protegido por el
/// Keychain / Keystore. Aun así nunca se guarda en claro y, tras 3 intentos
/// fallidos, la app exige la contraseña (ver `QuickUnlockRepository`).
///
/// Formato: `pbkdf2-sha256$<iteraciones>$<sal base64>$<hash base64>`.
class PinHasher {
  const PinHasher({this.iterations = 10000});

  final int iterations;

  static const _scheme = 'pbkdf2-sha256';

  String hash(String pin, {List<int>? salt}) {
    final s = salt ?? _randomBytes(16);
    final derived = pbkdf2(utf8.encode(pin), s, iterations);
    return '$_scheme\$$iterations\$${base64Encode(s)}\$${base64Encode(derived)}';
  }

  bool verify(String pin, String encoded) {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != _scheme) return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds <= 0) return false;
    try {
      final salt = base64Decode(parts[2]);
      final expected = base64Decode(parts[3]);
      return _constantTimeEquals(pbkdf2(utf8.encode(pin), salt, rounds), expected);
    } on FormatException {
      return false;
    }
  }

  /// PBKDF2-HMAC-SHA256 con una clave de 32 bytes (un solo bloque).
  static List<int> pbkdf2(List<int> password, List<int> salt, int rounds) {
    final hmac = Hmac(sha256, password);
    var block = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final result = Uint8List.fromList(block);
    for (var i = 1; i < rounds; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= block[j];
      }
    }
    return result;
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
