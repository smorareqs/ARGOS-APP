import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tasks_remote_datasource.g.dart';

/// Tareas (fase02 §4). Devuelve el JSON crudo de la lista para que el
/// repositorio lo pueda guardar tal cual en la caché.
class TasksRemoteDataSource {
  TasksRemoteDataSource(this._dio);

  final Dio _dio;

  /// `GET /tasks?date=YYYY-MM-DD` del usuario. Acepta `{items: [...]}` o una
  /// lista directa.
  Future<List<Map<String, dynamic>>> forDate(DateTime date) async {
    try {
      final response = await _dio.get<dynamic>(
        '/tasks',
        queryParameters: {'date': isoDate(date)},
      );
      final data = response.data;
      final items = data is Map ? data['items'] : data;
      return [
        for (final item in (items as List? ?? const []).whereType<Map>())
          Map<String, dynamic>.from(item),
      ];
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
