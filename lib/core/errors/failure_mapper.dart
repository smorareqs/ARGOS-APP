import 'package:argos_app/core/errors/app_failure.dart';
import 'package:dio/dio.dart';

AppFailure mapExceptionToFailure(Object error) {
  if (error is AppFailure) {
    return error;
  }

  if (error is DioException) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        const NetworkFailure(),
      _ when error.response?.statusCode != null => ServerFailure(
          'Error del servidor (${error.response!.statusCode}).',
        ),
      _ => const NetworkFailure(),
    };
  }

  final message = error.toString().toLowerCase();
  if (message.contains('sqlite') || message.contains('database')) {
    return const CacheFailure();
  }

  return UnexpectedFailure(error.toString());
}
