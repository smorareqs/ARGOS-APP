import 'dart:convert';

import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/core/network/dio_client.dart';
import 'package:argos_app/features/notifications/models/app_notification.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_repository.g.dart';

/// Bandeja de avisos, preferencias y registro del teléfono para push
/// (fase03 §4). La primera página se guarda para verla sin conexión.
class NotificationsRepository {
  NotificationsRepository(this._dio, this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final Dio _dio;
  final AppDatabase _db;
  final DateTime Function() _now;

  static const _key = 'notifications:first';

  /// Primera página (o la siguiente con [cursor]). Sin red devuelve la copia
  /// guardada de la primera.
  Future<(NotificationPage, DateTime?)> list({String? cursor}) async {
    try {
      final data = await _call(
        () => _dio.get<dynamic>(
          '/notifications',
          queryParameters: {'limit': 30, 'cursor': ?cursor},
        ),
      );
      final json = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      if (cursor == null) {
        await _db
            .into(_db.apiCache)
            .insertOnConflictUpdate(
              ApiCacheCompanion.insert(key: _key, body: jsonEncode(json), savedAt: _now()),
            );
      }
      return (NotificationPage.fromJson(json), null);
    } on DioException {
      if (cursor != null) rethrow;
      final cached = await (_db.select(_db.apiCache)..where((t) => t.key.equals(_key))).getSingleOrNull();
      if (cached == null) rethrow;
      return (
        NotificationPage.fromJson(Map<String, dynamic>.from(jsonDecode(cached.body) as Map)),
        cached.savedAt,
      );
    }
  }

  Future<void> markRead(String id) => _call(() => _dio.post<dynamic>('/notifications/$id/read'));

  Future<void> markAllRead() => _call(() => _dio.post<dynamic>('/notifications/read-all'));

  Future<List<NotificationPreference>> preferences() async {
    final data = await _call(() => _dio.get<dynamic>('/notifications/preferences'));
    return _prefs(data);
  }

  Future<List<NotificationPreference>> savePreferences(List<NotificationPreference> items) async {
    final data = await _call(
      () => _dio.put<dynamic>(
        '/notifications/preferences',
        data: {'items': [for (final p in items) if (!p.critical) p.toJson()]},
      ),
    );
    return _prefs(data);
  }

  Future<void> registerDevice(String token, String platform) => _call(
    () => _dio.post<dynamic>('/devices', data: {'token': token, 'platform': platform}),
  );

  Future<void> removeDevice(String token) =>
      _call(() => _dio.delete<dynamic>('/devices/${Uri.encodeComponent(token)}'));

  static List<NotificationPreference> _prefs(Object? data) => [
    for (final it in data is List ? data : const [])
      if (it is Map) NotificationPreference.fromJson(Map<String, dynamic>.from(it)),
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

@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) =>
    NotificationsRepository(ref.watch(dioClientProvider), ref.watch(appDatabaseProvider));
