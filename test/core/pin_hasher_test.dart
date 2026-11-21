import 'dart:convert';

import 'package:argos_app/core/security/pin_hasher.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

String _hex(List<int> bytes) => Digest(bytes).toString();

void main() {
  group('PBKDF2-HMAC-SHA256 (vectores de referencia)', () {
    final password = utf8.encode('password');
    final salt = utf8.encode('salt');

    test('1 iteración', () {
      expect(
        _hex(PinHasher.pbkdf2(password, salt, 1)),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
    });

    test('2 iteraciones', () {
      expect(
        _hex(PinHasher.pbkdf2(password, salt, 2)),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
    });

    test('4096 iteraciones', () {
      expect(
        _hex(PinHasher.pbkdf2(password, salt, 4096)),
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      );
    });
  });

  group('PinHasher', () {
    const hasher = PinHasher(iterations: 1000);

    test('verifica el PIN correcto y rechaza otro', () {
      final encoded = hasher.hash('482915');
      expect(encoded, startsWith(r'pbkdf2-sha256$1000$'));
      expect(encoded, isNot(contains('482915')));
      expect(hasher.verify('482915', encoded), isTrue);
      expect(hasher.verify('482916', encoded), isFalse);
    });

    test('usa una sal distinta en cada hash', () {
      expect(hasher.hash('482915'), isNot(hasher.hash('482915')));
    });

    test('rechaza formatos inválidos sin lanzar', () {
      for (final encoded in ['', 'md5', r'pbkdf2-sha256$x$a$b', r'otro$1$AA==$AA==', r'pbkdf2-sha256$1$%%%$AA==']) {
        expect(hasher.verify('482915', encoded), isFalse, reason: encoded);
      }
    });
  });
}
