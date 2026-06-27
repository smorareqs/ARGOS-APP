import 'package:argos_app/core/errors/app_failure.dart';
import 'package:argos_app/features/auth/models/usuario_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class AuthRepository {
  Future<Either<AppFailure, UsuarioEntity>> login({
    required String codigo,
    required String password,
  });

  Future<Either<AppFailure, void>> logout();

  Future<Either<AppFailure, bool>> isAuthenticated();

  Future<Either<AppFailure, UsuarioEntity?>> getCurrentUser();
}
