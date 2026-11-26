import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/core/network/dio_client.dart';
import 'package:argos_app/features/tickets/models/ticket.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tickets_repository.g.dart';

/// Incidencias (B12–B14). Reportar y resolver necesitan conexión: el ticket
/// lleva las fotos ya subidas y el número que devuelve el servidor.
class TicketsRepository {
  TicketsRepository(this._dio);

  final Dio _dio;

  /// [mine]: asignadas a mí (mantenimiento). Sin [mine]: las del alcance,
  /// que para limpieza son las que reportó.
  Future<List<Ticket>> list({bool mine = false, String? status}) async {
    final data = await _call(
      () => _dio.get<dynamic>(
        '/tickets',
        queryParameters: {'mine': ?(mine ? true : null), 'status': ?status, 'limit': 100},
      ),
    );
    final page = data is Map ? data : const {};
    return [
      for (final it in page['items'] as List? ?? const [])
        if (it is Map) Ticket.fromJson(Map<String, dynamic>.from(it)),
    ];
  }

  Future<TicketDetail> detail(String id) async => _detail(await _call(() => _dio.get<dynamic>('/tickets/$id')));

  Future<TicketDetail> create({
    required String propertyId,
    String? assetId,
    required String title,
    String? description,
    required String urgency,
    List<String> photoIds = const [],
  }) async => _detail(
    await _call(
      () => _dio.post<dynamic>(
        '/tickets',
        data: {
          'property_id': propertyId,
          'asset_id': ?assetId,
          'title': title.trim(),
          if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
          'urgency': urgency,
          if (photoIds.isNotEmpty) 'photo_file_ids': photoIds,
        },
      ),
    ),
  );

  Future<TicketDetail> start(String id) async => _detail(await _call(() => _dio.post<dynamic>('/tickets/$id/start')));

  Future<TicketDetail> resolve(
    String id, {
    required String resolution,
    double? cost,
    List<String> photoIds = const [],
    bool assetOperational = false,
  }) async => _detail(
    await _call(
      () => _dio.post<dynamic>(
        '/tickets/$id/resolve',
        data: {
          'resolution': resolution.trim(),
          'cost': ?cost,
          if (photoIds.isNotEmpty) 'photo_file_ids': photoIds,
          if (assetOperational) 'asset_operational': true,
        },
      ),
    ),
  );

  Future<List<PropertyOption>> properties() async {
    final data = await _call(
      () => _dio.get<dynamic>('/properties', queryParameters: {'active': 'true', 'limit': 500}),
    );
    final page = data is Map ? data : const {};
    return [
      for (final it in page['items'] as List? ?? const [])
        if (it is Map) PropertyOption.fromJson(Map<String, dynamic>.from(it)),
    ];
  }

  /// Activos de la propiedad. Quien no ve activos (403) recibe la lista vacía
  /// y reporta sin activo.
  Future<List<AssetOption>> assets(String propertyId) async {
    try {
      final data = await _call(
        () => _dio.get<dynamic>('/assets', queryParameters: {'property_id': propertyId, 'active': 'true', 'limit': 200}),
      );
      final page = data is Map ? data : const {};
      return [
        for (final it in page['items'] as List? ?? const [])
          if (it is Map) AssetOption.fromJson(Map<String, dynamic>.from(it)),
      ];
    } on ApiException catch (e) {
      if (e.statusCode == 403) return const [];
      rethrow;
    }
  }

  static TicketDetail _detail(Object? data) =>
      TicketDetail.fromJson(data is Map ? Map<String, dynamic>.from(data) : const {});

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
TicketsRepository ticketsRepository(Ref ref) => TicketsRepository(ref.watch(dioClientProvider));

@riverpod
Future<List<Ticket>> ticketList(Ref ref, {required bool mine, String? status}) =>
    ref.watch(ticketsRepositoryProvider).list(mine: mine, status: status);

@riverpod
Future<TicketDetail> ticketDetail(Ref ref, String id) => ref.watch(ticketsRepositoryProvider).detail(id);

@riverpod
Future<List<PropertyOption>> reportableProperties(Ref ref) => ref.watch(ticketsRepositoryProvider).properties();

@riverpod
Future<List<AssetOption>> propertyAssets(Ref ref, String propertyId) =>
    ref.watch(ticketsRepositoryProvider).assets(propertyId);
