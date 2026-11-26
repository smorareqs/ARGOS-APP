/// Categorías de artículos (fase02 `inventory_items.category`).
enum InventoryCategory {
  linens('linens', 'Blancos'),
  amenities('amenities', 'Amenidades'),
  cleaning('cleaning', 'Limpieza'),
  kitchen('kitchen', 'Cocina'),
  keys('keys', 'Llaves');

  const InventoryCategory(this.wire, this.label);

  final String wire;
  final String label;

  static InventoryCategory parse(String? v) =>
      values.firstWhere((c) => c.wire == v, orElse: () => InventoryCategory.amenities);
}

double _num(Object? v) => (v as num?)?.toDouble() ?? 0;

/// Un artículo que la persona tiene en custodia.
class CustodyEntry {
  const CustodyEntry({
    required this.itemId,
    required this.name,
    required this.category,
    required this.unit,
    required this.qty,
    required this.returnable,
    required this.since,
  });

  factory CustodyEntry.fromJson(Map<String, dynamic> j) => CustodyEntry(
    itemId: '${j['item_id']}',
    name: '${j['item_name'] ?? j['name']}',
    category: InventoryCategory.parse(j['category'] as String?),
    unit: '${j['unit'] ?? ''}',
    qty: _num(j['qty'] ?? j['quantity']),
    returnable: j['returnable'] as bool? ?? false,
    since: DateTime.tryParse('${j['since']}')?.toLocal(),
  );

  final String itemId;
  final String name;
  final InventoryCategory category;
  final String unit;
  final double qty;
  final bool returnable;
  final DateTime? since;
}

/// Artículo del catálogo con su existencia en la bodega elegida.
class StockItem {
  const StockItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    required this.unit,
    required this.available,
  });

  final String id;
  final String sku;
  final String name;
  final InventoryCategory category;
  final String unit;
  final double available;
}

class InventoryWarehouse {
  const InventoryWarehouse({required this.id, required this.name, this.propertyCode});

  final String id;
  final String name;
  final String? propertyCode;
}

/// Una solicitud de reposición propia.
class RestockRequestView {
  const RestockRequestView({
    required this.id,
    required this.status,
    required this.summary,
    required this.at,
    this.note,
  });

  factory RestockRequestView.fromJson(Map<String, dynamic> j) => RestockRequestView(
    id: '${j['id']}',
    status: '${j['status']}',
    summary: [
      for (final i in (j['items'] as List? ?? const []).whereType<Map>())
        '${i['item_name']} × ${_fmt(_num(i['qty']))}',
    ].join(', '),
    at: DateTime.tryParse('${j['at']}')?.toLocal() ?? DateTime.now(),
    note: j['note'] as String?,
  );

  final String id;

  /// pending, approved, rejected o fulfilled.
  final String status;
  final String summary;
  final DateTime at;
  final String? note;

  String get statusLabel => switch (status) {
    'approved' => 'Aprobada',
    'rejected' => 'Rechazada',
    'fulfilled' => 'Entregada',
    _ => 'Pendiente',
  };
}

String _fmt(double v) => v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(2);

/// `GET /inventory/me`: custodia, catálogo, bodegas, existencias y pedidos.
class MyInventory {
  const MyInventory({
    required this.custody,
    required this.warehouses,
    required this.requests,
    required this.raw,
  });

  factory MyInventory.fromJson(Map<String, dynamic> j) => MyInventory(
    custody: [
      for (final c in (j['custody'] as List? ?? const []).whereType<Map>())
        CustodyEntry.fromJson(Map<String, dynamic>.from(c)),
    ],
    warehouses: [
      for (final w in (j['warehouses'] as List? ?? const []).whereType<Map>())
        InventoryWarehouse(
          id: '${w['id']}',
          name: '${w['name']}',
          propertyCode: w['property_code'] as String?,
        ),
    ],
    requests: [
      for (final r in (j['requests'] as List? ?? const []).whereType<Map>())
        RestockRequestView.fromJson(Map<String, dynamic>.from(r)),
    ],
    raw: j,
  );

  final List<CustodyEntry> custody;
  final List<InventoryWarehouse> warehouses;
  final List<RestockRequestView> requests;
  final Map<String, dynamic> raw;

  /// Artículos activos con lo que hay en [warehouseId].
  List<StockItem> stockIn(String warehouseId) {
    final stock = {
      for (final s in (raw['stock'] as List? ?? const []).whereType<Map>())
        if ('${s['warehouse_id']}' == warehouseId) '${s['item_id']}': _num(s['qty']),
    };
    return [
      for (final i in (raw['items'] as List? ?? const []).whereType<Map>())
        StockItem(
          id: '${i['id']}',
          sku: '${i['sku'] ?? ''}',
          name: '${i['name']}',
          category: InventoryCategory.parse(i['category'] as String?),
          unit: '${i['unit'] ?? ''}',
          available: stock['${i['id']}'] ?? 0,
        ),
    ];
  }
}
