import 'dart:math';

import 'package:argos_app/core/network/mock/mock_backend.dart';
import 'package:argos_app/features/tasks/data/mock/tasks_mock_routes.dart';

/// Rutas simuladas de la fase 5: marcaje (`/attendance/*`), mis boletas
/// (`/payroll/me`), disciplina (`/disciplinary/me`) y métricas
/// (`/metrics/me`, `/metrics/team`, `/metrics/report`).
///
/// Cada persona de prueba tiene marcajes de lunes a viernes del mes pasado y
/// de este (hasta ayer); hoy no ha marcado. `ana@argos.demo` tiene una
/// llamada de atención por confirmar.
void registerHrMockRoutes(MockBackend backend, {DateTime Function()? clock}) {
  final api = _MockHr(clock ?? DateTime.now);
  backend
    ..on('GET', '/attendance/me', api.auth(api.myAttendance))
    ..on('POST', '/attendance/clock-in', api.auth((req, who) => api.clock(req, who, entering: true)))
    ..on('POST', '/attendance/clock-out', api.auth((req, who) => api.clock(req, who, entering: false)))
    ..on('GET', '/attendance/day', api.auth(api.day))
    ..on('GET', '/payroll/me', api.auth(api.payslips))
    ..on('GET', '/disciplinary/me', api.auth(api.disciplinary))
    ..on('POST', '/disciplinary/{action_id}/acknowledge', api.auth(api.acknowledge))
    ..on('GET', '/metrics/me', api.auth(api.myMetrics))
    ..on('GET', '/metrics/team', api.auth(api.team))
    ..on('GET', '/metrics/report', api.auth(api.report));
}

typedef _Who = (String, String, String);

class _Punch {
  _Punch(this.id, this.userId, this.name, this.clockIn, {this.clockOut, this.lat, this.lng});

  final String id;
  final String userId;
  final String name;
  DateTime clockIn;
  DateTime? clockOut;
  double? lat;
  double? lng;

  int? get minutes => clockOut?.difference(clockIn).inMinutes;
}

class _MockHr {
  _MockHr(this._now);

  final DateTime Function() _now;
  final _punches = <String, List<_Punch>>{};
  final _acks = <String, (DateTime, String?)>{};
  var _seq = 0;

  MockHandler auth(MockResponse Function(MockRequest, _Who) fn) => (req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'La sesión venció.');
    return fn(req, who);
  };

  static String _day(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Marcajes de lunes a viernes desde el mes pasado hasta ayer (con alguna
  /// llegada tarde y alguna ausencia, siempre iguales para la misma persona).
  List<_Punch> _of(_Who who) => _punches.putIfAbsent(who.$1, () {
    final now = _now();
    final rnd = Random(who.$1.hashCode);
    final out = <_Punch>[];
    for (
      var d = DateTime(now.year, now.month - 1, 1);
      d.isBefore(DateTime(now.year, now.month, now.day));
      d = d.add(const Duration(days: 1))
    ) {
      if (d.weekday > 5 || rnd.nextInt(18) == 0) continue;
      final lateBy = rnd.nextInt(10) == 0 ? 14 + rnd.nextInt(20) : rnd.nextInt(9) - 4;
      final cin = DateTime(d.year, d.month, d.day, 7).add(Duration(minutes: lateBy));
      final cout = DateTime(d.year, d.month, d.day, 15).add(Duration(minutes: rnd.nextInt(25) - 5));
      out.add(_Punch('att-${who.$1}-${_seq++}', who.$1, who.$2, cin, clockOut: cout, lat: 14.5986, lng: -90.5094));
    }
    return out;
  });

  Map<String, dynamic> _json(_Punch p) => {
    'id': p.id,
    'employee_id': 'emp-${p.userId}',
    'user_id': p.userId,
    'employee_name': p.name,
    'date': _day(p.clockIn),
    'clock_in_at': p.clockIn.toUtc().toIso8601String(),
    'clock_out_at': p.clockOut?.toUtc().toIso8601String(),
    'in_lat': p.lat,
    'in_lng': p.lng,
    'source': 'app',
    'autoclosed': false,
    'edit_reason': null,
    'worked_minutes': p.minutes,
    'late': p.clockIn.hour * 60 + p.clockIn.minute > 7 * 60 + 10,
    'off_schedule': false,
  };

  bool _employee(_Who who) => who.$3 != 'owner';

  MockResponse myAttendance(MockRequest req, _Who who) {
    if (!_employee(who)) return MockResponse.problem(422, 'Tu usuario no tiene ficha de colaborador.');
    final now = _now();
    final month = req.query['month'] ?? '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final list = _of(who);
    final items = [
      for (final p in list.reversed)
        if (_day(p.clockIn).startsWith(month)) p,
    ];
    final open = list.where((p) => p.clockOut == null).firstOrNull;
    final days = {for (final p in items) _day(p.clockIn)};
    return MockResponse.json({
      'employee_id': 'emp-${who.$1}',
      'month': month,
      'open': open == null ? null : _json(open),
      'items': [for (final p in items) _json(p)],
      'worked_minutes': items.fold<int>(0, (a, p) => a + (p.minutes ?? 0)),
      'days_worked': days.length,
      'late_count': items.where((p) => _json(p)['late'] == true).length,
      'schedule': [
        for (var w = 1; w <= 5; w++) {'weekday': w, 'starts_at': '07:00', 'ends_at': '15:00'},
      ],
    });
  }

  MockResponse clock(MockRequest req, _Who who, {required bool entering}) {
    if (!_employee(who)) return MockResponse.problem(422, 'Tu usuario no tiene ficha de colaborador.');
    final b = req.json;
    final lat = b['lat'], lng = b['lng'];
    if (lat is! num || lng is! num || (lat == 0 && lng == 0)) {
      return MockResponse.problem(422, 'Activa la ubicación para marcar.');
    }
    final list = _of(who);
    final open = list.where((p) => p.clockOut == null).firstOrNull;
    final now = _now();
    if (entering) {
      if (open != null) return MockResponse.problem(409, 'Ya marcaste tu entrada.');
      final p = _Punch('att-${who.$1}-${_seq++}', who.$1, who.$2, now, lat: lat.toDouble(), lng: lng.toDouble());
      list.add(p);
      return MockResponse.json(_json(p), status: 201);
    }
    if (open == null) return MockResponse.problem(409, 'No tienes una entrada abierta. Marca tu entrada primero.');
    open.clockOut = now.isBefore(open.clockIn) ? open.clockIn : now;
    return MockResponse.json(_json(open));
  }

  MockResponse day(MockRequest req, _Who who) {
    if (who.$3 != 'supervisor' && who.$3 != 'admin') return MockResponse.problem(403, 'No tienes permiso.');
    final date = req.query['date'] ?? _day(_now());
    final out = <Map<String, dynamic>>[];
    // Lo que marcó quien tiene la sesión y un par del equipo de limpieza.
    for (final p in _punches.values.expand((l) => l)) {
      if (_day(p.clockIn) == date) out.add(_json(p));
    }
    if (date == _day(_now())) {
      final n = _now();
      final today = DateTime(n.year, n.month, n.day);
      if (!out.any((r) => r['user_id'] == 'u-ana')) {
        out.add(_json(_Punch('att-demo-ana', 'u-ana', 'Ana López', today.add(const Duration(hours: 6, minutes: 56)))));
      }
      out.add(_json(_Punch('att-demo-marta', 'u-marta', 'Marta Díaz', today.add(const Duration(hours: 7, minutes: 21)))));
    }
    return MockResponse.json(out);
  }

  MockResponse payslips(MockRequest req, _Who who) {
    if (!_employee(who)) return MockResponse.problem(404, 'No tienes ficha laboral.');
    final now = _now();
    final items = <Map<String, dynamic>>[];
    var start = now.day > 15 ? DateTime(now.year, now.month, 1) : DateTime(now.year, now.month - 1, 16);
    for (var i = 0; i < 4; i++) {
      final end = start.day == 1 ? DateTime(start.year, start.month, 15) : DateTime(start.year, start.month + 1, 0);
      final base = who.$3 == 'cleaner' ? 2475.0 + i * 165 : 3900.0;
      final incentives = i == 1 ? 250.0 : 0.0;
      final igss = ((base) * 0.0483 * 100).roundToDouble() / 100;
      final gross = base + incentives + 125;
      const months = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      items.add({
        'id': 'pay-${who.$1}-$i',
        'period_name': 'Quincena ${start.day}–${end.day} ${months[start.month - 1].substring(0, 3)} ${start.year}',
        'period_start': _day(start),
        'period_end': _day(end),
        'period_status': 'closed',
        'pay_type': who.$3 == 'cleaner' ? 'per_cleaning' : 'fixed_monthly',
        'days_worked': 10,
        'hours_worked': 80,
        'cleanings_count': who.$3 == 'cleaner' ? 15 + i : 0,
        'base_amount': base,
        'overtime_amount': 0,
        'incentives_amount': incentives,
        'other_earnings': 0,
        'incentive_bonus_amount': 125,
        'bonus14_amount': 0,
        'aguinaldo_amount': 0,
        'igss_employee': igss,
        'other_deductions': i == 2 ? 50 : 0,
        'gross_amount': gross,
        'net_amount': gross - igss - (i == 2 ? 50 : 0),
        'payslip_url': null,
      });
      start = start.day == 1 ? DateTime(start.year, start.month - 1, 16) : DateTime(start.year, start.month, 1);
    }
    return MockResponse.json({'items': items, 'next_cursor': null});
  }

  List<Map<String, dynamic>> _actions(_Who who) {
    if (who.$1 != 'u-ana') return const [];
    final now = _now();
    final a = <Map<String, dynamic>>[
      {
        'id': 'disc-1',
        'type': 'verbal',
        'occurred_on': _day(now.subtract(const Duration(days: 2))),
        'description':
            'En la limpieza de OLI-3B quedó la llave en la caja equivocada. Recuerda devolverla siempre a la caja de la propiedad.',
        'issued_by_name': 'Sofía Méndez',
        'attachments': const [],
        'acknowledged_at': null,
        'acknowledgement_note': null,
      },
      {
        'id': 'disc-0',
        'type': 'written',
        'occurred_on': _day(now.subtract(const Duration(days: 41))),
        'description': 'Llegada 40 minutos tarde a la limpieza de salida sin avisar al supervisor.',
        'issued_by_name': 'Carlos Rivas',
        'attachments': const [],
        'acknowledged_at': now.subtract(const Duration(days: 40)).toUtc().toIso8601String(),
        'acknowledgement_note': 'Tuve un problema con el bus. Ya avisé al supervisor.',
      },
    ];
    for (final x in a) {
      final ack = _acks[x['id']];
      if (ack != null) {
        x['acknowledged_at'] = ack.$1.toUtc().toIso8601String();
        x['acknowledgement_note'] = ack.$2;
      }
    }
    return a;
  }

  MockResponse disciplinary(MockRequest req, _Who who) => MockResponse.json({'items': _actions(who), 'next_cursor': null});

  MockResponse acknowledge(MockRequest req, _Who who) {
    final id = req.pathParams['action_id'];
    final action = _actions(who).where((a) => a['id'] == id).firstOrNull;
    if (action == null) return MockResponse.problem(404, 'La acción no existe.');
    if (action['acknowledged_at'] != null) return MockResponse.problem(422, 'Ya confirmaste esta acción.');
    final note = req.json['note'];
    _acks[id!] = (_now(), note is String && note.isNotEmpty ? note : null);
    return MockResponse.json(_actions(who).firstWhere((a) => a['id'] == id));
  }

  (DateTime, DateTime) _span(String range) {
    final n = _now();
    final today = DateTime(n.year, n.month, n.day);
    return switch (range) {
      'week' => (today.subtract(Duration(days: today.weekday - 1)), today),
      'month' => (DateTime(today.year, today.month, 1), today),
      '30d' => (today.subtract(const Duration(days: 29)), today),
      _ => (today.subtract(const Duration(days: 6)), today),
    };
  }

  List<Map<String, dynamic>> _perDay(DateTime from, DateTime to, int seed) {
    final rnd = Random(seed);
    return [
      for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1)))
        {'date': _day(d), 'count': d.weekday > 5 ? rnd.nextInt(2) : 1 + rnd.nextInt(3)},
    ];
  }

  static const _team = [
    ('u-ana', 'Ana López', 'Colaborador de limpieza', 'cleaner', 1.0),
    ('u-marta', 'Marta Díaz', 'Colaborador de limpieza', 'cleaner', 0.86),
    ('u-pedro', 'Pedro Coc', 'Colaborador de limpieza', 'cleaner', 0.7),
    ('u-rosa', 'Rosa Tum', 'Colaborador de limpieza', 'cleaner', 0.55),
    ('u-luis', 'Luis Pérez', 'Mantenimiento', 'maintenance', 0.4),
  ];

  Map<String, dynamic> _person((String, String, String, String, double) p, int days, {double factor = 1}) {
    final cleanings = (days * 1.6 * p.$5 * factor).round();
    return {
      'id': p.$1,
      'employee_id': 'emp-${p.$1}',
      'name': p.$2,
      'role': p.$3,
      'role_key': p.$4,
      'cleanings': p.$4 == 'maintenance' ? 0 : cleanings,
      'on_time': (82 + 16 * p.$5).round().clamp(0, 100),
      'avg_minutes': (96 - 22 * p.$5).round(),
      'late': cleanings == 0 ? 0 : (cleanings * (1 - p.$5) * 0.25).round(),
      'returned': p.$5 < 0.7 ? 1 : 0,
      'checklist_compliance': (90 + 9.5 * p.$5 * 10).round() / 10,
      'tickets_reported': p.$4 == 'maintenance' ? 3 : (p.$5 * 2).round(),
    };
  }

  List<Map<String, dynamic>> _ranked(int days, {double factor = 1}) {
    final list = [for (final p in _team) _person(p, days, factor: factor)];
    final byRole = <String, int>{};
    final totals = <String, int>{};
    for (final p in list) {
      totals[p['role_key'] as String] = (totals[p['role_key'] as String] ?? 0) + 1;
    }
    for (final p in list) {
      final k = p['role_key'] as String;
      byRole[k] = (byRole[k] ?? 0) + 1;
      p['rank'] = byRole[k];
      p['rank_of'] = totals[k];
    }
    return list;
  }

  MockResponse myMetrics(MockRequest req, _Who who) {
    final range = req.query['range'] ?? '7d';
    final (from, to) = _span(range);
    final days = to.difference(from).inDays + 1;
    final team = _ranked(days);
    final me =
        team.where((p) => p['id'] == who.$1).firstOrNull ??
        {..._person((who.$1, who.$2, 'Colaborador', who.$3, 0.8), days), 'rank': 1, 'rank_of': 1};
    final prev = _person((who.$1, who.$2, '', who.$3, 0.8), days, factor: 0.85);
    final cleanings = (me['cleanings'] as int);
    final monthCleanings = range == 'month' ? cleanings : (cleanings * 30 / max(days, 1)).round();
    return MockResponse.json({
      'range': range,
      'from': _day(from),
      'to': _day(to),
      'me': me,
      'previous': prev,
      'per_day': _perDay(from, to, who.$1.hashCode),
      'goals': [
        {
          'id': 'goal-1',
          'title': 'Limpiezas del mes',
          'target': 30,
          'current': monthCleanings,
          'unit': 'limpiezas',
          'reward': 'Q250',
          'lower_is_better': false,
          'met': monthCleanings >= 30,
          'period': 'Este mes',
        },
        {
          'id': 'goal-2',
          'title': 'Sin retrasos en el mes',
          'target': 1,
          'current': me['late'],
          'unit': 'retrasos',
          'reward': 'Q100',
          'lower_is_better': true,
          'met': (me['late'] as int) <= 1,
          'period': 'Este mes',
        },
      ],
    });
  }

  MockResponse team(MockRequest req, _Who who) {
    if (who.$3 != 'supervisor' && who.$3 != 'admin' && who.$3 != 'owner') {
      return MockResponse.problem(403, 'No tienes permiso.');
    }
    final range = req.query['range'] ?? '7d';
    final (from, to) = _span(range);
    final people = _ranked(to.difference(from).inDays + 1);
    final total = people.fold<int>(0, (a, p) => a + (p['cleanings'] as int));
    return MockResponse.json({
      'range': range,
      'from': _day(from),
      'to': _day(to),
      'people': people,
      'totals': {'cleanings': total, 'on_time': 91, 'avg_minutes': 82, 'late': 3, 'returned': 2},
    });
  }

  MockResponse report(MockRequest req, _Who who) {
    if (who.$3 != 'owner' && who.$3 != 'admin' && who.$3 != 'supervisor') {
      return MockResponse.problem(403, 'No tienes permiso.');
    }
    final n = _now();
    final month = req.query['month'] ?? '${n.year}-${n.month.toString().padLeft(2, '0')}';
    final parts = month.split('-').map(int.parse).toList();
    final days = DateTime(parts[0], parts[1] + 1, 0).day;
    final rnd = Random(month.hashCode);
    final props = mockPropertyOptions.take(who.$3 == 'owner' ? 3 : 6).toList();
    final list = [
      for (final p in props)
        () {
          final nights = 8 + rnd.nextInt(days - 8);
          return {
            'code': p.$2,
            'name': p.$3,
            'nights_booked': nights,
            'occupancy': (100 * nights / days).round(),
            'cleanings': (nights / 2.4).round(),
            'tickets': rnd.nextInt(4),
            'avg_resolution_hours': rnd.nextInt(3) == 0 ? 0 : 2 + rnd.nextInt(40) / 2,
          };
        }(),
    ];
    final withHours = list.where((p) => (p['avg_resolution_hours'] as num) > 0).toList();
    return MockResponse.json({
      'month': month,
      'days': days,
      'totals': {
        'occupancy': list.isEmpty ? 0 : (list.fold<int>(0, (a, p) => a + (p['occupancy'] as int)) / list.length).round(),
        'cleanings': list.fold<int>(0, (a, p) => a + (p['cleanings'] as int)),
        'tickets': list.fold<int>(0, (a, p) => a + (p['tickets'] as int)),
        'avg_resolution_hours': withHours.isEmpty
            ? 0
            : withHours.fold<double>(0, (a, p) => a + (p['avg_resolution_hours'] as num).toDouble()) / withHours.length,
      },
      'properties': list,
    });
  }
}
