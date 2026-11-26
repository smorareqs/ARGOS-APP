import 'package:argos_app/features/tasks/models/task_summary.dart';

/// Tipo de foto de un punto del checklist (regla de archivos `tasks/*`).
enum PhotoKind {
  before('before', 'Antes'),
  after('after', 'Después'),
  evidence('evidence', 'Evidencia');

  const PhotoKind(this.wire, this.label);

  final String wire;
  final String label;

  static PhotoKind parse(String? v) => switch (v) {
    'before' => PhotoKind.before,
    'after' => PhotoKind.after,
    _ => PhotoKind.evidence,
  };
}

/// Foto ya subida a un punto.
class TaskPhotoRef {
  const TaskPhotoRef({required this.fileId, required this.kind});

  final String fileId;
  final PhotoKind kind;
}

/// Un punto del checklist de la tarea.
class ChecklistItem {
  const ChecklistItem({
    required this.id,
    required this.section,
    required this.position,
    required this.text,
    required this.requiresPhoto,
    required this.requiresBeforeAfter,
    required this.isDone,
    this.notes,
    this.photos = const [],
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
    id: '${json['id']}',
    section: '${json['section']}',
    position: (json['position'] as num?)?.toInt() ?? 0,
    text: '${json['text']}',
    requiresPhoto: json['requires_photo'] as bool? ?? false,
    requiresBeforeAfter: json['requires_before_after'] as bool? ?? false,
    isDone: json['is_done'] as bool? ?? false,
    notes: json['notes'] as String?,
    photos: [
      for (final p in (json['photos'] as List? ?? const []).whereType<Map>())
        TaskPhotoRef(
          fileId: '${p['file_id']}',
          kind: PhotoKind.parse(p['kind'] as String?),
        ),
    ],
  );

  final String id;
  final String section;
  final int position;
  final String text;
  final bool requiresPhoto;
  final bool requiresBeforeAfter;
  final bool isDone;
  final String? notes;
  final List<TaskPhotoRef> photos;

  bool get needsPhotos => requiresPhoto || requiresBeforeAfter;

  ChecklistItem copyWith({bool? isDone, String? notes}) => ChecklistItem(
    id: id,
    section: section,
    position: position,
    text: text,
    requiresPhoto: requiresPhoto,
    requiresBeforeAfter: requiresBeforeAfter,
    isDone: isDone ?? this.isDone,
    notes: notes ?? this.notes,
    photos: photos,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'section': section,
    'position': position,
    'text': text,
    'requires_photo': requiresPhoto,
    'requires_before_after': requiresBeforeAfter,
    'is_done': isDone,
    'notes': notes,
    'photos': [
      for (final p in photos) {'file_id': p.fileId, 'kind': p.kind.wire},
    ],
  };
}

/// Un artículo en custodia de quien consulta (para conciliar al cerrar).
class CustodyLine {
  const CustodyLine({
    required this.itemId,
    required this.name,
    required this.unit,
    required this.category,
    required this.returnable,
    required this.quantity,
  });

  factory CustodyLine.fromJson(Map<String, dynamic> json) => CustodyLine(
    itemId: '${json['item_id']}',
    name: '${json['name'] ?? json['item_name']}',
    unit: '${json['unit'] ?? ''}',
    category: '${json['category'] ?? ''}',
    returnable: json['returnable'] as bool? ?? false,
    quantity: ((json['quantity'] ?? json['qty']) as num?)?.toDouble() ?? 0,
  );

  final String itemId;
  final String name;
  final String unit;
  final String category;

  /// Blancos y llaves: se devuelven completos.
  final bool returnable;
  final double quantity;
}

/// La tarea con su checklist completo (`GET /tasks/{id}`).
class TaskDetail {
  const TaskDetail({
    required this.summary,
    required this.items,
    required this.custody,
    required this.canExecute,
    required this.canManage,
    this.raw = const {},
  });

  factory TaskDetail.fromJson(Map<String, dynamic> json) => TaskDetail(
    summary: TaskSummary.fromJson(json),
    items: [
      for (final i in (json['items'] as List? ?? const []).whereType<Map>())
        ChecklistItem.fromJson(Map<String, dynamic>.from(i)),
    ]..sort((a, b) => a.position.compareTo(b.position)),
    custody: [
      for (final c in (json['custody'] as List? ?? const []).whereType<Map>())
        CustodyLine.fromJson(Map<String, dynamic>.from(c)),
    ],
    canExecute: json['can_execute'] as bool? ?? false,
    canManage: json['can_manage'] as bool? ?? false,
    raw: json,
  );

  final TaskSummary summary;
  final List<ChecklistItem> items;
  final List<CustodyLine> custody;
  final bool canExecute;
  final bool canManage;

  /// JSON original (se guarda en la caché y se actualiza sin conexión).
  final Map<String, dynamic> raw;

  String get id => summary.id;

  /// Secciones en el orden del checklist.
  List<(String, List<ChecklistItem>)> get bySection {
    final out = <(String, List<ChecklistItem>)>[];
    for (final item in items) {
      if (out.isEmpty || out.last.$1 != item.section) {
        out.add((item.section, [item]));
      } else {
        out.last.$2.add(item);
      }
    }
    return out;
  }

  int get doneCount => items.where((i) => i.isDone).length;
}

/// Alguien a quien se le puede asignar una tarea (`GET /tasks/assignables`).
class TaskAssignee {
  const TaskAssignee({
    required this.id,
    required this.name,
    required this.role,
    this.scoped = false,
    this.propertyIds = const [],
  });

  factory TaskAssignee.fromJson(Map<String, dynamic> json) => TaskAssignee(
    id: '${json['id']}',
    name: '${json['name']}',
    role: '${json['role'] ?? ''}',
    scoped: json['scoped'] as bool? ?? false,
    propertyIds: [for (final p in (json['property_ids'] as List? ?? const [])) '$p'],
  );

  final String id;
  final String name;
  final String role;

  /// Solo atiende sus propiedades asignadas.
  final bool scoped;
  final List<String> propertyIds;

  /// Puede atender la propiedad.
  bool covers(String propertyId) => !scoped || propertyIds.contains(propertyId);
}
