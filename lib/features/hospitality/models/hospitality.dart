import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Modelos de la fase 4 que comparten el huésped, seguridad y supervisión:
/// áreas comunes, bloques reservados, parqueos y alarmas de salida. Siguen
/// las respuestas del backend (`sharedareas`, `parking`, `securityops`).

String _s(Object? v, [String def = '']) => v is String ? v : def;
int _i(Object? v) => v is num ? v.toInt() : 0;
bool _b(Object? v) => v == true;

/// "2026-10-22" → fecha local sin hora.
DateTime parseDay(String day) {
  final p = day.split('-').map(int.tryParse).toList();
  if (p.length != 3 || p.any((x) => x == null)) return DateTime(1970);
  return DateTime(p[0]!, p[1]!, p[2]!);
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// "Jue 22 oct".
String shortDay(DateTime d) {
  const w = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  const m = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  return '${w[d.weekday - 1]} ${d.day} ${m[d.month - 1]}';
}

/// Ilustración de la tarjeta de un área (la web usa fotos con el mismo
/// nombre; en la app, color e icono).
enum AreaArt {
  beachPool(Icons.pool_rounded, Color(0xFF2E7D8C)),
  brightRoom(Icons.celebration_outlined, Color(0xFFB07A2B)),
  lakeRoom(Icons.kayaking_rounded, Color(0xFF3D6B5A)),
  antiguaArch(Icons.account_balance_outlined, Color(0xFF8C5A3C));

  const AreaArt(this.icon, this.color);
  final IconData icon;
  final Color color;

  static AreaArt of(String key) => AreaArt.values.firstWhere((a) => a.name == key, orElse: () => AreaArt.brightRoom);
}

class SharedArea {
  const SharedArea({
    required this.id,
    required this.name,
    required this.building,
    required this.capacity,
    required this.opens,
    required this.closes,
    required this.block,
    required this.maxPerDay,
    required this.advanceHours,
    required this.advanceDays,
    required this.rules,
    required this.photo,
    this.description,
  });

  factory SharedArea.fromJson(Map<String, dynamic> j) => SharedArea(
    id: _s(j['id']),
    name: _s(j['name']),
    building: _s(j['building']),
    capacity: _i(j['capacity']),
    opens: _s(j['opens'], '08:00'),
    closes: _s(j['closes'], '20:00'),
    block: _i(j['block']) == 0 ? 60 : _i(j['block']),
    maxPerDay: _i(j['max_per_day']) == 0 ? 1 : _i(j['max_per_day']),
    advanceHours: _i(j['advance_hours']),
    advanceDays: _i(j['advance_days']) == 0 ? 7 : _i(j['advance_days']),
    rules: _s(j['rules']),
    photo: AreaArt.of(_s(j['photo'])),
    description: j['description'] as String?,
  );

  final String id;
  final String name;
  final String building;
  final int capacity;
  final String opens;
  final String closes;
  final int block;
  final int maxPerDay;
  final int advanceHours;
  final int advanceDays;
  final String rules;
  final AreaArt photo;
  final String? description;

  String get hours => '$opens – $closes';
}

class AreaSlot {
  const AreaSlot({required this.start, required this.end, required this.left, required this.past});

  factory AreaSlot.fromJson(Map<String, dynamic> j) =>
      AreaSlot(start: _s(j['start']), end: _s(j['end']), left: _i(j['left']), past: _b(j['past']));

  final String start;
  final String end;
  final int left;
  final bool past;

  bool get available => !past && left > 0;
}

class AreaBooking {
  const AreaBooking({
    required this.id,
    required this.areaId,
    required this.areaName,
    required this.date,
    required this.start,
    required this.end,
    required this.guestName,
    required this.propertyCode,
    required this.people,
    required this.byStaff,
    required this.startsAt,
    this.reservationId,
  });

  factory AreaBooking.fromJson(Map<String, dynamic> j) => AreaBooking(
    id: _s(j['id']),
    areaId: _s(j['area_id']),
    areaName: _s(j['area_name']),
    date: _s(j['date']),
    start: _s(j['start']),
    end: _s(j['end']),
    guestName: _s(j['guest_name']),
    propertyCode: _s(j['property_code']),
    people: _i(j['people']) == 0 ? 1 : _i(j['people']),
    byStaff: _b(j['by_staff']),
    startsAt: DateTime.tryParse(_s(j['starts_at']))?.toLocal() ?? parseDay(_s(j['date'])),
    reservationId: j['reservation_id'] as String?,
  );

  final String id;
  final String areaId;
  final String areaName;
  final String date;
  final String start;
  final String end;
  final String guestName;
  final String propertyCode;
  final int people;
  final bool byStaff;
  final DateTime startsAt;
  final String? reservationId;

  /// Se puede cancelar hasta 1 h antes (regla del backend).
  bool cancellable(DateTime now) => startsAt.isAfter(now.add(const Duration(hours: 1)));
}

/// Un espacio asignado a una estancia (`AssignmentRead`).
class ParkingSpot {
  const ParkingSpot({
    required this.id,
    required this.spaceCode,
    required this.building,
    required this.level,
    required this.covered,
    required this.plate,
    required this.from,
    required this.to,
    required this.reservationId,
    required this.reservationCode,
    required this.guestName,
    required this.propertyCode,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> j) => ParkingSpot(
    id: _s(j['id']),
    spaceCode: _s(j['space_code']),
    building: _s(j['building']),
    level: _s(j['level']),
    covered: _b(j['covered']),
    plate: _s(j['plate']),
    from: _s(j['from']),
    to: _s(j['to']),
    reservationId: _s(j['reservation_id']),
    reservationCode: _s(j['reservation_code']),
    guestName: _s(j['guest_name']),
    propertyCode: _s(j['property_code']),
  );

  final String id;
  final String spaceCode;
  final String building;
  final String level;
  final bool covered;
  final String plate;
  final String from;
  final String to;
  final String reservationId;
  final String reservationCode;
  final String guestName;
  final String propertyCode;
}

enum AlarmStatus {
  scheduled('Programada'),
  fired('Sonando'),
  attended('Atendida'),
  cancelled('Cancelada');

  const AlarmStatus(this.label);
  final String label;

  static AlarmStatus of(String v) => AlarmStatus.values.firstWhere((s) => s.name == v, orElse: () => AlarmStatus.scheduled);
}

class SecurityAlarm {
  const SecurityAlarm({
    required this.id,
    required this.reservationId,
    required this.reservationCode,
    required this.propertyCode,
    required this.propertyName,
    required this.guestName,
    required this.exact,
    required this.fireAt,
    required this.status,
    required this.checkOutTime,
    required this.plates,
    this.attendedByName,
    this.attendedAt,
    this.notes,
  });

  factory SecurityAlarm.fromJson(Map<String, dynamic> j) => SecurityAlarm(
    id: _s(j['id']),
    reservationId: _s(j['reservation_id']),
    reservationCode: _s(j['reservation_code']),
    propertyCode: _s(j['property_code']),
    propertyName: _s(j['property_name']),
    guestName: _s(j['guest_name']),
    exact: _b(j['exact']),
    fireAt: DateTime.tryParse(_s(j['fire_at']))?.toLocal() ?? DateTime.now(),
    status: AlarmStatus.of(_s(j['status'])),
    checkOutTime: _s(j['check_out_time']),
    plates: [for (final p in j['plates'] as List? ?? const []) '$p'],
    attendedByName: j['attended_by_name'] as String?,
    attendedAt: DateTime.tryParse(_s(j['attended_at']))?.toLocal(),
    notes: j['notes'] as String?,
  );

  final String id;
  final String reservationId;
  final String reservationCode;
  final String propertyCode;
  final String propertyName;
  final String guestName;
  final bool exact;
  final DateTime fireAt;
  final AlarmStatus status;
  final String checkOutTime;
  final List<String> plates;
  final String? attendedByName;
  final DateTime? attendedAt;
  final String? notes;

  bool get open => status == AlarmStatus.scheduled || status == AlarmStatus.fired;

  SecurityAlarm attended(String? by, String? note) => SecurityAlarm(
    id: id,
    reservationId: reservationId,
    reservationCode: reservationCode,
    propertyCode: propertyCode,
    propertyName: propertyName,
    guestName: guestName,
    exact: exact,
    fireAt: fireAt,
    status: AlarmStatus.attended,
    checkOutTime: checkOutTime,
    plates: plates,
    attendedByName: by,
    attendedAt: DateTime.now(),
    notes: note ?? notes,
  );

  Color get tone => switch (status) {
    AlarmStatus.fired => CustomColors.error,
    AlarmStatus.scheduled => CustomColors.warning,
    _ => CustomColors.textMuted,
  };
}

/// Una estancia en el tablero de seguridad (`SecurityStay`).
class BoardStay {
  const BoardStay({
    required this.reservationId,
    required this.code,
    required this.propertyCode,
    required this.propertyName,
    required this.building,
    required this.guestName,
    required this.status,
    required this.checkInDate,
    required this.checkOutDate,
    required this.checkInTime,
    required this.checkOutTime,
    required this.adults,
    required this.children,
    required this.channelName,
    required this.plates,
  });

  factory BoardStay.fromJson(Map<String, dynamic> j) => BoardStay(
    reservationId: _s(j['reservation_id']),
    code: _s(j['code']),
    propertyCode: _s(j['property_code']),
    propertyName: _s(j['property_name']),
    building: _s(j['building']),
    guestName: _s(j['guest_name']),
    status: _s(j['status']),
    checkInDate: _s(j['check_in_date']),
    checkOutDate: _s(j['check_out_date']),
    checkInTime: _s(j['check_in_time']),
    checkOutTime: _s(j['check_out_time']),
    adults: _i(j['adults']),
    children: _i(j['children']),
    channelName: _s(j['channel_name']),
    plates: [for (final p in j['plates'] as List? ?? const []) '$p'],
  );

  final String reservationId;
  final String code;
  final String propertyCode;
  final String propertyName;
  final String building;
  final String guestName;
  final String status;
  final String checkInDate;
  final String checkOutDate;
  final String checkInTime;
  final String checkOutTime;
  final int adults;
  final int children;
  final String channelName;
  final List<String> plates;

  String get people {
    final a = adults == 1 ? '1 adulto' : '$adults adultos';
    if (children == 0) return a;
    return '$a · ${children == 1 ? '1 niño' : '$children niños'}';
  }

  bool matches(String q) {
    final s = q.trim().toLowerCase().replaceAll(' ', '');
    if (s.isEmpty) return true;
    return guestName.toLowerCase().replaceAll(' ', '').contains(s) ||
        propertyCode.toLowerCase().contains(s) ||
        code.toLowerCase().contains(s) ||
        plates.any((p) => p.toLowerCase().contains(s));
  }
}

class SecurityBoard {
  const SecurityBoard({
    required this.date,
    required this.arrivals,
    required this.departures,
    required this.inHouse,
    required this.plates,
    required this.areaBookings,
    required this.alarms,
  });

  factory SecurityBoard.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) => [
      for (final it in j[key] as List? ?? const [])
        if (it is Map) f(Map<String, dynamic>.from(it)),
    ];
    return SecurityBoard(
      date: _s(j['date']),
      arrivals: list('arrivals', BoardStay.fromJson),
      departures: list('departures', BoardStay.fromJson),
      inHouse: list('in_house', BoardStay.fromJson),
      plates: list('plates', ParkingSpot.fromJson),
      areaBookings: list('area_bookings', AreaBooking.fromJson),
      alarms: list('alarms', SecurityAlarm.fromJson),
    );
  }

  final String date;
  final List<BoardStay> arrivals;
  final List<BoardStay> departures;
  final List<BoardStay> inHouse;
  final List<ParkingSpot> plates;
  final List<AreaBooking> areaBookings;
  final List<SecurityAlarm> alarms;
}
