class UsuarioEntity {
  const UsuarioEntity({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.activo,
  });

  final int id;
  final String codigo;
  final String nombre;
  final bool activo;
}
