import 'package:argos_app/core/errors/app_failure.dart';
import 'package:argos_app/core/errors/failure_mapper.dart';
import 'package:argos_app/core/storage/secure_storage_service.dart';
import 'package:argos_app/core/utils/md5_hash.dart';
import 'package:argos_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:argos_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:argos_app/features/auth/models/usuario_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository_impl.g.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._localDataSource, this._secureStorage);

  final AuthLocalDataSource _localDataSource;
  final SecureStorageService _secureStorage;

  @override
  Future<Either<AppFailure, UsuarioEntity>> login({
    required String codigo,
    required String password,
  }) async {
    try {
      if (codigo.trim().isEmpty || password.isEmpty) {
        return left(const ValidationFailure('Código y contraseña son requeridos.'));
      }

      final storedHash = await _localDataSource.getPasswordHashByCode(codigo.trim());
      if (storedHash == null) {
        return left(const AuthFailure('Usuario no encontrado.'));
      }

      if (hashMd5(password) != storedHash) {
        return left(const AuthFailure('Contraseña incorrecta.'));
      }

      final usuario = await _localDataSource.findByCode(codigo.trim());
      if (usuario == null || !usuario.activo) {
        return left(const AuthFailure('Usuario inactivo.'));
      }

      await _secureStorage.writeSessionToken('local_${usuario.id}_${usuario.codigo}');
      await _secureStorage.writeDeviceSerial(usuario.codigo);

      return right(usuario);
    } catch (error) {
      return left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<AppFailure, void>> logout() async {
    try {
      await _secureStorage.clearAll();
      return right(null);
    } catch (error) {
      return left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<AppFailure, bool>> isAuthenticated() async {
    try {
      final token = await _secureStorage.readSessionToken();
      return right(token != null && token.isNotEmpty);
    } catch (error) {
      return left(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Either<AppFailure, UsuarioEntity?>> getCurrentUser() async {
    try {
      final serial = await _secureStorage.readDeviceSerial();
      if (serial == null || serial.isEmpty) {
        return right(null);
      }
      final usuario = await _localDataSource.findByCode(serial);
      return right(usuario);
    } catch (error) {
      return left(mapExceptionToFailure(error));
    }
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(
    ref.watch(authLocalDataSourceProvider),
    ref.watch(secureStorageServiceProvider),
  );
}
