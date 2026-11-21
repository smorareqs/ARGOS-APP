import 'dart:async';

import 'package:argos_app/core/device/device_identity.dart';
import 'package:argos_app/core/errors/app_failure.dart';
import 'package:argos_app/core/errors/failure_mapper.dart';
import 'package:argos_app/core/network/access_token_source.dart';
import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/core/storage/secure_storage_service.dart';
import 'package:argos_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:argos_app/features/auth/data/datasources/session_local_datasource.dart';
import 'package:argos_app/features/auth/data/models/auth_dtos.dart';
import 'package:argos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:argos_app/features/auth/models/account.dart';
import 'package:argos_app/features/auth/models/login_outcome.dart';
import 'package:argos_app/features/auth/models/session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository_impl.g.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required SessionLocalDataSource local,
    required SecureStorageService storage,
    required DeviceIdentityService device,
    required SessionTokens tokens,
  }) : _remote = remote,
       _local = local,
       _storage = storage,
       _device = device,
       _tokens = tokens {
    _tokens.renewer = renewAccessToken;
  }

  final AuthRemoteDataSource _remote;
  final SessionLocalDataSource _local;
  final SecureStorageService _storage;
  final DeviceIdentityService _device;

  /// El token de acceso vive solo en memoria (15 min).
  final SessionTokens _tokens;
  Future<Either<AppFailure, String>>? _renewal;
  final _sessionEnded = StreamController<void>.broadcast();

  @override
  String? get accessToken => _tokens.accessToken;

  @override
  Stream<void> get sessionEnded => _sessionEnded.stream;

  @override
  Future<String?> renewAccessToken() async {
    final result = await _renew();
    return result.fold((failure) {
      if (failure is AuthFailure) _sessionEnded.add(null);
      return null;
    }, (token) => token);
  }

  /// Una sola renovación a la vez: las peticiones concurrentes esperan la
  /// misma (el refresh rota y solo se puede usar una vez).
  Future<Either<AppFailure, String>> _renew() {
    return _renewal ??= _doRenew().whenComplete(() => _renewal = null);
  }

  Future<Either<AppFailure, String>> _doRenew() async {
    try {
      final refreshToken = await _storage.readRefreshToken();
      if (refreshToken == null) {
        return left(const AuthFailure('No hay una sesión guardada.'));
      }
      final device = await _device.current();
      final pair = await _remote.refresh(
        refreshToken: refreshToken,
        deviceId: device.id,
      );
      await _storeTokens(pair);
      return right(pair.accessToken);
    } catch (error) {
      return left(await _failureClearingOnAuth(error));
    }
  }

  @override
  Future<bool> hasStoredSession() async {
    try {
      final token = await _storage.readRefreshToken();
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<CachedSession?> cachedSession() async {
    try {
      return await _local.read();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Either<AppFailure, Session>> restoreSession() async {
    final renewed = await _renew();
    if (renewed case Left(:final value)) return left(value);
    return _loadSession();
  }

  @override
  Future<Either<AppFailure, LoginOutcome>> login({
    required String email,
    required String password,
    String? totpCode,
  }) async {
    try {
      final response = await _remote.login(
        email: email.trim(),
        password: password,
        totpCode: totpCode,
        device: await _device.current(),
      );
      return _outcomeFrom(response);
    } on ApiException catch (e) {
      if (e.statusCode == 428) return right(const LoginNeedsTotp());
      return left(mapExceptionToFailure(e));
    } catch (error) {
      return left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<AppFailure, Session>> completeTenantSelection({
    required String selectionToken,
    required String tenantId,
  }) async {
    try {
      final response = await _remote.selectTenant(
        tenantId: tenantId,
        selectionToken: selectionToken,
        device: await _device.current(),
      );
      return _sessionFromTokens(response);
    } catch (error) {
      return left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<AppFailure, Session>> switchTenant(String tenantId) async {
    try {
      final refreshToken = await _storage.readRefreshToken();
      if (refreshToken == null) {
        return left(const AuthFailure('No hay una sesión guardada.'));
      }
      final response = await _remote.selectTenant(
        tenantId: tenantId,
        refreshToken: refreshToken,
      );
      return _sessionFromTokens(response);
    } catch (error) {
      return left(await _failureClearingOnAuth(error));
    }
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.readRefreshToken();
      if (refreshToken != null) await _remote.logout(refreshToken);
    } catch (_) {
      // Sin red o ya revocado: la sesión local se borra igual.
    }
    await _clearLocal();
  }

  @override
  Future<TenantPreference> tenantPreference() async {
    try {
      return TenantPreference(
        lastTenantId: await _storage.readLastTenantId(),
        remember: await _storage.readRememberTenant(),
      );
    } catch (_) {
      return const TenantPreference();
    }
  }

  @override
  Future<void> saveTenantPreference({
    required String lastTenantId,
    bool? remember,
  }) async {
    try {
      await _storage.writeLastTenantId(lastTenantId);
      if (remember != null) await _storage.writeRememberTenant(remember);
    } catch (_) {
      // Es solo una preferencia.
    }
  }

  @override
  Future<Either<AppFailure, void>> requestPasswordReset(String email) =>
      _guard(() => _remote.forgotPassword(email.trim()));

  @override
  Future<Either<AppFailure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _guard(
    () => _remote.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    ),
  );

  @override
  Future<Either<AppFailure, List<DeviceSession>>> activeSessions() =>
      _guard(_remote.sessions);

  @override
  Future<Either<AppFailure, void>> revokeSession(String id) =>
      _guard(() => _remote.revokeSession(id));

  @override
  Future<Either<AppFailure, void>> revokeOtherSessions() =>
      _guard(_remote.revokeOtherSessions);

  @override
  Future<Either<AppFailure, InvitationInfo>> invitation(String token) =>
      _guard(() => _remote.invitation(token));

  @override
  Future<Either<AppFailure, LoginOutcome>> acceptInvitation({
    required String token,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _remote.acceptInvitation(
        token: token,
        password: password,
        fullName: fullName,
        device: await _device.current(),
      );
      return _outcomeFrom(response);
    } on ApiException catch (e) {
      if (e.statusCode == 428) return right(const LoginNeedsTotp());
      return left(mapExceptionToFailure(e));
    } catch (error) {
      return left(mapExceptionToFailure(error));
    }
  }

  // ── Internos ───────────────────────────────────────────

  Future<Either<AppFailure, LoginOutcome>> _outcomeFrom(
    LoginResponse response,
  ) async {
    final selectionToken = response.selectionToken;
    if (selectionToken != null) {
      return right(
        LoginNeedsTenant(
          selectionToken: selectionToken,
          memberships: response.memberships,
        ),
      );
    }
    final session = await _sessionFromTokens(response);
    return session.map(LoginAuthenticated.new);
  }

  Future<Either<AppFailure, Session>> _sessionFromTokens(
    LoginResponse response,
  ) async {
    final tokens = response.tokens;
    if (tokens == null) {
      return left(const ServerFailure('El servidor no devolvió la sesión.'));
    }
    await _storeTokens(tokens);
    return _loadSession();
  }

  /// `GET /auth/me` y actualiza la caché local.
  Future<Either<AppFailure, Session>> _loadSession() async {
    try {
      final session = await _remote.me();
      await _local.save(session);
      return right(session);
    } catch (error) {
      return left(await _failureClearingOnAuth(error));
    }
  }

  Future<void> _storeTokens(TokenPair pair) async {
    _tokens.accessToken = pair.accessToken;
    await _storage.writeRefreshToken(pair.refreshToken);
  }

  /// Un 401 o 403 con la sesión ya abierta significa que dejó de ser válida
  /// (revocada, vencida, membresía suspendida): se borra la sesión local y se
  /// devuelve [AuthFailure]. Cualquier otro error (incluido un 429) es
  /// transitorio y nunca se reporta como [AuthFailure], para que la app no
  /// cierre la sesión por él.
  Future<AppFailure> _failureClearingOnAuth(Object error) async {
    final failure = mapExceptionToFailure(error);
    if (error is ApiException &&
        (error.statusCode == 401 || error.statusCode == 403)) {
      await _clearLocal();
      return failure;
    }
    return failure is AuthFailure ? ServerFailure(failure.message) : failure;
  }

  Future<void> _clearLocal() async {
    _tokens.accessToken = null;
    try {
      await _storage.clearSession();
      await _local.clear();
    } catch (_) {
      // Lo que no se pudo borrar se sobrescribe en el próximo login.
    }
  }

  Future<Either<AppFailure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } catch (error) {
      return left(mapExceptionToFailure(error));
    }
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(sessionLocalDataSourceProvider),
    storage: ref.watch(secureStorageServiceProvider),
    device: ref.watch(deviceIdentityServiceProvider),
    tokens: ref.watch(sessionTokensProvider),
  );
}
