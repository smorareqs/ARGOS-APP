import 'dart:convert';

import 'package:argos_app/core/network/mock/mock_backend.dart';
import 'package:argos_app/features/tasks/data/datasources/tasks_remote_datasource.dart';

/// Rutas simuladas de tareas (fase02 §4) para la agenda "Hoy" (B1).
///
/// Genera la agenda de cualquier día a partir de la fecha y el usuario, así
/// siempre se ve igual: días pasados terminados, hoy con una en progreso,
/// una retrasada y otras pendientes, días futuros pendientes y el domingo
/// libre.
void registerTasksMockRoutes(
  MockBackend backend, {
  DateTime Function()? clock,
}) {
  final now = clock ?? DateTime.now;
  backend.on('GET', '/tasks', (req) {
    final claims = _claims(req.bearerToken);
    final exp = claims?['exp'];
    if (claims == null ||
        exp is! int ||
        exp < now().millisecondsSinceEpoch ~/ 1000) {
      return MockResponse.problem(401, 'Token inválido o expirado.');
    }
    final date = DateTime.tryParse(req.query['date'] ?? '');
    if (date == null) {
      return MockResponse.problem(422, 'Falta la fecha (date=AAAA-MM-DD).');
    }
    return MockResponse.json({
      'items': mockAgenda(date, today: now(), userId: '${claims['sub']}'),
    });
  });
}

const _properties = [
  ('LAU-01', 'Casa Laurel', 'Calle de los Laureles 14, Escazú'),
  ('OLI-3B', 'Apartamento Olivo 3B', 'Torre Olivo, piso 3, Santa Ana'),
  ('CED-12', 'Villa Cedro', 'Residencial Los Cedros 12, Ciudad Colón'),
  ('PIN-07', 'Loft Pino', 'Avenida 9, Barrio Escalante, San José'),
  ('ROB-02', 'Casa Roble', 'Lomas de Ayarco 2, Curridabat'),
  ('ALM-05', 'Cabaña Almendro', 'Camino a Tabarcia km 3, Mora'),
];

const _windows = [
  ('07:30', '09:30'),
  ('09:30', '12:00'),
  ('11:00', '13:00'),
  ('13:30', '15:30'),
  ('15:30', '17:30'),
];

const _notes = [
  'Check-out a las 11:00. Revisar la terraza y dejar toallas extra.',
  'Huéspedes con mascota: aspirar sofás.',
  null,
  'Llave en la caja fuerte de la entrada.',
  null,
];

/// Agenda simulada de [date] para [userId] (pública para las pruebas).
List<Map<String, Object?>> mockAgenda(
  DateTime date, {
  required DateTime today,
  required String userId,
}) {
  final day = DateTime(date.year, date.month, date.day);
  final ref = DateTime(today.year, today.month, today.day);
  if (day.weekday == DateTime.sunday) return const [];

  final seed = day.day + day.month * 31 + userId.codeUnits.fold<int>(0, (a, b) => a + b);
  final count = 3 + seed % 2;
  final iso = TasksRemoteDataSource.isoDate(day);
  final relation = day.compareTo(ref); // <0 pasado, 0 hoy, >0 futuro

  return [
    for (var i = 0; i < count; i++)
      _task(
        id: 'task-$iso-$i',
        iso: iso,
        day: day,
        index: i,
        property: _properties[(seed + i) % _properties.length],
        window: _windows[i],
        relation: relation,
        type: i == 2 && seed.isEven ? 'inspection' : 'cleaning',
        notes: _notes[(seed + i) % _notes.length],
      ),
  ];
}

Map<String, Object?> _task({
  required String id,
  required String iso,
  required DateTime day,
  required int index,
  required (String, String, String) property,
  required (String, String) window,
  required int relation,
  required String type,
  required String? notes,
}) {
  // Hoy: la 1.ª terminada, la 2.ª en progreso, la 3.ª retrasada, el resto
  // pendientes.
  final status = relation < 0
      ? (index == 0 ? 'validated' : 'completed')
      : relation > 0
      ? 'pending'
      : switch (index) {
          0 => 'completed',
          1 => 'in_progress',
          _ => 'pending',
        };
  final late = relation == 0 && index == 2;
  final total = type == 'inspection' ? 12 : 18;
  final done = switch (status) {
    'completed' || 'validated' => total,
    'in_progress' => 7,
    _ => 0,
  };
  DateTime at(String hhmm, int minutes) => DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(hhmm.substring(0, 2)),
    int.parse(hhmm.substring(3)),
  ).add(Duration(minutes: minutes));

  return {
    'id': id,
    'type': type,
    'status': status,
    'is_late': late,
    'scheduled_date': iso,
    'window_start': '${window.$1}:00',
    'window_end': '${window.$2}:00',
    'started_at': status == 'pending'
        ? null
        : at(window.$1, 4).toUtc().toIso8601String(),
    'finished_at': status == 'completed' || status == 'validated'
        ? at(window.$2, -18).toUtc().toIso8601String()
        : null,
    'notes': notes,
    'property': {
      'id': 'prop-${property.$1.toLowerCase()}',
      'code': property.$1,
      'name': property.$2,
      'address': property.$3,
    },
    'checklist': {'done': done, 'total': total},
  };
}

Map<String, dynamic>? _claims(String? token) {
  const prefix = 'mock-at.';
  if (token == null || !token.startsWith(prefix)) return null;
  try {
    final payload = base64Url.normalize(token.substring(prefix.length));
    return Map<String, dynamic>.from(
      jsonDecode(utf8.decode(base64Url.decode(payload))) as Map,
    );
  } catch (_) {
    return null;
  }
}
