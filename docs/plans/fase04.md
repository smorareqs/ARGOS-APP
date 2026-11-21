# Fase 4 — Reservas, huéspedes, seguridad, parqueos y áreas comunes

> Estado: pendiente. Requiere fase 3 (notificaciones). Habilitada por la bandera
> `reservations` del tenant; `parking` y `shared_areas` tienen bandera propia.

## 1. Objetivo

ARGOS pasa a ser la fuente de verdad de las reservas: canales, huéspedes con documento,
dos flujos de venta (directa con depósito y check-in/out; agencia/OTA con inspección
interna), inspecciones antes/después, parqueos, áreas comunes reservables por el huésped,
tablero y alarmas de seguridad, importación iCal y acceso de huéspedes a la app sin
contraseña.

## 2. Modelo de datos (migraciones `tenant/0006_reservations` y `tenant/0007_guest_parking_areas`)

Reparto (ver [reparto.md](reparto.md)): `0006_reservations` (Persona A) crea
`booking_channels`, `property_ical_feeds`, `guests`, `reservations`,
`reservation_guests`, `reservation_events`, `deposit_transactions`, `inspections`,
`inspection_findings` y agrega las FK `tasks.reservation_id` y
`maintenance_tickets.reported_by_guest_id`. `0007_guest_parking_areas` (Persona B) crea
`guest_access_tokens`, `security_alarms`, `parking_spots`, `parking_assignments`,
`shared_areas` y `shared_area_bookings`.

### `booking_channels`

| Columna | Tipo | Notas |
| --- | --- | --- |
| name | varchar(64) | "Booking", "Airbnb", "Página web", "Agencia X" |
| kind | varchar(16) CHECK IN ('direct','booking','airbnb','agency','other') | |
| requires_deposit | bool | |
| has_checkin | bool | flujo formal de check-in / check-out |
| default_deposit_amount | numeric(12,2) null | |
| is_active | bool | |

Al activar la bandera `reservations` se siembran: Directo (depósito, check-in),
Booking (sin depósito, sin check-in), Airbnb (igual que Booking).

### `property_ical_feeds`

`property_id FK`, `channel_id FK`, `url text`, `last_synced_at`, `last_error text null`,
`is_active`. `UNIQUE (property_id, channel_id)`.

### `guests`

| Columna | Tipo | Notas |
| --- | --- | --- |
| full_name | varchar(160) | |
| email | varchar(320) null | obligatorio para el huésped principal |
| phone | varchar(32) null | |
| document_type | varchar(16) CHECK IN ('dpi','passport') | |
| document_number | varchar(32) | |
| nationality | char(2) null | |
| notes | text null | |
| blacklisted | bool default false | |

`UNIQUE (document_type, document_number)`. Fotos del documento: `files` con
`entity_type='guest'`, `kind in ('id_front','id_back')`, `expires_at` fijado al
check-out + 90 días (ver 3).

### `reservations`

| Columna | Tipo | Notas |
| --- | --- | --- |
| property_id | uuid FK | |
| channel_id | uuid FK booking_channels | |
| external_ref | varchar(128) null | id en Booking/Airbnb/UID iCal |
| code | varchar(12) unique | código corto para el huésped (ej. `ARG-7K3P9Q`) |
| primary_guest_id | uuid FK guests null | null hasta que el admin completa una reserva importada |
| status | varchar(16) CHECK IN ('pending','confirmed','checked_in','checked_out','cancelled','no_show') | |
| check_in_date, check_out_date | date | |
| check_in_time, check_out_time | time | por defecto de settings del tenant (15:00 / 11:00) |
| checked_in_at, checked_out_at | timestamptz null | reales |
| adults, children | smallint | |
| total_amount | numeric(12,2) null | |
| currency | char(3) | |
| deposit_amount | numeric(12,2) null | |
| deposit_status | varchar(16) CHECK IN ('none','pending','received','returned','retained_partial','retained_full') | |
| source | varchar(16) CHECK IN ('manual','ical','api') | |
| notes | text null | |
| created_by | uuid FK null | |
| cancelled_at | timestamptz null, cancel_reason text null | |

Índices: `(property_id, check_in_date)`, `(check_out_date)`, `(status)`,
`UNIQUE (property_id, external_ref) WHERE external_ref IS NOT NULL`.
Restricción de solapamiento: `EXCLUDE USING gist (property_id WITH =,
daterange(check_in_date, check_out_date) WITH &&) WHERE (status NOT IN
('cancelled','no_show'))` (requiere `btree_gist`).

`reservation_guests`: `reservation_id`, `guest_id`, `is_primary`. PK compuesta.

`reservation_events`: `reservation_id`, `type`, `actor_user_id`, `actor_guest_id`,
`data`, `created_at`.

### `deposit_transactions`

`reservation_id FK`, `type varchar(16) CHECK IN ('received','returned','retained')`,
`amount numeric(12,2)`, `method varchar(16) CHECK IN ('cash','transfer','card','other')`,
`reference varchar(128) null`, `notes text null`, `registered_by uuid FK`. Inmutable.
`deposit_status` de la reserva se recalcula en el service.

### `inspections`

| Columna | Tipo |
| --- | --- |
| reservation_id | uuid FK |
| property_id | uuid FK |
| kind | varchar(16) CHECK IN ('pre_arrival','post_departure') |
| performed_by | uuid FK |
| performed_at | timestamptz |
| task_id | uuid FK tasks null |
| notes | text null |

`inspection_findings`: `inspection_id`, `area varchar(64)`, `description text`,
`severity varchar(8)`, `estimated_cost numeric(12,2) null`, `charge_to_deposit bool`,
`ticket_id uuid FK null` (si se convierte en incidencia). Fotos por `files`.

### `guest_access_tokens`

| Columna | Tipo |
| --- | --- |
| reservation_id | uuid FK ON DELETE CASCADE |
| guest_id | uuid FK |
| token_hash | char(64) unique |
| kind | varchar(8) CHECK IN ('magic','code') |
| expires_at | timestamptz (check_out + 24 h) |
| last_used_at | timestamptz null |
| fcm_token | varchar(512) null |
| revoked_at | timestamptz null |

### Parqueos (bandera `parking`)

`parking_spots`: `building_id FK null`, `property_id FK null` (uno obligatorio),
`code varchar(16)`, `is_active`. `UNIQUE (building_id, code)`.

`parking_assignments`: `spot_id FK`, `reservation_id FK`, `vehicle_plate varchar(16)`,
`vehicle_description varchar(128) null`, `from_date`, `to_date`, `created_by`.
`EXCLUDE USING gist (spot_id WITH =, daterange(from_date, to_date, '[]') WITH &&)`.

### Áreas comunes (bandera `shared_areas`)

`shared_areas`: `building_id FK null`, `property_id FK null`, `name`, `description`,
`capacity smallint` (reservas simultáneas), `slot_minutes smallint`, `opens_at time`,
`closes_at time`, `max_per_reservation_per_day smallint default 1`,
`advance_days smallint default 7`, `rules text null`, `is_active`.

`shared_area_bookings`: `area_id FK`, `reservation_id FK null`, `guest_id FK null`,
`booked_by_user_id FK null` (admin/supervisor), `starts_at`, `ends_at` (timestamptz),
`status varchar(16) CHECK IN ('confirmed','cancelled')`, `cancelled_at`,
`cancel_reason`. Índice `(area_id, starts_at)`.

### Alarmas de seguridad

`security_alarms`: `reservation_id FK`, `kind varchar(16) CHECK IN ('checkout','checkin')`,
`fire_at timestamptz`, `status varchar(16) CHECK IN ('scheduled','fired','attended','cancelled')`,
`attended_by uuid FK null`, `attended_at`, `notes`.

## 3. Reglas de negocio

* **Crear reserva** (manual): valida solapamiento, genera `code`, aplica
  `requires_deposit` del canal (`deposit_status='pending'` con `deposit_amount` por
  defecto). Estado `confirmed` al guardarla si tiene huésped principal; `pending` si no.
* **Confirmar**: crea `guest_access_tokens` (magic + code), envía correo al huésped con
  detalle, instrucciones, enlace `argos://guest?token=` y código; programa:
  * recordatorio de check-in al huésped (día anterior, 18:00 hora del tenant),
  * `security_alarms` `checkout` con `fire_at = check_out_date + check_out_time -
    settings.checkout_alarm_lead_minutes` (por defecto 30) y un segundo a la hora
    exacta (dedupe por `dedupe_key`),
  * tarea `cleaning` para `check_out_date` con ventana desde `check_out_time`, asignada
    por el admin después (estado `pending` sin asignado) y con `reservation_id`.
* **Registro de huéspedes**: obligatorio antes del check-in en canales `has_checkin`:
  nombre, correo, documento, fotos frente y reverso (obligatorias). El service fija
  `files.expires_at = check_out_date + 90 días`; el job `retention_cleanup` (diario)
  borra de S3 y marca `deleted` los vencidos. El número de documento se conserva.
  Solo `guests.documents` puede obtener URL de esas fotos.
* **Check-in**: canal `has_checkin`; exige huéspedes registrados y, si
  `requires_deposit`, depósito `received`. Marca `checked_in`, cancela la alarma
  `checkin` si existía.
* **Check-out**: marca `checked_out`; para venta directa abre inspección
  `post_departure` obligatoria antes de devolver depósito; para OTA/agencia la
  inspección es el mecanismo de "cómo lo dejé / cómo lo dejaron": el sistema exige que
  exista `pre_arrival` (fotos al terminar la limpieza previa, se puede vincular a la
  tarea) y `post_departure`.
* **Depósito**: `returned` solo tras inspección sin hallazgos con `charge_to_deposit`;
  `retained_*` con hallazgos. Toda transacción notifica al huésped por correo.
* **Alarma de check-out**: al `fire_at`, notificación push y `inapp` a todos los
  usuarios con `security.dashboard` (críticas, no desactivables), y alerta
  `checkout_alarm_unattended` si nadie la marca atendida en 60 min.
* **Parqueo**: al asignar se valida disponibilidad por fechas; el huésped ve su espacio
  en la app; seguridad ve placas activas hoy.
* **Áreas comunes**: el huésped reserva bloques entre `opens_at` y `closes_at` de
  `slot_minutes`, hasta `advance_days` adelante, dentro de su estancia, máximo
  `max_per_reservation_per_day`; el service bloquea el área (`SELECT ... FOR UPDATE`)
  y verifica `count(confirmadas solapadas) < capacity`. Confirmación automática; correo y
  push. Cancelación hasta 1 h antes.
* **iCal**: job `ical_sync` cada 30 min por feed: parsea eventos (`github.com/emersion/go-ical`), crea o
  actualiza reservas `source='ical'` por `(property_id, external_ref=UID)`, estado
  `pending` hasta que el admin completa huésped; cancela las que desaparecen del feed.
  No sobrescribe campos editados manualmente (guarda `synced_fields` en evento).
* **Acceso de huésped**: `POST /guest/auth` con `token` o `code + email` → JWT
  `typ=guest`, `tid`, `rid` (reservation), `gid`. Vigencia hasta `expires_at`. El
  scope del guest es exactamente una reserva y su propiedad. Sin refresh: el JWT dura
  lo mismo que el token de acceso del huésped y se renueva con el mismo código.
* `reservations.read` con alcance `hoy` (security): solo reservas con check-in o
  check-out hoy, o activas. `owner`: reservas de sus propiedades sin datos de documento.

## 4. Endpoints

| Ruta | Permiso |
| --- | --- |
| `GET/POST/PATCH /channels`, `/properties/{id}/ical-feeds` | `reservations.manage` |
| `GET /reservations?from&to&property&status`, `GET /reservations/{id}` | `reservations.read` (scope) |
| `POST /reservations`, `PATCH`, `/confirm`, `/cancel`, `/no-show` | `reservations.manage` |
| `POST /reservations/{id}/guests`, `DELETE .../guests/{gid}` | `guests.manage` |
| `POST /reservations/{id}/check-in`, `/check-out` | `reservations.checkin` |
| `GET/POST /guests`, `PATCH /guests/{id}` | `guests.read` / `guests.manage` |
| `GET /guests/{id}/documents/{file}/url` | `guests.documents` |
| `GET /reservations/{id}/deposit`, `POST .../deposit/transactions` | `deposits.read` / `deposits.manage` |
| `POST /reservations/{id}/inspections`, `POST /inspections/{id}/findings` | `tasks.validate` |
| `GET/POST/PATCH /parking/spots`, `POST /parking/assignments` | `parking.read` / `parking.manage` |
| `GET/POST/PATCH /shared-areas`, `GET /shared-areas/{id}/availability?date=` | `shared_areas.manage` / `shared_areas.read` |
| `POST /shared-areas/{id}/bookings`, `DELETE /bookings/{id}` | `shared_areas.book` |
| `GET /security/dashboard?date=`, `GET /security/alarms`, `POST /security/alarms/{id}/attend` | `security.dashboard` |
| `POST /guest/auth`, `GET /guest/me`, `GET /guest/reservation`, `POST /guest/shared-areas/{id}/bookings`, `GET /guest/parking`, `POST /guest/tickets`, `POST /guest/device` | principal `guest` |
| `POST /public/reservations` | clave API del tenant (fase 6 formaliza `api_keys`; aquí queda definido el contrato) |

## 5. App móvil

* **Modo huésped**: entrada por deep link o código; pantalla "Mi reserva" (fechas,
  propiedad, instrucciones de acceso publicadas por el admin, contacto), áreas comunes
  (calendario de disponibilidad y mis reservas), mi parqueo, reportar problema, chat
  (fase 6). Sesión guardada hasta el vencimiento; sin biometría.
* **Seguridad**: tablero del día (llegadas, salidas, activos, placas, áreas reservadas),
  alarmas pendientes con botón "atendida", búsqueda de huésped por nombre o placa.
* **Supervisor/admin**: check-in con registro de huéspedes y captura de DPI (cámara con
  guía de encuadre), registrar depósito, inspección con fotos por área y hallazgos.
* Limpieza: al cerrar una tarea ligada a reserva se ofrece crear la inspección
  `pre_arrival` reutilizando las fotos "después".

## 6. Portal web

* Reservas: calendario por propiedad (ocupación), lista, ficha (huéspedes, documentos
  con acceso restringido, depósito y transacciones, inspecciones, línea de tiempo,
  parqueo, áreas reservadas), alta manual, importación iCal por propiedad.
* Huéspedes: directorio, historial, lista negra.
* Parqueos y áreas comunes: configuración y calendarios de uso.
* Configuración: canales, horas por defecto, anticipación de alarma, plantilla de
  instrucciones para el huésped.

## 7. Pruebas

* Huésped con token de la reserva A no puede leer la reserva B ni la propiedad de B
  (404), ni tras vencer su token (401).
* Fotos de DPI: solo `guests.documents` obtiene URL; el job de retención borra a los
  90 días y el registro queda `deleted` con el número conservado.
* Solapamiento de reservas y de parqueos rechazado por la BD.
* Reserva de área común respeta capacidad bajo concurrencia (dos peticiones simultáneas
  con capacidad 1: una falla).
* Alarma de check-out se programa en la zona del tenant y se dispara a seguridad.
* `security` no ve reservas fuera de hoy/activas ni documentos.

## 8. Criterios de aceptación

El admin importa el iCal de Booking, completa el huésped, este recibe correo y entra a
la app con su código, reserva la piscina, seguridad recibe la alarma a la hora de
check-out y la marca atendida; para una venta directa se registra el depósito, la
inspección de salida y la devolución, y las fotos del DPI desaparecen a los 90 días.
