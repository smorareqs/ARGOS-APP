import 'package:argos_app/features/shell/models/shell_tab.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> _labels(
  String role, {
  Set<String> permissions = const {},
  Map<String, bool> features = const {},
}) => tabsFor(roleKey: role, permissions: permissions, features: features)
    .map((t) => t.label)
    .toList();

void main() {
  test('destinos por rol (ux-ui.md §4.1)', () {
    expect(_labels('cleaner'), ['Hoy', 'Semana', 'Inventario', 'Alertas', 'Perfil']);
    expect(_labels('maintenance'), ['Hoy', 'Tickets', 'Inventario', 'Alertas', 'Perfil']);
    expect(_labels('owner'), ['Mis propiedades', 'Reportes', 'Perfil']);
  });

  test('Reservas solo con la bandera del tenant y el permiso', () {
    const perms = {'reservations.read'};
    expect(
      _labels('supervisor', permissions: perms, features: {'reservations': true}),
      ['Hoy', 'Equipo', 'Reservas', 'Alertas', 'Más'],
    );
    expect(
      _labels('supervisor', permissions: perms, features: {'reservations': false}),
      ['Hoy', 'Equipo', 'Alertas', 'Más'],
    );
    expect(
      _labels('admin', features: {'reservations': true}),
      ['Hoy', 'Equipo', 'Alertas', 'Más'],
    );
  });

  test('Áreas de seguridad solo con la bandera shared_areas', () {
    expect(
      _labels('security', features: {'shared_areas': true}),
      ['Seguridad', 'Alarmas', 'Áreas', 'Alertas', 'Perfil'],
    );
    expect(_labels('security'), ['Seguridad', 'Alarmas', 'Alertas', 'Perfil']);
  });

  test('rol personalizado: destinos según permisos', () {
    expect(_labels('jardinero', permissions: {'tasks.execute'}), ['Hoy', 'Alertas', 'Perfil']);
    expect(
      _labels('coordinador', permissions: {'tasks.read', 'tasks.assign'}),
      ['Hoy', 'Equipo', 'Alertas', 'Perfil'],
    );
    expect(_labels('consulta'), ['Alertas', 'Perfil']);
  });

  test('ids de ruta únicos', () {
    final ids = ShellTab.values.map((t) => t.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });
}
