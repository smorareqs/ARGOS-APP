/// Tipo de tarea (fase02 `tasks.type`).
enum TaskType {
  cleaning('Limpieza'),
  inspection('Inspección'),
  maintenance('Mantenimiento'),
  checkoutReview('Revisión de salida');

  const TaskType(this.label);

  final String label;

  static TaskType parse(String? value) => switch (value) {
    'inspection' => TaskType.inspection,
    'maintenance' => TaskType.maintenance,
    'checkout_review' => TaskType.checkoutReview,
    _ => TaskType.cleaning,
  };
}

/// Estado de una tarea (fase02 `tasks.status`).
enum TaskStatus {
  pending,
  inProgress,
  completed,
  validated,
  cancelled;

  static TaskStatus parse(String? value) => switch (value) {
    'in_progress' => TaskStatus.inProgress,
    'completed' => TaskStatus.completed,
    'validated' => TaskStatus.validated,
    'cancelled' => TaskStatus.cancelled,
    _ => TaskStatus.pending,
  };

  bool get isFinished => this == completed || this == validated;
}

/// Propiedad de una tarea, lo justo para la lista y el detalle.
class TaskProperty {
  const TaskProperty({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
  });

  factory TaskProperty.fromJson(Map<String, dynamic> json) => TaskProperty(
    id: '${json['id']}',
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    address: json['address'] as String? ?? '',
  );

  final String id;
  final String code;
  final String name;
  final String address;
}

/// Una tarea de la agenda (`GET /tasks?date=`).
class TaskSummary {
  const TaskSummary({
    required this.id,
    required this.type,
    required this.status,
    required this.isLate,
    required this.scheduledDate,
    required this.property,
    this.windowStart,
    this.windowEnd,
    this.startedAt,
    this.finishedAt,
    this.checklistDone,
    this.checklistTotal,
    this.notes,
  });

  factory TaskSummary.fromJson(Map<String, dynamic> json) {
    final checklist = json['checklist'] is Map
        ? Map<String, dynamic>.from(json['checklist'] as Map)
        : const <String, dynamic>{};
    DateTime? time(String key) => json[key] == null
        ? null
        : DateTime.parse(json[key] as String).toLocal();
    return TaskSummary(
      id: '${json['id']}',
      type: TaskType.parse(json['type'] as String?),
      status: TaskStatus.parse(json['status'] as String?),
      isLate: json['is_late'] as bool? ?? false,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      property: TaskProperty.fromJson(
        Map<String, dynamic>.from(json['property'] as Map),
      ),
      windowStart: _hhmm(json['window_start']),
      windowEnd: _hhmm(json['window_end']),
      startedAt: time('started_at'),
      finishedAt: time('finished_at'),
      checklistDone: (checklist['done'] as num?)?.toInt(),
      checklistTotal: (checklist['total'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );
  }

  final String id;
  final TaskType type;
  final TaskStatus status;

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
  final String? notes;

  String? get windowLabel => windowStart == null
      ? null
      : windowEnd == null
      ? 'Desde $windowStart'
      : '$windowStart – $windowEnd';

  /// Retrasada y todavía abierta.
  bool get showsLate =>
      isLate && (status == TaskStatus.pending || status == TaskStatus.inProgress);

  /// "09:30:00" → "09:30".
  static String? _hhmm(Object? value) {
    if (value is! String || value.length < 5) return null;
    return value.substring(0, 5);
  }
}
