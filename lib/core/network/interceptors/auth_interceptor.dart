import 'package:argos_app/core/network/access_token_source.dart';
import 'package:dio/dio.dart';

/// Agrega `Authorization: Bearer` y, ante un 401, renueva el token una sola
/// vez y reintenta la petición. Si la renovación falla, deja pasar el 401
/// (el repositorio de auth ya avisó que la sesión terminó).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required AccessTokenSource tokens,
    required Dio retryClient,
  }) : _tokens = tokens,
       _retryClient = retryClient;

  final AccessTokenSource _tokens;
  final Dio _retryClient;

  static const _retriedKey = 'argos_auth_retried';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokens.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || options.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    final source = _tokens;
    final current = source.accessToken;
    // Si otra petición ya renovó el token mientras esta volaba, basta con
    // reintentar con el nuevo.
    final token = current != null && options.headers['Authorization'] != 'Bearer $current'
        ? current
        : await source.renewAccessToken();
    if (token == null) return handler.next(err);

    options.headers['Authorization'] = 'Bearer $token';
    options.extra[_retriedKey] = true;
    try {
      handler.resolve(await _retryClient.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
