# Fase 2 — Operación: propiedades, colaboradores, itinerario, limpiezas e inventario

> Estado: pendiente. Requiere fase 1 completa.

## 1. Objetivo

Que un tenant pueda operar su día a día de limpieza: dar de alta propiedades con su
checklist, asignar colaboradores a lugares, programar tareas, ejecutarlas desde la app
con evidencias, y controlar el inventario con custodia y conciliación al cierre.
Todo queda en bitácora.

Fuera de la fase: mantenimiento (fase 3), reservas (fase 4), nómina (fase 5).

## 2. Modelo de datos (schema de tenant, migraciones `tenant/0002_properties` y `tenant/0003_tasks_inventory`)

Todas las tablas llevan `id`, `created_at`, `updated_at`. Las FK a usuarios apuntan a
`shared.users(id)`.

Reparto (ver [reparto.md](reparto.md)): `0002_properties` (Persona A) crea `buildings`,
`properties`, `property_owners`, `property_assignments`, `employees`,
`employee_schedules`, `checklist_templates` y `checklist_template_items`.
`0003_tasks_inventory` (Persona B, `down_revision` = 0002) crea `tasks`,
`task_checklist_items`, `task_events`, `task_consumptions` y todas las tablas de
inventario.

### `buildings`

| Columna | Tipo |
| --- | --- |
| name | varchar(128) |
| address | text null |
| lat, lng | numeric(9,6) null |
| notes | text null |
| is_active | bool default true |

### `properties`

| Columna | Tipo | Notas |
| --- | --- | --- |
| building_id | uuid FK buildings null | |
| code | varchar(32) unique | corto, visible en app |
| name | varchar(128) | |
| type | varchar(16) CHECK IN ('apartment','house','room','other') | |
| address | text null | |
| lat, lng | numeric(9,6) null | |
| bedrooms, bathrooms | smallint null | |
| max_guests | smallint null | |
| checklist_template_id | uuid FK checklist_templates null | plantilla por defecto |
| access_info | text null | **cifrado** (EncryptedString): llaves, códigos, wifi |
| notes | text null | |
| is_active | bool default true | |
| deleted_at | timestamptz null | borrado lógico |

### `property_owners`

| Columna | Tipo |
| --- | --- |
| property_id | uuid FK properties ON DELETE CASCADE |
| user_id | uuid FK shared.users |

PK `(property_id, user_id)`. El usuario debe tener membresía en el tenant (validado en
service). Define el alcance del rol `owner`.

### `property_assignments`

| Columna | Tipo |
| --- | --- |
| property_id | uuid FK properties ON DELETE CASCADE |
| user_id | uuid FK shared.users |
| assigned_by | uuid FK shared.users |
| created_at | timestamptz |

PK `(property_id, user_id)`. Define el alcance de `cleaner` y `maintenance`.

### `employees` (perfil laboral)

| Columna | Tipo | Notas |
| --- | --- | --- |
| user_id | uuid FK shared.users unique | |
| employee_code | varchar(32) unique | |
| position | varchar(64) | |
| hire_date | date | |
| termination_date | date null | |
| document_type | varchar(16) CHECK IN ('dpi','passport') null | |
| document_number | varchar(32) null | |
| igss_number | varchar(32) null | |
| nit | varchar(16) null | |
| pay_type | varchar(16) CHECK IN ('fixed_monthly','per_day','per_hour','per_cleaning') | |
| pay_rate | numeric(12,2) | monto por unidad del esquema |
| on_payroll | bool default false | en planilla |
| emergency_contact | jsonb null | |
| notes | text null | |

### `employee_schedules`

| Columna | Tipo |
| --- | --- |
| employee_id | uuid FK employees ON DELETE CASCADE |
| weekday | smallint CHECK 0..6 |
| starts_at, ends_at | time |

### `checklist_templates`, `checklist_template_items`

`checklist_templates`: `name`, `description`, `is_default bool`.

`checklist_template_items`: `template_id FK`, `section varchar(64)` (Habitación 1, Baño,
Cocina, Áreas comunes…), `position int`, `text varchar(255)`, `requires_photo bool`,
`requires_before_after bool`.

### `tasks`

| Columna | Tipo | Notas |
| --- | --- | --- |
| property_id | uuid FK properties | |
| type | varchar(24) CHECK IN ('cleaning','inspection','maintenance','checkout_review') | |
| status | varchar(16) CHECK IN ('pending','in_progress','completed','validated','cancelled') | |
| scheduled_date | date | |
| window_start, window_end | time null | ventana |
| assigned_to | uuid FK shared.users null | |
| assigned_by | uuid FK shared.users null | |
| created_by | uuid FK shared.users null | null si la creó el sistema |
| reservation_id | uuid null | FK real en fase 4 |
| maintenance_ticket_id | uuid null | FK real en fase 3 |
| checklist_template_id | uuid FK null | snapshot al iniciar |
| priority | smallint default 0 | |
| started_at, finished_at | timestamptz null | |
| start_lat, start_lng, end_lat, end_lng | numeric(9,6) null | |
| validated_by | uuid FK null, validated_at timestamptz null | |
| is_late | bool default false | lo marca el job de retrasos |
| notes | text null | |
| completion_notes | text null | |

Índices: `(scheduled_date)`, `(assigned_to, scheduled_date)`, `(property_id, scheduled_date)`,
`(status)`.

### `task_checklist_items`

| Columna | Tipo |
| --- | --- |
| task_id | uuid FK tasks ON DELETE CASCADE |
| section | varchar(64) |
| position | int |
| text | varchar(255) |
| requires_photo | bool |
| requires_before_after | bool |
| is_done | bool default false |
| done_at | timestamptz null |
| notes | text null |

Las fotos se relacionan por `files.entity_type='task_checklist_item'` con `kind`
`before`/`after`/`evidence`.

### `task_events`

| Columna | Tipo |
| --- | --- |
| task_id | uuid FK ON DELETE CASCADE |
| type | varchar(24): created, assigned, reassigned, rescheduled, started, checkpoint, finished, validated, cancelled, late |
| actor_user_id | uuid null |
| data | jsonb |
| created_at | timestamptz |

### `task_consumptions` (insumos usados en la tarea)

`task_id FK`, `item_id FK inventory_items`, `quantity numeric(12,3)`.

### Inventario

`warehouses`: `name`, `property_id FK null` (null = bodega central), `is_active`.
`UNIQUE (property_id)` parcial para una bodega por propiedad.

`inventory_items`: `sku varchar(32) unique null`, `name`, `category varchar(16) CHECK IN
('consumable','tool','key')`, `unit varchar(16)`, `min_stock numeric(12,3) default 0`,
`is_active`.

`inventory_stock`: `warehouse_id FK`, `item_id FK`, `quantity numeric(12,3)`.
PK `(warehouse_id, item_id)`.

`inventory_movements`:

| Columna | Tipo | Notas |
| --- | --- | --- |
| item_id | uuid FK | |
| type | varchar(24) CHECK IN ('in','out','transfer','consumption','adjustment','checkout_to_employee','return_from_employee') | |
| quantity | numeric(12,3) | positiva |
| from_warehouse_id | uuid FK null | |
| to_warehouse_id | uuid FK null | |
| employee_user_id | uuid FK null | en checkout/return |
| task_id | uuid FK null | |
| reference | varchar(128) null | factura, nota |
| notes | text null | |
| created_by | uuid FK | |

`employee_custody`: `user_id`, `item_id`, `quantity numeric(12,3)`. PK `(user_id, item_id)`.
Se actualiza en la misma transacción que el movimiento.

`inventory_discrepancies`:

| Columna | Tipo |
| --- | --- |
| user_id | uuid FK |
| item_id | uuid FK |
| task_id | uuid FK null |
| expected_qty, returned_qty | numeric(12,3) |
| status | varchar(16) CHECK IN ('open','justified','closed') |
| justification | text null |
| resolved_by | uuid FK null, resolved_at timestamptz null |

`restock_requests`: `item_id`, `warehouse_id`, `quantity`, `requested_by`, `status`
(`open`, `approved`, `rejected`, `fulfilled`), `notes`.

## 3. Reglas de negocio

* **Alcance**: `ScopeResolver.property_ids_for(principal)` devuelve: todas si tiene
  `properties.manage` o `tasks.manage`; las de `property_assignments` para cleaner y
  maintenance; las de `property_owners` para owner. Todo repositorio de tareas,
  propiedades e inventario por propiedad filtra por ese conjunto.
* Solo se puede asignar una tarea a un usuario con la propiedad en sus asignaciones y
  con rol que tenga `tasks.execute`.
* `access_info` solo se incluye en la respuesta si el principal tiene
  `properties.access_info`, y solo para tareas del día (cleaner/maintenance) o siempre
  (admin/supervisor/security).
* Iniciar tarea: requiere GPS; copia la plantilla a `task_checklist_items`; crea evento.
  Solo el asignado o un supervisor/admin.
* Cierre de tarea (**prueba de check-out del colaborador**), en una sola transacción:
  1. Todos los ítems con `requires_photo` tienen al menos un `file` `ready`.
  2. Todos los ítems `requires_before_after` tienen `before` y `after`.
  3. GPS de fin presente.
  4. Se envía la declaración de custodia: por cada ítem en `employee_custody` del
     usuario, cantidad devuelta y consumida. Herramientas y llaves: devuelta debe
     igualar la custodia; consumibles: devuelta + consumida debe igualar la custodia.
     Cada diferencia crea `inventory_discrepancies` en `open` y un evento.
  5. Se registran movimientos `return_from_employee` y `consumption`.
  6. Estado → `completed`; notificación al supervisor (fase 3 la envía; aquí solo se
     encola el job).
* Validación por supervisor: `completed` → `validated`, con nota opcional. Puede
  devolver a `in_progress` con motivo.
* Job `mark_late_tasks` (cada 5 min): marca `is_late` si pasó `window_start` sin iniciar
  o `window_end` sin terminar, y crea evento `late`.
* Reprogramar o reasignar: solo `tasks.assign`; crea evento; encola notificación.
* Inventario: `inventory_stock` nunca negativo (CHECK); los movimientos son inmutables;
  los ajustes exigen `inventory.manage` y nota.
* Bitácora: cada service escribe en `audit_log` con `before`/`after` para propiedades,
  asignaciones, tareas (cambios de estado), movimientos e inventario.

## 4. Endpoints principales

| Ruta | Permiso |
| --- | --- |
| `GET/POST/PATCH/DELETE /buildings`, `/properties` | `properties.read` / `properties.manage` |
| `GET /properties/{id}/access-info` | `properties.access_info` |
| `PUT /properties/{id}/owners`, `/assignments` | `properties.manage` |
| `GET/POST/PATCH /checklist-templates` | `properties.manage` |
| `GET/POST/PATCH /employees`, `/employees/{id}/schedule` | `users.manage` |
| `GET /tasks?date=&from=&to=&property=&assignee=&status=` | `tasks.read` (scope) |
| `POST /tasks`, `PATCH /tasks/{id}`, `POST /tasks/{id}/assign`, `/reschedule`, `/cancel` | `tasks.manage` / `tasks.assign` |
| `POST /tasks/{id}/start`, `PATCH /tasks/{id}/checklist/{item}`, `POST /tasks/{id}/consumptions`, `POST /tasks/{id}/complete` | `tasks.execute` |
| `POST /tasks/{id}/validate`, `/reopen` | `tasks.validate` |
| `GET /tasks/{id}/events` | `tasks.read` |
| `GET/POST/PATCH /inventory/items`, `/warehouses`, `GET /inventory/stock` | `inventory.read` / `inventory.manage` |
| `POST /inventory/movements` | `inventory.manage`; tipos checkout/return también con `inventory.checkout` para el propio usuario |
| `GET /inventory/custody/me`, `GET /inventory/custody/{user}` | `inventory.checkout` / `inventory.reconcile` |
| `GET/PATCH /inventory/discrepancies` | `inventory.reconcile` |
| `POST /inventory/restock-requests` | `inventory.checkout` |
| `GET /audit?entity=&property=&actor=&from=&to=` | `audit.read` |

Todos con paginación por cursor (`?cursor=&limit=`).

## 5. App móvil

* **Hoy / Semana**: lista de tareas del usuario con estado, propiedad, ventana y
  retraso. Detalle con dirección, mapa, información de acceso (si permite), checklist
  por secciones, cámara integrada por ítem (compresión a 1600 px, JPEG 80).
* **Cierre**: pantalla de conciliación de custodia con cantidades editables y resumen
  de diferencias antes de confirmar.
* **Inventario**: mi custodia, sacar artículos (escaneo de código de barras opcional
  con `mobile_scanner`), solicitar reposición.
* **Supervisor**: equipo del día, reasignar, validar con galería de evidencias.
* **Sin conexión**: Drift guarda tareas de hoy y mañana, checklist y propiedades
  asignadas. Cola local `pending_uploads` (fotos, checkpoints, consumos) con reintento
  en segundo plano (`workmanager`). El cierre de tarea exige conexión; si no hay, queda
  "lista para cerrar" y se cierra al reconectar.
* **Sync**: reemplazar el mock actual por sincronización real: `GET /sync/bootstrap`
  (propiedades, plantillas, ítems de inventario) y `GET /tasks?from&to` incremental por
  `updated_since`.

## 6. Portal web

* Propiedades: lista, ficha (pestañas: datos, acceso, checklist, propietarios,
  asignados, historial), edificios.
* Colaboradores: lista, ficha laboral, horario, propiedades asignadas.
* Itinerario: calendario semanal por colaborador y por propiedad (arrastrar para
  reasignar/reprogramar), tablero del día con retrasos, detalle de tarea con evidencias
  y línea de tiempo.
* Inventario: artículos, bodegas, existencias con alertas de mínimo, movimientos,
  custodias, discrepancias, solicitudes de reposición.
* Bitácora: tabla con filtros.

## 7. Pruebas

* Cleaner de `tenant_a` no ve tareas de propiedades no asignadas (lista vacía) y recibe
  404 al pedir una por id.
* Owner solo ve sus propiedades y sus tareas.
* Cierre de tarea falla sin fotos obligatorias; con custodia 5 y devolución 4 crea
  discrepancia.
* Stock nunca negativo; movimiento y custodia atómicos.
* Job de retrasos marca correctamente en la zona horaria del tenant.

## 8. Criterios de aceptación

Una empresa registra tres propiedades con checklist, asigna dos colaboradores, programa
la semana, los colaboradores ejecutan tareas con fotos desde el móvil (incluso con
señal intermitente), cierran con conciliación de inventario, el supervisor valida y todo
aparece en bitácora y en el calendario web.
