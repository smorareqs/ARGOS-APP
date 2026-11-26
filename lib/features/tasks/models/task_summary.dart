/// Tipo de tarea tal como lo devuelve el backend (`type` de `GET /tasks`).
enum TaskType {
  checkoutCleaning('Limpieza de salida', 'checkout_cleaning'),
  deepCleaning('Limpieza profunda', 'deep_cleaning'),
  touchUp('Repaso antes de llegada', 'touch_up'),
  inspection('Inspección', 'inspection'),
  maintenance('Mantenimiento', 'maintenance');

  const TaskType(this.label, this.wire);

  final String label;
  final String wire;

  /// Las tres limpiezas llevan checklist e insumos.
  bool get isCleaning =>
      this == checkoutCleaning || this == deepCleaning || this == touchUp;

  static TaskType parse(String? value) => switch (value) {
    'deep_cleaning' => TaskType.deepCleaning,
    'touch_up' => TaskType.touchUp,
    'inspection' => TaskType.inspection,
    'maintenance' => TaskType.maintenance,
    _ => TaskType.checkoutCleaning,
  };
}

/// Estado de una tarea (fase02 `tasks.status`).
enum TaskStatus {
  pending,
  inProgress,
  done,
  validated,
  returned,
  cancelled;

  static TaskStatus parse(String? value) => switch (value) {
    'in_progress' => TaskStatus.inProgress,
    'done' || 'completed' => TaskStatus.done,
    'validated' => TaskStatus.validated,
    'returned' => TaskStatus.returned,
    'cancelled' => TaskStatus.cancelled,
    _ => TaskStatus.pending,
  };

  bool get isFinished => this == done || this == validated;

  /// Todavía se puede trabajar en ella.
  bool get isOpen => this == pending || this == inProgress || this == returned;
}

/// Propiedad de una tarea, lo justo para la lista y el detalle.
class TaskProperty {
  const TaskProperty({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    this.lat,
    this.lng,
    this.buildingName,
  });

  final String id;
  final String code;
  final String name;
  final String address;
  final double? lat;
  final double? lng;
  final String? buildingName;
}

/// Avance de una sección del checklist.
class ChecklistSection {
  const ChecklistSection({
    required this.name,
    required this.total,
    required this.done,
  });

  final String name;
  final int total;
  final int done;
}

/// Insumo usado en la tarea.
class TaskConsumption {
  const TaskConsumption({
    required this.itemId,
    required this.item,
    required this.qty,
    required this.unit,
  });

  final String itemId;
  final String item;
  final double qty;
  final String unit;
}

/// Un paso de la línea de tiempo, ya en texto.
class TaskEvent {
  const TaskEvent({
    required this.at,
    required this.type,
    required this.text,
    required this.actor,
    this.detail,
  });

  final DateTime at;
  final String type;
  final String text;
  final String actor;
  final String? detail;
}

/// Una tarea de la agenda (`GET /tasks`).
class TaskSummary {
  const TaskSummary({
    required this.id,
    required this.type,
    required this.status,
    required this.isLate,
    required this.scheduledDate,
    required this.property,
    this.number = 0,
    this.highPriority = false,
    this.windowStart,
    this.windowEnd,
    this.startedAt,
    this.finishedAt,
    this.checklistDone,
    this.checklistTotal,
    this.sections = const [],
    this.photos = 0,
    this.notes,
    this.assigneeId,
    this.assigneeName,
    this.reservationCode,
    this.ticketId,
    this.discrepancy,
    this.consumption = const [],
    this.timeline = const [],
  });

  factory TaskSummary.fromJson(Map<String, dynamic> json) {
    DateTime? time(String key) => json[key] == null
        ? null
        : DateTime.parse(json[key] as String).toLocal();
    double? number(Object? v) => (v as num?)?.toDouble();
    final sections = [
      for (final s in (json['checklist'] as List? ?? const []).whereType<Map>())
        ChecklistSection(
          name: '${s['name']}',
          total: (s['total'] as num?)?.toInt() ?? 0,
          done: (s['done'] as num?)?.toInt() ?? 0,
        ),
    ];
    final total = sections.fold<int>(0, (a, s) => a + s.total);
    final done = sections.fold<int>(0, (a, s) => a + s.done);
    return TaskSummary(
      id: '${json['id']}',
      number: (json['number'] as num?)?.toInt() ?? 0,
      type: TaskType.parse(json['type'] as String?),
      status: TaskStatus.parse(json['status'] as String?),
      highPriority: json['priority'] == 'high',
      isLate: json['late'] as bool? ?? false,
      scheduledDate: DateTime.parse(json['date'] as String),
      property: TaskProperty(
        id: '${json['property_id']}',
        code: json['property_code'] as String? ?? '',
        name: json['property_name'] as String? ?? '',
        address:
            json['property_address'] as String? ??
            json['building_name'] as String? ??
            '',
        lat: number(json['lat']),
        lng: number(json['lng']),
        buildingName: json['building_name'] as String?,
      ),
      windowStart: _hhmm(json['start']),
      windowEnd: _hhmm(json['end']),
      startedAt: time('started_at'),
      finishedAt: time('finished_at'),
      checklistDone: total == 0 ? null : done,
      checklistTotal: total == 0 ? null : total,
      sections: sections,
      photos: (json['photos'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      assigneeId: json['assignee_id'] as String?,
      assigneeName: json['assignee_name'] as String?,
      reservationCode: json['reservation_code'] as String?,
      ticketId: json['ticket_id'] as String?,
      discrepancy: json['discrepancy'] as String?,
      consumption: [
        for (final c
            in (json['consumption'] as List? ?? const []).whereType<Map>())
          TaskConsumption(
            itemId: '${c['item_id']}',
            item: '${c['item']}',
            qty: number(c['qty']) ?? 0,
            unit: '${c['unit'] ?? ''}',
          ),
      ],
      timeline: [
        for (final e in (json['timeline'] as List? ?? const []).whereType<Map>())
          TaskEvent(
            at: DateTime.parse(e['at'] as String).toLocal(),
            type: '${e['type']}',
            text: '${e['text']}',
            actor: '${e['actor'] ?? ''}',
            detail: e['detail'] as String?,
          ),
      ],
    );
  }

  final String id;

  /// Folio corto de la empresa (#128).
  final int number;
  final TaskType type;
  final TaskStatus status;
  final bool highPriority;

  /// Lo marca el backend si pasó la ventana sin iniciar o sin terminar.
  final bool isLate;
  final DateTime scheduledDate;
  final TaskProperty property;

  /// "09:30" (hora local de la empresa).
  final String? windowStart;
  final String? windowEnd;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int? checklistDone;
  final int? checklistTotal;
  final List<ChecklistSection> sections;
  final int photos;
  final String? notes;
  final String? assigneeId;
  final String? assigneeName;
  final String? reservationCode;
  final String? ticketId;

  /// Resumen de las diferencias de inventario abiertas.
  final String? discrepancy;
  final List<TaskConsumption> consumption;
  final List<TaskEvent> timeline;

  String? get windowLabel => windowStart == null
      ? null
      : windowEnd == null
      ? 'Desde $windowStart'
      : '$windowStart – $windowEnd';

  /// Retrasada y todavía abierta.
  bool get showsLate => isLate && status.isOpen;

  /// "09:30:00" → "09:30".
  static String? _hhmm(Object? value) {
    if (value is! String || value.length < 5) return null;
    return value.substring(0, 5);
  }
}
