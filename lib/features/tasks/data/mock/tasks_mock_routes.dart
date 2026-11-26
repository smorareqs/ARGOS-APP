import 'dart:convert';

import 'package:argos_app/core/network/mock/mock_backend.dart';
import 'package:argos_app/features/tasks/data/datasources/tasks_remote_datasource.dart';
import 'package:argos_app/features/uploads/data/mock/files_mock_routes.dart';

/// Rutas simuladas de tareas e inventario (fase02 §4) con la misma forma
/// que el backend real (`TaskRead`, `TaskDetail`, `MyInventory`).
///
/// La agenda de cualquier día sale de la fecha y el usuario, así siempre se
/// ve igual: días pasados validados, ayer terminadas, hoy una terminada, una
/// en progreso, una retrasada y otras pendientes; el domingo libre. Lo que se
/// hace en la app (iniciar, checklist, insumos, cerrar, validar) se guarda en
/// memoria mientras la app está abierta.
void registerTasksMockRoutes(MockBackend backend, {DateTime Function()? clock}) {
  final api = _MockTasksApi(clock ?? DateTime.now);
  backend
    ..on('GET', '/tasks', api.list)
    ..on('GET', '/tasks/assignables', api.assignables)
    ..on('GET', '/tasks/{id}', api.detail)
    ..on('POST', '/tasks/{id}/start', api.start)
    ..on('PATCH', '/tasks/{id}/checklist/{item}', api.item)
    ..on('POST', '/tasks/{id}/consumptions', api.consumptions)
    ..on('POST', '/tasks/{id}/complete', api.complete)
    ..on('POST', '/tasks/{id}/validate', (r) => api.decide(r, approve: true))
    ..on('POST', '/tasks/{id}/return', (r) => api.decide(r, approve: false))
    ..on('POST', '/tasks/{id}/reschedule', api.reschedule)
    ..on('GET', '/properties/{id}/access-info', api.accessInfo)
    ..on('GET', '/inventory/me', api.myInventory)
    ..on('POST', '/inventory/movements', api.movement)
    ..on('POST', '/inventory/restock-requests', api.restock);
}

const _properties = [
  ('LAU-01', 'Casa Laurel', 'Calle de los Laureles 14, Escazú', 9.9187, -84.1398),
  ('OLI-3B', 'Apartamento Olivo 3B', 'Torre Olivo, piso 3, Santa Ana', 9.9326, -84.1825),
  ('CED-12', 'Villa Cedro', 'Residencial Los Cedros 12, Ciudad Colón', 9.9130, -84.2402),
  ('PIN-07', 'Loft Pino', 'Avenida 9, Barrio Escalante, San José', 9.9351, -84.0627),
  ('ROB-02', 'Casa Roble', 'Lomas de Ayarco 2, Curridabat', 9.9050, -84.0170),
  ('ALM-05', 'Cabaña Almendro', 'Camino a Tabarcia km 3, Mora', 9.8397, -84.2470),
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

/// Checklist de limpieza: (sección, texto, foto, antes/después).
const _cleaningChecklist = [
  ('Habitación principal', 'Cambiar sábanas y fundas', false, false),
  ('Habitación principal', 'Tender la cama', true, false),
  ('Habitación principal', 'Aspirar y trapear el piso', false, false),
  ('Habitación principal', 'Limpiar mesas de noche y lámparas', false, false),
  ('Baño', 'Desinfectar inodoro y lavamanos', false, true),
  ('Baño', 'Limpiar ducha y mampara', false, false),
  ('Baño', 'Reponer toallas', true, false),
  ('Baño', 'Reponer papel, jabón y shampoo', false, false),
  ('Cocina', 'Lavar y guardar la vajilla', false, false),
  ('Cocina', 'Limpiar estufa y refrigerador por dentro', false, true),
  ('Cocina', 'Reponer café y bolsas de basura', false, false),
  ('Sala', 'Ordenar cojines y mantas', false, false),
  ('Sala', 'Limpiar vidrios y espejos', false, false),
  ('Sala', 'Foto general de la sala', true, false),
];

const _inspectionChecklist = [
  ('Entrada', 'Cerradura y llaves funcionan', false, false),
  ('Entrada', 'Foto de la puerta principal', true, false),
  ('Habitaciones', 'Colchones y blancos sin manchas', true, false),
  ('Habitaciones', 'Aire acondicionado enciende', false, false),
  ('Baño', 'Sin fugas en lavamanos ni inodoro', false, false),
  ('Baño', 'Agua caliente', false, false),
  ('Cocina', 'Electrodomésticos funcionan', false, false),
  ('Cocina', 'Inventario de vajilla completo', true, false),
];

const _people = {
  'ana@argos.demo': ('u-ana', 'Ana López', 'cleaner'),
  'luis@argos.demo': ('u-luis', 'Luis Pérez', 'maintenance'),
  'sofia@argos.demo': ('u-sofia', 'Sofía Méndez', 'supervisor'),
  'admin@argos.demo': ('u-carlos', 'Carlos Rivas', 'admin'),
};

/// Quienes aparecen en "Equipo hoy" del supervisor.
const _team = [
  ('u-ana', 'Ana López', 'cleaner'),
  ('u-marta', 'Marta Díaz', 'cleaner'),
  ('u-luis', 'Luis Pérez', 'maintenance'),
];

const _catalog = [
  ('it-toa-ban', 'TOA-BAN', 'Toalla de baño', 'linens', 'unidad', 64.0),
  ('it-toa-man', 'TOA-MAN', 'Toalla de manos', 'linens', 'unidad', 48.0),
  ('it-sab-que', 'SAB-QUE', 'Juego de sábanas queen', 'linens', 'juego', 26.0),
  ('it-jab-toc', 'JAB-TOC', 'Jabón de tocador', 'amenities', 'unidad', 180.0),
  ('it-sha-30', 'SHA-30', 'Shampoo 30 ml', 'amenities', 'unidad', 12.0),
  ('it-pap-hig', 'PAP-HIG', 'Papel higiénico', 'amenities', 'rollo', 140.0),
  ('it-des-mul', 'DES-MUL', 'Desinfectante multiusos', 'cleaning', 'litro', 15.0),
  ('it-bol-bas', 'BOL-BAS', 'Bolsas de basura', 'cleaning', 'unidad', 240.0),
  ('it-caf-mol', 'CAF-MOL', 'Café molido', 'kitchen', 'bolsa', 18.0),
  ('it-lla-mae', 'LLA-MAE', 'Llave maestra de bodega', 'keys', 'unidad', 2.0),
];

class _MockTasksApi {
  _MockTasksApi(this._now) {
    for (final c in _catalog) {
      _stock[c.$1] = c.$6;
    }
  }

  final DateTime Function() _now;

  /// Tareas ya generadas (con lo que se les haya hecho), por id.
  final _tasks = <String, Map<String, dynamic>>{};

  /// Custodia por usuario: item_id → cantidad.
  final _custody = <String, Map<String, double>>{};
  final _custodySince = <String, String>{};
  final _stock = <String, double>{};
  final _requests = <String, List<Map<String, dynamic>>>{};

  // ── Sesión ────────────────────────────────────────────

  (String, String, String)? _who(MockRequest req) {
    final claims = _claims(req.bearerToken);
    final exp = claims?['exp'];
    if (claims == null || exp is! int || exp < _now().millisecondsSinceEpoch ~/ 1000) {
      return null;
    }
    final email = '${claims['sub']}';
    return _people[email] ?? ('u-${email.split('@').first}', email, 'cleaner');
  }

  static bool _manager((String, String, String) who) =>
      who.$3 == 'supervisor' || who.$3 == 'admin';

  Map<String, double> _custodyOf(String userId) => _custody.putIfAbsent(userId, () {
    _custodySince[userId] = _now().subtract(const Duration(days: 2)).toUtc().toIso8601String();
    return {'it-toa-ban': 6, 'it-toa-man': 4, 'it-jab-toc': 10, 'it-sha-30': 6};
  });

  // ── Tareas ────────────────────────────────────────────

  MockResponse list(MockRequest req) {
    final who = _who(req);
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final date = DateTime.tryParse(req.query['date'] ?? '');
    if (date == null) return MockResponse.problem(422, 'Falta la fecha (date=AAAA-MM-DD).');
    final mine = req.query['mine'] == 'true' || !_manager(who);
    final people = mine ? [who] : _team;
    final out = <Map<String, dynamic>>[];
    for (final p in people) {
      for (final t in mockAgenda(date, today: _now(), userId: p.$1, assigneeName: p.$2)) {
        final stored = _tasks.putIfAbsent('${t['id']}', () => t);
        out.add(_read(stored));
      }
    }
    return MockResponse.json({'items': out});
  }

  MockResponse assignables(MockRequest req) {
    final who = _who(req);
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    return MockResponse.json({
      'items': [
        for (final p in _team)
          {
            'id': p.$1,
            'name': p.$2,
            'initials': p.$2.split(' ').map((w) => w[0]).take(2).join(),
            'role': p.$3,
            'scoped': false,
            'property_ids': const <String>[],
          },
      ],
    });
  }

  Map<String, dynamic>? _task(MockRequest req) {
    final id = req.pathParams['id']!;
    final known = _tasks[id];
    if (known != null) return known;
    // Id del tipo task-<user>-AAAA-MM-DD-<n>: se genera ese día.
    final match = RegExp(r'^task-(.+)-(\d{4}-\d{2}-\d{2})-(\d+)$').firstMatch(id);
    if (match == null) return null;
    final user = match.group(1)!;
    final name = _team.where((p) => p.$1 == user).firstOrNull?.$2;
    for (final t in mockAgenda(
      DateTime.parse(match.group(2)!),
      today: _now(),
      userId: user,
      assigneeName: name,
    )) {
      _tasks.putIfAbsent('${t['id']}', () => t);
    }
    return _tasks[id];
  }

  MockResponse detail(MockRequest req) {
    final who = _who(req);
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final t = _task(req);
    if (t == null) return MockResponse.problem(404, 'La tarea no existe.');
    return MockResponse.json(_detail(t, who));
  }

  MockResponse? _guard(MockRequest req, (String, String, String)? who, Map<String, dynamic>? t, {String? status}) {
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    if (t == null) return MockResponse.problem(404, 'La tarea no existe.');
    if (t['assignee_id'] != who.$1) {
      return MockResponse.problem(403, 'Solo quien tiene asignada la tarea puede ejecutarla.');
    }
    if (status != null && t['status'] != status) {
      return MockResponse.problem(409, 'La tarea no está en curso.');
    }
    return null;
  }

  MockResponse start(MockRequest req) {
    final who = _who(req);
    final t = _task(req);
    final bad = _guard(req, who, t);
    if (bad != null) return bad;
    if (t!['status'] != 'pending' && t['status'] != 'returned') {
      return MockResponse.problem(409, 'La tarea ya se inició.');
    }
    t['status'] = 'in_progress';
    t['started_at'] ??= _iso();
    t['late'] = false;
    _event(t, 'started', 'Iniciada', who!.$2);
    return MockResponse.json(_detail(t, who));
  }

  MockResponse item(MockRequest req) {
    final who = _who(req);
    final t = _task(req);
    final bad = _guard(req, who, t, status: 'in_progress');
    if (bad != null) return bad;
    final items = (t!['items'] as List).cast<Map<String, dynamic>>();
    final item = items.where((i) => i['id'] == req.pathParams['item']).firstOrNull;
    if (item == null) return MockResponse.problem(404, 'El punto no existe.');
    final body = req.json;
    if (body['is_done'] is bool) {
      item['is_done'] = body['is_done'];
      item['done_at'] = body['is_done'] == true ? _iso() : null;
    }
    if (body.containsKey('notes')) item['notes'] = body['notes'];
    return MockResponse.json(_item(item));
  }

  MockResponse consumptions(MockRequest req) {
    final who = _who(req);
    final t = _task(req);
    final bad = _guard(req, who, t, status: 'in_progress');
    if (bad != null) return bad;
    final custody = _custodyOf(who!.$1);
    final consumption = (t!['consumption'] as List).cast<Map<String, dynamic>>();
    final lines = (req.json['items'] as List? ?? const []).whereType<Map>().toList();
    for (final (i, l) in lines.indexed) {
      final id = '${l['item_id']}';
      final qty = (l['quantity'] as num?)?.toDouble() ?? 0;
      final item = _item_(id);
      if (item == null || !custody.containsKey(id)) {
        return MockResponse.problem(422, 'No tienes ese artículo en custodia (items[$i]).');
      }
      if (_returnable(item.$4)) {
        return MockResponse.problem(422, '${item.$3} se devuelve, no se consume.');
      }
      if (qty > custody[id]! + 0.0005) {
        return MockResponse.problem(422, 'Tienes solo ${_num(custody[id]!)} de ${item.$3}.');
      }
    }
    final parts = <String>[];
    for (final l in lines) {
      final id = '${l['item_id']}';
      final qty = (l['quantity'] as num).toDouble();
      final item = _item_(id)!;
      custody[id] = custody[id]! - qty;
      if (custody[id]! <= 0.0005) custody.remove(id);
      final existing = consumption.where((c) => c['item_id'] == id).firstOrNull;
      if (existing != null) {
        existing['qty'] = (existing['qty'] as num) + qty;
      } else {
        consumption.add({'item_id': id, 'item': item.$3, 'qty': qty, 'unit': item.$5});
      }
      parts.add('${item.$3} ${_num(qty)}');
    }
    _event(t, 'consumption', 'Registró insumos', who.$2, parts.join(', '));
    return MockResponse.json(_read(t));
  }

  MockResponse complete(MockRequest req) {
    final who = _who(req);
    final t = _task(req);
    final bad = _guard(req, who, t, status: 'in_progress');
    if (bad != null) return bad;
    final items = (t!['items'] as List).cast<Map<String, dynamic>>();
    if (items.any((i) => i['is_done'] != true)) {
      return MockResponse.problem(422, 'Faltan puntos del checklist por marcar.');
    }
    final missingPhotos = items.where((i) {
      final photos = _photos('${i['id']}');
      if (i['requires_before_after'] == true) {
        return !photos.any((p) => p['kind'] == 'before') || !photos.any((p) => p['kind'] == 'after');
      }
      return i['requires_photo'] == true && photos.isEmpty;
    }).length;
    if (missingPhotos > 0) {
      return MockResponse.problem(422, 'Faltan fotos en $missingPhotos puntos.');
    }
    final custody = _custodyOf(who!.$1);
    final declared = {
      for (final c in (req.json['custody'] as List? ?? const []).whereType<Map>()) '${c['item_id']}': c,
    };
    if (custody.keys.any((k) => !declared.containsKey(k))) {
      return MockResponse.problem(422, 'Falta conciliar artículos de tu custodia.');
    }
    final missing = <String>[];
    for (final e in custody.entries.toList()) {
      final d = declared[e.key]!;
      double n(String k) => (d[k] as num?)?.toDouble() ?? 0;
      final item = _item_(e.key)!;
      if (_returnable(item.$4) && n('consumed') > 0) {
        return MockResponse.problem(422, '${item.$3} se devuelve, no se consume.');
      }
      final accounted = n('returned') + n('consumed') + n('kept');
      if (accounted - e.value > 0.0005) {
        return MockResponse.problem(422, 'Declaraste más ${item.$3} de los que tienes.');
      }
      _stock[e.key] = (_stock[e.key] ?? 0) + n('returned');
      if (e.value - accounted > 0.0005) missing.add('${item.$3} ${_num(e.value - accounted)}');
      if (n('kept') > 0.0005) {
        custody[e.key] = n('kept');
      } else {
        custody.remove(e.key);
      }
    }
    t['status'] = 'done';
    t['finished_at'] = _iso();
    t['late'] = false;
    t['completion_notes'] = req.json['notes'];
    if (missing.isNotEmpty) {
      t['discrepancy'] = 'Faltan: ${missing.join(', ')}';
      _event(t, 'discrepancy', 'Diferencia de inventario', 'Sistema', missing.join(', '));
    }
    _event(t, 'finished', 'Terminada', who.$2);
    return MockResponse.json(_detail(t, who));
  }

  MockResponse decide(MockRequest req, {required bool approve}) {
    final who = _who(req);
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    if (!_manager(who)) return MockResponse.problem(403, 'No tienes permiso para validar.');
    final t = _task(req);
    if (t == null) return MockResponse.problem(404, 'La tarea no existe.');
    if (t['status'] != 'done') return MockResponse.problem(409, 'La tarea no está terminada.');
    final note = req.json['note'] as String?;
    if (!approve && (note == null || note.trim().isEmpty)) {
      return MockResponse.problem(422, 'Escribe el motivo para devolverla.');
    }
    if (approve) {
      t['status'] = 'validated';
      t['validated_at'] = _iso();
      _event(t, 'validated', 'Validada', who.$2, note);
    } else {
      t['status'] = 'returned';
      t['finished_at'] = null;
      _event(t, 'returned', 'Devuelta para corregir', who.$2, note);
    }
    return MockResponse.json(_read(t));
  }

  MockResponse reschedule(MockRequest req) {
    final who = _who(req);
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    if (!_manager(who)) return MockResponse.problem(403, 'No tienes permiso para reasignar.');
    final t = _task(req);
    if (t == null) return MockResponse.problem(404, 'La tarea no existe.');
    final body = req.json;
    if ('${body['reason'] ?? ''}'.trim().isEmpty) {
      return MockResponse.problem(422, 'Escribe el motivo del cambio.');
    }
    final parts = <String>[];
    if (body.containsKey('assignee_id')) {
      final p = _team.where((p) => p.$1 == body['assignee_id']).firstOrNull;
      t['assignee_id'] = p?.$1;
      t['assignee_name'] = p?.$2;
      parts.add(p == null ? 'sin asignar' : 'a ${p.$2}');
    }
    for (final k in ['date', 'start', 'end']) {
      if (body[k] != null) t[k] = body[k];
    }
    if (body['date'] != null || body['start'] != null) {
      parts.add('para el ${t['date']} ${t['start']}');
    }
    _event(t, 'rescheduled', 'Reprogramada', who.$2, '${parts.join(' ')} · ${body['reason']}');
    return MockResponse.json(_read(t));
  }

  MockResponse accessInfo(MockRequest req) {
    final who = _who(req);
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final code = req.pathParams['id']!.replaceFirst('prop-', '').toUpperCase();
    return MockResponse.json({
      'property_id': req.pathParams['id'],
      'text':
          'Caja de llaves junto a la puerta · código 4821\n'
          'Alarma: 1397 y luego OFF\n'
          'Wifi: Argos-$code · clave laurel2026',
      'updated_at': _now().subtract(const Duration(days: 12)).toUtc().toIso8601String(),
      'viewed_at': _iso(),
    });
  }

  // ── Inventario ────────────────────────────────────────

  MockResponse myInventory(MockRequest req) {
    final who = _who(req);
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    return MockResponse.json(_mine(who));
  }

  Map<String, dynamic> _mine((String, String, String) who) {
    final custody = _custodyOf(who.$1);
    return {
      'custody': [
        for (final e in custody.entries)
          {
            'person_id': who.$1,
            'person_name': who.$2,
            'item_id': e.key,
            'item_name': _item_(e.key)!.$3,
            'category': _item_(e.key)!.$4,
            'returnable': _returnable(_item_(e.key)!.$4),
            'unit': _item_(e.key)!.$5,
            'qty': e.value,
            'since': _custodySince[who.$1] ?? _iso(),
          },
      ],
      'items': [
        for (final c in _catalog)
          {
            'id': c.$1,
            'sku': c.$2,
            'name': c.$3,
            'category': c.$4,
            'unit': c.$5,
            'min': 10,
            'total': _stock[c.$1],
            'returnable': _returnable(c.$4),
            'is_active': true,
          },
      ],
      'warehouses': [
        {'id': 'wh-central', 'name': 'Bodega central', 'property_id': null, 'property_code': null, 'is_active': true},
      ],
      'stock': [
        for (final c in _catalog) {'item_id': c.$1, 'warehouse_id': 'wh-central', 'qty': _stock[c.$1]},
      ],
      'requests': _requests[who.$1] ?? const [],
    };
  }

  MockResponse movement(MockRequest req) {
    final who = _who(req);
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final body = req.json;
    final id = '${body['item_id']}';
    final qty = (body['qty'] as num?)?.toDouble() ?? 0;
    final item = _item_(id);
    if (item == null) return MockResponse.problem(404, 'El artículo no existe.');
    if (qty <= 0) return MockResponse.problem(422, 'La cantidad debe ser mayor que cero.');
    final custody = _custodyOf(who.$1);
    switch (body['kind']) {
      case 'checkout':
        if ((_stock[id] ?? 0) < qty) {
          return MockResponse.problem(422, 'Solo quedan ${_num(_stock[id] ?? 0)} en la bodega.');
        }
        _stock[id] = _stock[id]! - qty;
        custody[id] = (custody[id] ?? 0) + qty;
      case 'return':
        if ((custody[id] ?? 0) < qty) {
          return MockResponse.problem(422, 'No tienes tantos en custodia.');
        }
        custody[id] = custody[id]! - qty;
        if (custody[id]! <= 0.0005) custody.remove(id);
        _stock[id] = (_stock[id] ?? 0) + qty;
      default:
        return MockResponse.problem(403, 'Ese movimiento lo hace el administrador.');
    }
    return MockResponse.noContent();
  }

  MockResponse restock(MockRequest req) {
    final who = _who(req);
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final lines = (req.json['items'] as List? ?? const []).whereType<Map>().toList();
    if (lines.isEmpty) return MockResponse.problem(422, 'Agrega al menos un artículo.');
    final request = {
      'id': 'rq-${_now().microsecondsSinceEpoch}',
      'status': 'pending',
      'person_id': who.$1,
      'person_name': who.$2,
      'property_id': req.json['property_id'],
      'property_code': '',
      'items': [
        for (final l in lines)
          {'item_id': l['item_id'], 'item_name': _item_('${l['item_id']}')?.$3 ?? '', 'qty': l['quantity']},
      ],
      'at': _iso(),
      'note': req.json['note'],
    };
    _requests.putIfAbsent(who.$1, () => []).insert(0, request);
    return MockResponse.json(request, status: 201);
  }

  // ── Armado de respuestas ─────────────────────────────

  Map<String, dynamic> _read(Map<String, dynamic> t) {
    final items = (t['items'] as List).cast<Map<String, dynamic>>();
    final sections = <String, List<int>>{};
    for (final i in items) {
      final s = sections.putIfAbsent('${i['section']}', () => [0, 0]);
      s[0]++;
      if (i['is_done'] == true) s[1]++;
    }
    final out = Map<String, dynamic>.from(t)..remove('items');
    out['checklist'] = [
      for (final e in sections.entries) {'name': e.key, 'total': e.value[0], 'done': e.value[1]},
    ];
    out['photos'] = items.fold<int>(0, (a, i) => a + _photos('${i['id']}').length);
    return out;
  }

  Map<String, dynamic> _detail(Map<String, dynamic> t, (String, String, String) who) {
    final custody = _custodyOf(who.$1);
    return {
      ..._read(t),
      'items': [for (final i in (t['items'] as List).cast<Map<String, dynamic>>()) _item(i)],
      'evidence': const [],
      'custody': [
        for (final e in custody.entries)
          {
            'item_id': e.key,
            'name': _item_(e.key)!.$3,
            'unit': _item_(e.key)!.$5,
            'category': _item_(e.key)!.$4,
            'returnable': _returnable(_item_(e.key)!.$4),
            'quantity': e.value,
          },
      ],
      'can_execute': t['assignee_id'] == who.$1,
      'can_manage': _manager(who),
    };
  }

  Map<String, dynamic> _item(Map<String, dynamic> i) => {...i, 'photos': _photos('${i['id']}')};

  List<Map<String, String>> _photos(String itemId) => [
    for (final e in mockStoredFiles.entries)
      if (e.value.entityType == 'task_checklist_item' && e.value.entityId == itemId)
        {'file_id': e.key, 'kind': e.value.kind, 'created_at': _iso()},
  ];

  void _event(Map<String, dynamic> t, String type, String text, String actor, [String? detail]) {
    (t['timeline'] as List).add({
      'at': _iso(),
      'type': type,
      'text': text,
      'actor': actor,
      'detail': ?detail,
    });
    t['updated_at'] = _iso();
  }

  String _iso() => _now().toUtc().toIso8601String();

  static (String, String, String, String, String, double)? _item_(String id) =>
      _catalog.where((c) => c.$1 == id).firstOrNull;

  static bool _returnable(String category) => category == 'linens' || category == 'keys';
}

/// Agenda simulada de [date] para [userId] con la forma de `TaskRead` más
/// sus puntos de checklist en `items` (pública para las pruebas).
List<Map<String, dynamic>> mockAgenda(
  DateTime date, {
  required DateTime today,
  required String userId,
  String? assigneeName,
}) {
  final day = DateTime(date.year, date.month, date.day);
  final ref = DateTime(today.year, today.month, today.day);
  if (day.weekday == DateTime.sunday) return [];

  final seed = day.day + day.month * 31 + userId.codeUnits.fold<int>(0, (a, b) => a + b);
  final count = 3 + seed % 2;
  final iso = TasksRemoteDataSource.isoDate(day);
  final relation = day.compareTo(ref); // <0 pasado, 0 hoy, >0 futuro
  final yesterday = day.add(const Duration(days: 1)) == ref;

  return [
    for (var i = 0; i < count; i++)
      _task(
        id: 'task-$userId-$iso-$i',
        number: 100 + (seed * 7 + i) % 900,
        iso: iso,
        day: day,
        index: i,
        property: _properties[(seed + i) % _properties.length],
        window: _windows[i],
        relation: relation,
        yesterday: yesterday,
        type: i == 2 && seed.isEven
            ? 'inspection'
            : const ['checkout_cleaning', 'deep_cleaning', 'touch_up'][(seed + i) % 3],
        notes: _notes[(seed + i) % _notes.length],
        userId: userId,
        assigneeName: assigneeName ?? 'Tú',
      ),
  ];
}

Map<String, dynamic> _task({
  required String id,
  required int number,
  required String iso,
  required DateTime day,
  required int index,
  required (String, String, String, double, double) property,
  required (String, String) window,
  required int relation,
  required bool yesterday,
  required String type,
  required String? notes,
  required String userId,
  required String assigneeName,
}) {
  // Hoy: la 1.ª terminada, la 2.ª en progreso, la 3.ª retrasada, el resto
  // pendientes. Ayer, terminadas sin validar; antes, validadas.
  final status = relation < 0
      ? (yesterday ? 'done' : 'validated')
      : relation > 0
      ? 'pending'
      : switch (index) {
          0 => 'done',
          1 => 'in_progress',
          _ => 'pending',
        };
  final late = relation == 0 && index == 2;
  DateTime at(String hhmm, int minutes) => DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(hhmm.substring(0, 2)),
    int.parse(hhmm.substring(3)),
  ).add(Duration(minutes: minutes));
  String utc(DateTime t) => t.toUtc().toIso8601String();

  final template = type == 'inspection' ? _inspectionChecklist : _cleaningChecklist;
  final started = status == 'pending' ? null : at(window.$1, 4);
  final finished = status == 'done' || status == 'validated' ? at(window.$2, -18) : null;
  final items = [
    for (final (pos, (section, text, photo, pair)) in template.indexed)
      {
        'id': '$id-i$pos',
        'section': section,
        'position': pos,
        'text': text,
        // Lo ya terminado no exige fotos (no hay en memoria).
        'requires_photo': photo && finished == null,
        'requires_before_after': pair && finished == null,
        'is_done': finished != null || (status == 'in_progress' && pos.isEven && !photo && !pair),
        'done_at': null,
        'notes': null,
      },
  ];
  final timeline = <Map<String, dynamic>>[
    {
      'at': utc(at(window.$1, -20 * 60)),
      'type': 'created',
      'text': 'Programada',
      'actor': 'Sofía Méndez',
      'detail': 'Ventana ${window.$1} – ${window.$2}',
    },
    {'at': utc(at(window.$1, -20 * 60 + 1)), 'type': 'assigned', 'text': 'Asignada', 'actor': 'Sofía Méndez', 'detail': 'a $assigneeName'},
    if (started != null) {'at': utc(started), 'type': 'started', 'text': 'Iniciada', 'actor': assigneeName},
    if (late) {'at': utc(at(window.$1, 15)), 'type': 'late', 'text': 'Marcada como retrasada', 'actor': 'Sistema'},
    if (finished != null) {'at': utc(finished), 'type': 'finished', 'text': 'Terminada', 'actor': assigneeName},
    if (status == 'validated')
      {'at': utc(finished!.add(const Duration(hours: 2))), 'type': 'validated', 'text': 'Validada', 'actor': 'Sofía Méndez'},
  ];

  return {
    'id': id,
    'number': number,
    'type': type,
    'status': status,
    'priority': type == 'checkout_cleaning' ? 'high' : 'normal',
    'property_id': 'prop-${property.$1.toLowerCase()}',
    'property_code': property.$1,
    'property_name': property.$2,
    'property_address': property.$3,
    'lat': property.$4,
    'lng': property.$5,
    'building_id': null,
    'building_name': null,
    'assignee_id': userId,
    'assignee_name': assigneeName,
    'date': iso,
    'start': window.$1,
    'end': window.$2,
    'late': late,
    'photos': 0,
    'started_at': started == null ? null : utc(started),
    'finished_at': finished == null ? null : utc(finished),
    'validated_at': status == 'validated' ? utc(finished!.add(const Duration(hours: 2))) : null,
    'reservation_id': type == 'checkout_cleaning' ? 'res-$id' : null,
    'reservation_code': type == 'checkout_cleaning' ? 'R-${2400 + number}' : null,
    'ticket_id': null,
    'notes': notes,
    'completion_notes': null,
    'consumption': <Map<String, dynamic>>[],
    'discrepancy': null,
    'timeline': timeline,
    'created_at': utc(at(window.$1, -20 * 60)),
    'updated_at': utc(finished ?? started ?? at(window.$1, -20 * 60)),
    'items': items,
  };
}

String _num(double v) => v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(2);

Map<String, dynamic>? _claims(String? token) {
  const prefix = 'mock-at.';
  if (token == null || !token.startsWith(prefix)) return null;
  try {
    final payload = base64Url.normalize(token.substring(prefix.length));
    return Map<String, dynamic>.from(jsonDecode(utf8.decode(base64Url.decode(payload))) as Map);
  } catch (_) {
    return null;
  }
}
