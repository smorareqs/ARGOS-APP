import 'dart:convert';

import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/core/network/dio_client.dart';
import 'package:argos_app/features/inventory/models/my_inventory.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'inventory_repository.g.dart';

/// Mi inventario (B9–B11). La custodia se guarda para verla sin conexión;
/// sacar artículos y pedir reposición necesitan conexión (la bodega debe
/// confirmar que hay existencia).
class InventoryRepository {
  InventoryRepository(this._dio, this._db, {DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  final Dio _dio;
  final AppDatabase _db;
  final DateTime Function() _now;

  static const _key = 'inventory:me';

  Future<(MyInventory, DateTime?)> mine() async {
    try {
      final data = await _call(() => _dio.get<dynamic>('/inventory/me'));
      final json = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      await _db
          .into(_db.apiCache)
          .insertOnConflictUpdate(
            ApiCacheCompanion.insert(key: _key, body: jsonEncode(json), savedAt: _now()),
          );
      return (MyInventory.fromJson(json), null);
    } on DioException {
      final cached = await (_db.select(_db.apiCache)..where((t) => t.key.equals(_key))).getSingleOrNull();
      if (cached == null) rethrow;
      return (
        MyInventory.fromJson(Map<String, dynamic>.from(jsonDecode(cached.body) as Map)),
        cached.savedAt,
      );
    }
  }

  /// Saca artículos de una bodega a la custodia propia.
  Future<void> checkout(String warehouseId, Map<String, int> qty) async {
    for (final e in qty.entries.where((e) => e.value > 0)) {
      await _call(
        () => _dio.post<dynamic>(
          '/inventory/movements',
          data: {'kind': 'checkout', 'item_id': e.key, 'warehouse_id': warehouseId, 'qty': e.value},
        ),
      );
    }
  }

  /// Devuelve a la bodega lo que tiene en custodia.
  Future<void> giveBack(String warehouseId, String itemId, double qty) => _call(
    () => _dio.post<dynamic>(
      '/inventory/movements',
      data: {'kind': 'return', 'item_id': itemId, 'warehouse_id': warehouseId, 'qty': qty},
    ),
  );

  Future<void> requestRestock({
    required Map<String, int> items,
    String? note,
    String? propertyId,
  }) => _call(
    () => _dio.post<dynamic>(
      '/inventory/restock-requests',
      data: {
        'property_id': ?propertyId,
        'items': [
          for (final e in items.entries)
            if (e.value > 0) {'item_id': e.key, 'quantity': e.value},
        ],
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    ),
  );

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
InventoryRepository inventoryRepository(Ref ref) =>
    InventoryRepository(ref.watch(dioClientProvider), ref.watch(appDatabaseProvider));

/// Mi inventario con la hora de la copia si vino sin conexión.
@riverpod
Future<(MyInventory, DateTime?)> myInventory(Ref ref) => ref.watch(inventoryRepositoryProvider).mine();
