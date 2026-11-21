import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'access_token_source.g.dart';

/// Fuente del token de acceso que usa [AuthInterceptor].
abstract interface class AccessTokenSource {
  /// Token de acceso vigente (solo en memoria), o null si no hay sesión.
  String? get accessToken;

  /// Renueva el token con el refresh guardado. Si varias peticiones lo piden
  /// a la vez se hace una sola renovación. Devuelve null si la sesión ya no
  /// es válida o no hay conexión.
  Future<String?> renewAccessToken();
}

/// Token de acceso en memoria, compartido entre el repositorio de
/// autenticación (lo escribe y registra cómo renovarlo) y el interceptor
/// HTTP (lo lee). Vive en core para que el cliente HTTP no dependa de la
/// feature de auth.
class SessionTokens implements AccessTokenSource {
  @override
  String? accessToken;

  /// Lo registra el repositorio de autenticación, dueño del refresh token.
  Future<String?> Function()? renewer;

  @override
  Future<String?> renewAccessToken() async => renewer == null ? null : renewer!();
}

@Riverpod(keepAlive: true)
SessionTokens sessionTokens(Ref ref) => SessionTokens();
