import 'package:argos_app/core/errors/app_failure.dart';
import 'package:argos_app/features/auth/models/account.dart';
import 'package:argos_app/features/auth/models/login_outcome.dart';
import 'package:argos_app/features/auth/models/session.dart';
import 'package:fpdart/fpdart.dart';

/// Dueño de la sesión: tokens (acceso en memoria, refresh en almacenamiento
/// seguro), caché local de la sesión y operaciones de cuenta.
abstract interface class AuthRepository {
  /// Token de acceso vigente (solo en memoria).
  String? get accessToken;

  /// Renueva el token de acceso (una sola renovación concurrente). Lo usa
  /// el interceptor HTTP a través de `SessionTokens`.
  Future<String?> renewAccessToken();

  /// Emite cuando la sesión termina en segundo plano (el refresh fue
  /// rechazado al renovar el token de una petición).
  Stream<void> get sessionEnded;

  /// Hay un refresh token guardado.
  Future<bool> hasStoredSession();

  Future<CachedSession?> cachedSession();

  /// Renueva el token y recarga la sesión desde el backend. Devuelve
  /// [NetworkFailure] sin red y [AuthFailure] si la sesión ya no es válida
  /// (en cuyo caso borra la sesión local).
  Future<Either<AppFailure, Session>> restoreSession();

  Future<Either<AppFailure, LoginOutcome>> login({
    required String email,
    required String password,
    String? totpCode,
  });

  /// Completa el login eligiendo empresa con el token de selección (A4).
  Future<Either<AppFailure, Session>> completeTenantSelection({
    required String selectionToken,
    required String tenantId,
  });

  /// Cambia de empresa sin cerrar sesión.
  Future<Either<AppFailure, Session>> switchTenant(String tenantId);

  /// Revoca el refresh en el backend (si hay red) y borra la sesión local.
  /// Nunca falla.
  Future<void> logout();

  Future<TenantPreference> tenantPreference();

  Future<void> saveTenantPreference({required String lastTenantId, bool? remember});

  Future<Either<AppFailure, void>> requestPasswordReset(String email);

  Future<Either<AppFailure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Either<AppFailure, List<DeviceSession>>> activeSessions();

  Future<Either<AppFailure, void>> revokeSession(String id);

  Future<Either<AppFailure, void>> revokeOtherSessions();

  Future<Either<AppFailure, InvitationInfo>> invitation(String token);

  Future<Either<AppFailure, LoginOutcome>> acceptInvitation({
    required String token,
    required String password,
    String? fullName,
  });
}
