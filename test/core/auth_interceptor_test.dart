import 'dart:typed_data';

import 'package:argos_app/core/network/access_token_source.dart';
import 'package:argos_app/core/network/interceptors/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Backend que acepta solo el token [validToken].
class _TokenCheckingAdapter implements HttpClientAdapter {
  _TokenCheckingAdapter(this.validToken);

  String validToken;
  final seenTokens = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final header = options.headers['Authorization'] as String?;
    seenTokens.add(header);
    final ok = header == 'Bearer $validToken';
    return ResponseBody.fromString(
      ok ? '{"ok":true}' : '{"detail":"Token inválido o expirado."}',
      ok ? 200 : 401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Tokens implements AccessTokenSource {
  _Tokens(this.accessToken, {this.renewTo});

  @override
  String? accessToken;
  String? renewTo;
  int renewals = 0;

  @override
  Future<String?> renewAccessToken() async {
    renewals++;
    accessToken = renewTo;
    return renewTo;
  }
}

Dio _dio(_TokenCheckingAdapter adapter, _Tokens tokens) {
  final dio = Dio(BaseOptions(baseUrl: 'http://argos.test'))
    ..httpClientAdapter = adapter;
  dio.interceptors.add(AuthInterceptor(tokens: tokens, retryClient: dio));
  return dio;
}

void main() {
  test('agrega el token de acceso', () async {
    final adapter = _TokenCheckingAdapter('nuevo');
    final tokens = _Tokens('nuevo');
    final response = await _dio(adapter, tokens).get<dynamic>('/auth/me');
    expect(response.statusCode, 200);
    expect(tokens.renewals, 0);
  });

  test('ante un 401 renueva una vez y reintenta', () async {
    final adapter = _TokenCheckingAdapter('nuevo');
    final tokens = _Tokens('viejo', renewTo: 'nuevo');
    final response = await _dio(adapter, tokens).get<dynamic>('/auth/me');
    expect(response.statusCode, 200);
    expect(tokens.renewals, 1);
    expect(adapter.seenTokens, ['Bearer viejo', 'Bearer nuevo']);
  });

  test('si la renovación falla deja pasar el 401', () async {
    final adapter = _TokenCheckingAdapter('nuevo');
    final tokens = _Tokens('viejo');
    await expectLater(
      _dio(adapter, tokens).get<dynamic>('/auth/me'),
      throwsA(isA<DioException>().having((e) => e.response?.statusCode, 'status', 401)),
    );
    expect(tokens.renewals, 1);
  });

  test('no reintenta más de una vez', () async {
    final adapter = _TokenCheckingAdapter('otro');
    final tokens = _Tokens('viejo', renewTo: 'nuevo');
    await expectLater(_dio(adapter, tokens).get<dynamic>('/auth/me'), throwsA(isA<DioException>()));
    expect(adapter.seenTokens, hasLength(2));
  });

  test('si otra petición ya renovó, reintenta sin volver a renovar', () async {
    final adapter = _TokenCheckingAdapter('nuevo');
    final tokens = _Tokens('viejo', renewTo: 'otro-mas');
    final dio = _dio(adapter, tokens);
    // Corre después de AuthInterceptor: la petición ya lleva "viejo" y,
    // mientras vuela, otra petición renueva el token.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          tokens.accessToken = 'nuevo';
          handler.next(options);
        },
      ),
    );
    final response = await dio.get<dynamic>('/auth/me');
    expect(response.statusCode, 200);
    expect(tokens.renewals, 0);
    expect(adapter.seenTokens, ['Bearer viejo', 'Bearer nuevo']);
  });
}
