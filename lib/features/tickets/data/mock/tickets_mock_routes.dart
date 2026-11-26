import 'package:argos_app/core/network/mock/mock_backend.dart';
import 'package:argos_app/features/notifications/data/mock/notifications_mock_routes.dart';
import 'package:argos_app/features/tasks/data/mock/tasks_mock_routes.dart';
import 'package:argos_app/features/uploads/data/mock/files_mock_routes.dart';

/// Rutas simuladas de incidencias (fase03 §4, `TicketRead`/`TicketDetail`):
/// lista (mías, reportadas o todas), detalle, reportar, iniciar y resolver,
/// más las propiedades y los activos para el formulario.
void registerTicketsMockRoutes(MockBackend backend, {DateTime Function()? clock}) {
  final api = _MockTicketsApi(clock ?? DateTime.now);
  backend
    ..on('GET', '/properties', api.properties)
    ..on('GET', '/assets', api.assets)
    ..on('GET', '/tickets', api.list)
    ..on('POST', '/tickets', api.create)
    ..on('GET', '/tickets/{id}', api.detail)
    ..on('POST', '/tickets/{id}/start', api.start)
    ..on('POST', '/tickets/{id}/resolve', api.resolve);
}

const _assets = [
  // (propiedad, id, nombre, categoría, ubicación)
  (0, 'as-lau-lav', 'Lavamanos del baño principal', 'plumbing', 'Baño principal'),
  (0, 'as-lau-cal', 'Calentador de agua', 'water', 'Cuarto de pilas'),
  (1, 'as-oli-ac', 'Aire acondicionado de la sala', 'hvac', 'Sala'),
  (1, 'as-oli-ref', 'Refrigeradora', 'appliance', 'Cocina'),
  (2, 'as-ced-luz', 'Iluminación del pasillo', 'electrical', 'Pasillo'),
  (3, 'as-pin-com', 'Juego de comedor', 'furniture', 'Comedor'),
  (3, 'as-pin-tv', 'Televisor', 'appliance', 'Sala'),
];

class _MockTicketsApi {
  _MockTicketsApi(this._now) {
    final p = mockPropertyOptions;
    _add('tk-41', 41, 0, 'as-lau-lav', 'Fuga en el lavamanos', 'Gotea debajo del mueble; puse un balde.', 'high',
        'assigned', 'u-ana', 'Ana López', 'u-luis', 'Luis Pérez', const Duration(hours: 26), photos: 2);
    _add('tk-42', 42, 1, 'as-oli-ac', 'Aire acondicionado no enfría', 'Enciende pero sale aire caliente. Huéspedes llegan hoy.',
        'critical', 'in_progress', 'u-sofia', 'Sofía Méndez', 'u-luis', 'Luis Pérez', const Duration(hours: 7), photos: 1);
    _add('tk-38', 38, 2, 'as-ced-luz', 'Cambiar foco del pasillo', 'El foco del pasillo parpadea.', 'low', 'resolved',
        'u-ana', 'Ana López', 'u-luis', 'Luis Pérez', const Duration(days: 2),
        resolution: 'Cambié el foco por uno LED de 9 W.', cost: 35);
    _add('tk-43', 43, 3, 'as-pin-com', 'Silla del comedor rota', 'Una pata está floja; no es segura.', 'medium', 'open',
        'u-ana', 'Ana López', null, null, const Duration(minutes: 30));
    _seq = 43;
    assert(p.length >= 4);
  }

  final DateTime Function() _now;
  final _tickets = <String, Map<String, dynamic>>{};
  var _seq = 0;

  void _add(
    String id,
    int number,
    int property,
    String? asset,
    String title,
    String description,
    String urgency,
    String status,
    String reporterId,
    String reporterName,
    String? assigneeId,
    String? assigneeName,
    Duration ago, {
    int photos = 0,
    String? resolution,
    double? cost,
  }) {
    final p = mockPropertyOptions[property];
    final a = _assets.where((x) => x.$2 == asset).firstOrNull;
    final created = _now().subtract(ago).toUtc();
    final events = <Map<String, dynamic>>[
      _event('created', reporterId, reporterName, created, {}),
      if (assigneeName != null)
        _event('assigned', 'u-sofia', 'Sofía Méndez', created.add(const Duration(minutes: 20)), {'assignee_name': assigneeName}),
      if (status == 'in_progress' || status == 'resolved')
        _event('started', assigneeId, assigneeName, created.add(const Duration(hours: 1)), {}),
      if (status == 'resolved')
        _event('resolved', assigneeId, assigneeName, created.add(const Duration(hours: 3)), {'resolution': resolution}),
    ];
    _tickets[id] = {
      'id': id,
      'number': number,
      'property_id': p.$1,
      'property_code': p.$2,
      'property_name': p.$3,
      'building_id': null,
      'building_name': null,
      'asset_id': a?.$2,
      'asset_name': a?.$3,
      'asset_category': a?.$4,
      'plan_id': null,
      'plan_name': null,
      'title': title,
      'description': description,
      'urgency': urgency,
      'status': status,
      'reported_by_user_id': reporterId,
      'reporter_name': reporterName,
      'assigned_to': assigneeId,
      'assignee_name': assigneeName,
      'vendor_id': null,
      'vendor_name': null,
      'task_id': null,
      'resolution': resolution,
      'cost': cost,
      'photos_count': photos,
      'resolved_at': status == 'resolved' ? created.add(const Duration(hours: 3)).toIso8601String() : null,
      'closed_at': null,
      'created_at': created.toIso8601String(),
      'updated_at': created.toIso8601String(),
      'events': events,
      'photos': <Map<String, dynamic>>[
        for (var i = 0; i < photos; i++)
          {
            'file_id': '$id-ph-$i',
            'stage': 'report',
            'url': 'https://picsum.photos/seed/$id-$i/800/600',
            'created_at': created.toIso8601String(),
          },
      ],
    };
  }

  Map<String, dynamic> _event(String type, String? actorId, String? actorName, DateTime at, Map<String, dynamic> data) => {
    'id': 'ev-${at.microsecondsSinceEpoch}-$type',
    'type': type,
    'actor_user_id': actorId,
    'actor_name': actorName,
    'data': data,
    'created_at': at.toIso8601String(),
  };

  static Map<String, dynamic> _read(Map<String, dynamic> t) =>
      Map<String, dynamic>.from(t)..remove('events')..remove('photos');

  bool _sees((String, String, String) who, Map<String, dynamic> t) => switch (who.$3) {
    'admin' || 'supervisor' => true,
    'maintenance' => t['assigned_to'] == who.$1 || t['reported_by_user_id'] == who.$1,
    _ => t['reported_by_user_id'] == who.$1,
  };

  MockResponse properties(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    return MockResponse.json({
      'items': [
        for (final p in mockPropertyOptions) {'id': p.$1, 'code': p.$2, 'name': p.$3, 'is_active': true},
      ],
      'next_cursor': null,
    });
  }

  MockResponse assets(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    if (who.$3 == 'security' || who.$3 == 'owner') {
      return MockResponse.problem(403, 'No tienes permiso para ver activos.');
    }
    final property = req.query['property_id'];
    final ids = mockPropertyOptions.map((p) => p.$1).toList();
    return MockResponse.json({
      'items': [
        for (final a in _assets)
          if (property == null || ids[a.$1] == property)
            {'id': a.$2, 'name': a.$3, 'category': a.$4, 'location': a.$5, 'property_id': ids[a.$1], 'status': 'operational'},
      ],
      'next_cursor': null,
    });
  }

  MockResponse list(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final mine = req.query['mine'] == 'true';
    final items = _tickets.values
        .where((t) => mine ? t['assigned_to'] == who.$1 : _sees(who, t))
        .map(_read)
        .toList()
      ..sort((a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'));
    return MockResponse.json({'items': items, 'next_cursor': null});
  }

  MockResponse detail(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final t = _tickets[req.pathParams['id']];
    if (t == null || !_sees(who, t)) return MockResponse.problem(404, 'La incidencia no existe.');
    return MockResponse.json(t);
  }

  MockResponse create(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final body = req.json;
    final index = mockPropertyOptions.indexWhere((p) => p.$1 == body['property_id']);
    if (index < 0) return MockResponse.problem(404, 'La propiedad no existe.');
    final title = '${body['title'] ?? ''}'.trim();
    if (title.length < 3) return MockResponse.problem(422, 'El título necesita al menos 3 letras.');
    final photoIds = [for (final id in body['photo_file_ids'] as List? ?? const []) '$id'];
    if (photoIds.any((id) => !mockStoredFiles.containsKey(id))) {
      return MockResponse.problem(422, 'Alguna foto no terminó de subir.');
    }
    final id = 'tk-${++_seq}';
    _add(id, _seq, index, body['asset_id'] as String?, title, '${body['description'] ?? ''}', '${body['urgency']}', 'open',
        who.$1, who.$2, null, null, Duration.zero, photos: photoIds.length);
    final t = _tickets[id]!;
    // Lo ve supervisión al instante (si alguien de supervisión usa la app).
    for (final user in ['u-sofia', 'u-carlos']) {
      if (user == who.$1) continue;
      mockNotify?.call(user, {
        'type': 'ticket_created',
        'title': 'Incidencia #${t['number']}: $title',
        'body': '${t['property_code']} · ${t['urgency']} · reportó ${who.$2}',
        'data': {'ticket_id': id, 'urgency': t['urgency'], 'app_route': '/tickets/$id'},
      });
    }
    return MockResponse.json(t, status: 201);
  }

  MockResponse start(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final t = _tickets[req.pathParams['id']];
    if (t == null) return MockResponse.problem(404, 'La incidencia no existe.');
    if (t['assigned_to'] != null && t['assigned_to'] != who.$1) {
      return MockResponse.problem(403, 'La incidencia es de otra persona.');
    }
    if (t['status'] != 'open' && t['status'] != 'assigned') {
      return MockResponse.problem(422, 'La incidencia ya se inició.');
    }
    t['status'] = 'in_progress';
    t['assigned_to'] = who.$1;
    t['assignee_name'] = who.$2;
    (t['events'] as List).add(_event('started', who.$1, who.$2, _now().toUtc(), {}));
    return MockResponse.json(t);
  }

  MockResponse resolve(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final t = _tickets[req.pathParams['id']];
    if (t == null) return MockResponse.problem(404, 'La incidencia no existe.');
    if (t['status'] != 'in_progress') return MockResponse.problem(422, 'Primero inicia la incidencia.');
    final resolution = '${req.json['resolution'] ?? ''}'.trim();
    if (resolution.length < 3) return MockResponse.problem(422, 'Cuenta qué se hizo.');
    final now = _now().toUtc();
    final photoIds = [for (final id in req.json['photo_file_ids'] as List? ?? const []) '$id'];
    t
      ..['status'] = 'resolved'
      ..['resolution'] = resolution
      ..['cost'] = req.json['cost']
      ..['resolved_at'] = now.toIso8601String();
    (t['events'] as List).add(_event('resolved', who.$1, who.$2, now, {'resolution': resolution}));
    (t['photos'] as List).addAll(<Map<String, dynamic>>[
      for (final (i, id) in photoIds.indexed)
        {'file_id': id, 'stage': 'resolution', 'url': 'https://picsum.photos/seed/$id-$i/800/600', 'created_at': now.toIso8601String()},
    ]);
    final reporter = t['reported_by_user_id'] as String?;
    if (reporter != null && reporter != who.$1) {
      mockNotify?.call(reporter, {
        'type': 'ticket_resolved',
        'title': 'Resolvieron tu reporte #${t['number']}',
        'body': '${t['property_code']} · ${t['title']}',
        'data': {'ticket_id': t['id'], 'app_route': '/tickets/${t['id']}'},
      });
    }
    return MockResponse.json(t);
  }
}
