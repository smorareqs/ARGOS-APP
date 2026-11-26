import 'package:argos_app/features/hospitality/models/hospitality.dart';

/// El huésped de la sesión (`GET /guest/me`).
class GuestMe {
  const GuestMe({
    required this.guestId,
    required this.name,
    required this.tenantName,
    required this.reservationId,
    required this.reservationCode,
    required this.expiresAt,
    required this.features,
    this.email,
  });

  factory GuestMe.fromJson(Map<String, dynamic> j) => GuestMe(
    guestId: '${j['guest_id'] ?? ''}',
    name: '${j['name'] ?? ''}',
    email: j['email'] as String?,
    tenantName: '${j['tenant_name'] ?? ''}',
    reservationId: '${j['reservation_id'] ?? ''}',
    reservationCode: '${j['reservation_code'] ?? ''}',
    expiresAt: DateTime.tryParse('${j['expires_at']}')?.toLocal() ?? DateTime.now(),
    features: {for (final e in (j['features'] as Map? ?? const {}).entries) '${e.key}': e.value == true},
  );

  Map<String, dynamic> toJson() => {
    'guest_id': guestId,
    'name': name,
    'email': email,
    'tenant_name': tenantName,
    'reservation_id': reservationId,
    'reservation_code': reservationCode,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'features': features,
  };

  final String guestId;
  final String name;
  final String? email;
  final String tenantName;
  final String reservationId;
  final String reservationCode;
  final DateTime expiresAt;
  final Map<String, bool> features;

  String get firstName => name.trim().split(' ').first;
  bool get parking => features['parking'] ?? false;
  bool get sharedAreas => features['shared_areas'] ?? false;
}

/// Sesión guardada del huésped: el token y quién es.
class GuestSession {
  const GuestSession({required this.token, required this.me});

  final String token;
  final GuestMe me;

  bool expired(DateTime now) => !me.expiresAt.isAfter(now);
}

enum StayPhase { before, during, after }

/// Mi reserva (`GET /guest/reservation`).
class GuestStay {
  const GuestStay({
    required this.code,
    required this.status,
    required this.propertyCode,
    required this.propertyName,
    required this.checkInDate,
    required this.checkOutDate,
    required this.checkInTime,
    required this.checkOutTime,
    required this.nights,
    required this.adults,
    required this.children,
    required this.guestName,
    required this.instructions,
    required this.contactName,
    required this.parkingCount,
    required this.bookingsCount,
    this.address,
    this.building,
    this.lat,
    this.lng,
    this.contactPhone,
    this.contactEmail,
  });

  factory GuestStay.fromJson(Map<String, dynamic> j) => GuestStay(
    code: '${j['code'] ?? ''}',
    status: '${j['status'] ?? ''}',
    propertyCode: '${j['property_code'] ?? ''}',
    propertyName: '${j['property_name'] ?? ''}',
    address: j['property_address'] as String?,
    building: j['building'] as String?,
    lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble(),
    checkInDate: parseDay('${j['check_in_date']}'),
    checkOutDate: parseDay('${j['check_out_date']}'),
    checkInTime: '${j['check_in_time'] ?? '15:00'}',
    checkOutTime: '${j['check_out_time'] ?? '11:00'}',
    nights: (j['nights'] as num?)?.toInt() ?? 0,
    adults: (j['adults'] as num?)?.toInt() ?? 0,
    children: (j['children'] as num?)?.toInt() ?? 0,
    guestName: '${j['guest_name'] ?? ''}',
    instructions: '${j['instructions'] ?? ''}',
    contactName: '${j['contact_name'] ?? ''}',
    contactPhone: j['contact_phone'] as String?,
    contactEmail: j['contact_email'] as String?,
    parkingCount: (j['parking_count'] as num?)?.toInt() ?? 0,
    bookingsCount: (j['bookings_count'] as num?)?.toInt() ?? 0,
  );

  final String code;
  final String status;
  final String propertyCode;
  final String propertyName;
  final String? address;
  final String? building;
  final double? lat;
  final double? lng;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String checkInTime;
  final String checkOutTime;
  final int nights;
  final int adults;
  final int children;
  final String guestName;
  final String instructions;
  final String contactName;
  final String? contactPhone;
  final String? contactEmail;
  final int parkingCount;
  final int bookingsCount;

  DateTime _at(DateTime day, String hhmm) {
    final p = hhmm.split(':');
    return DateTime(
      day.year,
      day.month,
      day.day,
      int.tryParse(p.first) ?? 0,
      int.tryParse(p.length > 1 ? p[1] : '0') ?? 0,
    );
  }

  DateTime get arrivesAt => _at(checkInDate, checkInTime);
  DateTime get leavesAt => _at(checkOutDate, checkOutTime);

  StayPhase phase(DateTime now) {
    if (status == 'checked_out' || now.isAfter(leavesAt)) return StayPhase.after;
    if (status == 'checked_in' || !now.isBefore(arrivesAt)) return StayPhase.during;
    return StayPhase.before;
  }

  /// Días en los que se pueden reservar áreas: de la entrada a la salida.
  List<DateTime> get days => [
    for (var d = checkInDate; !d.isAfter(checkOutDate); d = DateTime(d.year, d.month, d.day + 1)) d,
  ];
}
