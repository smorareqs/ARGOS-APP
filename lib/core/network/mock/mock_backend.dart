import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Manejador de una ruta simulada.
typedef MockHandler = FutureOr<MockResponse> Function(MockRequest request);

/// Petición recibida por el backend simulado.
class MockRequest {
  MockRequest({
    required this.method,
    required this.path,
    required this.query,
    required this.headers,
    required this.body,
    required this.pathParams,
  });

  final String method;

  /// Ruta relativa a la URL base, p. ej. `/auth/sessions/abc`.
  final String path;
  final Map<String, String> query;

  /// Headers con el nombre en minúsculas.
  final Map<String, String> headers;
  final Object? body;

  /// Segmentos variables de la ruta, p. ej. `{id}` → `pathParams['id']`.
  final Map<String, String> pathParams;

  Map<String, dynamic> get json =>
      body is Map ? Map<String, dynamic>.from(body! as Map) : const {};

  String? get bearerToken {
    final header = headers['authorization'];
    if (header == null || !header.toLowerCase().startsWith('bearer ')) {
      return null;
    }
    return header.substring(7).trim();
  }
}

/// Respuesta del backend simulado.
class MockResponse {
  const MockResponse(this.status, {this.body, this.headers = const {}});

  factory MockResponse.json(Object body, {int status = 200}) =>
      MockResponse(status, body: body);

  factory MockResponse.noContent() => const MockResponse(204);

  /// Error RFC 9457, igual que el backend real.
  factory MockResponse.problem(
    int status,
    String detail, {
    Map<String, String> headers = const {},
  }) => MockResponse(
    status,
    body: {'title': _titles[status] ?? 'Error', 'status': status, 'detail': detail},
    headers: headers,
  );

  final int status;
  final Object? body;
  final Map<String, String> headers;

  static const _titles = {
    400: 'Bad Request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Not Found',
    409: 'Conflict',
    422: 'Unprocessable Entity',
    428: 'Precondition Required',
    429: 'Too Many Requests',
    500: 'Internal Server Error',
  };
}

/// Backend simulado a nivel HTTP. Con `--dart-define=ARGOS_MOCK=true` reemplaza
/// el adaptador de Dio, así que la app ejecuta su código real (datasources,
/// interceptor, manejo de errores) contra respuestas que siguen el contrato
/// de `docs/plans/fase0N.md`.
///
/// Cada feature registra sus rutas en `mock_routes.dart`.
class MockBackend implements HttpClientAdapter {
  MockBackend({this.latency = const Duration(milliseconds: 350)});

  /// Retardo simulado de red.
  final Duration latency;
  final _routes = <_Route>[];

  /// Simula estar sin red: cada petición falla como error de conexión.
  bool offline = false;

  /// Peticiones recibidas (`METHOD /ruta`), para depurar y para pruebas.
  final requests = <String>[];

  void on(String method, String pattern, MockHandler handler) {
    _routes.add(_Route(method.toUpperCase(), pattern, handler));
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'Sin conexión (backend simulado)',
      );
    }

    final path = _relativePath(options);
    requests.add('${options.method.toUpperCase()} $path');
    final response = await _dispatch(options, path);
    final headers = <String, List<String>>{
      Headers.contentTypeHeader: [Headers.jsonContentType],
      for (final entry in response.headers.entries) entry.key: [entry.value],
    };
    final body = response.body == null ? '' : jsonEncode(response.body);
    return ResponseBody.fromString(body, response.status, headers: headers);
  }

  Future<MockResponse> _dispatch(RequestOptions options, String path) async {
    for (final route in _routes) {
      if (route.method != options.method.toUpperCase()) continue;
      final params = route.match(path);
      if (params == null) continue;

      final request = MockRequest(
        method: options.method.toUpperCase(),
        path: path,
        query: options.uri.queryParameters,
        headers: {
          for (final entry in options.headers.entries)
            entry.key.toLowerCase(): '${entry.value}',
        },
        body: options.data,
        pathParams: params,
      );
      try {
        return await route.handler(request);
      } catch (e) {
        return MockResponse.problem(500, 'Error en el backend simulado: $e');
      }
    }
    return MockResponse.problem(
      404,
      'Ruta no simulada: ${options.method} $path',
    );
  }

  String _relativePath(RequestOptions options) {
    var base = Uri.parse(options.baseUrl).path;
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    final path = options.uri.path;
    return path.startsWith(base) ? path.substring(base.length) : path;
  }

  @override
  void close({bool force = false}) {}
}

class _Route {
  _Route(this.method, String pattern, this.handler)
    : _segments = _split(pattern);

  final String method;
  final MockHandler handler;
  final List<String> _segments;

  Map<String, String>? match(String path) {
    final parts = _split(path);
    if (parts.length != _segments.length) return null;
    final params = <String, String>{};
    for (var i = 0; i < parts.length; i++) {
      final segment = _segments[i];
      if (segment.startsWith('{') && segment.endsWith('}')) {
        params[segment.substring(1, segment.length - 1)] =
            Uri.decodeComponent(parts[i]);
      } else if (segment != parts[i]) {
        return null;
      }
    }
    return params;
  }

  static List<String> _split(String path) =>
      path.split('/').where((s) => s.isNotEmpty).toList();
}
