import 'package:design_system/design_system.dart';

/// Incidencia (`TicketRead`).
class Ticket {
  const Ticket({
    required this.id,
    required this.number,
    required this.title,
    required this.description,
    required this.urgency,
    required this.status,
    required this.createdAt,
    this.propertyId,
    this.propertyCode,
    this.propertyName,
    this.buildingName,
    this.assetId,
    this.assetName,
    this.reporterName,
    this.assigneeId,
    this.assigneeName,
    this.vendorName,
    this.resolution,
    this.cost,
    this.photosCount = 0,
    this.resolvedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
    id: '${json['id']}',
    number: (json['number'] as num?)?.toInt() ?? 0,
    title: '${json['title'] ?? ''}',
    description: '${json['description'] ?? ''}',
    urgency: Urgency.parse(json['urgency'] as String?),
    status: TicketStatus.parse(json['status'] as String?),
    createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal() ?? DateTime.now(),
    propertyId: json['property_id'] as String?,
    propertyCode: json['property_code'] as String?,
    propertyName: json['property_name'] as String?,
    buildingName: json['building_name'] as String?,
    assetId: json['asset_id'] as String?,
    assetName: json['asset_name'] as String?,
    reporterName: json['reporter_name'] as String?,
    assigneeId: json['assigned_to'] as String?,
    assigneeName: json['assignee_name'] as String?,
    vendorName: json['vendor_name'] as String?,
    resolution: json['resolution'] as String?,
    cost: (json['cost'] as num?)?.toDouble(),
    photosCount: (json['photos_count'] as num?)?.toInt() ?? 0,
    resolvedAt: json['resolved_at'] == null ? null : DateTime.tryParse('${json['resolved_at']}')?.toLocal(),
  );

  final String id;
  final int number;
  final String title;
  final String description;
  final Urgency urgency;
  final TicketStatus status;
  final DateTime createdAt;
  final String? propertyId;
  final String? propertyCode;
  final String? propertyName;
  final String? buildingName;
  final String? assetId;
  final String? assetName;
  final String? reporterName;
  final String? assigneeId;
  final String? assigneeName;
  final String? vendorName;
  final String? resolution;
  final double? cost;
  final int photosCount;
  final DateTime? resolvedAt;

  /// "TB-504 · Torre Bosque" o el edificio en preventivos de áreas comunes.
  String get place => [
    if (propertyCode != null) propertyCode!,
    if (propertyName != null) propertyName! else if (buildingName != null) buildingName!,
  ].join(' · ');
}

enum TicketStatus {
  open('open', 'Abierta', StatusBadgeVariant.incident),
  assigned('assigned', 'Asignada', StatusBadgeVariant.pending),
  inProgress('in_progress', 'En curso', StatusBadgeVariant.inProgress),
  resolved('resolved', 'Resuelta', StatusBadgeVariant.operative),
  closed('closed', 'Cerrada', StatusBadgeVariant.operative),
  rejected('rejected', 'Rechazada', StatusBadgeVariant.pending);

  const TicketStatus(this.wire, this.label, this.badge);

  final String wire;
  final String label;
  final StatusBadgeVariant badge;

  bool get active => this == open || this == assigned || this == inProgress;

  static TicketStatus parse(String? v) =>
      TicketStatus.values.firstWhere((s) => s.wire == v, orElse: () => TicketStatus.open);
}

/// Paso de la línea de tiempo.
class TicketEvent {
  const TicketEvent({required this.type, required this.createdAt, this.actorName, this.data = const {}});

  factory TicketEvent.fromJson(Map<String, dynamic> json) => TicketEvent(
    type: '${json['type']}',
    createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal() ?? DateTime.now(),
    actorName: json['actor_name'] as String?,
    data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : const {},
  );

  final String type;
  final DateTime createdAt;
  final String? actorName;
  final Map<String, dynamic> data;

  String get title {
    final who = actorName ?? 'El sistema';
    return switch (type) {
      'created' => '$who la reportó',
      'assigned' => 'Asignada a ${data['assignee_name'] ?? data['vendor_name'] ?? 'alguien'}',
      'started' => '$who la inició',
      'resolved' => '$who la resolvió',
      'closed' => 'Cerrada por $who',
      'rejected' => 'Rechazada por $who',
      'reopened' => 'Reabierta por $who',
      'updated' => '$who la corrigió',
      _ => type,
    };
  }

  String? get detail {
    final note = data['resolution'] ?? data['reason'] ?? data['note'];
    return note is String && note.isNotEmpty ? note : null;
  }

  TimelineTone get tone => switch (type) {
    'created' => TimelineTone.warning,
    'resolved' || 'closed' => TimelineTone.success,
    'rejected' => TimelineTone.error,
    'started' || 'assigned' => TimelineTone.info,
    _ => TimelineTone.neutral,
  };
}

class TicketPhoto {
  const TicketPhoto({required this.fileId, required this.stage, required this.url});

  factory TicketPhoto.fromJson(Map<String, dynamic> json) => TicketPhoto(
    fileId: '${json['file_id']}',
    stage: '${json['stage'] ?? 'report'}',
    url: '${json['url'] ?? ''}',
  );

  final String fileId;

  /// report o resolution.
  final String stage;
  final String url;
}

/// `TicketDetail`: la incidencia con línea de tiempo y fotos.
class TicketDetail {
  const TicketDetail({required this.ticket, required this.events, required this.photos});

  factory TicketDetail.fromJson(Map<String, dynamic> json) => TicketDetail(
    ticket: Ticket.fromJson(json),
    events: [
      for (final e in json['events'] as List? ?? const [])
        if (e is Map) TicketEvent.fromJson(Map<String, dynamic>.from(e)),
    ],
    photos: [
      for (final p in json['photos'] as List? ?? const [])
        if (p is Map) TicketPhoto.fromJson(Map<String, dynamic>.from(p)),
    ],
  );

  final Ticket ticket;
  final List<TicketEvent> events;
  final List<TicketPhoto> photos;
}

/// Propiedad del alcance para reportar.
class PropertyOption {
  const PropertyOption({required this.id, required this.code, required this.name});

  factory PropertyOption.fromJson(Map<String, dynamic> json) =>
      PropertyOption(id: '${json['id']}', code: '${json['code'] ?? ''}', name: '${json['name'] ?? ''}');

  final String id;
  final String code;
  final String name;
}

/// Activo de una propiedad (o de su edificio).
class AssetOption {
  const AssetOption({required this.id, required this.name, required this.category, this.location});

  factory AssetOption.fromJson(Map<String, dynamic> json) => AssetOption(
    id: '${json['id']}',
    name: '${json['name'] ?? ''}',
    category: '${json['category'] ?? 'other'}',
    location: json['location'] as String?,
  );

  final String id;
  final String name;
  final String category;
  final String? location;

  static String categoryLabel(String c) => switch (c) {
    'elevator' => 'Ascensores',
    'camera' => 'Cámaras',
    'water' => 'Agua',
    'paint' => 'Pintura',
    'appliance' => 'Electrodomésticos',
    'plumbing' => 'Fontanería',
    'electrical' => 'Electricidad',
    'hvac' => 'Aire acondicionado',
    'hospitality' => 'Hospitalidad',
    'furniture' => 'Mobiliario',
    _ => 'Otros',
  };
}
