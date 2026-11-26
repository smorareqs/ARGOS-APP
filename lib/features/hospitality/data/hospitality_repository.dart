import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/core/network/dio_client.dart';
import 'package:argos_app/core/realtime/realtime_providers.dart';
import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:argos_app/features/hospitality/models/reservation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Datos de hospitalidad del personal: tablero y alarmas de seguridad (D1–D3),
/// áreas comunes y parqueos, y las reservas del supervisor (C5–C10).
class HospitalityRepository {
  HospitalityRepository(this._dio);

  final Dio _dio;

  // ── Seguridad ────────────────────────────────────────────

  Future<SecurityBoard> board(DateTime day) async => SecurityBoard.fromJson(
    _map(await _call(() => _dio.get<dynamic>('/security/dashboard', queryParameters: {'date': dayKey(day)}))),
  );

  /// [status]: `pending`, `today` o `all`.
  Future<List<SecurityAlarm>> alarms(String status) async => [
    for (final it in _list(await _call(() => _dio.get<dynamic>('/security/alarms', queryParameters: {'status': status}))))
      SecurityAlarm.fromJson(it),
  ];

  Future<SecurityAlarm> attend(String alarmId, String? notes) async => SecurityAlarm.fromJson(
    _map(
      await _call(
        () => _dio.post<dynamic>(
          '/security/alarms/$alarmId/attend',
          data: {if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim()},
        ),
      ),
    ),
  );

  // ── Áreas y parqueos ─────────────────────────────────────

  Future<List<SharedArea>> areas() async => [
    for (final it in _list(await _call(() => _dio.get<dynamic>('/shared-areas')))) SharedArea.fromJson(it),
  ];

  Future<List<AreaBooking>> bookings(DateTime from, DateTime to) async => [
    for (final it in _list(
      await _call(
        () => _dio.get<dynamic>('/shared-areas/bookings', queryParameters: {'from': dayKey(from), 'to': dayKey(to)}),
      ),
    ))
      AreaBooking.fromJson(it),
  ];

  Future<List<ParkingSpot>> assignments(DateTime from, DateTime to) async => [
    for (final it in _list(
      await _call(
        () => _dio.get<dynamic>('/parking/assignments', queryParameters: {'from': dayKey(from), 'to': dayKey(to)}),
      ),
    ))
      ParkingSpot.fromJson(it),
  ];

  /// Espacios activos y sin bloquear: (id, código, nivel).
  Future<List<(String, String, String)>> spaces() async => [
    for (final it in _list(await _call(() => _dio.get<dynamic>('/parking/spaces'))))
      if (it['active'] != false && it['blocked'] != true) ('${it['id']}', '${it['code']}', '${it['level'] ?? ''}'),
  ];

  Future<ParkingSpot> assignParking({required String spaceId, required String reservationCode, required String plate, String? description}) async =>
      ParkingSpot.fromJson(
        _map(
          await _call(
            () => _dio.post<dynamic>(
              '/parking/assignments',
              data: {
                'space_id': spaceId,
                'reservation_code': reservationCode,
                'plate': plate.trim().toUpperCase(),
                if (description != null && description.trim().isNotEmpty) 'vehicle_description': description.trim(),
              },
            ),
          ),
        ),
      );

  Future<void> releaseParking(String assignmentId) => _call(() => _dio.delete<dynamic>('/parking/assignments/$assignmentId'));

  // ── Reservas ─────────────────────────────────────────────

  /// Estancias que tocan [from, to).
  Future<List<Reservation>> reservations(DateTime from, DateTime to) async {
    final m = _map(
      await _call(
        () => _dio.get<dynamic>(
          '/reservations',
          queryParameters: {'from': dayKey(from), 'to': dayKey(to), 'limit': 200},
        ),
      ),
    );
    return [for (final it in _list(m['items'])) Reservation.fromJson(it)];
  }

  /// La ficha con su parqueo y áreas reservadas (si el módulo está activo).
  Future<ReservationDetail> detail(String id) async {
    final d = _detail(await _call(() => _dio.get<dynamic>('/reservations/$id')));
    return _withExtras(d);
  }

  Future<ReservationDetail> _withExtras(ReservationDetail d) async {
    final r = d.reservation;
    Future<List<T>> optional<T>(Future<List<T>> Function() fn) async {
      try {
        return await fn();
      } on Object {
        return <T>[];
      }
    }

    final parking = await optional(() => assignments(r.checkInDate, r.checkOutDate));
    final bookings = await optional(() => this.bookings(r.checkInDate, r.checkOutDate));
    return d.withExtras(
      parking: [for (final p in parking) if (p.reservationId == r.id) p],
      bookings: [for (final b in bookings) if (b.reservationId == r.id) b],
    );
  }

  Future<ReservationDetail> checkIn(String id) async =>
      _withExtras(_detail(await _call(() => _dio.post<dynamic>('/reservations/$id/check-in'))));

  Future<ReservationDetail> checkOut(String id) async =>
      _withExtras(_detail(await _call(() => _dio.post<dynamic>('/reservations/$id/check-out'))));

  /// Huésped ya registrado con ese número de documento (C7).
  Future<StayGuest?> findByDocument(String number) async {
    final m = _map(await _call(() => _dio.get<dynamic>('/guests', queryParameters: {'document': number.trim(), 'limit': 5})));
    final items = _list(m['items']);
    final n = number.trim().toUpperCase();
    final hit = items.where((g) => '${g['document_number'] ?? ''}'.toUpperCase() == n).firstOrNull;
    return hit == null ? null : StayGuest.fromJson(hit);
  }

  Future<ReservationDetail> addGuest(String reservationId, {String? guestId, Map<String, dynamic>? guest, bool primary = false}) async =>
      _withExtras(
        _detail(
          await _call(
            () => _dio.post<dynamic>(
              '/reservations/$reservationId/guests',
              data: {'guest_id': ?guestId, 'guest': ?guest, if (primary) 'is_primary': true},
            ),
          ),
        ),
      );

  Future<void> updateGuest(String guestId, Map<String, dynamic> changes) =>
      _call(() => _dio.patch<dynamic>('/guests/$guestId', data: changes));

  Future<void> attachDocument(String guestId, String kind, String fileId) =>
      _call(() => _dio.post<dynamic>('/guests/$guestId/documents', data: {'kind': kind, 'file_id': fileId}));

  Future<Deposit> depositTx(
    String reservationId, {
    required String type,
    required double amount,
    required String method,
    String? reference,
    String? notes,
  }) async => Deposit.fromJson(
    _map(
      await _call(
        () => _dio.post<dynamic>(
          '/reservations/$reservationId/deposit/transactions',
          data: {
            'type': type,
            'amount': amount,
            'method': method,
            if (reference != null && reference.trim().isNotEmpty) 'reference': reference.trim(),
            if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
          },
        ),
      ),
    ),
  );

  Future<ReservationDetail> createInspection(
    String reservationId, {
    required String kind,
    String? notes,
    List<String> photoIds = const [],
    String? taskId,
  }) async => _withExtras(
    _detail(
      await _call(
        () => _dio.post<dynamic>(
          '/reservations/$reservationId/inspections',
          data: {
            'kind': kind,
            if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
            if (photoIds.isNotEmpty) 'photo_file_ids': photoIds,
            'task_id': ?taskId,
          },
        ),
      ),
    ),
  );

  Future<ReservationDetail> addFinding(
    String inspectionId, {
    required String area,
    required String description,
    required String severity,
    double? cost,
    bool charge = false,
    bool createTicket = false,
    List<String> photoIds = const [],
  }) async => _withExtras(
    _detail(
      await _call(
        () => _dio.post<dynamic>(
          '/inspections/$inspectionId/findings',
          data: {
            'area': area.trim(),
            'description': description.trim(),
            'severity': severity,
            'estimated_cost': ?cost,
            if (charge) 'charge_to_deposit': true,
            if (createTicket) 'create_ticket': true,
            if (photoIds.isNotEmpty) 'photo_file_ids': photoIds,
          },
        ),
      ),
    ),
  );

  static ReservationDetail _detail(Object? d) => ReservationDetail.fromJson(_map(d));

  static Map<String, dynamic> _map(Object? d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};

  static List<Map<String, dynamic>> _list(Object? d) => [
    for (final it in d is List ? d : const [])
      if (it is Map) Map<String, dynamic>.from(it),
  ];

  static Future<Object?> _call(Future<Response<dynamic>> Function() fn) async {
    try {
      return (await fn()).data;
    } on DioException catch (e) {
      final api = ApiException.fromDio(e);
      if (api != null) throw api;
      rethrow;
    }
  }
}

final hospitalityRepositoryProvider = Provider<HospitalityRepository>(
  (ref) => HospitalityRepository(ref.watch(dioClientProvider)),
);

DateTime _today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Recarga el proveedor cuando llega un aviso de alarma por tiempo real.
void _refreshOnAlarm(Ref ref) {
  ref.listen(realtimeMessagesProvider, (_, next) {
    final type = next.valueOrNull?.type ?? '';
    if (type == 'security.alarm' || type.startsWith('reservation.')) ref.invalidateSelf();
  });
}

/// D1 · Tablero del día (clave `yyyy-mm-dd`).
final securityBoardProvider = FutureProvider.autoDispose.family<SecurityBoard, String>((ref, day) {
  _refreshOnAlarm(ref);
  return ref.watch(hospitalityRepositoryProvider).board(parseDay(day));
});

/// D2 · Alarmas: `pending`, `today` o `all`.
final securityAlarmsProvider = FutureProvider.autoDispose.family<List<SecurityAlarm>, String>((ref, status) {
  _refreshOnAlarm(ref);
  return ref.watch(hospitalityRepositoryProvider).alarms(status);
});

/// Reservas de áreas de un día.
final areaBookingsProvider = FutureProvider.autoDispose.family<List<AreaBooking>, String>((ref, day) {
  final d = parseDay(day);
  return ref.watch(hospitalityRepositoryProvider).bookings(d, d);
});

final sharedAreasProvider = FutureProvider.autoDispose<List<SharedArea>>(
  (ref) => ref.watch(hospitalityRepositoryProvider).areas(),
);

/// C5 · Lo que toca hoy (llegadas, salidas y hospedados).
final reservationsTodayProvider = FutureProvider.autoDispose<List<Reservation>>((ref) {
  _refreshOnAlarm(ref);
  final today = _today();
  return ref.watch(hospitalityRepositoryProvider).reservations(today, DateTime(today.year, today.month, today.day + 1));
});

/// Próximas llegadas (siete días), para la pestaña de reservas.
final reservationsUpcomingProvider = FutureProvider.autoDispose<List<Reservation>>((ref) {
  final today = _today();
  return ref.watch(hospitalityRepositoryProvider).reservations(
    DateTime(today.year, today.month, today.day + 1),
    DateTime(today.year, today.month, today.day + 8),
  );
});

/// C6 · Ficha de la reserva.
final reservationDetailProvider = FutureProvider.autoDispose.family<ReservationDetail, String>(
  (ref, id) => ref.watch(hospitalityRepositoryProvider).detail(id),
);
