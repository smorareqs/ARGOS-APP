# Fase 3 — Mantenimiento, activos, notificaciones y alertas

> Estado: en curso. Parte de Persona A **hecha** (2026-11-22): migración `tenant/0004_maintenance`,
> módulos `maintenance`, `alerts` y `dashboard`, bus de eventos `internal/core/events`, trabajos
> `maintenance_due` y `low_stock`, con la web conectada (W-G1 a W-G5, W-L1 y W-B1; la bandeja de la
> campana usa datos simulados hasta que exista la API de B). Contrato en §5.1. Pendiente (Persona B):
> `tenant/0005_notifications`, módulos `notifications` y `realtime`, enganche de eventos y la app.

## 1. Objetivo

* Catálogo de activos por propiedad y edificio (elevadores, cámaras, agua, pintura,
  electrodomésticos, plomería, electricidad, A/C, hotelería) con mantenimiento
  preventivo, proveedores y documentos.
* Incidencias reportables desde la app por cualquier rol, con asignación y seguimiento.
* Sistema de notificaciones completo: push (FCM), correo (SES) y bandeja en app y web.
* Panel de alertas en web.

## 2. Modelo de datos (migraciones `tenant/0004_maintenance` y `tenant/0005_notifications`)

Reparto (ver [reparto.md](reparto.md)): `0004_maintenance` (Persona A) crea `vendors`,
`assets`, `maintenance_plans`, `maintenance_tickets`, `ticket_events` y `alerts`.
`0005_notifications` (Persona B) crea `notifications` y `notification_preferences`.

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

`internal/core/notifications` → `notifications.Service.Notify(ctx, q, recipients, type,
title, body, data, channels)`: inserta `notifications` y encola `send_push` y
`send_email` según preferencias. Handlers:

* `send_push`: FCM HTTP v1 con el Firebase Admin SDK para Go
  (`firebase.google.com/go/v4/messaging`); tokens en `shared.device_tokens`;
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

### 5.1 Contrato implementado (Persona A, 2026-11-22)

Existe en el backend (rama `dev/sebas`) y la web lo usa contra la API real. **La app de B puede
consumirlo tal cual.** OpenAPI vivo en `GET /api/v1/openapi.json` (etiquetas `mantenimiento`, `alertas`
e `inicio`). Rutas bajo `/api/v1`, en la empresa de la sesión; en modo plataforma responden 403.
Paginación, PATCH con `null` y errores 422 por campo como en fase02 §4.1.

**Alcance de incidencias.** Una persona ve una incidencia si su propiedad está en su alcance
(`authz.ResolvePropertyScope`), si la reportó o si la tiene asignada. Las de un activo del edificio
(sin propiedad) las ve quien tiene en su alcance alguna propiedad de ese edificio. Fuera de alcance:
la lista no la trae y por id responde **404**, también al reportar sobre una propiedad ajena. Los
activos siguen la misma regla (los del edificio aparecen en todas sus propiedades). Cada incidencia
tiene `number`, un folio corto por empresa (#42) que también sirve para buscar (`q=#42`).

**Proveedores** (`maintenance.read` / `maintenance.manage`):

| Endpoint | Cuerpo / query | Respuestas |
| --- | --- | --- |
| `GET /vendors` · `GET /vendors/{id}` | `active=true` o `false` | 200 `{id, name, service_type, contact_name, phone, email, notes, is_active, assets_count, open_tickets, tickets_done, spend_year, avg_hours, created_at, updated_at}`, por nombre |
| `POST /vendors` · `PATCH /vendors/{id}` | `name` (2–128), `service_type?`, `contact_name?`, `phone?`, `email?`, `notes?` (`is_active` en PATCH) | 201/200 · 422 `body.name` (repetido, sin importar mayúsculas) |

**Activos** (`maintenance.read` / `maintenance.manage`):

| Endpoint | Cuerpo / query | Respuestas |
| --- | --- | --- |
| **`GET /assets`** | `q` (nombre, marca, modelo, serie, ubicación o código), `property_id` (incluye los de su edificio), `building_id`, `vendor_id`, `category`, `status`, `active`, `cursor`, `limit` | 200 página de activos, por nombre |
| **`GET /assets/{id}`** | — | 200 activo con `plans[]`, `documents[]` y `tickets[]` (las 20 más recientes) · 404 |
| `POST /assets` | `property_id` **o** `building_id` (solo uno), `category`, `name`, `brand?`, `model?`, `serial?`, `location?`, `installed_at?`, `warranty_until?` (AAAA-MM-DD), `vendor_id?`, `status?` (por defecto `operational`), `notes?` | 201 · 422 `body.property_id` (ninguno o los dos), `body.building_id`, `body.vendor_id` (no existe o inactivo), `body.warranty_until` (antes de la instalación) |
| `PATCH /assets/{id}` | lo anterior opcional, `null` borra; `is_active` | 200. Cambiar `status` levanta o resuelve su alerta (ver abajo) |
| `POST /assets/{id}/documents` | `file_id` (archivo `maintenance/asset_document` ya confirmado por quien lo adjunta) | 201 `{file_id, name, content_type, size_bytes, url (firmada 1 h), created_at}` · 422 `body.file_id` |
| `DELETE /assets/{id}/documents/{file_id}` | — | 204 · 404 |

Activo: `{id, property_id, property_code, property_name, building_id (el suyo o el de su propiedad),
building_name, category, name, brand, model, serial, location, installed_at, warranty_until, vendor_id,
vendor_name, status, notes, is_active, open_tickets, tickets_count, cost_year, next_due_at (próximo
preventivo activo), created_at, updated_at}`. Categorías: `elevator`, `camera`, `water`, `paint`,
`appliance`, `plumbing`, `electrical`, `hvac`, `hospitality`, `furniture`, `other`.

**Preventivos** (`maintenance.read` / `maintenance.manage`):

| Endpoint | Cuerpo / query | Respuestas |
| --- | --- | --- |
| `GET /maintenance/plans` | `from`, `to` (vencen entre, incluidos), `asset_id`, `active` | 200 `{items}` por fecha (calendario W-G3) |
| `GET /assets/{id}/plans` | — | 200 `{items}` · 404 |
| `POST /assets/{id}/plans` | `name`, `frequency_days` (1–3650), `responsible_user_id?` (con `maintenance.execute`), `vendor_id?`, `last_done_at?`, `next_due_at?` (por defecto última + frecuencia, u hoy + frecuencia), `lead_days?` (0–365, por defecto 7) | 201 · 422 `body.responsible_user_id`, `body.vendor_id` |
| `PATCH /assets/{id}/plans/{plan_id}` | lo anterior opcional (`null` quita responsable o proveedor) e `is_active` | 200 · 404 |

Preventivo: `{id, asset_id, asset_name, asset_category, property_id, property_code, building_name, name,
frequency_days, responsible_user_id, responsible_name, vendor_id, vendor_name, last_done_at, next_due_at,
lead_days, is_active, due_state (ok, upcoming = dentro de lead_days, overdue, inactive), open_ticket_id,
open_ticket_number, created_at, updated_at}`.

**Incidencias** (leer con `maintenance.read` **o** `maintenance.report`):

| Endpoint | Cuerpo / query | Permiso | Respuestas |
| --- | --- | --- | --- |
| **`GET /tickets`** | `q` (título, propiedad, activo o `#folio`), `status` (lista con comas; `active` = open, assigned e in_progress), `urgency`, `property_id`, `asset_id`, `vendor_id`, `assignee`, **`mine=true`** (las asignadas a quien consulta: app de mantenimiento), `cursor`, `limit` | read o report | 200 página, las más nuevas primero |
| **`GET /tickets/{id}`** | — | read o report | 200 incidencia con `events[]` y `photos[]` · 404 |
| **`POST /tickets`** | `property_id`, `asset_id?` (de esa propiedad o de su edificio), `title` (3–160), `description?`, `urgency` (`low`, `medium`, `high`, `critical`), `photo_file_ids[]?` (hasta 10, `maintenance/ticket_photo` subidas por quien reporta) | `maintenance.report` | 201 detalle · 404 propiedad fuera de alcance · 422 `body.asset_id`, `body.photo_file_ids` |
| `PATCH /tickets/{id}` | `title`, `description`, `urgency`, `asset_id` (null lo quita), `cost` (null lo borra) | `maintenance.manage` | 200 |
| **`POST /tickets/{id}/assign`** | `assignee_id?` (miembro con `maintenance.execute`), `vendor_id?`, `note?`. Es la asignación completa: lo que no viene se quita | `maintenance.assign` o `.manage` | 200 · 422 `body.assignee_id` (ninguno, o no puede atender) |
| **`POST /tickets/{id}/start`** | — (desde open o assigned; sin asignado, la toma quien la inicia) | `maintenance.execute` | 200 · 403 asignada a otra persona · 422 estado |
| **`POST /tickets/{id}/resolve`** | `resolution` (3–2000), `cost?`, `photo_file_ids[]?` (`maintenance/ticket_resolution`), `asset_operational?` (deja el activo operando y resuelve su alerta) | `maintenance.execute` | 200 · 403 · 422 estado |
| `POST /tickets/{id}/close` · `/reject` · `/reopen` | `reason` (obligatorio en reject y reopen; nota opcional en close) | `maintenance.manage` | 200 · 422 `body.reason`, estado |
| `GET /maintenance/assignables` | — | `maintenance.assign` o `.manage` | 200 `{items[{user_id, full_name, role_name, open_tickets}]}`, los menos cargados primero |
| `GET /maintenance/metrics` | — | `maintenance.read` | 200 `{open, urgent, unassigned, overdue_plans, due_plans, avg_hours (90 días), cost_month, cost_year, open_by_place[{kind, id, code, name, open}], resolution[{month, hours, resolved}] (6 meses), cost_by_category[{category, cost, tickets}]}` |

Incidencia: `{id, number, property_id, property_code, property_name, building_id, building_name, asset_id,
asset_name, asset_category, plan_id, plan_name, title, description, urgency, status, reported_by_user_id,
reporter_name (null = la generó un preventivo), assigned_to, assignee_name, vendor_id, vendor_name, task_id,
resolution, cost, photos_count, resolved_at, closed_at, created_at, updated_at}`. El detalle suma
`events[{id, type, actor_user_id, actor_name (null = el sistema), data, created_at}]` y
`photos[{file_id, stage (report o resolution), url (firmada 1 h), created_at}]`.

Estados: `open → assigned → in_progress → resolved → closed`. Se rechaza desde open o assigned; se
reabre desde resolved o rejected (vuelve a open o assigned). Resolver se puede desde cualquier estado
activo; quien no tiene `maintenance.manage` ni `maintenance.assign` solo inicia y resuelve las suyas o
las libres. Al resolver
una incidencia de preventivo, el plan avanza: `last_done_at = hoy` y `next_due_at` suma la frecuencia
hasta quedar en el futuro. Un preventivo tiene a lo más una incidencia abierta (422 si se reabre otra).

**Alertas** (`alerts.read` / `alerts.manage`):

| Endpoint | Query | Respuestas |
| --- | --- | --- |
| `GET /alerts` | `status` (`open` = activas y reconocidas, por defecto; `active`, `acknowledged`, `resolved`), `type`, `severity`, `property_id`, `cursor`, `limit` | 200 página de `{id, type, severity, status, entity_type, entity_id, property_id, property_code, property_name, message, created_at, updated_at, acknowledged_at, acknowledged_by_name, resolved_at, resolved_by_name (null = se resolvió sola)}`, las más nuevas primero |
| `GET /alerts/summary` | — | 200 `{open, high, fresh (sin reconocer), by_type[{type, open, high, fresh}]}` (tarjetas, campana e Inicio) |
| `POST /alerts/{id}/ack` | — | 200. Idempotente |
| `POST /alerts/{id}/resolve` | — | 200 · 422 ya resuelta. Si la causa sigue, el sistema la vuelve a levantar en su siguiente revisión |

Los roles con alcance restringido solo ven alertas de propiedades de su alcance (no las de toda la
empresa). `entity_type` dice a qué lleva: `asset`, `maintenance_plan`, `maintenance_ticket`, `task`,
`inventory_item`, `inventory_discrepancy`, `reservation`.

**Inicio** (`GET /dashboard`, cualquier sesión de empresa): `{date (hoy en la zona de la empresa),
alerts (summary), top_alerts[] (hasta 3, altas primero), incidents{open, urgent, unassigned}, upcoming[]
(preventivos de los próximos 30 días y vencidos, hasta 5), pins[{id, code, name, type, building, zone, lat, lng,
open_tickets, status}], activity[] (8 entradas de bitácora), tasks{available, done, total, in_progress,
late, pending, in_field, ranking[]}}`. Cada bloque respeta el alcance y viene vacío sin su permiso
(alerts.read, maintenance.read, audit.read, properties.read). `tasks.available = false` mientras B no
registre su fuente; la web muestra esos números como muestra.

**Archivos** (flujo de fase01 §3.7.2): `maintenance/ticket_photo` (sube `maintenance.report`, ven
`maintenance.read` o `.report`), `maintenance/ticket_resolution` (sube `maintenance.execute`) e imágenes
PNG, JPG o WebP de hasta 8 MB; `maintenance/asset_document` (sube `maintenance.manage`; PDF o imagen de
hasta 15 MB). `files` guarda ahora `original_name` (el nombre con que se subió).

**Sync**: `GET /sync/bootstrap` suma `assets[{id, property_id, building_id, category, name, location,
status}]` (activos del alcance para el selector de "Reportar incidencia" sin conexión; requiere
`maintenance.report` o `maintenance.read`). Un activo con `building_id` y sin `property_id` se ofrece en
todas las propiedades de ese edificio.

**Trabajos** (worker, cada hora; uno por empresa activa con la hora de su zona):

* `maintenance_due`: para cada preventivo activo con `next_due_at - lead_days <= hoy` y sin incidencia
  abierta crea su incidencia (`plan_id`, urgencia alta si ya venció, `assigned` si tiene responsable o
  proveedor) y publica `maintenance.due`. Si `next_due_at < hoy` levanta `maintenance_overdue` (alta
  si pasó más de una semana).
* `low_stock`: una alerta por artículo con alguna bodega bajo su mínimo (alta si alguna quedó en cero)
  y resuelve las de los que ya se repusieron. Lee `inventory_items.min_stock`, `inventory_stock.quantity`
  y `warehouses` como dice fase02 §2; mientras esas tablas no existan no hace nada.
* `asset_failure`: lo levanta el cambio de estado del activo (`needs_attention` e `in_repair` = media,
  `out_of_service` = alta) y se resuelve al volver a `operational` o al desactivarlo.

**Eventos** (`internal/core/events`, síncronos dentro de la transacción del cambio; `bus.Subscribe(tipo,
fn)` en `app/services.go`):

| Tipo | Data | Destinatarios sugeridos (§4) |
| --- | --- | --- |
| `ticket.created` | `maintenance.TicketEvent{Ticket}` | admin y supervisores |
| `ticket.assigned` | `maintenance.TicketEvent{Ticket, PreviousAssignee}` | el asignado (y el anterior) |
| `ticket.resolved` | `maintenance.TicketEvent{Ticket}` | quien la reportó |
| `maintenance.due` | `maintenance.PlanDueEvent{Plan, Ticket}` | responsable del plan |
| `alert.raised` | `alerts.AlertRead` (solo al crearse, no al refrescar) | según el tipo |

`Event{Type, TenantID, ActorID (uuid.Nil = el sistema), Data}`. Un error del suscriptor revierte el
cambio, así que el suscriptor de notificaciones debe solo encolar (`jobs.Enqueue`), no mandar.

**Para B (enganches listos):**

* `maintenance.Service.SetTaskLinker(fn)`: `fn(ctx, q, actor, ticket) (*uuid.UUID, error)` crea o
  reasigna la tarea `maintenance` al asignar a un colaborador; el id se guarda en `task_id`. Cuando la
  llama el trabajo de preventivos, `actor.UserID` es `uuid.Nil`. Sin linker, asignar no crea tarea.
* `maintenance.Service.ResolveFromTask(ctx, q, actor, taskID, resolution)`: al cerrar la tarea, resuelve
  su incidencia en la misma transacción (false si no tenía).
* `alerts.Service.Raise(ctx, q, tenantID, alerts.Raise{Type, Severity, EntityType, EntityID, PropertyID,
  Message})` y `alerts.ResolveFor(ctx, q, type, entityType, entityID, by)`: para `task_late`,
  `discrepancy_open` y `checkout_alarm_unattended`. Levantar dos veces la misma causa no duplica (refresca
  mensaje y severidad).
* `dashboard.Service.SetTasksSource(fn)`: llena `tasks` y el estado de los pines (`cleaning`, `late`,
  `pending`, `ready`) del Inicio.
* Bandeja web: la campana ya llama a `GET /notifications?limit=30` → `{items[{id, type, title, body,
  data, read_at, created_at}], next_cursor, unread}`, `POST /notifications/{id}/read` y
  `POST /notifications/read-all`, cada 60 s. Al tocar una, la web navega a `data.route` (ruta de la web,
  p. ej. `/mantenimiento?ver=<ticket_id>`, `/mantenimiento?tab=preventivos`, `/alertas?tipo=low_stock`,
  `/inventario`). Si B sigue este contrato, basta poner `notifications: false` en `MOCK_MODULES`.

**Diferencias con el plan:**

* `maintenance_tickets.property_id` es opcional y se agregó `building_id`: el preventivo de un elevador
  no es de una propiedad. Al menos uno de los dos (CHECK). También `number` (folio corto por empresa).
* `alerts.resolved_by`: quien la resolvió a mano (vacío si se resolvió sola).
* La FK `task_id → tasks` se crea solo si `tasks` existe al migrar. En el orden normal (0003 de B antes
  que 0004) siempre existe. Una base local que aplicó 0004 sin 0003 debe revertir 0004 antes de aplicar
  0003: el motor de migraciones se detiene si aparece una versión menor después de una mayor.
* Documentos y fotos usan `files` con `entity_type` `asset` o `maintenance_ticket` (fotos: `kind`
  `ticket_photo` o `ticket_resolution`; documentos: `asset_document`).
* Endpoint nuevo `POST /tickets/{id}/reopen` y `GET /maintenance/assignables`; `GET /tickets` también lo
  usa quien solo tiene `maintenance.report` (ve lo que reportó).
* Los trabajos corren cada hora (no diario) para respetar la zona horaria de cada empresa; son
  idempotentes.
* `low_stock` levanta una alerta por artículo (con sus bodegas en el mensaje), no por bodega.

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
