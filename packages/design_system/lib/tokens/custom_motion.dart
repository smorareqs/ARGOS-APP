import 'package:flutter/widgets.dart';

/// Tokens de movimiento ARGOS.
/// Entrada ease-out, salida ease-in. Si el sistema pide reducir movimiento,
/// todo pasa a un fundido de 100 ms ([resolve]).
/// Ref: ux-ui.md §2.4.
abstract final class CustomMotion {
  /// Estados de botón.
  static const Duration fast = Duration(milliseconds: 150);

  /// Aparición de tarjetas, cambio de tab, expandir.
  static const Duration base = Duration(milliseconds: 250);

  /// Hojas y modales.
  static const Duration slow = Duration(milliseconds: 400);

  /// Duración con "reducir movimiento" activo.
  static const Duration reduced = Duration(milliseconds: 100);

  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;

  /// Devuelve [duration] o [reduced] según la preferencia del sistema.
  static Duration resolve(BuildContext context, Duration duration) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? reduced
        : duration;
  }
}
