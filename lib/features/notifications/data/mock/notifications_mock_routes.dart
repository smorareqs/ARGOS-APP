import 'dart:async';

import 'package:argos_app/core/network/mock/mock_backend.dart';
import 'package:argos_app/core/realtime/realtime_client.dart';
import 'package:argos_app/features/tasks/data/datasources/tasks_remote_datasource.dart';
import 'package:argos_app/features/tasks/data/mock/tasks_mock_routes.dart';

/// Rutas simuladas de avisos (fase03 §4): bandeja por usuario según su rol,
/// leer, leer todos, preferencias, dispositivos y el panel de alertas. En
/// la app con `ARGOS_MOCK=true`, 20 s después de abrir la bandeja llega un
/// aviso nuevo "por tiempo real" para ver la insignia y el aviso en pantalla.
void registerNotificationsMockRoutes(
  MockBackend backend, {
  DateTime Function()? clock,
  bool liveDemo = const bool.fromEnvironment('ARGOS_MOCK'),
}) {
  final api = _MockNotificationsApi(clock ?? DateTime.now, liveDemo: liveDemo);
  backend
    ..on('GET', '/notifications/preferences', api.preferences)
    ..on('PUT', '/notifications/preferences', api.savePreferences)
    ..on('POST', '/notifications/read-all', api.readAll)
    ..on('GET', '/notifications', api.list)
    ..on('POST', '/notifications/{id}/read', api.read)
    ..on('POST', '/devices', api.registerDevice)
    ..on('DELETE', '/devices/{token}', api.removeDevice)
    ..on('GET', '/alerts/summary', api.alertsSummary)
    ..on('GET', '/alerts', api.alerts)
    ..on('POST', '/alerts/{id}/ack', api.ackAlert);
}

/// Mock: agrega un aviso a la bandeja de [userId] y lo publica por el canal.
void Function(String userId, Map<String, dynamic> notice)? mockNotify;

const _labels = {
  'task_assigned': 'Tareas asignadas o reasignadas',
  'task_rescheduled': 'Cambios de día u hora de mis tareas',
  'task_reminder': 'Recordatorio 30 min antes',
  'task_late': 'Tareas retrasadas del equipo',
  'task_completed': 'Tareas terminadas por validar',
  'task_validated': 'Mis tareas validadas',
  'task_returned': 'Mis tareas devueltas',
  'ticket_created': 'Incidencias nuevas',
  'ticket_assigned': 'Incidencias asignadas',
  'ticket_resolved': 'Incidencias resueltas',
  'maintenance_due': 'Preventivos por hacer',
  'low_stock': 'Stock bajo',
  'discrepancy_open': 'Diferencias de inventario',
  'checkout_alarm': 'Alarmas de check-out',
  'payslip_available': 'Boletas de pago',
  'chat_message': 'Mensajes de chat',
};

const _critical = {'task_assigned', 'checkout_alarm'};

class _MockNotificationsApi {
  _MockNotificationsApi(this._now, {required this.liveDemo}) {
    mockNotify = (user, n) => _push(user, n);
  }

  final DateTime Function() _now;
  final bool liveDemo;
  final _inbox = <String, List<Map<String, dynamic>>>{};
  final _prefs = <String, Map<String, (bool, bool)>>{};
  final _demoSent = <String>{};
  final _devices = <String, String>{};
  var _seq = 0;

  List<Map<String, dynamic>> _of((String, String, String) who) =>
      _inbox.putIfAbsent(who.$1, () => _seed(who));

  Map<String, dynamic> _n(String type, String title, String body, Duration ago, Map<String, dynamic> data,
      {bool read = false}) {
    final at = _now().subtract(ago).toUtc();
    return {
      'id': 'ntf-${++_seq}',
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'read_at': read ? at.add(const Duration(minutes: 3)).toIso8601String() : null,
      'created_at': at.toIso8601String(),
    };
  }

  List<Map<String, dynamic>> _seed((String, String, String) who) {
    final today = TasksRemoteDataSource.isoDate(_now());
    final task = 'task-${who.$1}-$today-1';
    final p = mockPropertyOptions;
    switch (who.$3) {
      case 'maintenance':
        return [
          _n('ticket_assigned', 'Te asignaron la incidencia #42', '${p[1].$2} · Aire acondicionado no enfría · crítica',
              const Duration(minutes: 12), {'ticket_id': 'tk-42', 'urgency': 'critical', 'app_route': '/tickets/tk-42'}),
          _n('maintenance_due', 'Preventivo por hacer', '${p[2].$2} · Limpieza de filtros del aire · vence mañana',
              const Duration(hours: 3), {'app_route': '/tickets'}),
          _n('ticket_created', 'Incidencia #41: Fuga en el lavamanos', '${p[0].$2} · alta · reportó Ana López',
              const Duration(hours: 26), {'ticket_id': 'tk-41', 'urgency': 'high', 'app_route': '/tickets/tk-41'},
              read: true),
        ];
      case 'supervisor' || 'admin':
        return [
          _n('task_completed', 'Limpieza de salida terminada', '${p[0].$2} · Ana López · lista para validar',
              const Duration(minutes: 8), {'task_id': 'task-u-ana-$today-0', 'app_route': '/tasks/task-u-ana-$today-0'}),
          _n('task_late', 'Tarea retrasada', '${p[3].$2} · Marta Díaz no ha iniciado (ventana 09:30)',
              const Duration(minutes: 40), {'app_route': '/home/team'}),
          _n('discrepancy_open', 'Diferencia de inventario', 'Ana López · Toalla de baño: faltan 2 (esperado 6, devolvió 4)',
              const Duration(hours: 2), {'app_route': '/inventory'}),
          _n('alert', 'Stock bajo: Jabón de tocador', 'Quedan 4 unidades (mínimo 10)', const Duration(hours: 5),
              {'severity': 'medium', 'app_route': '/alerts'}),
          _n('reservation_requested', 'Reserva nueva del sitio web', '${p[1].$2} · 2 noches desde el viernes',
              const Duration(hours: 20), {'app_route': '/reservations/res-demo'}, read: true),
        ];
      case 'security':
        return [
          _n('checkout_alarm', 'Check-out en 30 min', '${p[1].$2} · Familia Rojas · revisar llaves y parqueo',
              const Duration(minutes: 5), {'app_route': '/home/alarms'}),
        ];
      default:
        return [
          _n('task_assigned', 'Nueva tarea: limpieza de salida', '${p[1].$2} · hoy 09:30–12:00',
              const Duration(minutes: 15), {'task_id': task, 'app_route': '/tasks/$task'}),
          _n('task_reminder', 'Tu tarea empieza en 30 min', '${p[1].$2} · 09:30', const Duration(minutes: 50),
              {'task_id': task, 'app_route': '/tasks/$task'}),
          _n('ticket_resolved', 'Resolvieron tu reporte #38', '${p[2].$2} · Cambiar foco del pasillo',
              const Duration(hours: 23), {'ticket_id': 'tk-38', 'app_route': '/tickets/tk-38'}, read: true),
          _n('task_validated', 'Tu limpieza fue validada', '${p[0].$2} · ¡Buen trabajo!', const Duration(days: 1, hours: 2),
              {'app_route': '/home/week'}, read: true),
        ];
    }
  }

  void _push(String userId, Map<String, dynamic> notice) {
    final at = _now().toUtc().toIso8601String();
    final n = {
      'id': 'ntf-${++_seq}',
      'read_at': null,
      'created_at': at,
      'data': const <String, dynamic>{},
      ...notice,
    };
    _inbox.putIfAbsent(userId, () => []).insert(0, n);
    mockRealtimeBus.add(RealtimeMessage('notification', n));
  }

  void _demo((String, String, String) who) {
    if (!liveDemo || !_demoSent.add(who.$1)) return;
    Timer(const Duration(seconds: 20), () {
      final p = mockPropertyOptions;
      final today = TasksRemoteDataSource.isoDate(_now());
      switch (who.$3) {
        case 'maintenance':
          _push(who.$1, {
            'type': 'ticket_assigned',
            'title': 'Te asignaron la incidencia #43',
            'body': '${p[3].$2} · Silla del comedor rota · media',
            'data': {'ticket_id': 'tk-43', 'app_route': '/tickets/tk-43'},
          });
        case 'supervisor' || 'admin':
          _push(who.$1, {
            'type': 'ticket_created',
            'title': 'Incidencia #43: Silla del comedor rota',
            'body': '${p[3].$2} · media · reportó Ana López',
            'data': {'ticket_id': 'tk-43', 'app_route': '/tickets/tk-43'},
          });
        default:
          _push(who.$1, {
            'type': 'task_rescheduled',
            'title': 'Cambió tu tarea',
            'body': 'Limpieza de salida en ${p[2].$2} ahora es hoy 13:30–15:30: el huésped sale tarde',
            'data': {'app_route': '/tasks/task-${who.$1}-$today-2'},
          });
      }
    });
  }

  MockResponse list(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final all = _of(who);
    _demo(who);
    final unreadOnly = req.query['unread'] == 'true';
    final items = unreadOnly ? all.where((n) => n['read_at'] == null).toList() : all;
    return MockResponse.json({
      'items': items,
      'next_cursor': null,
      'unread': all.where((n) => n['read_at'] == null).length,
    });
  }

  MockResponse read(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final id = req.pathParams['id'];
    final n = _of(who).where((n) => n['id'] == id).firstOrNull;
    if (n == null) return MockResponse.problem(404, 'El aviso no existe.');
    n['read_at'] ??= _now().toUtc().toIso8601String();
    return MockResponse.noContent();
  }

  MockResponse readAll(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final at = _now().toUtc().toIso8601String();
    for (final n in _of(who)) {
      n['read_at'] ??= at;
    }
    return MockResponse.noContent();
  }

  List<Map<String, dynamic>> _prefsOf(String user) {
    final mine = _prefs[user] ?? const {};
    final types = _labels.keys.toList()..sort();
    return [
      for (final t in types)
        {
          'type': t,
          'label': _labels[t],
          'push': _critical.contains(t) || (mine[t]?.$1 ?? true),
          'email': _critical.contains(t) || (mine[t]?.$2 ?? true),
          'critical': _critical.contains(t),
        },
    ];
  }

  MockResponse preferences(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    return MockResponse.json(_prefsOf(who.$1));
  }

  MockResponse savePreferences(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final mine = _prefs.putIfAbsent(who.$1, () => {});
    for (final it in req.json['items'] as List? ?? const []) {
      if (it is! Map || !_labels.containsKey(it['type'])) {
        return MockResponse.problem(422, 'Tipo de aviso desconocido.');
      }
      if (_critical.contains(it['type'])) continue;
      mine['${it['type']}'] = (it['push'] == true, it['email'] == true);
    }
    return MockResponse.json(_prefsOf(who.$1));
  }

  MockResponse registerDevice(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final token = '${req.json['token'] ?? ''}'.trim();
    if (token.isEmpty) return MockResponse.problem(422, 'Falta el token del dispositivo.');
    _devices[token] = who.$1;
    return MockResponse.noContent();
  }

  MockResponse removeDevice(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final token = Uri.decodeComponent(req.pathParams['token']!);
    if (_devices[token] != who.$1) return MockResponse.problem(404, 'El dispositivo no está registrado.');
    _devices.remove(token);
    return MockResponse.noContent();
  }

  // ── Alertas (panel del supervisor) ─────────────────────

  late final _alerts = <Map<String, dynamic>>[
    _alert('al-1', 'task_late', 'high', 'Marta Díaz no ha iniciado la limpieza de las 09:30', 3, const Duration(minutes: 40)),
    _alert('al-2', 'low_stock', 'medium', 'Jabón de tocador: quedan 4 (mínimo 10)', null, const Duration(hours: 5)),
    _alert('al-3', 'asset_failure', 'high', 'Aire acondicionado de la sala fuera de servicio', 1, const Duration(hours: 7)),
    _alert('al-4', 'discrepancy_open', 'medium', 'Toalla de baño: faltan 2 en la custodia de Ana López', 0, const Duration(hours: 2)),
  ];

  Map<String, dynamic> _alert(String id, String type, String severity, String message, int? property, Duration ago) => {
    'id': id,
    'type': type,
    'severity': severity,
    'status': 'active',
    'message': message,
    'property_code': property == null ? null : mockPropertyOptions[property].$2,
    'created_at': _now().subtract(ago).toUtc().toIso8601String(),
    'acknowledged_at': null,
    'acknowledged_by_name': null,
  };

  MockResponse alertsSummary(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final open = _alerts.where((a) => a['status'] != 'resolved').toList();
    final types = <String, int>{};
    for (final a in open) {
      types['${a['type']}'] = (types['${a['type']}'] ?? 0) + 1;
    }
    return MockResponse.json({
      'open': open.length,
      'high': open.where((a) => a['severity'] == 'high').length,
      'fresh': open.where((a) => a['status'] == 'active').length,
      'by_type': [
        for (final e in types.entries) {'type': e.key, 'open': e.value, 'high': 0, 'fresh': 0},
      ],
    });
  }

  MockResponse alerts(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    return MockResponse.json({
      'items': _alerts.where((a) => a['status'] != 'resolved').toList(),
      'next_cursor': null,
    });
  }

  MockResponse ackAlert(MockRequest req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'Token inválido o expirado.');
    final a = _alerts.where((a) => a['id'] == req.pathParams['id']).firstOrNull;
    if (a == null) return MockResponse.problem(404, 'La alerta no existe.');
    a['status'] = 'acknowledged';
    a['acknowledged_at'] = _now().toUtc().toIso8601String();
    a['acknowledged_by_name'] = who.$2;
    return MockResponse.json(a);
  }
}
