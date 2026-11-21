import 'package:argos_app/core/device/device_identity.dart';
import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/core/network/dio_client.dart';
import 'package:argos_app/features/auth/data/models/auth_dtos.dart';
import 'package:argos_app/features/auth/models/account.dart';
import 'package:argos_app/features/auth/models/session.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_remote_datasource.g.dart';

/// Endpoints de autenticación (fase01.md §3.7.1). Solo I/O: las respuestas de
/// error se lanzan como [ApiException]; los fallos de red, como
/// [DioException].
class AuthRemoteDataSource {
  AuthRemoteDataSource({required Dio publicClient, required Dio authClient})
    : _public = publicClient,
      _auth = authClient;

  /// Sin token: login, refresh, recuperar contraseña, invitaciones.
  final Dio _public;

  /// Con token y renovación automática.
  final Dio _auth;

  Future<LoginResponse> login({
    required String email,
    required String password,
    required DeviceIdentity device,
    String? totpCode,
  }) => _send(
    () => _public.post<dynamic>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
        'totp_code': ?totpCode,
        'device': device.toJson(),
      },
    ),
    (data) => LoginResponse.fromJson(_map(data)),
  );

  /// Con [selectionToken] tras el login; con [refreshToken] para cambiar de
  /// empresa sin cerrar sesión.
  Future<LoginResponse> selectTenant({
    required String tenantId,
    String? selectionToken,
    String? refreshToken,
    DeviceIdentity? device,
  }) => _send(
    () => _public.post<dynamic>(
      '/auth/select-tenant',
      data: {
        'tenant_id': tenantId,
        'selection_token': ?selectionToken,
        'refresh_token': ?refreshToken,
        'device': ?device?.toJson(),
      },
    ),
    (data) => LoginResponse.fromJson(_map(data)),
  );

  Future<TokenPair> refresh({
    required String refreshToken,
    required String deviceId,
  }) => _send(
    () => _public.post<dynamic>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken, 'device_id': deviceId},
    ),
    (data) => TokenPair.fromJson(_map(data)),
  );

  Future<void> logout(String refreshToken) => _send(
    () => _public.post<dynamic>(
      '/auth/logout',
      data: {'refresh_token': refreshToken},
    ),
    (_) {},
  );

  Future<Session> me() => _send(
    () => _auth.get<dynamic>('/auth/me'),
    (data) => sessionFromMeJson(_map(data)),
  );

  Future<List<DeviceSession>> sessions() => _send(
    () => _auth.get<dynamic>('/auth/sessions'),
    (data) => [
      for (final item in (data as List).whereType<Map>())
        deviceSessionFromJson(Map<String, dynamic>.from(item)),
    ],
  );

  Future<void> revokeSession(String id) => _send(
    () => _auth.delete<dynamic>('/auth/sessions/${Uri.encodeComponent(id)}'),
    (_) {},
  );

  Future<void> revokeOtherSessions() =>
      _send(() => _auth.delete<dynamic>('/auth/sessions'), (_) {});

  Future<void> forgotPassword(String email) => _send(
    () => _public.post<dynamic>('/auth/password/forgot', data: {'email': email}),
    (_) {},
  );

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _send(
    () => _auth.post<dynamic>(
      '/auth/password/change',
      data: {'current_password': currentPassword, 'new_password': newPassword},
    ),
    (_) {},
  );

  Future<InvitationInfo> invitation(String token) => _send(
    () => _public.get<dynamic>('/auth/invitations/${Uri.encodeComponent(token)}'),
    (data) => invitationFromJson(_map(data)),
  );

  Future<LoginResponse> acceptInvitation({
    required String token,
    required String password,
    required DeviceIdentity device,
    String? fullName,
  }) => _send(
    () => _public.post<dynamic>(
      '/auth/invitations/accept',
      data: {
        'token': token,
        'password': password,
        'full_name': ?fullName,
        'device': device.toJson(),
      },
    ),
    (data) => LoginResponse.fromJson(_map(data)),
  );

  Future<T> _send<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data) parse,
  ) async {
    try {
      final response = await request();
      return parse(response.data);
    } on DioException catch (e) {
      final api = ApiException.fromDio(e);
      if (api != null) throw api;
      rethrow;
    }
  }

  static Map<String, dynamic> _map(dynamic data) =>
      Map<String, dynamic>.from(data as Map);
}

@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  return AuthRemoteDataSource(
    publicClient: ref.watch(publicDioProvider),
    authClient: ref.watch(dioClientProvider),
  );
}
