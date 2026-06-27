import 'package:drift/drift.dart';

class Usuarios extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text().withLength(min: 1, max: 50)();
  TextColumn get nombre => text().withLength(min: 1, max: 200)();
  TextColumn get passwordHash => text().withLength(min: 32, max: 64)();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
}
