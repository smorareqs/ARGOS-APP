import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Un aviso de la bandeja (`NotificationRead`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: '${json['id']}',
    type: '${json['type'] ?? ''}',
    title: '${json['title'] ?? ''}',
    body: '${json['body'] ?? ''}',
    data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : const {},
    createdAt: DateTime.tryParse('${json['created_at']}')?.toLocal() ?? DateTime.now(),
    readAt: json['read_at'] == null ? null : DateTime.tryParse('${json['read_at']}')?.toLocal(),
  );

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get unread => readAt == null;

  /// Pantalla de la app que abre (`/tasks/<id>`…).
  String? get appRoute => data['app_route'] as String?;

  AppNotification read(DateTime at) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    data: data,
    createdAt: createdAt,
    readAt: readAt ?? at,
  );

  IconData get icon => switch (type) {
    'task_assigned' || 'task_rescheduled' || 'task_reminder' => CustomIcons.today,
    'task_late' => CustomIcons.time,
    'task_completed' || 'task_validated' => CustomIcons.done,
    'task_returned' || 'task_cancelled' => CustomIcons.retry,
    'discrepancy_open' || 'restock_requested' || 'low_stock' => CustomIcons.equipment,
    'ticket_created' || 'ticket_assigned' => CustomIcons.incident,
    'ticket_resolved' => CustomIcons.tickets,
    'maintenance_due' => CustomIcons.maintenance,
    'reservation_requested' || 'reservation_changed' || 'guest_checked_in' => CustomIcons.reservations,
    'checkout_alarm' => CustomIcons.alarm,
    'payslip_available' => CustomIcons.reports,
    'disciplinary_notice' || 'disciplinary_acknowledged' => CustomIcons.info,
    'chat_message' => CustomIcons.chat,
    _ => CustomIcons.notifications,
  };

  NotificationTone get tone => switch (type) {
    'task_late' || 'task_returned' || 'checkout_alarm' || 'disciplinary_notice' => NotificationTone.danger,
    'discrepancy_open' || 'low_stock' || 'maintenance_due' || 'task_cancelled' => NotificationTone.warning,
    'task_validated' || 'ticket_resolved' || 'payslip_available' => NotificationTone.success,
    'alert' => data['severity'] == 'high' ? NotificationTone.danger : NotificationTone.warning,
    'ticket_created' || 'ticket_assigned' =>
      data['urgency'] == 'critical' || data['urgency'] == 'high'
          ? NotificationTone.danger
          : NotificationTone.warning,
    _ => NotificationTone.info,
  };
}

/// Página de `GET /notifications`.
class NotificationPage {
  const NotificationPage({required this.items, required this.unread, this.nextCursor});

  factory NotificationPage.fromJson(Map<String, dynamic> json) => NotificationPage(
    items: [
      for (final it in json['items'] as List? ?? const [])
        if (it is Map) AppNotification.fromJson(Map<String, dynamic>.from(it)),
    ],
    unread: (json['unread'] as num?)?.toInt() ?? 0,
    nextCursor: json['next_cursor'] as String?,
  );

  final List<AppNotification> items;
  final int unread;
  final String? nextCursor;
}

/// Preferencia de un tipo de aviso.
class NotificationPreference {
  const NotificationPreference({
    required this.type,
    required this.label,
    required this.push,
    required this.email,
    required this.critical,
  });

  factory NotificationPreference.fromJson(Map<String, dynamic> json) => NotificationPreference(
    type: '${json['type']}',
    label: '${json['label'] ?? json['type']}',
    push: json['push'] == true,
    email: json['email'] == true,
    critical: json['critical'] == true,
  );

  final String type;
  final String label;
  final bool push;
  final bool email;
  final bool critical;

  NotificationPreference copyWith({bool? push, bool? email}) => NotificationPreference(
    type: type,
    label: label,
    push: push ?? this.push,
    email: email ?? this.email,
    critical: critical,
  );

  Map<String, dynamic> toJson() => {'type': type, 'push': push, 'email': email};
}
