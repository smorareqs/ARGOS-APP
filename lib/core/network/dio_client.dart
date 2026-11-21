import 'package:argos_app/core/config/app_config.dart';
import 'package:argos_app/core/network/access_token_source.dart';
import 'package:argos_app/core/network/interceptors/auth_interceptor.dart';
import 'package:argos_app/core/network/mock/mock_routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_client.g.dart';

Dio _createDio(Ref ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  if (config.useMock) {
    dio.httpClientAdapter = ref.watch(mockBackendProvider);
  }
  return dio;
}

/// Cliente sin token: login, refresh, recuperar contraseña e invitaciones.
@Riverpod(keepAlive: true)
Dio publicDio(Ref ref) => _createDio(ref);

/// Cliente autenticado: agrega el token de acceso y lo renueva ante un 401.
@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
  final dio = _createDio(ref);
  dio.interceptors.add(
    AuthInterceptor(
      tokens: ref.watch(sessionTokensProvider),
      retryClient: dio,
    ),
  );
  return dio;
}
