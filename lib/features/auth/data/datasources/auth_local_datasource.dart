import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/features/auth/data/models/usuario_model.dart';
import 'package:argos_app/features/auth/models/usuario_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_local_datasource.g.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._database);

  final AppDatabase _database;

  Future<UsuarioEntity?> findByCode(String codigo) async {
    final usuario = await _database.findUsuarioByCode(codigo);
    return usuario?.toEntity();
  }

  Future<String?> getPasswordHashByCode(String codigo) async {
    final usuario = await _database.findUsuarioByCode(codigo);
    return usuario?.passwordHash;
  }
}

@Riverpod(keepAlive: true)
AuthLocalDataSource authLocalDataSource(Ref ref) {
  return AuthLocalDataSource(ref.watch(appDatabaseProvider));
}
