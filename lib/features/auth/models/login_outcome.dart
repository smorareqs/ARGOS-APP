import 'package:argos_app/features/auth/models/session.dart';

/// Resultado de un inicio de sesión con contraseña (o al aceptar invitación).
sealed class LoginOutcome {
  const LoginOutcome();
}

/// Sesión abierta en la única empresa del usuario.
final class LoginAuthenticated extends LoginOutcome {
  const LoginAuthenticated(this.session);

  final Session session;
}

/// El backend respondió 428: hay que repetir el login con el código TOTP.
final class LoginNeedsTotp extends LoginOutcome {
  const LoginNeedsTotp();
}

/// El usuario tiene varias empresas: debe elegir una (A4).
final class LoginNeedsTenant extends LoginOutcome {
  const LoginNeedsTenant({
    required this.selectionToken,
    required this.memberships,
  });

  final String selectionToken;
  final List<Membership> memberships;
}
