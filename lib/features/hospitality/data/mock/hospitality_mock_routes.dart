import 'package:argos_app/core/network/mock/mock_backend.dart';
import 'package:argos_app/core/realtime/realtime_client.dart';
import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:argos_app/features/tasks/data/mock/tasks_mock_routes.dart';

/// Rutas simuladas de la fase 4: modo huésped (`/guest/*`), tablero y
/// alarmas de seguridad, áreas comunes, parqueos y las reservas del
/// supervisor (check-in, huéspedes, depósito e inspecciones). Comparten un
/// mismo estado: lo que reserva el huésped lo ve seguridad.
///
/// Huéspedes de prueba: código `HUESPED-CST` con `tomas.reyes@correo.sv`
/// (hospedado, con parqueo y áreas) o `HUESPED-GAR` con
/// `ana.gomez@correo.sv` (llega mañana). Enlace: `argos://guest?token=demo-huesped`.
void registerHospitalityMockRoutes(MockBackend backend, {DateTime Function()? clock}) {
  final api = _MockHospitality(clock ?? DateTime.now);
  backend
    // Huésped.
    ..on('POST', '/guest/auth', api.guestAuth)
    ..on('GET', '/guest/me', api.guest(api.guestMe))
    ..on('GET', '/guest/reservation', api.guest(api.guestReservation))
    ..on('GET', '/guest/parking', api.guest(api.guestParking))
    ..on('GET', '/guest/shared-areas', api.guest(api.guestAreas))
    ..on('GET', '/guest/shared-areas/{area_id}/availability', api.guest(api.guestAvailability))
    ..on('POST', '/guest/shared-areas/{area_id}/bookings', api.guest(api.guestBook))
    ..on('GET', '/guest/bookings', api.guest(api.guestBookings))
    ..on('DELETE', '/guest/bookings/{booking_id}', api.guest(api.guestCancel))
    ..on('POST', '/guest/tickets', api.guest(api.guestTicket))
    ..on('POST', '/guest/device', api.guest((_, _) => MockResponse.noContent()))
    // Seguridad.
    ..on('GET', '/security/dashboard', api.staff(api.dashboard))
    ..on('GET', '/security/alarms', api.staff(api.alarms))
    ..on('POST', '/security/alarms/{alarm_id}/attend', api.staff(api.attend))
    // Áreas comunes.
    ..on('GET', '/shared-areas', api.staff(api.areas))
    ..on('GET', '/shared-areas/bookings', api.staff(api.bookings))
    ..on('POST', '/shared-areas/bookings', api.staff(api.staffBook))
    ..on('DELETE', '/shared-areas/bookings/{booking_id}', api.staff(api.staffCancel))
    ..on('GET', '/shared-areas/{area_id}/availability', api.staff(api.availability))
    ..on('GET', '/reservations/in-house', api.staff(api.inHouse))
    // Parqueos.
    ..on('GET', '/parking/spaces', api.staff(api.spaces))
    ..on('GET', '/parking/assignments', api.staff(api.assignments))
    ..on('POST', '/parking/assignments', api.staff(api.assign))
    ..on('DELETE', '/parking/assignments/{assignment_id}', api.staff(api.release))
    ..on('GET', '/parking/assignable-stays', api.staff(api.assignableStays))
    // Reservas (supervisor).
    ..on('GET', '/reservations/today', api.staff(api.today))
    ..on('GET', '/reservations', api.staff(api.reservations))
    ..on('GET', '/reservations/{reservation_id}', api.staff(api.detail))
    ..on('POST', '/reservations/{reservation_id}/check-in', api.staff(api.checkIn))
    ..on('POST', '/reservations/{reservation_id}/check-out', api.staff(api.checkOut))
    ..on('POST', '/reservations/{reservation_id}/guests', api.staff(api.addGuest))
    ..on('PATCH', '/guests/{guest_id}', api.staff(api.updateGuest))
    ..on('POST', '/guests/{guest_id}/documents', api.staff(api.attachDocument))
    ..on('GET', '/guests', api.staff(api.findGuests))
    ..on('GET', '/reservations/{reservation_id}/deposit', api.staff(api.deposit))
    ..on('POST', '/reservations/{reservation_id}/deposit/transactions', api.staff(api.depositTx))
    ..on('POST', '/reservations/{reservation_id}/inspections', api.staff(api.inspection))
    ..on('POST', '/inspections/{inspection_id}/findings', api.staff(api.finding));
}

typedef _Who = (String, String, String);

class _Guest {
  _Guest(this.id, this.name, {this.email, this.phone, this.docType, this.docNumber, this.nationality, this.front = false, this.back = false});

  final String id;
  String name;
  String? email;
  String? phone;
  String? docType;
  String? docNumber;
  String? nationality;
  bool front;
  bool back;

  List<String> get missing => [
    if ((email ?? '').isEmpty) 'email',
    if ((docNumber ?? '').isEmpty) 'document',
    if (!front) 'id_front',
    if (!back) 'id_back',
  ];
}

class _Stay {
  _Stay({
    required this.id,
    required this.code,
    required this.property,
    required this.building,
    required this.channel,
    required this.status,
    required this.checkIn,
    required this.checkOut,
    required this.inTime,
    required this.outTime,
    required this.adults,
    this.children = 0,
    this.deposit,
    this.depositStatus = 'none',
    this.total,
    this.notes,
  });

  final String id;
  final String code;
  final int property;
  final String building;

  /// (nombre, tipo, check-in formal, exige depósito)
  final (String, String, bool, bool) channel;
  String status;
  final DateTime checkIn;
  final DateTime checkOut;
  final String inTime;
  final String outTime;
  final int adults;
  final int children;
  final double? deposit;
  String depositStatus;
  final double? total;
  final String? notes;
  final guests = <(_Guest, bool)>[];
  final events = <Map<String, dynamic>>[];
  final txs = <Map<String, dynamic>>[];
  final inspections = <Map<String, dynamic>>[];
  DateTime? checkedInAt;
  DateTime? checkedOutAt;

  String? get primaryName => guests.where((g) => g.$2).map((g) => g.$1.name).firstOrNull;
  int get pending => guests.where((g) => g.$1.missing.isNotEmpty).length;
}

class _MockHospitality {
  _MockHospitality(this._now) {
    _seed();
  }

  final DateTime Function() _now;
  final _stays = <String, _Stay>{};
  final _guests = <String, _Guest>{};
  final _areas = <Map<String, dynamic>>[];
  final _bookings = <Map<String, dynamic>>[];
  final _spaces = <Map<String, dynamic>>[];
  final _assignments = <Map<String, dynamic>>[];
  final _alarms = <Map<String, dynamic>>[];
  var _seq = 100;
  var _ticketSeq = 60;

  DateTime get _today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime _day(int offset) => DateTime(_today.year, _today.month, _today.day + offset);

  String _hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _id(String prefix) => '$prefix-${_seq++}';

  static const _direct = ('Directo', 'direct', true, true);
  static const _airbnb = ('Airbnb', 'airbnb', false, false);
  static const _bookingCom = ('Booking.com', 'booking', false, false);

  // ── Datos iniciales ───────────────────────────────────────

  void _seed() {
    final now = _now();
    final soon = now.add(const Duration(minutes: 20));
    final later = now.add(const Duration(minutes: 150));

    _Guest g(String id, String name, {String? email, String? doc, bool photos = true, String type = 'dpi', String? nat}) {
      final guest = _Guest(id, name, email: email, docType: doc == null ? null : type, docNumber: doc, nationality: nat, front: photos && doc != null, back: photos && doc != null);
      _guests[id] = guest;
      return guest;
    }

    void stay(_Stay s, List<(_Guest, bool)> people) {
      s.guests.addAll(people);
      _stays[s.id] = s;
      _event(s, 'created', 'Sofía Méndez', s.checkIn.subtract(const Duration(days: 9)));
      if (s.status != 'pending') _event(s, 'confirmed', 'Sofía Méndez', s.checkIn.subtract(const Duration(days: 9)));
      if (s.status == 'checked_in') {
        s.checkedInAt = DateTime(s.checkIn.year, s.checkIn.month, s.checkIn.day, 15, 20);
        _event(s, 'checked_in', s.channel.$3 ? 'Sofía Méndez' : null, s.checkedInAt!);
      }
    }

    final tomas = _Stay(
      id: 'res-tomas', code: 'ARG-7K3P9Q', property: 1, building: 'Torre Olivo', channel: _direct,
      status: 'checked_in', checkIn: _day(-2), checkOut: _day(1), inTime: '15:00', outTime: '11:00',
      adults: 2, children: 1, deposit: 150, depositStatus: 'received', total: 540,
    );
    stay(tomas, [
      (g('g-tomas', 'Tomás Reyes', email: 'tomas.reyes@correo.sv', doc: '04839201-7'), true),
      (g('g-carla', 'Carla Reyes', email: 'carla.reyes@correo.sv', doc: '05120394-2'), false),
    ]);
    tomas.txs.add(_tx('received', 150, 'cash', null, 'Sofía Méndez', tomas.checkIn.add(const Duration(hours: 15))));

    final lucia = _Stay(
      id: 'res-lucia', code: 'ARG-4M8T2W', property: 0, building: 'Casa Laurel', channel: _direct,
      status: 'confirmed', checkIn: _day(0), checkOut: _day(3), inTime: '15:00', outTime: '11:00',
      adults: 2, deposit: 200, depositStatus: 'pending', total: 780, notes: 'Llegan en vuelo de la tarde; piden cuna.',
    );
    stay(lucia, [
      (g('g-lucia', 'Lucía Hernández', email: 'lucia.hdz@correo.sv', doc: 'X4829103', type: 'passport', nat: 'MX', photos: false), true),
      (g('g-diego', 'Diego Hernández'), false),
    ]);

    final marco = _Stay(
      id: 'res-marco', code: 'ARG-9D2K5R', property: 2, building: 'Villa Cedro', channel: _airbnb,
      status: 'checked_in', checkIn: _day(-3), checkOut: _day(0), inTime: '15:00', outTime: _hhmm(soon), adults: 2,
    );
    stay(marco, [(g('g-marco', 'Marco Bianchi'), true)]);

    final ortiz = _Stay(
      id: 'res-ortiz', code: 'ARG-2H6V8N', property: 3, building: 'Loft Pino', channel: _bookingCom,
      status: 'checked_in', checkIn: _day(-1), checkOut: _day(0), inTime: '15:00', outTime: _hhmm(later), adults: 3,
    );
    stay(ortiz, [(g('g-ortiz', 'Andrea Ortiz'), true)]);

    final vega = _Stay(
      id: 'res-vega', code: 'ARG-5P1Q7S', property: 4, building: 'Casa Roble', channel: _direct,
      status: 'confirmed', checkIn: _day(2), checkOut: _day(5), inTime: '15:00', outTime: '11:00', adults: 4,
      deposit: 200, depositStatus: 'pending', total: 960,
    );
    stay(vega, [(g('g-daniela', 'Daniela Vega', email: 'daniela.vega@correo.sv'), true)]);

    // Huésped de la otra empresa (Garrent): solo para el modo huésped.
    final ana = _Stay(
      id: 'res-ana', code: 'ARG-8F3J1L', property: 5, building: 'Garrent Centro', channel: _direct,
      status: 'confirmed', checkIn: _day(1), checkOut: _day(4), inTime: '14:00', outTime: '12:00', adults: 1,
    );
    ana.guests.add((g('g-ana', 'Ana Gómez', email: 'ana.gomez@correo.sv', doc: '03312877-1'), true));
    _stays[ana.id] = ana;

    // Áreas comunes.
    _areas.addAll([
      _area('area-pool', 'Piscina', 'Piscina con vista al valle; toallas en recepción.', 12, '08:00', '20:00', 60, 2, 2, 7,
          'Ducharse antes de entrar. Niños siempre con un adulto. Sin vidrio.', 'beachPool'),
      _area('area-salon', 'Salón de eventos', 'Salón con mesas, sonido y cocineta.', 30, '10:00', '22:00', 120, 1, 24, 14,
          'Música hasta las 21:30. Dejar el salón como se encontró.', 'brightRoom'),
      _area('area-rancho', 'Rancho y asadores', 'Rancho techado con dos asadores de carbón.', 10, '09:00', '18:00', 180, 1, 4, 7,
          'Traer el carbón. Apagar las brasas con agua al terminar.', 'lakeRoom'),
    ]);
    _bookings.addAll([
      _booking(_areas[0], _day(0), '16:00', tomas, 3),
      _booking(_areas[2], _day(1), '12:00', tomas, 3),
      _booking(_areas[0], _day(0), '10:00', ortiz, 2, byStaff: true),
      _booking(_areas[1], _day(0), '18:00', null, 20, guestName: 'Cumpleaños Familia Paz', propertyCode: 'OLI-3B', byStaff: true),
    ]);

    // Parqueos.
    for (final (code, level, covered) in [
      ('E-10', 'Sótano 1', true), ('E-11', 'Sótano 1', true), ('E-12', 'Sótano 1', true),
      ('E-13', 'Sótano 1', true), ('E-14', 'Exterior', false), ('V-01', 'Visitas', false), ('V-02', 'Visitas', false),
    ]) {
      _spaces.add({
        'id': 'sp-${code.toLowerCase()}', 'code': code, 'building': 'Torre Olivo', 'level': level,
        'kind': code.startsWith('V') ? 'visitor' : 'guest', 'covered': covered, 'blocked': code == 'E-14', 'active': true,
      });
    }
    _assignments.addAll([
      _assignment(_spaces[2], tomas, 'P123-456', 'Toyota RAV4 gris'),
      _assignment(_spaces[3], marco, 'P789-012', 'Hyundai Tucson blanco'),
      _assignment(_spaces[5], ortiz, 'M456-789', null),
    ]);

    // Alarmas de salida: la previa de Marco ya suena; las demás vienen.
    _alarm(marco, exact: false, fireAt: soon.subtract(const Duration(minutes: 30)), status: 'fired');
    _alarm(marco, exact: true, fireAt: soon);
    _alarm(ortiz, exact: false, fireAt: later.subtract(const Duration(minutes: 30)));
    _alarm(ortiz, exact: true, fireAt: later);
    final yesterday = now.subtract(const Duration(days: 1));
    _alarms.add({
      ..._alarmJson(ortiz, true, yesterday),
      'id': _id('al'), 'status': 'attended', 'attended_by_name': 'Jorge Castillo',
      'attended_at': yesterday.add(const Duration(minutes: 4)).toUtc().toIso8601String(),
      'notes': 'Ejemplo de una alarma atendida.', 'reservation_code': 'ARG-1A2B3C', 'guest_name': 'Roberto Salas',
    });
  }

  Map<String, dynamic> _area(String id, String name, String description, int capacity, String opens, String closes, int block,
          int maxPerDay, int advanceHours, int advanceDays, String rules, String photo) =>
      {
        'id': id, 'name': name, 'description': description, 'building': 'Torre Olivo', 'capacity': capacity,
        'opens': opens, 'closes': closes, 'block': block, 'max_per_day': maxPerDay, 'advance_hours': advanceHours,
        'advance_days': advanceDays, 'rules': rules, 'photo': photo, 'active': true,
      };

  Map<String, dynamic> _booking(Map<String, dynamic> area, DateTime day, String start, _Stay? stay, int people,
      {bool byStaff = false, String? guestName, String? propertyCode}) {
    final p = start.split(':').map(int.parse).toList();
    final starts = DateTime(day.year, day.month, day.day, p[0], p[1]);
    final ends = starts.add(Duration(minutes: area['block'] as int));
    return {
      'id': _id('bk'), 'area_id': area['id'], 'area_name': area['name'], 'date': dayKey(day), 'start': start, 'end': _hhmm(ends),
      'guest_name': guestName ?? stay?.primaryName ?? '', 'property_code': propertyCode ?? (stay == null ? '' : _code(stay)),
      'reservation_id': stay?.id, 'reservation_code': stay?.code, 'people': people, 'by_staff': byStaff,
      'starts_at': starts.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _assignment(Map<String, dynamic> space, _Stay s, String plate, String? description) => {
    'id': _id('pa'), 'space_id': space['id'], 'space_code': space['code'], 'building': space['building'], 'level': space['level'],
    'covered': space['covered'], 'reservation_id': s.id, 'reservation_code': s.code, 'guest_name': s.primaryName ?? '',
    'property_code': _code(s), 'plate': plate, 'vehicle_description': description, 'from': dayKey(s.checkIn), 'to': dayKey(s.checkOut),
  };

  Map<String, dynamic> _alarmJson(_Stay s, bool exact, DateTime fireAt) {
    final p = mockPropertyOptions[s.property % mockPropertyOptions.length];
    return {
      'reservation_id': s.id, 'reservation_code': s.code, 'property_id': p.$1, 'property_code': p.$2, 'property_name': p.$3,
      'guest_name': s.primaryName ?? '', 'kind': 'checkout', 'exact': exact, 'fire_at': fireAt.toUtc().toIso8601String(),
      'check_out_time': s.outTime, 'plates': [for (final a in _assignments) if (a['reservation_id'] == s.id) a['plate']],
    };
  }

  void _alarm(_Stay s, {required bool exact, required DateTime fireAt, String status = 'scheduled'}) {
    _alarms.add({
      ..._alarmJson(s, exact, fireAt),
      'id': _id('al'), 'status': status,
      'fired_at': status == 'fired' ? fireAt.toUtc().toIso8601String() : null,
      'attended_at': null, 'attended_by_name': null, 'notes': null,
    });
  }

  Map<String, dynamic> _tx(String type, double amount, String method, String? reference, String? by, DateTime at, {String? notes}) => {
    'id': _id('tx'), 'type': type, 'amount': amount, 'method': method, 'reference': reference, 'notes': notes,
    'registered_by_name': by, 'created_at': at.toUtc().toIso8601String(),
  };

  void _event(_Stay s, String type, String? actor, DateTime at, [Map<String, dynamic> data = const {}]) {
    s.events.add({
      'id': _id('ev'), 'type': type, 'actor_user_id': null, 'actor_name': actor, 'actor_guest_id': null,
      'data': data, 'created_at': at.toUtc().toIso8601String(),
    });
  }

  String _code(_Stay s) => s.id == 'res-ana' ? 'AN-H03' : mockPropertyOptions[s.property % mockPropertyOptions.length].$2;

  String _name(_Stay s) =>
      s.id == 'res-ana' ? 'Apartamento H03' : mockPropertyOptions[s.property % mockPropertyOptions.length].$3;

  // ── Guardas ──────────────────────────────────────────────

  MockHandler guest(MockResponse Function(MockRequest, _Stay) fn) => (req) {
    final token = req.bearerToken ?? '';
    final stay = token.startsWith('guest-') ? _stays[token.substring(6)] : null;
    if (stay == null) return MockResponse.problem(401, 'Tu acceso terminó. Pide un código nuevo a la recepción.');
    return fn(req, stay);
  };

  MockHandler staff(MockResponse Function(MockRequest, _Who) fn) => (req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'La sesión venció.');
    return fn(req, who);
  };

  // ── Huésped ──────────────────────────────────────────────

  static String _norm(Object? v) => '${v ?? ''}'.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

  MockResponse guestAuth(MockRequest req) {
    final b = req.json;
    _Stay? stay;
    if (b['token'] != null) {
      if (b['token'] == 'demo-huesped') stay = _stays['res-tomas'];
      if (stay == null) return MockResponse.problem(401, 'Este enlace ya no sirve. Entra con el código de tu reserva.');
    } else {
      final code = _norm(b['code']);
      final email = '${b['email'] ?? ''}'.trim().toLowerCase();
      stay = switch (code) {
        'HUESPEDCST' when email == 'tomas.reyes@correo.sv' => _stays['res-tomas'],
        'HUESPEDGAR' when email == 'ana.gomez@correo.sv' => _stays['res-ana'],
        _ => null,
      };
      if (stay == null) return MockResponse.problem(401, 'El código o el correo no coinciden. Revisa el correo de tu reserva.');
    }
    return MockResponse.json({
      'access_token': 'guest-${stay.id}',
      'token_type': 'Bearer',
      'expires_at': stay.checkOut.add(const Duration(days: 1)).toUtc().toIso8601String(),
      'me': _me(stay),
    });
  }

  Map<String, dynamic> _me(_Stay s) {
    final garrent = s.id == 'res-ana';
    final primary = s.guests.firstWhere((g) => g.$2).$1;
    return {
      'guest_id': primary.id, 'name': primary.name, 'email': primary.email,
      'tenant_name': garrent ? 'Garrent' : 'Costa Limpia S.A.', 'reservation_id': s.id, 'reservation_code': s.code,
      'expires_at': s.checkOut.add(const Duration(days: 1)).toUtc().toIso8601String(),
      'features': {'parking': !garrent, 'shared_areas': !garrent, 'guest_chat': !garrent},
    };
  }

  MockResponse guestMe(MockRequest req, _Stay s) => MockResponse.json(_me(s));

  MockResponse guestReservation(MockRequest req, _Stay s) {
    final garrent = s.id == 'res-ana';
    final mine = _bookings.where((b) => b['reservation_id'] == s.id && !_past(b)).length;
    return MockResponse.json({
      'code': s.code, 'status': s.status, 'property_code': _code(s), 'property_name': _name(s),
      'property_address': garrent ? 'Avenida Reforma 12-40, Zona 9' : 'Torre Olivo, piso 3, Santa Ana',
      'building': s.building, 'lat': garrent ? 14.6037 : 9.9326, 'lng': garrent ? -90.5131 : -84.1825,
      'check_in_date': dayKey(s.checkIn), 'check_out_date': dayKey(s.checkOut), 'check_in_time': s.inTime,
      'check_out_time': s.outTime, 'nights': s.checkOut.difference(s.checkIn).inDays, 'adults': s.adults,
      'children': s.children, 'guest_name': s.primaryName,
      'instructions': garrent
          ? 'Hola, Ana. Al llegar, anúnciate en la garita con el código ${s.code}. La llave está en la caja '
              'de seguridad junto a la puerta; el código es 4821. El Wi-Fi es "Garrent-H03" y la clave "bienvenidos".'
          : 'Hola, Tomás. Tu apartamento es el 3B de la Torre Olivo. En recepción te entregan la tarjeta del '
              'ascensor. Wi-Fi: "Olivo-3B", clave "olivo2026". El parqueo está en el sótano 1.',
      'contact_name': garrent ? 'Recepción Garrent' : 'Recepción Costa Limpia',
      'contact_phone': garrent ? '+502 2333 4455' : '+506 2222 1010',
      'contact_email': garrent ? 'reservas@garrent.gt' : 'hola@costalimpia.cr',
      'parking_count': _assignments.where((a) => a['reservation_id'] == s.id).length,
      'bookings_count': mine,
    });
  }

  MockResponse guestParking(MockRequest req, _Stay s) =>
      MockResponse.json([for (final a in _assignments) if (a['reservation_id'] == s.id) a]);

  bool _past(Map<String, dynamic> b) => !DateTime.parse('${b['starts_at']}').isAfter(_now());

  List<Map<String, dynamic>> _mine(_Stay s) {
    final list = [for (final b in _bookings) if (b['reservation_id'] == s.id && !_past(b)) b];
    list.sort((a, b) => '${a['starts_at']}'.compareTo('${b['starts_at']}'));
    return list;
  }

  MockResponse guestAreas(MockRequest req, _Stay s) {
    if (s.id == 'res-ana') return MockResponse.problem(403, 'Este módulo no está activo en tu empresa.');
    return MockResponse.json({'areas': _areas, 'bookings': _mine(s)});
  }

  Map<String, dynamic>? _areaOf(String id) => _areas.where((a) => a['id'] == id).firstOrNull;

  List<Map<String, dynamic>> _slots(Map<String, dynamic> area, DateTime day, {_Stay? guest}) {
    final open = (area['opens'] as String).split(':').map(int.parse).toList();
    final close = (area['closes'] as String).split(':').map(int.parse).toList();
    final block = area['block'] as int;
    var t = DateTime(day.year, day.month, day.day, open[0], open[1]);
    final end = DateTime(day.year, day.month, day.day, close[0], close[1]);
    final minStart = _now().add(Duration(hours: guest == null ? 0 : area['advance_hours'] as int));
    final slots = <Map<String, dynamic>>[];
    while (!t.add(Duration(minutes: block)).isAfter(end)) {
      final start = _hhmm(t);
      final used = _bookings
          .where((b) => b['area_id'] == area['id'] && b['date'] == dayKey(day) && b['start'] == start)
          .fold<int>(0, (sum, b) => sum + (b['people'] as int));
      slots.add({
        'start': start, 'end': _hhmm(t.add(Duration(minutes: block))),
        'left': (area['capacity'] as int) - used, 'past': t.isBefore(minStart),
      });
      t = t.add(Duration(minutes: block));
    }
    return slots;
  }

  MockResponse guestAvailability(MockRequest req, _Stay s) {
    final area = _areaOf(req.pathParams['area_id']!);
    if (area == null) return MockResponse.problem(404, 'El área no existe.');
    final day = parseDay(req.query['date'] ?? '');
    return MockResponse.json({'area_id': area['id'], 'date': dayKey(day), 'slots': _slots(area, day, guest: s)});
  }

  MockResponse? _bookError(Map<String, dynamic> area, DateTime day, String start, int people, _Stay? stay, {bool guest = false}) {
    final slot = _slots(area, day, guest: guest ? stay : null).where((x) => x['start'] == start).firstOrNull;
    if (slot == null) return MockResponse.problem(422, 'Ese horario no existe en el área.');
    if (slot['past'] == true) {
      return MockResponse.problem(422, guest && (area['advance_hours'] as int) > 0
          ? 'Se reserva con al menos ${area['advance_hours']} h de anticipación.'
          : 'Ese horario ya pasó.');
    }
    if ((slot['left'] as int) < people) {
      final left = slot['left'] as int;
      return MockResponse.problem(409, left <= 0 ? 'Ese horario ya está lleno.' : 'Solo quedan $left lugares en ese horario.');
    }
    if (stay != null) {
      if (guest && (day.isBefore(stay.checkIn) || day.isAfter(stay.checkOut))) {
        return MockResponse.problem(422, 'Solo puedes reservar durante tu estancia.');
      }
      final sameDay = _bookings.where((b) => b['area_id'] == area['id'] && b['reservation_id'] == stay.id && b['date'] == dayKey(day));
      if (sameDay.length >= (area['max_per_day'] as int)) {
        return MockResponse.problem(409, 'Ya tienes ${area['max_per_day']} ${area['max_per_day'] == 1 ? 'bloque' : 'bloques'} ese día en ${area['name']}.');
      }
    }
    return null;
  }

  MockResponse guestBook(MockRequest req, _Stay s) {
    final area = _areaOf(req.pathParams['area_id']!);
    if (area == null) return MockResponse.problem(404, 'El área no existe.');
    final day = parseDay('${req.json['date']}');
    final start = '${req.json['start']}';
    final people = (req.json['people'] as num?)?.toInt() ?? 1;
    final error = _bookError(area, day, start, people, s, guest: true);
    if (error != null) return error;
    final b = _booking(area, day, start, s, people);
    _bookings.add(b);
    _event(s, 'area_booked', null, _now(), {'area': area['name'], 'date': b['date'], 'start': start});
    return MockResponse.json(b, status: 201);
  }

  MockResponse guestBookings(MockRequest req, _Stay s) => MockResponse.json(_mine(s));

  MockResponse guestCancel(MockRequest req, _Stay s) {
    final b = _bookings.where((x) => x['id'] == req.pathParams['booking_id'] && x['reservation_id'] == s.id).firstOrNull;
    if (b == null) return MockResponse.problem(404, 'Esa reserva del área no existe.');
    if (!DateTime.parse('${b['starts_at']}').isAfter(_now().add(const Duration(hours: 1)))) {
      return MockResponse.problem(422, 'Ya no se puede cancelar: falta menos de 1 hora.');
    }
    _bookings.remove(b);
    return MockResponse.noContent();
  }

  MockResponse guestTicket(MockRequest req, _Stay s) {
    final title = '${req.json['title'] ?? ''}'.trim();
    if (title.length < 3) return MockResponse.problem(422, 'Cuéntanos en pocas palabras qué pasa.');
    final number = ++_ticketSeq;
    _event(s, 'guest_ticket', null, _now(), {'number': number, 'title': title});
    return MockResponse.json({'id': 'tk-$number', 'number': number}, status: 201);
  }

  // ── Seguridad ────────────────────────────────────────────

  List<String> _plates(_Stay s) => [for (final a in _assignments) if (a['reservation_id'] == s.id) '${a['plate']}'];

  Map<String, dynamic> _board(_Stay s) => {
    'reservation_id': s.id, 'code': s.code, 'property_id': mockPropertyOptions[s.property].$1, 'property_code': _code(s),
    'property_name': _name(s), 'building': s.building, 'guest_name': s.primaryName ?? 'Por registrar', 'status': s.status,
    'check_in_date': dayKey(s.checkIn), 'check_out_date': dayKey(s.checkOut), 'check_in_time': s.inTime,
    'check_out_time': s.outTime, 'adults': s.adults, 'children': s.children, 'channel_name': s.channel.$1,
    'plates': _plates(s),
  };

  Iterable<_Stay> get _live => _stays.values.where((s) => s.id != 'res-ana' && s.status != 'cancelled');

  MockResponse dashboard(MockRequest req, _Who who) {
    final day = req.query['date'] == null ? _today : parseDay(req.query['date']!);
    final key = dayKey(day);
    final arrivals = [for (final s in _live) if (dayKey(s.checkIn) == key && s.status != 'pending') _board(s)];
    final departures = [for (final s in _live) if (dayKey(s.checkOut) == key && s.status != 'pending') _board(s)];
    final inHouse = [
      for (final s in _live)
        if (s.status == 'checked_in' && s.checkIn.isBefore(day) && s.checkOut.isAfter(day)) _board(s),
    ];
    final plates = [
      for (final a in _assignments)
        if ('${a['from']}'.compareTo(key) <= 0 && '${a['to']}'.compareTo(key) >= 0) a,
    ];
    final bookings = [for (final b in _bookings) if (b['date'] == key) b]
      ..sort((a, b) => '${a['start']}'.compareTo('${b['start']}'));
    final alarms = [
      for (final a in _alarms)
        if ((a['status'] == 'scheduled' || a['status'] == 'fired') && dayKey(DateTime.parse('${a['fire_at']}').toLocal()) == key) a,
    ]..sort((a, b) => '${a['fire_at']}'.compareTo('${b['fire_at']}'));
    return MockResponse.json({
      'date': key,
      'counts': {
        'arrivals': arrivals.length, 'departures': departures.length, 'in_house': inHouse.length,
        'plates': plates.length, 'area_bookings': bookings.length, 'alarms_pending': alarms.length,
      },
      'arrivals': arrivals, 'departures': departures, 'in_house': inHouse, 'plates': plates,
      'area_bookings': bookings, 'alarms': alarms,
    });
  }

  MockResponse alarms(MockRequest req, _Who who) {
    final status = req.query['status'] ?? 'pending';
    final today = dayKey(_today);
    final list = [
      for (final a in _alarms)
        if (switch (status) {
          'pending' => a['status'] == 'scheduled' || a['status'] == 'fired',
          'today' => dayKey(DateTime.parse('${a['fire_at']}').toLocal()) == today,
          _ => true,
        })
          a,
    ]..sort((a, b) => '${a['fire_at']}'.compareTo('${b['fire_at']}'));
    return MockResponse.json(list);
  }

  MockResponse attend(MockRequest req, _Who who) {
    final alarm = _alarms.where((a) => a['id'] == req.pathParams['alarm_id']).firstOrNull;
    if (alarm == null) return MockResponse.problem(404, 'La alarma no existe.');
    if (alarm['status'] == 'attended') return MockResponse.json(alarm);
    if (alarm['status'] == 'cancelled') return MockResponse.problem(422, 'Esa alarma se canceló: el huésped ya salió.');
    final at = DateTime.parse('${alarm['fire_at']}');
    final note = '${req.json['notes'] ?? ''}'.trim();
    for (final a in _alarms) {
      final open = a['status'] == 'scheduled' || a['status'] == 'fired';
      if (open && a['reservation_id'] == alarm['reservation_id'] && DateTime.parse('${a['fire_at']}').difference(at).inHours.abs() <= 4) {
        a['status'] = 'attended';
        a['attended_by_name'] = who.$2;
        a['attended_at'] = _now().toUtc().toIso8601String();
        if (note.isNotEmpty) a['notes'] = note;
      }
    }
    mockRealtimeBus.add(RealtimeMessage('security.alarm', {'id': alarm['id'], 'status': 'attended'}));
    return MockResponse.json(alarm);
  }

  // ── Áreas comunes (personal) ─────────────────────────────

  MockResponse areas(MockRequest req, _Who who) => MockResponse.json(_areas);

  MockResponse bookings(MockRequest req, _Who who) {
    final from = req.query['from'] ?? dayKey(_today);
    final to = req.query['to'] ?? from;
    final list = [
      for (final b in _bookings)
        if ('${b['date']}'.compareTo(from) >= 0 && '${b['date']}'.compareTo(to) <= 0) b,
    ]..sort((a, b) => '${a['starts_at']}'.compareTo('${b['starts_at']}'));
    return MockResponse.json(list);
  }

  MockResponse availability(MockRequest req, _Who who) {
    final area = _areaOf(req.pathParams['area_id']!);
    if (area == null) return MockResponse.problem(404, 'El área no existe.');
    final day = parseDay(req.query['date'] ?? '');
    return MockResponse.json({'area_id': area['id'], 'date': dayKey(day), 'slots': _slots(area, day)});
  }

  MockResponse staffBook(MockRequest req, _Who who) {
    if (who.$3 == 'security') return MockResponse.problem(403, 'No tienes permiso para reservar áreas.');
    final b = req.json;
    final area = _areaOf('${b['area_id']}');
    if (area == null) return MockResponse.problem(404, 'El área no existe.');
    final stay = _stays[b['reservation_id']];
    final day = parseDay('${b['date']}');
    final people = (b['people'] as num?)?.toInt() ?? 1;
    final error = _bookError(area, day, '${b['start']}', people, stay);
    if (error != null) return error;
    final parts = '${b['guest'] ?? ''}'.split('|');
    final booking = _booking(area, day, '${b['start']}', stay, people,
        byStaff: true, guestName: stay == null ? parts.first : null, propertyCode: stay == null && parts.length > 1 ? parts[1] : null);
    _bookings.add(booking);
    return MockResponse.json(booking, status: 201);
  }

  MockResponse staffCancel(MockRequest req, _Who who) {
    if (who.$3 == 'security') return MockResponse.problem(403, 'No tienes permiso para cancelar reservas de áreas.');
    _bookings.removeWhere((b) => b['id'] == req.pathParams['booking_id']);
    return MockResponse.noContent();
  }

  MockResponse inHouse(MockRequest req, _Who who) => MockResponse.json([
    for (final s in _live)
      if (s.status == 'checked_in' || dayKey(s.checkIn) == dayKey(_today))
        {
          'name': s.primaryName ?? '', 'property_code': _code(s), 'reservation_id': s.id, 'reservation_code': s.code,
          'check_out_date': dayKey(s.checkOut),
        },
  ]);

  // ── Parqueos ─────────────────────────────────────────────

  MockResponse spaces(MockRequest req, _Who who) => MockResponse.json(_spaces);

  MockResponse assignments(MockRequest req, _Who who) {
    final from = req.query['from'] ?? dayKey(_today);
    final to = req.query['to'] ?? from;
    return MockResponse.json([
      for (final a in _assignments)
        if ('${a['from']}'.compareTo(to) <= 0 && '${a['to']}'.compareTo(from) >= 0) a,
    ]);
  }

  MockResponse assign(MockRequest req, _Who who) {
    if (who.$3 == 'security' || who.$3 == 'cleaner') return MockResponse.problem(403, 'No tienes permiso para asignar parqueos.');
    final b = req.json;
    final space = _spaces.where((s) => s['id'] == b['space_id']).firstOrNull;
    final stay = _stays.values.where((s) => s.code == '${b['reservation_code']}'.toUpperCase()).firstOrNull;
    if (space == null) return MockResponse.problem(404, 'El espacio no existe.');
    if (stay == null) return MockResponse.problem(422, 'No encontramos esa reserva.');
    if (space['blocked'] == true) return MockResponse.problem(422, 'Ese espacio está bloqueado.');
    final plate = '${b['plate'] ?? ''}'.toUpperCase().replaceAll(' ', '');
    if (!RegExp(r'^[A-Z0-9-]{5,10}$').hasMatch(plate)) return MockResponse.problem(422, 'Revisa la placa: letras, números y guion.');
    final from = dayKey(stay.checkIn);
    final to = dayKey(stay.checkOut);
    final clash = _assignments
        .where((a) => a['space_id'] == space['id'] && '${a['from']}'.compareTo(to) < 0 && '${a['to']}'.compareTo(from) > 0)
        .firstOrNull;
    if (clash != null) {
      return MockResponse.problem(409, 'Ocupado por ${clash['reservation_code']} (${clash['guest_name']}) en esas fechas.');
    }
    final a = _assignment(space, stay, plate, b['vehicle_description'] as String?);
    _assignments.add(a);
    _event(stay, 'parking_assigned', who.$2, _now(), {'space': space['code'], 'plate': plate});
    return MockResponse.json(a, status: 201);
  }

  MockResponse release(MockRequest req, _Who who) {
    _assignments.removeWhere((a) => a['id'] == req.pathParams['assignment_id']);
    return MockResponse.noContent();
  }

  MockResponse assignableStays(MockRequest req, _Who who) => MockResponse.json([
    for (final s in _live)
      if (s.status == 'confirmed' || s.status == 'checked_in')
        {
          'reservation_id': s.id, 'reservation_code': s.code, 'guest_name': s.primaryName ?? '', 'property_code': _code(s),
          'building': s.building, 'from': dayKey(s.checkIn), 'to': dayKey(s.checkOut),
        },
  ]);

  // ── Reservas (supervisor) ────────────────────────────────

  Map<String, dynamic> _read(_Stay s) {
    final p = mockPropertyOptions[s.property % mockPropertyOptions.length];
    final primary = s.guests.where((g) => g.$2).map((g) => g.$1).firstOrNull;
    return {
      'id': s.id, 'code': s.code, 'property_id': p.$1, 'property_code': _code(s), 'property_name': _name(s),
      'channel_id': 'ch-${s.channel.$2}', 'channel_name': s.channel.$1, 'channel_kind': s.channel.$2,
      'requires_deposit': s.channel.$4, 'has_checkin': s.channel.$3, 'source': s.channel.$2 == 'direct' ? 'manual' : 'ical',
      'primary_guest_id': primary?.id, 'guest_name': primary?.name, 'guest_email': primary?.email,
      'guests_count': s.guests.length, 'guests_pending': s.pending, 'status': s.status, 'incomplete': primary == null,
      'check_in_date': dayKey(s.checkIn), 'check_out_date': dayKey(s.checkOut), 'check_in_time': s.inTime,
      'check_out_time': s.outTime, 'nights': s.checkOut.difference(s.checkIn).inDays,
      'checked_in_at': s.checkedInAt?.toUtc().toIso8601String(), 'checked_out_at': s.checkedOutAt?.toUtc().toIso8601String(),
      'adults': s.adults, 'children': s.children, 'total_amount': s.total, 'currency': 'USD', 'deposit_amount': s.deposit,
      'deposit_status': s.depositStatus, 'notes': s.notes, 'parking': [
        for (final a in _assignments) if (a['reservation_id'] == s.id) '${a['space_code']}',
      ],
    };
  }

  Map<String, dynamic> _guestJson(_Guest g) => {
    'id': g.id, 'full_name': g.name, 'email': g.email, 'phone': g.phone, 'document_type': g.docType,
    'document_number': g.docNumber, 'nationality': g.nationality, 'notes': null, 'blacklisted': false,
    'blacklist_reason': null, 'stays': g.id == 'g-tomas' ? 2 : 0, 'last_stay': g.id == 'g-tomas' ? '2026-03-03' : null,
    'next_stay': null,
  };

  Map<String, dynamic> _depositJson(_Stay s) {
    double sum(String type) => s.txs.where((t) => t['type'] == type).fold(0, (a, t) => a + (t['amount'] as num).toDouble());
    final hasPost = s.inspections.any((i) => i['kind'] == 'post_departure');
    final charges = s.inspections
        .expand((i) => i['findings'] as List)
        .where((f) => f['charge_to_deposit'] == true)
        .fold<double>(0, (a, f) => a + ((f['estimated_cost'] as num?)?.toDouble() ?? 0));
    return {
      'available': true, 'amount': s.deposit, 'status': s.depositStatus, 'received': sum('received'),
      'returned': sum('returned'), 'retained': sum('retained'),
      'balance': sum('received') - sum('returned') - sum('retained'), 'charges': charges,
      'inspection_required': s.status == 'checked_out' && !hasPost && s.depositStatus == 'received',
      'transactions': s.txs.reversed.toList(),
    };
  }

  Map<String, dynamic> _detailJson(_Stay s) => {
    ..._read(s),
    'guests': [
      for (final (g, primary) in s.guests)
        {
          ..._guestJson(g), 'is_primary': primary, 'registered': g.missing.isEmpty, 'missing': g.missing,
          'documents': [
            if (g.front) {'file_id': 'doc-${g.id}-f', 'kind': 'id_front', 'content_type': 'image/jpeg', 'size_bytes': 180000, 'created_at': _now().toUtc().toIso8601String(), 'expires_at': null},
            if (g.back) {'file_id': 'doc-${g.id}-b', 'kind': 'id_back', 'content_type': 'image/jpeg', 'size_bytes': 170000, 'created_at': _now().toUtc().toIso8601String(), 'expires_at': null},
          ],
        },
    ],
    'events': s.events.reversed.toList(),
    'deposit': _depositJson(s),
    'inspections': s.inspections,
    'parking_spots': [for (final a in _assignments) if (a['reservation_id'] == s.id) a],
    'area_bookings': [for (final b in _bookings) if (b['reservation_id'] == s.id) b],
  };

  MockResponse today(MockRequest req, _Who who) {
    final key = dayKey(_today);
    return MockResponse.json({
      'available': true,
      'arrivals': _live.where((s) => dayKey(s.checkIn) == key && s.status != 'pending').length,
      'departures': _live.where((s) => dayKey(s.checkOut) == key).length,
      'in_house': _live.where((s) => s.status == 'checked_in').length,
      'incomplete': 0,
      'checkin_time': '15:00',
    });
  }

  MockResponse reservations(MockRequest req, _Who who) {
    final from = req.query['from'];
    final to = req.query['to'];
    final list = [
      for (final s in _live)
        if ((from == null || dayKey(s.checkOut).compareTo(from) >= 0) && (to == null || dayKey(s.checkIn).compareTo(to) < 0)) _read(s),
    ]..sort((a, b) => '${a['check_in_date']}'.compareTo('${b['check_in_date']}'));
    return MockResponse.json({'items': list, 'next_cursor': null});
  }

  _Stay? _stay(MockRequest req) => _stays[req.pathParams['reservation_id']];

  MockResponse detail(MockRequest req, _Who who) {
    final s = _stay(req);
    if (s == null || s.id == 'res-ana') return MockResponse.problem(404, 'La reserva no existe.');
    final json = _detailJson(s);
    if (who.$3 == 'security') {
      // Alcance de seguridad: sin documentos, contacto ni montos.
      for (final g in json['guests'] as List) {
        (g as Map)
          ..['documents'] = []
          ..['email'] = null
          ..['phone'] = null
          ..['document_number'] = null;
      }
      json['deposit'] = {'available': false, 'status': s.depositStatus, 'received': 0, 'returned': 0, 'retained': 0, 'balance': 0, 'charges': 0, 'inspection_required': false, 'transactions': []};
      json['guest_email'] = null;
    }
    return MockResponse.json(json);
  }

  bool _canCheckin(_Who who) => who.$3 == 'supervisor' || who.$3 == 'admin';

  MockResponse checkIn(MockRequest req, _Who who) {
    final s = _stay(req);
    if (s == null) return MockResponse.problem(404, 'La reserva no existe.');
    if (!_canCheckin(who)) return MockResponse.problem(403, 'No tienes permiso para hacer check-in.');
    if (s.status != 'confirmed') return MockResponse.problem(422, 'La reserva no está en un estado que permita esto.');
    if (s.checkIn.isAfter(_today)) return MockResponse.problem(422, 'La entrada es el ${shortDay(s.checkIn)}.');
    if (s.channel.$3) {
      final pending = [for (final (g, _) in s.guests) if (g.missing.isNotEmpty) g.name];
      if (pending.isNotEmpty) return MockResponse.problem(422, 'Faltan datos de huéspedes para el check-in: ${pending.join(', ')}.');
      if (s.channel.$4 && (s.deposit ?? 0) > 0 && s.depositStatus != 'received') {
        return MockResponse.problem(422, 'Registra el depósito antes del check-in.');
      }
    }
    s
      ..status = 'checked_in'
      ..checkedInAt = _now();
    _event(s, 'checked_in', who.$2, _now());
    // Programa las alarmas de salida como el backend.
    final p = s.outTime.split(':').map(int.parse).toList();
    final exact = DateTime(s.checkOut.year, s.checkOut.month, s.checkOut.day, p[0], p[1]);
    _alarm(s, exact: false, fireAt: exact.subtract(const Duration(minutes: 30)));
    _alarm(s, exact: true, fireAt: exact);
    return MockResponse.json(_detailJson(s));
  }

  MockResponse checkOut(MockRequest req, _Who who) {
    final s = _stay(req);
    if (s == null) return MockResponse.problem(404, 'La reserva no existe.');
    if (!_canCheckin(who)) return MockResponse.problem(403, 'No tienes permiso para hacer check-out.');
    if (s.status != 'checked_in') return MockResponse.problem(422, 'La reserva no está en un estado que permita esto.');
    s
      ..status = 'checked_out'
      ..checkedOutAt = _now();
    _event(s, 'checked_out', who.$2, _now());
    for (final a in _alarms) {
      if (a['reservation_id'] == s.id && (a['status'] == 'scheduled' || a['status'] == 'fired')) a['status'] = 'cancelled';
    }
    return MockResponse.json(_detailJson(s));
  }

  MockResponse addGuest(MockRequest req, _Who who) {
    final s = _stay(req);
    if (s == null) return MockResponse.problem(404, 'La reserva no existe.');
    final b = req.json;
    _Guest guest;
    if (b['guest_id'] != null) {
      final existing = _guests[b['guest_id']];
      if (existing == null) return MockResponse.problem(404, 'El huésped no existe.');
      guest = existing;
    } else {
      final g = Map<String, dynamic>.from(b['guest'] as Map? ?? const {});
      final name = '${g['full_name'] ?? ''}'.trim();
      if (name.length < 2) return MockResponse.problem(422, 'Escribe el nombre completo.');
      final number = (g['document_number'] as String?)?.trim();
      final same = number == null || number.isEmpty
          ? null
          : _guests.values.where((x) => x.docNumber?.toUpperCase() == number.toUpperCase()).firstOrNull;
      guest = same ??
          _Guest(_id('g'), name,
              email: (g['email'] as String?)?.trim(), phone: (g['phone'] as String?)?.trim(),
              docType: g['document_type'] as String?, docNumber: number, nationality: g['nationality'] as String?);
      _guests[guest.id] = guest;
    }
    if (s.guests.any((x) => x.$1.id == guest.id)) return MockResponse.problem(422, '${guest.name} ya está en la reserva.');
    final primary = b['is_primary'] == true || s.guests.isEmpty;
    if (primary) {
      for (var i = 0; i < s.guests.length; i++) {
        s.guests[i] = (s.guests[i].$1, false);
      }
    }
    s.guests.add((guest, primary));
    _event(s, 'guest_added', who.$2, _now(), {'name': guest.name});
    return MockResponse.json(_detailJson(s), status: 201);
  }

  MockResponse updateGuest(MockRequest req, _Who who) {
    final g = _guests[req.pathParams['guest_id']];
    if (g == null) return MockResponse.problem(404, 'El huésped no existe.');
    final b = req.json;
    String? opt(String key, String? current) => b.containsKey(key) ? ((b[key] as String?)?.trim().isEmpty ?? true ? null : (b[key] as String).trim()) : current;
    if (b['full_name'] != null) g.name = '${b['full_name']}'.trim();
    g
      ..email = opt('email', g.email)
      ..phone = opt('phone', g.phone)
      ..docType = opt('document_type', g.docType)
      ..docNumber = opt('document_number', g.docNumber)
      ..nationality = opt('nationality', g.nationality);
    return MockResponse.json(_guestJson(g));
  }

  MockResponse attachDocument(MockRequest req, _Who who) {
    final g = _guests[req.pathParams['guest_id']];
    if (g == null) return MockResponse.problem(404, 'El huésped no existe.');
    switch (req.json['kind']) {
      case 'id_front':
        g.front = true;
      case 'id_back':
        g.back = true;
      default:
        return MockResponse.problem(422, 'Tipo de foto no válido.');
    }
    return MockResponse.json(_guestJson(g), status: 201);
  }

  MockResponse findGuests(MockRequest req, _Who who) {
    final q = (req.query['document'] ?? req.query['q'] ?? '').trim().toUpperCase();
    if (q.isEmpty) return MockResponse.json({'items': [], 'next_cursor': null});
    return MockResponse.json({
      'items': [
        for (final g in _guests.values)
          if ((g.docNumber ?? '').toUpperCase() == q || g.name.toUpperCase().contains(q)) _guestJson(g),
      ],
      'next_cursor': null,
    });
  }

  MockResponse deposit(MockRequest req, _Who who) {
    final s = _stay(req);
    if (s == null) return MockResponse.problem(404, 'La reserva no existe.');
    return MockResponse.json(_depositJson(s));
  }

  MockResponse depositTx(MockRequest req, _Who who) {
    final s = _stay(req);
    if (s == null) return MockResponse.problem(404, 'La reserva no existe.');
    if (who.$3 != 'admin' && who.$3 != 'supervisor') return MockResponse.problem(403, 'No tienes permiso para registrar depósitos.');
    final b = req.json;
    final type = '${b['type']}';
    final amount = (b['amount'] as num?)?.toDouble() ?? 0;
    if (amount <= 0) return MockResponse.problem(422, 'Escribe un monto mayor que cero.');
    final d = _depositJson(s);
    if (type != 'received') {
      if (d['inspection_required'] == true) return MockResponse.problem(422, 'Primero registra la inspección de salida.');
      if (amount > (d['balance'] as double) + 0.001) return MockResponse.problem(422, 'El monto supera lo que queda del depósito.');
    }
    s.txs.add(_tx(type, amount, '${b['method'] ?? 'cash'}', b['reference'] as String?, who.$2, _now(), notes: b['notes'] as String?));
    final after = _depositJson(s);
    final balance = after['balance'] as double;
    s.depositStatus = switch (type) {
      'received' => 'received',
      _ when balance > 0.001 => 'received',
      _ when (after['retained'] as double) > 0 && (after['returned'] as double) == 0 => 'retained_full',
      _ when (after['retained'] as double) > 0 => 'retained_partial',
      _ => 'returned',
    };
    _event(s, 'deposit_$type', who.$2, _now(), {'amount': amount});
    return MockResponse.json(_depositJson(s), status: 201);
  }

  MockResponse inspection(MockRequest req, _Who who) {
    final s = _stay(req);
    if (s == null) return MockResponse.problem(404, 'La reserva no existe.');
    final kind = '${req.json['kind']}';
    if (s.inspections.any((i) => i['kind'] == kind)) {
      return MockResponse.problem(422, 'Ya hay una inspección ${kind == 'pre_arrival' ? 'antes de llegar' : 'de salida'}.');
    }
    if (kind == 'post_departure' && s.status != 'checked_out') {
      return MockResponse.problem(422, 'La inspección de salida se hace después del check-out.');
    }
    final photos = [
      for (final id in req.json['photo_file_ids'] as List? ?? const [])
        {'file_id': '$id', 'url': 'https://picsum.photos/seed/$id/800/600', 'created_at': _now().toUtc().toIso8601String()},
    ];
    s.inspections.add({
      'id': _id('in'), 'kind': kind, 'performed_by': null, 'performed_by_name': who.$2,
      'performed_at': _now().toUtc().toIso8601String(), 'task_id': req.json['task_id'], 'notes': req.json['notes'],
      'photos': photos, 'findings': <Map<String, dynamic>>[],
    });
    _event(s, 'inspection_$kind', who.$2, _now());
    return MockResponse.json(_detailJson(s), status: 201);
  }

  MockResponse finding(MockRequest req, _Who who) {
    final id = req.pathParams['inspection_id'];
    for (final s in _stays.values) {
      final ins = s.inspections.where((i) => i['id'] == id).firstOrNull;
      if (ins == null) continue;
      final b = req.json;
      if ('${b['description'] ?? ''}'.trim().length < 3) return MockResponse.problem(422, 'Describe el hallazgo.');
      final ticket = b['create_ticket'] == true ? ++_ticketSeq : null;
      (ins['findings'] as List).add({
        'id': _id('fi'), 'area': b['area'], 'description': '${b['description']}'.trim(), 'severity': b['severity'] ?? 'low',
        'estimated_cost': b['estimated_cost'], 'charge_to_deposit': b['charge_to_deposit'] == true,
        'ticket_id': ticket == null ? null : 'tk-$ticket', 'ticket_number': ticket,
        'created_at': _now().toUtc().toIso8601String(),
        'photos': [
          for (final pid in b['photo_file_ids'] as List? ?? const [])
            {'file_id': '$pid', 'url': 'https://picsum.photos/seed/$pid/800/600', 'created_at': _now().toUtc().toIso8601String()},
        ],
      });
      return MockResponse.json(_detailJson(s), status: 201);
    }
    return MockResponse.problem(404, 'La inspección no existe.');
  }
}
