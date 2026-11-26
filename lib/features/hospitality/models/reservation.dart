import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:design_system/design_system.dart';

/// Reservas para el supervisor y seguridad (C5–C10, D3). Siguen
/// `ReservationRead` / `ReservationDetail` del módulo `reservations`.

String _s(Object? v, [String def = '']) => v is String ? v : def;
String? _ns(Object? v) => v is String && v.isNotEmpty ? v : null;
int _i(Object? v) => v is num ? v.toInt() : 0;
double _d(Object? v) => v is num ? v.toDouble() : 0;
double? _nd(Object? v) => v is num ? v.toDouble() : null;
bool _b(Object? v) => v == true;
DateTime? _dt(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

List<Map<String, dynamic>> _list(Object? v) => [
  for (final it in v is List ? v : const [])
    if (it is Map) Map<String, dynamic>.from(it),
];

enum ReservationStatus {
  pending('Por confirmar', StatusBadgeVariant.pending),
  confirmed('Confirmada', StatusBadgeVariant.pending),
  checkedIn('Hospedado', StatusBadgeVariant.inProgress),
  checkedOut('Salió', StatusBadgeVariant.operative),
  cancelled('Cancelada', StatusBadgeVariant.incident),
  noShow('No llegó', StatusBadgeVariant.incident);

  const ReservationStatus(this.label, this.badge);
  final String label;
  final StatusBadgeVariant badge;

  static ReservationStatus of(String v) => switch (v) {
    'confirmed' => confirmed,
    'checked_in' => checkedIn,
    'checked_out' => checkedOut,
    'cancelled' => cancelled,
    'no_show' => noShow,
    _ => pending,
  };
}

/// "Recibido", "Pendiente"… del depósito.
String depositLabel(String status) => switch (status) {
  'pending' => 'Depósito pendiente',
  'received' => 'Depósito recibido',
  'returned' => 'Depósito devuelto',
  'retained_partial' => 'Retenido en parte',
  'retained_full' => 'Depósito retenido',
  _ => 'Sin depósito',
};

String money(double v, [String currency = 'USD']) {
  final whole = v == v.roundToDouble();
  final n = whole ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  final symbol = switch (currency) {
    'USD' => r'$',
    'GTQ' => 'Q',
    'CRC' => '₡',
    _ => '$currency ',
  };
  return '$symbol$n';
}

class Reservation {
  const Reservation({
    required this.id,
    required this.code,
    required this.propertyId,
    required this.propertyCode,
    required this.propertyName,
    required this.channelName,
    required this.channelKind,
    required this.requiresDeposit,
    required this.hasCheckin,
    required this.guestsCount,
    required this.guestsPending,
    required this.status,
    required this.checkInDate,
    required this.checkOutDate,
    required this.checkInTime,
    required this.checkOutTime,
    required this.nights,
    required this.adults,
    required this.children,
    required this.depositStatus,
    required this.currency,
    this.guestName,
    this.depositAmount,
    this.notes,
    this.checkedInAt,
    this.checkedOutAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> j) => Reservation(
    id: _s(j['id']),
    code: _s(j['code']),
    propertyId: _s(j['property_id']),
    propertyCode: _s(j['property_code']),
    propertyName: _s(j['property_name']),
    channelName: _s(j['channel_name']),
    channelKind: _s(j['channel_kind']),
    requiresDeposit: _b(j['requires_deposit']),
    hasCheckin: _b(j['has_checkin']),
    guestName: _ns(j['guest_name']),
    guestsCount: _i(j['guests_count']),
    guestsPending: _i(j['guests_pending']),
    status: ReservationStatus.of(_s(j['status'])),
    checkInDate: parseDay(_s(j['check_in_date'])),
    checkOutDate: parseDay(_s(j['check_out_date'])),
    checkInTime: _s(j['check_in_time'], '15:00'),
    checkOutTime: _s(j['check_out_time'], '11:00'),
    nights: _i(j['nights']),
    adults: _i(j['adults']),
    children: _i(j['children']),
    depositAmount: _nd(j['deposit_amount']),
    depositStatus: _s(j['deposit_status'], 'none'),
    currency: _s(j['currency'], 'USD'),
    notes: _ns(j['notes']),
    checkedInAt: _dt(j['checked_in_at']),
    checkedOutAt: _dt(j['checked_out_at']),
  );

  final String id;
  final String code;
  final String propertyId;
  final String propertyCode;
  final String propertyName;
  final String channelName;
  final String channelKind;
  final bool requiresDeposit;
  final bool hasCheckin;
  final String? guestName;
  final int guestsCount;
  final int guestsPending;
  final ReservationStatus status;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final String checkInTime;
  final String checkOutTime;
  final int nights;
  final int adults;
  final int children;
  final double? depositAmount;
  final String depositStatus;
  final String currency;
  final String? notes;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;

  String get displayName => guestName ?? 'Huésped por registrar';

  String get people {
    final a = adults == 1 ? '1 adulto' : '$adults adultos';
    if (children == 0) return a;
    return '$a · ${children == 1 ? '1 niño' : '$children niños'}';
  }

  bool get needsDeposit => requiresDeposit && (depositAmount ?? 0) > 0;

  bool arrivesOn(DateTime day) => _same(checkInDate, day);
  bool leavesOn(DateTime day) => _same(checkOutDate, day);

  static bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class GuestDoc {
  const GuestDoc({required this.fileId, required this.kind});

  factory GuestDoc.fromJson(Map<String, dynamic> j) => GuestDoc(fileId: _s(j['file_id']), kind: _s(j['kind']));

  final String fileId;
  final String kind;
}

/// Un huésped de la reserva con el estado de su registro.
class StayGuest {
  const StayGuest({
    required this.id,
    required this.fullName,
    required this.isPrimary,
    required this.registered,
    required this.missing,
    required this.documents,
    required this.stays,
    this.email,
    this.phone,
    this.documentType,
    this.documentNumber,
    this.nationality,
    this.lastStay,
  });

  factory StayGuest.fromJson(Map<String, dynamic> j) => StayGuest(
    id: _s(j['id']),
    fullName: _s(j['full_name']),
    email: _ns(j['email']),
    phone: _ns(j['phone']),
    documentType: _ns(j['document_type']),
    documentNumber: _ns(j['document_number']),
    nationality: _ns(j['nationality']),
    isPrimary: _b(j['is_primary']),
    registered: _b(j['registered']),
    missing: [for (final m in j['missing'] as List? ?? const []) '$m'],
    documents: [for (final d in _list(j['documents'])) GuestDoc.fromJson(d)],
    stays: _i(j['stays']),
    lastStay: _ns(j['last_stay']),
  );

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? documentType;
  final String? documentNumber;
  final String? nationality;
  final bool isPrimary;
  final bool registered;
  final List<String> missing;
  final List<GuestDoc> documents;
  final int stays;
  final String? lastStay;

  bool has(String kind) => !missing.contains(kind);

  String get missingLabel {
    final parts = [
      if (missing.contains('email')) 'correo',
      if (missing.contains('document')) 'documento',
      if (missing.contains('id_front') || missing.contains('id_back')) 'fotos del documento',
    ];
    return parts.isEmpty ? 'Registro completo' : 'Falta: ${parts.join(', ')}';
  }

  String get documentLabel => switch (documentType) {
    'passport' => 'Pasaporte',
    'dpi' => 'DPI',
    _ => 'Documento',
  };
}

class DepositTx {
  const DepositTx({required this.id, required this.type, required this.amount, required this.method, required this.createdAt, this.reference, this.notes, this.byName});

  factory DepositTx.fromJson(Map<String, dynamic> j) => DepositTx(
    id: _s(j['id']),
    type: _s(j['type']),
    amount: _d(j['amount']),
    method: _s(j['method']),
    reference: _ns(j['reference']),
    notes: _ns(j['notes']),
    byName: _ns(j['registered_by_name']),
    createdAt: _dt(j['created_at']) ?? DateTime.now(),
  );

  final String id;
  final String type;
  final double amount;
  final String method;
  final String? reference;
  final String? notes;
  final String? byName;
  final DateTime createdAt;

  String get typeLabel => switch (type) {
    'received' => 'Recibido',
    'returned' => 'Devuelto',
    'retained' => 'Retenido',
    _ => type,
  };

  static String methodLabel(String m) => switch (m) {
    'cash' => 'Efectivo',
    'transfer' => 'Transferencia',
    'card' => 'Tarjeta',
    _ => 'Otro',
  };
}

class Deposit {
  const Deposit({
    required this.available,
    required this.status,
    required this.received,
    required this.returned,
    required this.retained,
    required this.balance,
    required this.charges,
    required this.inspectionRequired,
    required this.transactions,
    this.amount,
  });

  factory Deposit.fromJson(Map<String, dynamic> j) => Deposit(
    available: _b(j['available']),
    amount: _nd(j['amount']),
    status: _s(j['status'], 'none'),
    received: _d(j['received']),
    returned: _d(j['returned']),
    retained: _d(j['retained']),
    balance: _d(j['balance']),
    charges: _d(j['charges']),
    inspectionRequired: _b(j['inspection_required']),
    transactions: [for (final t in _list(j['transactions'])) DepositTx.fromJson(t)],
  );

  static const empty = Deposit(
    available: false,
    status: 'none',
    received: 0,
    returned: 0,
    retained: 0,
    balance: 0,
    charges: 0,
    inspectionRequired: false,
    transactions: [],
  );

  final bool available;
  final double? amount;
  final String status;
  final double received;
  final double returned;
  final double retained;
  final double balance;
  final double charges;
  final bool inspectionRequired;
  final List<DepositTx> transactions;
}

class Finding {
  const Finding({
    required this.id,
    required this.area,
    required this.description,
    required this.severity,
    required this.chargeToDeposit,
    required this.photos,
    this.estimatedCost,
    this.ticketNumber,
  });

  factory Finding.fromJson(Map<String, dynamic> j) => Finding(
    id: _s(j['id']),
    area: _s(j['area']),
    description: _s(j['description']),
    severity: _s(j['severity'], 'low'),
    estimatedCost: _nd(j['estimated_cost']),
    chargeToDeposit: _b(j['charge_to_deposit']),
    ticketNumber: j['ticket_number'] is num ? (j['ticket_number'] as num).toInt() : null,
    photos: [for (final p in _list(j['photos'])) _s(p['url'])],
  );

  final String id;
  final String area;
  final String description;
  final String severity;
  final double? estimatedCost;
  final bool chargeToDeposit;
  final int? ticketNumber;
  final List<String> photos;

  String get severityLabel => switch (severity) {
    'high' => 'Grave',
    'medium' => 'Moderado',
    _ => 'Leve',
  };
}

class Inspection {
  const Inspection({required this.id, required this.kind, required this.performedAt, required this.photos, required this.findings, this.byName, this.notes});

  factory Inspection.fromJson(Map<String, dynamic> j) => Inspection(
    id: _s(j['id']),
    kind: _s(j['kind']),
    byName: _ns(j['performed_by_name']),
    performedAt: _dt(j['performed_at']) ?? DateTime.now(),
    notes: _ns(j['notes']),
    photos: [for (final p in _list(j['photos'])) _s(p['url'])],
    findings: [for (final f in _list(j['findings'])) Finding.fromJson(f)],
  );

  final String id;
  final String kind;
  final String? byName;
  final DateTime performedAt;
  final String? notes;
  final List<String> photos;
  final List<Finding> findings;

  bool get preArrival => kind == 'pre_arrival';
  String get label => preArrival ? 'Antes de la llegada' : 'Después de la salida';
}

class StayEvent {
  const StayEvent({required this.type, required this.createdAt, required this.data, this.actorName});

  factory StayEvent.fromJson(Map<String, dynamic> j) => StayEvent(
    type: _s(j['type']),
    actorName: _ns(j['actor_name']),
    data: j['data'] is Map ? Map<String, dynamic>.from(j['data'] as Map) : const {},
    createdAt: _dt(j['created_at']) ?? DateTime.now(),
  );

  final String type;
  final String? actorName;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  String get title => switch (type) {
    'created' => 'Reserva creada',
    'confirmed' => 'Reserva confirmada',
    'updated' => 'Reserva modificada',
    'checked_in' => 'Check-in',
    'checked_out' => 'Check-out',
    'cancelled' => 'Reserva cancelada',
    'no_show' => 'No llegó',
    'guest_added' => 'Huésped agregado${data['name'] == null ? '' : ': ${data['name']}'}',
    'guest_removed' => 'Huésped quitado',
    'deposit_received' => 'Depósito recibido',
    'deposit_returned' => 'Depósito devuelto',
    'deposit_retained' => 'Depósito retenido',
    'inspection_pre_arrival' => 'Inspección antes de llegar',
    'inspection_post_departure' => 'Inspección de salida',
    'area_booked' => 'Reservó ${data['area'] ?? 'un área'}',
    'guest_ticket' => 'Reportó un problema${data['number'] == null ? '' : ' (#${data['number']})'}',
    'parking_assigned' => 'Parqueo ${data['space'] ?? ''} asignado',
    'email_sent' || 'confirmation_sent' => 'Correo enviado al huésped',
    _ => type.replaceAll('_', ' '),
  };
}

class ReservationDetail {
  const ReservationDetail({
    required this.reservation,
    required this.guests,
    required this.events,
    required this.deposit,
    required this.inspections,
    this.parking = const [],
    this.bookings = const [],
  });

  factory ReservationDetail.fromJson(Map<String, dynamic> j) => ReservationDetail(
    reservation: Reservation.fromJson(j),
    guests: [for (final g in _list(j['guests'])) StayGuest.fromJson(g)],
    events: [for (final e in _list(j['events'])) StayEvent.fromJson(e)],
    deposit: j['deposit'] is Map ? Deposit.fromJson(Map<String, dynamic>.from(j['deposit'] as Map)) : Deposit.empty,
    inspections: [for (final i in _list(j['inspections'])) Inspection.fromJson(i)],
  );

  final Reservation reservation;
  final List<StayGuest> guests;
  final List<StayEvent> events;
  final Deposit deposit;
  final List<Inspection> inspections;
  final List<ParkingSpot> parking;
  final List<AreaBooking> bookings;

  ReservationDetail withExtras({List<ParkingSpot>? parking, List<AreaBooking>? bookings}) => ReservationDetail(
    reservation: reservation,
    guests: guests,
    events: events,
    deposit: deposit,
    inspections: inspections,
    parking: parking ?? this.parking,
    bookings: bookings ?? this.bookings,
  );

  Inspection? inspection(String kind) => inspections.where((i) => i.kind == kind).firstOrNull;

  int get pendingGuests => guests.where((g) => !g.registered).length;

  /// Lo que falta para el check-in, en palabras (vacío si se puede).
  List<String> checkInBlockers(DateTime today) {
    final r = reservation;
    final day = DateTime(today.year, today.month, today.day);
    return [
      if (r.status != ReservationStatus.confirmed) 'La reserva está ${r.status.label.toLowerCase()}.',
      if (r.checkInDate.isAfter(day)) 'La entrada es el ${shortDay(r.checkInDate)}.',
      if (r.hasCheckin && guests.isEmpty) 'Registra al menos un huésped.',
      if (r.hasCheckin && pendingGuests > 0)
        pendingGuests == 1 ? 'Falta completar 1 huésped.' : 'Faltan completar $pendingGuests huéspedes.',
      if (r.hasCheckin && r.needsDeposit && r.depositStatus != 'received') 'Registra el depósito.',
    ];
  }
}
