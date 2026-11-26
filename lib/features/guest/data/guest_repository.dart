import 'package:argos_app/core/config/app_config.dart';
import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/core/network/mock/mock_routes.dart';
import 'package:argos_app/features/chat/models/chat.dart';
import 'package:argos_app/features/guest/models/guest.dart';
import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Token del huésped en memoria (lo escribe [GuestSessionController]).
class GuestToken {
  String? value;

  /// Se llama ante un 401: el acceso venció o lo revocaron.
  void Function()? onExpired;
}

final guestTokenProvider = Provider<GuestToken>((ref) => GuestToken());

/// Cliente del modo huésped: misma API, con el JWT del huésped. No hay
/// refresh: un 401 cierra la sesión de huésped.
final guestDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final token = ref.watch(guestTokenProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );
  if (config.useMock) dio.httpClientAdapter = ref.watch(mockBackendProvider);
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final t = token.value;
        if (t != null && !options.path.endsWith('/guest/auth')) {
          options.headers['Authorization'] = 'Bearer $t';
        }
        handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401 && !e.requestOptions.path.endsWith('/guest/auth')) {
          token.onExpired?.call();
        }
        handler.next(e);
      },
    ),
  );
  return dio;
});

/// Modo huésped (A9, F1–F9): entrar, mi reserva, áreas comunes, parqueo y
/// reportar un problema.
class GuestRepository {
  GuestRepository(this._dio);

  final Dio _dio;

  /// Con el token del enlace o con el código y el correo.
  Future<GuestSession> signIn({String? token, String? code, String? email}) async {
    final data = await _call(
      () => _dio.post<dynamic>(
        '/guest/auth',
        data: token != null ? {'token': token} : {'code': code?.trim(), 'email': email?.trim()},
      ),
    );
    final m = _map(data);
    return GuestSession(token: '${m['access_token']}', me: GuestMe.fromJson(_map(m['me'])));
  }

  Future<GuestMe> me() async => GuestMe.fromJson(_map(await _call(() => _dio.get<dynamic>('/guest/me'))));

  Future<GuestStay> reservation() async =>
      GuestStay.fromJson(_map(await _call(() => _dio.get<dynamic>('/guest/reservation'))));

  Future<List<ParkingSpot>> parking() async => [
    for (final it in _list(await _call(() => _dio.get<dynamic>('/guest/parking')))) ParkingSpot.fromJson(it),
  ];

  Future<({List<SharedArea> areas, List<AreaBooking> bookings})> areas() async {
    final m = _map(await _call(() => _dio.get<dynamic>('/guest/shared-areas')));
    return (
      areas: [for (final it in _list(m['areas'])) SharedArea.fromJson(it)],
      bookings: [for (final it in _list(m['bookings'])) AreaBooking.fromJson(it)],
    );
  }

  Future<List<AreaSlot>> availability(String areaId, DateTime day) async {
    final m = _map(
      await _call(
        () => _dio.get<dynamic>('/guest/shared-areas/$areaId/availability', queryParameters: {'date': dayKey(day)}),
      ),
    );
    return [for (final it in _list(m['slots'])) AreaSlot.fromJson(it)];
  }

  Future<AreaBooking> book(String areaId, DateTime day, String start, int people) async => AreaBooking.fromJson(
    _map(
      await _call(
        () => _dio.post<dynamic>(
          '/guest/shared-areas/$areaId/bookings',
          data: {'date': dayKey(day), 'start': start, 'people': people},
        ),
      ),
    ),
  );

  Future<List<AreaBooking>> bookings() async => [
    for (final it in _list(await _call(() => _dio.get<dynamic>('/guest/bookings')))) AreaBooking.fromJson(it),
  ];

  Future<void> cancel(String bookingId) => _call(() => _dio.delete<dynamic>('/guest/bookings/$bookingId'));

  /// Devuelve el número de incidencia.
  Future<int> report({required String title, String? description, required String urgency}) async {
    final m = _map(
      await _call(
        () => _dio.post<dynamic>(
          '/guest/tickets',
          data: {
            'title': title.trim(),
            if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
            'urgency': urgency,
          },
        ),
      ),
    );
    return (m['number'] as num?)?.toInt() ?? 0;
  }

  // ── Chat con la empresa (F8) y código de la puerta (F1) ─────────

  Future<GuestChat> chat() async => GuestChat.fromJson(_map(await _call(() => _dio.get<dynamic>('/guest/chat'))));

  Future<ChatMessage> sendChat(String body) async => ChatMessage.fromJson(
    _map(await _call(() => _dio.post<dynamic>('/guest/chat/messages', data: {'body': body.trim()}))),
  );

  Future<void> readChat() => _call(() => _dio.post<dynamic>('/guest/chat/read'));

  Future<GuestLock> lock() async => GuestLock.fromJson(_map(await _call(() => _dio.get<dynamic>('/guest/lock'))));

  Future<void> registerDevice(String fcmToken) =>
      _call(() => _dio.post<dynamic>('/guest/device', data: {'token': fcmToken}));

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

final guestRepositoryProvider = Provider<GuestRepository>((ref) => GuestRepository(ref.watch(guestDioProvider)));
