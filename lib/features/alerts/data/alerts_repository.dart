import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/core/network/dio_client.dart';
import 'package:argos_app/features/alerts/models/alert.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alerts_repository.g.dart';

/// Panel de alertas del supervisor (C4).
class AlertsRepository {
  AlertsRepository(this._dio);

  final Dio _dio;

  Future<(AlertsSummary, List<OpsAlert>)> panel() async {
    final results = await Future.wait([
      _call(() => _dio.get<dynamic>('/alerts/summary')),
      _call(() => _dio.get<dynamic>('/alerts', queryParameters: {'status': 'open', 'limit': 20})),
    ]);
    final summary = results[0] is Map
        ? AlertsSummary.fromJson(Map<String, dynamic>.from(results[0]! as Map))
        : const AlertsSummary(open: 0, high: 0, fresh: 0, byType: []);
    final page = results[1] is Map ? results[1]! as Map : const {};
    final items = [
      for (final it in page['items'] as List? ?? const [])
        if (it is Map) OpsAlert.fromJson(Map<String, dynamic>.from(it)),
    ];
    return (summary, items);
  }

  Future<void> acknowledge(String id) => _call(() => _dio.post<dynamic>('/alerts/$id/ack'));

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

@Riverpod(keepAlive: true)
AlertsRepository alertsRepository(Ref ref) => AlertsRepository(ref.watch(dioClientProvider));

@riverpod
Future<(AlertsSummary, List<OpsAlert>)> alertsPanel(Ref ref) =>
    ref.watch(alertsRepositoryProvider).panel();
