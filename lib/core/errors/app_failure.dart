sealed class AppFailure {
  const AppFailure(this.message);

  final String message;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([super.message = 'Sin conexión de red o tiempo de espera agotado.']);
}

final class ServerFailure extends AppFailure {
  const ServerFailure([super.message = 'Error devuelto por el servidor.']);
}

final class AuthFailure extends AppFailure {
  const AuthFailure([super.message = 'Credenciales inválidas o sesión expirada.']);
}

final class CacheFailure extends AppFailure {
  const CacheFailure([super.message = 'Error al acceder a la base de datos local.']);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure([super.message = 'Los datos ingresados no son válidos.']);
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure([super.message = 'Ocurrió un error inesperado.']);
}
