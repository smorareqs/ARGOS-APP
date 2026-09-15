# Fase 3 — Mantenimiento, activos, notificaciones y alertas

> Estado: pendiente. Requiere fase 2.

## 1. Objetivo

* Catálogo de activos por propiedad y edificio (elevadores, cámaras, agua, pintura,
  electrodomésticos, plomería, electricidad, A/C, hotelería) con mantenimiento
  preventivo, proveedores y documentos.
* Incidencias reportables desde la app por cualquier rol, con asignación y seguimiento.
* Sistema de notificaciones completo: push (FCM), correo (SES) y bandeja en app y web.
* Panel de alertas en web.

## 2. Modelo de datos (migración `tenant/0003_maintenance_notifications`)

### `vendors`

`name`, `service_type varchar(64)`, `contact_name`, `phone`, `email`, `notes`,
`is_active`.

### `assets`

| Columna | Tipo | Notas |
| --- | --- | --- |
| property_id | uuid FK null | uno de los dos obligatorio (CHECK) |
| building_id | uuid FK null | elevadores, cámaras de edificio |
| category | varchar(24) CHECK IN ('elevator','camera','water','paint','appliance','plumbing','electrical','hvac','hospitality','furniture','other') | |
| name | varchar(128) | |
| brand, model, serial | varchar(128) null | |
| location | varchar(128) null | "cocina", "azotea" |
| installed_at | date null | |
| warranty_until | date null | |
| vendor_id | uuid FK vendors null | |
| status | varchar(24) CHECK IN ('operational','needs_attention','in_repair','out_of_service') | |
| notes | text null | |
| is_active | bool | |

Documentos: `files` con `entity_type='asset'`, `kind='document'`.

### `maintenance_plans`

| Columna | Tipo |
| --- | --- |
| asset_id | uuid FK ON DELETE CASCADE |
| name | varchar(128) |
| frequency_days | int |
| responsible_user_id | uuid FK null |
| vendor_id | uuid FK null |
| last_done_at | date null |
| next_due_at | date |
| lead_days | int default 7 (con cuánta anticipación se genera la tarea y el recordatorio) |
| is_active | bool |

### `maintenance_tickets` (incidencias)

| Columna | Tipo | Notas |
| --- | --- | --- |
| property_id | uuid FK | |
| asset_id | uuid FK null | |
| plan_id | uuid FK null | si nace de un preventivo |
| title | varchar(160) | |
| description | text | |
| urgency | varchar(16) CHECK IN ('low','medium','high','critical') | |
| status | varchar(16) CHECK IN ('open','assigned','in_progress','resolved','closed','rejected') | |
| reported_by_user_id | uuid FK null | |
| reported_by_guest_id | uuid null | fase 4 |
| assigned_to | uuid FK null | |
| vendor_id | uuid FK null | |
| task_id | uuid FK tasks null | tarea generada al asignar |
| resolved_at, closed_at | timestamptz null | |
| resolution | text null | |
| cost | numeric(12,2) null | |

`ticket_events`: `ticket_id`, `type`, `actor_user_id`, `actor_guest_id`, `data`,
`created_at`.

### `notifications`

| Columna | Tipo |
| --- | --- |
| recipient_user_id | uuid FK shared.users null |
| recipient_guest_id | uuid null |
| type | varchar(48) |
| title | varchar(160) |
| body | text |
| data | jsonb (ruta de destino en app/web, ids) |
| channels | jsonb (['push','email','inapp']) |
| sent_push_at, sent_email_at | timestamptz null |
| read_at | timestamptz null |

Índice `(recipient_user_id, read_at, created_at)`.

`notification_preferences`: `user_id`, `type`, `push bool`, `email bool`. Sin fila =
ambos activos. Los tipos críticos (alarma de check-out, tarea reasignada) no se pueden
desactivar.

### `alerts`

| Columna | Tipo |
| --- | --- |
| type | varchar(32): asset_failure, maintenance_overdue, task_late, low_stock, discrepancy_open, checkout_alarm_unattended |
| severity | varchar(8): low, medium, high |
| entity_type, entity_id | |
| property_id | uuid null |
| message | varchar(255) |
| status | varchar(16): active, acknowledged, resolved |
| acknowledged_by, acknowledged_at | |
| resolved_at | |

`UNIQUE (type, entity_type, entity_id) WHERE status <> 'resolved'`.

## 3. Reglas de negocio

* Cualquier rol con `maintenance.report` crea tickets, pero solo sobre propiedades de su
  alcance (huésped: la de su reserva).
* Asignar ticket a colaborador crea una `task` tipo `maintenance` con `task_id`;
  cerrar la tarea resuelve el ticket. Asignar a proveedor no crea tarea.
* Cambiar a `needs_attention` o `out_of_service` un activo crea alerta `asset_failure`;
  volver a `operational` la resuelve.
* Job diario `maintenance_due`: por cada plan con `next_due_at - lead_days <= hoy` sin
  ticket abierto, crea ticket con `plan_id`, notifica responsable; si `next_due_at <
  hoy` crea alerta `maintenance_overdue`. Al resolver el ticket, `last_done_at = hoy`,
  `next_due_at += frequency_days`.
* Job `low_stock` (cada hora): alerta por ítem/bodega bajo mínimo.
* Job `task_late` de fase 2 crea alerta `task_late`.
* Discrepancia `open` → alerta; `justified/closed` → resuelta.

## 4. Notificaciones

`src/core/notifications/NotificationService.notify(recipients, type, title, body, data,
channels)`: inserta `notifications` y encola `send_push` y `send_email` según
preferencias. Handlers:

* `send_push`: FCM HTTP v1 con `google-auth`; tokens en `shared.device_tokens`;
  tokens inválidos se borran.
* `send_email`: plantilla por tipo.

Eventos y destinatarios de esta fase (los de fases 2, 4, 5 se enganchan aquí):

| Evento | Destinatarios | Canales |
| --- | --- | --- |
| task_assigned / reassigned / rescheduled | asignado | push, email |
| task_reminder (30 min antes de window_start) | asignado | push |
| task_late | supervisores y admin | push, inapp |
| task_completed | supervisores | inapp |
| discrepancy_open | admin, supervisores | push, email |
| ticket_created | admin, supervisores | push, inapp |
| ticket_assigned | asignado | push, email |
| ticket_resolved | quien reportó | push |
| maintenance_due | responsable | push, email |
| low_stock | admin | email, inapp |

`GET /notifications`, `POST /notifications/{id}/read`, `POST /notifications/read-all`,
`GET/PUT /notifications/preferences`, `POST /devices` (registrar token FCM),
`DELETE /devices/{token}`.

Tiempo real: endpoint `WS /ws` autenticado por token; el worker publica
`NOTIFY notif_<tenant_id>` y la API reenvía a los sockets de ese usuario. La bandeja
en app y web se actualiza sin recargar. Esta infraestructura se reutiliza para el chat.

## 5. Endpoints de mantenimiento

| Ruta | Permiso |
| --- | --- |
| `GET/POST/PATCH /assets`, `/vendors` | `maintenance.read` / `maintenance.manage` |
| `GET/POST/PATCH /assets/{id}/plans` | `maintenance.manage` |
| `POST /tickets` | `maintenance.report` |
| `GET /tickets` (scope), `GET /tickets/{id}` | `maintenance.read` |
| `POST /tickets/{id}/assign`, `/reject`, `/close`, `PATCH /tickets/{id}` | `maintenance.manage` / `maintenance.assign` |
| `POST /tickets/{id}/start`, `/resolve` | `maintenance.execute` |
| `GET /alerts`, `POST /alerts/{id}/ack`, `/resolve` | `alerts.read` / `alerts.manage` |
| `GET /maintenance/metrics` | `maintenance.read` |

## 6. App móvil

* Reportar incidencia (desde tarea, desde propiedad o desde el menú): fotos, urgencia,
  activo (lista por propiedad).
* Rol mantenimiento: mis tickets, iniciar/resolver con fotos y costo.
* Bandeja de notificaciones con navegación al destino; badge en pestaña Alertas.
* Registro del token FCM al iniciar sesión y limpieza al cerrar.
* Recepción push en primer plano y segundo plano (`firebase_messaging`).

## 7. Portal web

* Mantenimiento: activos (por propiedad/edificio, con documentos y estado), proveedores,
  planes preventivos con calendario, incidencias (tablero por estado, asignar, costos),
  indicadores (abiertas por propiedad, tiempo promedio, costo mensual).
* Panel de alertas: tarjetas por tipo, filtros por prioridad/propiedad/estado, acciones
  de reconocer y resolver.
* Campana de notificaciones en topbar con WebSocket.

## 8. Pruebas

* Huésped o owner reportan ticket solo de su alcance (404 fuera).
* El job de preventivos genera un ticket y una alerta; resolverlo recalcula
  `next_due_at`.
* Notificación a usuario de `tenant_a` nunca usa tokens de dispositivos de `tenant_b`
  (los tokens son por usuario; el test verifica que el destinatario se resuelve por
  membresía del tenant activo).
* Preferencias respetadas salvo tipos críticos.

## 9. Criterios de aceptación

Un colaborador reporta un elevador con falla desde la app; el admin lo ve en alertas y lo
asigna a un proveedor; el preventivo mensual del elevador genera su ticket solo; el
supervisor recibe push cuando una tarea se atrasa.
