import 'package:dio/dio.dart';

/// Error de un campo en una respuesta 422.
class ApiFieldError {
  const ApiFieldError({required this.location, required this.message});

  /// Ubicación del campo, p. ej. `body.email`.
  final String location;
  final String message;
}

/// Error devuelto por la API en formato RFC 9457 (`application/problem+json`):
/// el mensaje para el usuario viene en `detail`.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.detail,
    this.retryAfter,
    this.fieldErrors = const [],
  });

  final int statusCode;
  final String detail;

  /// Espera indicada por el header `Retry-After` (p. ej. en un 429).
  final Duration? retryAfter;
  final List<ApiFieldError> fieldErrors;

  /// Convierte la respuesta de error de Dio. Devuelve null si no hubo
  /// respuesta (sin conexión o tiempo agotado).
  static ApiException? fromDio(DioException error) {
    final response = error.response;
    if (response == null) return null;

    final status = response.statusCode ?? 0;
    final data = response.data;
    final retryAfter = _parseRetryAfter(response.headers.value('retry-after'));
    String? detail;
    final fieldErrors = <ApiFieldError>[];
    if (data is Map) {
      if (data['detail'] is String) detail = data['detail'] as String;
      final errors = data['errors'];
      if (errors is List) {
        for (final e in errors.whereType<Map>()) {
          fieldErrors.add(
            ApiFieldError(
              location: '${e['location'] ?? ''}',
              message: '${e['message'] ?? ''}',
            ),
          );
        }
      }
    }

    return ApiException(
      statusCode: status,
      detail: (detail == null || detail.isEmpty)
          ? _defaultDetail(status, retryAfter)
          : detail,
      retryAfter: retryAfter,
      fieldErrors: fieldErrors,
    );
  }

  static Duration? _parseRetryAfter(String? value) {
    final seconds = int.tryParse(value ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }

  static String _defaultDetail(int status, Duration? retryAfter) {
    return switch (status) {
      401 => 'Tu sesión no es válida. Ingresa de nuevo.',
      403 => 'No tienes acceso a esto.',
      404 => 'No encontramos lo que buscas.',
      429 when retryAfter != null && retryAfter.inMinutes >= 1 =>
        'Demasiados intentos. Espera ${retryAfter.inMinutes} min e intenta de nuevo.',
      429 => 'Demasiados intentos. Espera un momento e intenta de nuevo.',
      >= 500 => 'El servidor no pudo completar la operación. Intenta más tarde.',
      _ => 'La solicitud no se pudo completar.',
    };
  }

  @override
  String toString() => 'ApiException($statusCode): $detail';
}
