import 'package:argos_app/core/errors/app_failure.dart';
import 'package:argos_app/core/network/api_exception.dart';
import 'package:dio/dio.dart';

AppFailure mapExceptionToFailure(Object error) {
  if (error is AppFailure) {
    return error;
  }

  if (error is ApiException) {
    return _fromApi(error);
  }

  if (error is DioException) {
    final api = ApiException.fromDio(error);
    if (api != null) return _fromApi(api);
    return const NetworkFailure();
  }

  final message = error.toString().toLowerCase();
  if (message.contains('sqlite') || message.contains('database')) {
    return const CacheFailure();
  }

  return UnexpectedFailure(error.toString());
}

AppFailure _fromApi(ApiException error) {
  return switch (error.statusCode) {
    401 || 403 || 429 => AuthFailure(error.detail),
    // huma responde "validation failed" con el detalle por campo en errors[].
    400 || 422 =>
      error.detail == 'validation failed'
          ? const ValidationFailure()
          : ValidationFailure(error.detail),
    _ => ServerFailure(error.detail),
  };
}
