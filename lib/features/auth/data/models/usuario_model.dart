import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/features/auth/models/usuario_entity.dart';

extension UsuarioModelMapper on Usuario {
  UsuarioEntity toEntity() {
    return UsuarioEntity(
      id: id,
      codigo: codigo,
      nombre: nombre,
      activo: activo,
    );
  }
}
