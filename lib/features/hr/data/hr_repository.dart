import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/core/network/dio_client.dart';
import 'package:argos_app/core/realtime/realtime_providers.dart';
import 'package:argos_app/features/hr/models/hr.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Datos de la fase 5: marcaje, boletas, disciplina, métricas y el reporte
/// del propietario.
class HrRepository {
  HrRepository(this._dio);

  final Dio _dio;

  // ── Asistencia ───────────────────────────────────────────

  Future<AttendanceMonth> myAttendance(String month) async =>
      AttendanceMonth.fromJson(_map(await _call(() => _dio.get<dynamic>('/attendance/me', queryParameters: {'month': month}))));

  Future<AttendanceRecord> clock({required bool entering, required double lat, required double lng, String? photoFileId}) async =>
      AttendanceRecord.fromJson(
        _map(
          await _call(
            () => _dio.post<dynamic>(
              entering ? '/attendance/clock-in' : '/attendance/clock-out',
              data: {'lat': lat, 'lng': lng, if (photoFileId != null) 'photo_file_id': photoFileId},
            ),
          ),
        ),
      );

  /// C1: quién marcó ese día (solo con tasks.assign o RRHH).
  Future<List<AttendanceRecord>> day(String date) async => [
    for (final it in _list(await _call(() => _dio.get<dynamic>('/attendance/day', queryParameters: {'date': date}))))
      AttendanceRecord.fromJson(it),
  ];

  // ── Boletas y disciplina ─────────────────────────────────

  Future<List<Payslip>> payslips() async => [
    for (final it in _list(_map(await _call(() => _dio.get<dynamic>('/payroll/me')))['items'])) Payslip.fromJson(it),
  ];

  Future<List<DisciplinaryAction>> disciplinary() async => [
    for (final it in _list(_map(await _call(() => _dio.get<dynamic>('/disciplinary/me')))['items'])) DisciplinaryAction.fromJson(it),
  ];

  Future<DisciplinaryAction> acknowledge(String id, String? note) async => DisciplinaryAction.fromJson(
    _map(
      await _call(
        () => _dio.post<dynamic>('/disciplinary/$id/acknowledge', data: {if (note != null && note.trim().isNotEmpty) 'note': note.trim()}),
      ),
    ),
  );

  // ── Métricas ─────────────────────────────────────────────

  Future<MyMetrics> myMetrics(String range) async =>
      MyMetrics.fromJson(_map(await _call(() => _dio.get<dynamic>('/metrics/me', queryParameters: {'range': range}))));

  Future<TeamMetrics> team(String range) async =>
      TeamMetrics.fromJson(_map(await _call(() => _dio.get<dynamic>('/metrics/team', queryParameters: {'range': range}))));

  Future<MonthReport> report(String month) async =>
      MonthReport.fromJson(_map(await _call(() => _dio.get<dynamic>('/metrics/report', queryParameters: {'month': month}))));

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

final hrRepositoryProvider = Provider<HrRepository>((ref) => HrRepository(ref.watch(dioClientProvider)));

/// Recarga cuando llega un aviso del tipo (boleta, disciplina o marcaje).
void _refreshOn(Ref ref, bool Function(String type) match) {
  ref.listen(realtimeMessagesProvider, (_, next) {
    final msg = next.valueOrNull;
    if (msg == null) return;
    final type = msg.data?['type'];
    final kind = msg.type == 'notification' && type is String ? type : msg.type;
    if (match(kind)) ref.invalidateSelf();
  });
}

/// B15 · Mi asistencia del mes `yyyy-mm`.
final myAttendanceProvider = FutureProvider.autoDispose.family<AttendanceMonth, String>((ref, month) {
  _refreshOn(ref, (t) => t.startsWith('attendance'));
  return ref.watch(hrRepositoryProvider).myAttendance(month);
});

/// C1 · Quién marcó ese día (`yyyy-mm-dd`). Vacío si la sesión no puede verlo.
final teamAttendanceProvider = FutureProvider.autoDispose.family<List<AttendanceRecord>, String>((ref, date) async {
  try {
    return await ref.watch(hrRepositoryProvider).day(date);
  } on ApiException catch (e) {
    if (e.statusCode == 403 || e.statusCode == 404) return const [];
    rethrow;
  }
});

/// B20 · Mis boletas.
final payslipsProvider = FutureProvider.autoDispose<List<Payslip>>((ref) {
  _refreshOn(ref, (t) => t == 'payslip_available');
  return ref.watch(hrRepositoryProvider).payslips();
});

/// B21 · Mi historial disciplinario.
final disciplinaryProvider = FutureProvider.autoDispose<List<DisciplinaryAction>>((ref) {
  _refreshOn(ref, (t) => t.startsWith('disciplinary'));
  return ref.watch(hrRepositoryProvider).disciplinary();
});

/// B19 · Mis métricas (`week`, `month`, `7d`, `30d`).
final myMetricsProvider = FutureProvider.autoDispose.family<MyMetrics, String>(
  (ref, range) => ref.watch(hrRepositoryProvider).myMetrics(range),
);

/// Métricas del equipo (supervisor).
final teamMetricsProvider = FutureProvider.autoDispose.family<TeamMetrics, String>(
  (ref, range) => ref.watch(hrRepositoryProvider).team(range),
);

/// E3 · Reporte del mes `yyyy-mm`.
final monthReportProvider = FutureProvider.autoDispose.family<MonthReport, String>(
  (ref, month) => ref.watch(hrRepositoryProvider).report(month),
);
