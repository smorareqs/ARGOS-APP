# Fase 2 — Operación: propiedades, colaboradores, itinerario, limpiezas e inventario

> Estado: en curso. Parte de Persona A **hecha** (2026-11-21): migraciones `shared/0003_role_scope` y
> `tenant/0002_properties`, módulos `properties`, `checklists`, `employees`, `audit` (lectura),
> `ScopeResolver` (`authz.ResolvePropertyScope`) y `sync` (`GET /sync/bootstrap`), con la web conectada
> (W-C1 a W-C4, W-D2 sin RRHH, W-N1). Contrato en §4.1. Pendiente: `tenant/0003_tasks_inventory` y
> los módulos `tasks` e `inventory` (Persona B).

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
`0003_tasks_inventory` (Persona B, se aplica después de 0002) crea `tasks`,
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

### 4.1 Contrato implementado (Persona A, 2026-11-21)

Existe en el backend (rama `dev/sebas`) y la web lo usa contra la API real. **La app de B puede
consumirlo tal cual.** OpenAPI vivo en `GET /api/v1/openapi.json`. Todas las rutas van bajo `/api/v1`
y operan en la empresa de la sesión (el `tid` del token); en modo plataforma responden 403.

Convenciones nuevas:

* **Alcance** (`authz.ResolvePropertyScope`): ve todas las propiedades quien tiene `properties.manage`,
  `tasks.manage` o un rol sin alcance restringido (`roles.scoped = false`: administración, supervisión,
  seguridad). Los roles con `scoped = true` (limpieza, mantenimiento, propietario y los personalizados
  que lo marquen) ven solo `property_assignments` ∪ `property_owners`. Fuera de alcance: la lista no
  la trae y por id responde **404**.
* **Paginación** (`internal/core/paging`): `?limit=` (por defecto 50, máximo 500) y `?cursor=` opaco;
  respuesta `{items, next_cursor}` (null en la última página). Un cursor inválido da 422 `query.cursor`.
* **PATCH**: solo cambia lo que viene; `null` borra un campo opcional (`internal/core/optional`).
* Errores 422 con `errors[].location` por campo (`body.code`, `body.user_ids`…), como en la fase 1.

**Propiedades** (`properties.read` para leer, `properties.manage` para escribir):

| Endpoint | Cuerpo / query | Respuestas |
| --- | --- | --- |
| **`GET /properties`** | `q` (código, nombre, zona o edificio; sin importar tildes), `building_id`, `active=true` o `false`, `assignee`, `owner`, `cursor`, `limit` | 200 página de propiedades (ver abajo), por código |
| **`GET /properties/{id}`** | — | 200 · 404 fuera de alcance |
| `POST /properties` | `code` (2–32 letras, números o guiones; se guarda en mayúsculas), `name`, `type` (`apartment`, `house`, `room`, `other`), `building_id?`, `address?`, `zone?`, `lat?` y `lng?` (juntas), `bedrooms?`, `bathrooms?`, `max_guests?`, `checklist_template_id?` (sin valor = plantilla por defecto), `access_info?`, `cover_file_id?`, `notes?` | 201 · 422 `body.code` (repetido o inválido), `body.building_id`, `body.checklist_template_id`, `body.cover_file_id`, `body.lat` |
| `PATCH /properties/{id}` | cualquiera de los anteriores y `is_active`; `access_info: null` o `""` la borra | 200 · 404 · 422 por campo |
| `DELETE /properties/{id}` | — | 204. Borrado lógico: libera el código y quita asignaciones; el historial queda |
| **`GET /properties/{id}/access-info`** | — | 200 `{property_id, text, updated_at, viewed_at}` (`properties.access_info`). Cada consulta queda en la bitácora (`property.access_viewed`). Limpieza y mantenimiento reciben **403** sin tarea del día (ver `AccessGate`); 404 si no tiene acceso cargado |
| `PUT /properties/{id}/assignments` · `/owners` | `user_ids[]` (personas de la empresa) | 200 propiedad · 422 `body.user_ids` |
| `PUT /property-assignments/{user_id}` · `/property-owners/{user_id}` | `property_ids[]` | 200 `{user_id, property_ids}` · 404 si la persona no es de la empresa · 422 `body.property_ids` |

Propiedad: `{id, code, name, type, building_id, building_name, building_zone, address, zone, lat, lng,
bedrooms, bathrooms, max_guests, checklist_template_id, checklist_template_name, has_access_info,
access_info_updated_at, cover_file_id, cover_url (firmada 12 h), notes, is_active, assigned[{user_id,
full_name}], owners[{user_id, full_name}], created_at, updated_at}`. **Nunca** trae el texto de acceso.
Cuando existan tareas (0003) se agregan `today_status` y `last_cleaning_at`, y en la fase 3
`open_incidents` (A agrega esos JOIN en su repositorio).

**Edificios** (`properties.read` / `properties.manage`):

| Endpoint | Cuerpo | Respuestas |
| --- | --- | --- |
| **`GET /buildings`** · `GET /buildings/{id}` | — | 200 `{id, name, address, zone, lat, lng, notes, is_active, properties_count, created_at, updated_at}`. Con alcance restringido, solo los edificios donde tiene alguna propiedad |
| `POST /buildings` · `PATCH /buildings/{id}` | `name`, `address?`, `zone?`, `lat?` y `lng?`, `notes?` (`is_active` en PATCH) | 201/200 · 422 `body.name` (repetido) / `body.lat` |
| `DELETE /buildings/{id}` | — | 204 · 422 si tiene propiedades (se desactiva en su lugar) |

**Plantillas de checklist** (leer con `properties.read`, cambiar con `properties.manage`):

| Endpoint | Cuerpo | Respuestas |
| --- | --- | --- |
| **`GET /checklist-templates`** · `GET /checklist-templates/{id}` | — | 200 `{id, name, description, is_default, properties_count, items[{id, section, position, text, requires_photo, requires_before_after}], created_at, updated_at}`; la de por defecto primero |
| `POST /checklist-templates` | `name`, `description?`, `is_default?`, `items[{section, text, requires_photo?, requires_before_after?}]` (el orden de la lista es el orden; antes y después implica foto) | 201 · 422 `body.name` (repetido) / `body.items` (vacío) |
| `PATCH /checklist-templates/{id}` | lo anterior opcional; `items` reemplaza todos | 200. Marcar `is_default` le quita la marca a la anterior |
| `DELETE /checklist-templates/{id}` | — | 204; sus propiedades quedan sin plantilla |

Diferencia con el plan: leer plantillas pide `properties.read` (no `properties.manage`) porque la app
las necesita sin conexión. La tarea copia los ítems al iniciar (B), así que editar una plantilla no
cambia las tareas en curso.

**Ficha laboral** (`users.manage`):

| Endpoint | Cuerpo | Respuestas |
| --- | --- | --- |
| `GET /employees?user_id=` · `GET /employees/{id}` | — | 200 `{id, user_id, full_name, email, employee_code, position, hire_date, termination_date, document_type, document_number, igss_number, nit, pay_type, pay_rate, on_payroll, emergency_name, emergency_phone, emergency_relation, notes, schedule[], created_at, updated_at}` |
| `POST /employees` | `user_id`, `position`, `hire_date` (AAAA-MM-DD), `pay_type` (`fixed_monthly`, `per_day`, `per_hour`, `per_cleaning`), `pay_rate` y opcionales: `employee_code` (sin valor: EMP-0001…), `termination_date`, `document_type` (`dpi`, `passport`), `document_number` (DPI: 13 dígitos), `igss_number`, `nit` (1234567-8 o CF), `on_payroll`, `emergency_name` con `emergency_phone`, `emergency_relation`, `notes`, `schedule[]` | 201 · 422 `body.user_id` (no es de la empresa o ya tiene ficha), `body.document_number`, `body.document_type`, `body.nit`, `body.termination_date`, `body.emergency_phone`, `body.schedule` |
| `PATCH /employees/{id}` | lo anterior sin `user_id` ni `schedule`; null borra | 200 |
| `PUT /employees/{id}/schedule` | `blocks[{weekday (0 = domingo … 6 = sábado), starts_at, ends_at (HH:MM)}]` | 200 ficha · 422 `body.blocks` (fin antes del inicio o bloques que se cruzan el mismo día) |

La bitácora de la ficha registra qué campos cambiaron, nunca los valores de los documentos.

**Bitácora** (`audit.read`):

| Endpoint | Query | Respuestas |
| --- | --- | --- |
| `GET /audit` | `entity`, `entity_id`, `property_id`, `actor_id`, `action` (prefijo, p. ej. `property.`), `from` y `to` (RFC 3339; `to` excluyente), `cursor`, `limit` | 200 página de `{id, actor_id, actor_name, actor_email, actor_role, action, entity, entity_id, entity_label, property_id, property_code, property_name, before, after, ip, user_agent, created_at}`, lo más reciente primero |

Acciones registradas en esta fase: `property.created`, `.updated`, `.deleted`, `.access_viewed`,
`.assignments_changed`, `.owners_changed`; `building.*`; `checklist_template.*`; `employee.created`,
`.updated`, `.schedule_changed`; más las de la fase 1 (`member.*`, `invitation.*`, `role.*`,
`tenant.settings_updated`).

**Sync para la app** (cualquier sesión dentro de una empresa):

| Endpoint | Respuesta |
| --- | --- |
| **`GET /sync/bootstrap`** | 200 `{server_time, scoped, properties[] (como GET /properties, sin acceso), buildings[], checklist_templates[] (las que usan sus propiedades), schedule[] (horario propio)}`. Sin `properties.read`, las listas vienen vacías |

Las tareas se sincronizan aparte con `GET /tasks?from=&to=&updated_since=` (B). B agrega
`inventory_items` al bootstrap cuando exista su módulo (campo nuevo en `appsync.Bootstrap`, PR pequeño).

**Archivos**: tipo nuevo `properties/cover` (PNG, JPG o WebP, 5 MB; lo sube quien tiene
`properties.manage` y lo ve quien tiene `properties.read`). El flujo es el de fase01 §3.7.2; después
`PATCH /properties/{id}` con `cover_file_id`.

**Invitaciones**: los `property_ids` de `POST /tenants/{id}/invitations` ahora se validan (422
`body.property_ids`) y al aceptar se crean las asignaciones (o la propiedad queda como propia si el
rol es `owner`).

**Roles**: `scoped` en `GET/POST/PATCH /tenants/{id}/roles` (antes solo informativo). Quien tiene un
rol con alcance restringido no crea ni da roles sin restricción (422 `body.scoped` / `body.role_key`).

**Para B (enganches listos):**

* `authz.ResolvePropertyScope(ctx, q, actor)` con `scope.SQLArgs()` filtra tareas e inventario por
  propiedad (`WHERE ($1::bool OR t.property_id = ANY($2::uuid[]))`). `auth.Principal.Actor()` arma
  el actor desde el handler.
* `properties.Service.SetAccessGate(fn)`: B registra en `app/services.go` la regla de la tarea del día
  (`fn(ctx, q, actor, propertyID) (bool, error)`). Sin ella, limpieza y mantenimiento reciben 403 al
  pedir el acceso.
* `audit.Record(ctx, q, audit.Entry{...})` dentro de la transacción del cambio, con `PropertyID` para
  que aparezca en el historial de la propiedad.
* `paging.Limit`, `paging.Decode` y `paging.Page` para las listas con cursor.
* `optional.Value[T]` para los PATCH con null.
* `files.Rules`: B agrega `tasks/before`, `tasks/after` y `tasks/evidence` (solo se agregan líneas).

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
