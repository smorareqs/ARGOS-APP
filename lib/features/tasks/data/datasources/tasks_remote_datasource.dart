import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tasks_remote_datasource.g.dart';

/// Tareas (fase02 §4). Devuelve el JSON crudo para que el repositorio lo
/// pueda guardar tal cual en la caché.
class TasksRemoteDataSource {
  TasksRemoteDataSource(this._dio);

  final Dio _dio;

  /// `GET /tasks?date=` del usuario (`mine=true`) o de todo su alcance
  /// (supervisor). Acepta `{items: [...]}` o una lista directa.
  Future<List<Map<String, dynamic>>> forDate(
    DateTime date, {
    bool mine = true,
  }) => _call(() async {
    final response = await _dio.get<dynamic>(
      '/tasks',
      queryParameters: {
        'date': isoDate(date),
        if (mine) 'mine': true,
        'limit': 500,
      },
    );
    final data = response.data;
    final items = data is Map ? data['items'] : data;
    return [
      for (final item in (items as List? ?? const []).whereType<Map>())
        Map<String, dynamic>.from(item),
    ];
  });

  /// `GET /tasks/{id}`: la tarea con su checklist y la custodia propia.
  Future<Map<String, dynamic>> detail(String id) =>
      _map(() => _dio.get<dynamic>('/tasks/$id'));

  /// `POST /tasks/{id}/start` con el GPS.
  Future<Map<String, dynamic>> start(String id, double lat, double lng) =>
      _map(() => _dio.post<dynamic>(
        '/tasks/$id/start',
        data: {'lat': lat, 'lng': lng},
      ));

  /// `PATCH /tasks/{id}/checklist/{item}`.
  Future<Map<String, dynamic>> updateItem(
    String id,
    String itemId, {
    bool? isDone,
    String? notes,
  }) => _map(() => _dio.patch<dynamic>(
    '/tasks/$id/checklist/$itemId',
    data: {'is_done': ?isDone, 'notes': ?notes},
  ));

  /// `POST /tasks/{id}/consumptions`.
  Future<Map<String, dynamic>> consumptions(
    String id,
    List<Map<String, Object>> items,
  ) => _map(() => _dio.post<dynamic>(
    '/tasks/$id/consumptions',
    data: {'items': items},
  ));

  /// `POST /tasks/{id}/complete`: GPS, notas y la conciliación de custodia.
  Future<Map<String, dynamic>> complete(
    String id, {
    required double lat,
    required double lng,
    String? notes,
    required List<Map<String, Object>> custody,
  }) => _map(() => _dio.post<dynamic>(
    '/tasks/$id/complete',
    data: {
      'lat': lat,
      'lng': lng,
      'notes': ?notes,
      'custody': custody,
    },
  ));

  /// `POST /tasks/{id}/validate` o `/return` (supervisor).
  Future<Map<String, dynamic>> decide(
    String id, {
    required bool approve,
    String? note,
  }) => _map(() => _dio.post<dynamic>(
    '/tasks/$id/${approve ? 'validate' : 'return'}',
    data: {'note': note},
  ));

  /// `GET /tasks/assignables`: a quién se le puede asignar.
  Future<List<Map<String, dynamic>>> assignables() => _call(() async {
    final data = (await _dio.get<dynamic>('/tasks/assignables')).data;
    final items = data is Map ? data['items'] : data;
    return [
      for (final item in (items as List? ?? const []).whereType<Map>())
        Map<String, dynamic>.from(item),
    ];
  });

  /// `POST /tasks/{id}/reschedule`: otra persona, otro día u otra ventana.
  Future<Map<String, dynamic>> reschedule(
    String id, {
    String? assigneeId,
    bool changeAssignee = false,
    DateTime? date,
    String? start,
    String? end,
    required String reason,
  }) => _map(() => _dio.post<dynamic>(
    '/tasks/$id/reschedule',
    data: {
      if (changeAssignee) 'assignee_id': assigneeId,
      if (date != null) 'date': isoDate(date),
      'start': ?start,
      'end': ?end,
      'reason': reason,
    },
  ));

  /// `GET /properties/{id}/access-info` (solo el día con tarea).
  Future<String> accessInfo(String propertyId) async {
    final data = await _map(
      () => _dio.get<dynamic>('/properties/$propertyId/access-info'),
    );
    return '${data['text'] ?? ''}';
  }

  /// Ejecuta una petición ya armada (la cola sin conexión).
  Future<Map<String, dynamic>> send(
    String method,
    String path,
    Object? body,
  ) => _map(() => _dio.request<dynamic>(
    path,
    data: body,
    options: Options(method: method),
  ));

  Future<Map<String, dynamic>> _map(
    Future<Response<dynamic>> Function() request,
  ) => _call(() async {
    final data = (await request()).data;
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  });

  static Future<T> _call<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      final api = ApiException.fromDio(e);
      if (api != null) throw api;
      rethrow;
    }
  }

  static String isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

@Riverpod(keepAlive: true)
TasksRemoteDataSource tasksRemoteDataSource(Ref ref) =>
    TasksRemoteDataSource(ref.watch(dioClientProvider));
