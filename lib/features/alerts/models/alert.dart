/// Alerta operativa (`AlertRead`): falla de activo, preventivo vencido,
/// tarea retrasada, stock bajo, diferencia de inventario, alarma sin atender.
class OpsAlert {
  const OpsAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.status,
    required this.message,
    required this.createdAt,
    this.propertyCode,
    this.acknowledgedByName,
  });

  factory OpsAlert.fromJson(Map<String, dynamic> json) => OpsAlert(
    id: '${json['id']}',
    type: '${json['type']}',
    severity: '${json['severity'] ?? 'medium'}',
    status: '${json['status'] ?? 'active'}',
    message: '${json['message'] ?? ''}',
    createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal() ?? DateTime.now(),
    propertyCode: json['property_code'] as String?,
    acknowledgedByName: json['acknowledged_by_name'] as String?,
  );

  final String id;
  final String type;
  final String severity;
  final String status;
  final String message;
  final DateTime createdAt;
  final String? propertyCode;
  final String? acknowledgedByName;

  bool get acknowledged => status == 'acknowledged';

  OpsAlert acknowledge(String by) => OpsAlert(
    id: id,
    type: type,
    severity: severity,
    status: 'acknowledged',
    message: message,
    createdAt: createdAt,
    propertyCode: propertyCode,
    acknowledgedByName: by,
  );

  static String typeLabel(String type) => switch (type) {
    'asset_failure' => 'Fallas',
    'maintenance_overdue' => 'Preventivos vencidos',
    'task_late' => 'Tareas retrasadas',
    'low_stock' => 'Stock bajo',
    'discrepancy_open' => 'Diferencias',
    'checkout_alarm_unattended' => 'Alarmas sin atender',
    _ => 'Otras',
  };
}

/// Contadores del panel (`GET /alerts/summary`).
class AlertsSummary {
  const AlertsSummary({required this.open, required this.high, required this.fresh, required this.byType});

  factory AlertsSummary.fromJson(Map<String, dynamic> json) => AlertsSummary(
    open: (json['open'] as num?)?.toInt() ?? 0,
    high: (json['high'] as num?)?.toInt() ?? 0,
    fresh: (json['fresh'] as num?)?.toInt() ?? 0,
    byType: [
      for (final t in json['by_type'] as List? ?? const [])
        if (t is Map) ('${t['type']}', (t['open'] as num?)?.toInt() ?? 0),
    ],
  );

  final int open;
  final int high;
  final int fresh;
  final List<(String, int)> byType;
}
