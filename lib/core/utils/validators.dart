/// Validaciones de formulario con mensajes que dicen la causa y la salida
/// (ux-ui.md §3.3).
abstract final class Validators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Escribe tu correo.';
    if (!_emailPattern.hasMatch(text)) {
      return 'Revisa el correo: debe tener el formato nombre@empresa.com.';
    }
    return null;
  }

  static String? required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  /// Contraseña nueva: mínimo 8 caracteres (igual que el backend).
  static String? newPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Escribe una contraseña.';
    if (text.length < 8) return 'Usa al menos 8 caracteres.';
    if (text.length > 128) return 'Usa como máximo 128 caracteres.';
    return null;
  }

  /// Fortaleza de 0 a 4 para el medidor de A8.
  static int passwordStrength(String value) {
    if (value.length < 8) return value.isEmpty ? 0 : 1;
    var score = 1;
    if (value.length >= 12) score++;
    if (RegExp('[A-Z]').hasMatch(value) && RegExp('[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value) && RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      score++;
    }
    return score.clamp(0, 4);
  }
}
