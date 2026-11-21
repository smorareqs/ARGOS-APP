import 'package:drift/drift.dart';

/// Copia local de la sesión (usuario, empresa, rol, permisos, banderas) para
/// arrancar sin red. Nunca guarda contraseñas ni tokens. Tiene una sola fila.
@DataClassName('SessionCacheRow')
class SessionCache extends Table {
  /// Siempre 1: hay como máximo una sesión en el dispositivo.
  IntColumn get id => integer()();
  TextColumn get userId => text()();
  TextColumn get email => text()();
  TextColumn get fullName => text()();
  BoolColumn get totpEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get tenantId => text()();
  TextColumn get tenantName => text()();
  TextColumn get tenantLogoUrl => text().nullable()();
  TextColumn get timezone => text()();
  TextColumn get currency => text()();
  TextColumn get roleKey => text()();
  TextColumn get roleName => text()();

  /// Lista JSON de permisos.
  TextColumn get permissionsJson => text()();

  /// Mapa JSON de banderas del tenant.
  TextColumn get featuresJson => text()();

  /// Lista JSON de membresías activas (para "Cambiar de empresa").
  TextColumn get membershipsJson => text()();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
