# Fase 4 — Reservas, huéspedes, seguridad, parqueos y áreas comunes

> Estado: en curso. Parte de Persona A **hecha** (2026-11-22): migraciones `shared/0004_btree_gist`
> y `tenant/0006_reservations`, módulo `reservations` (canales, iCal, reservas, huéspedes,
> depósitos e inspecciones), trabajos `ical_sync`, `reservation_status`, `reservation_reminder` y
> `retention_cleanup`, correos al huésped y eventos `reservation.*`, con la web conectada (W-H1 a
> W-H6; W-I1 y W-I2 siguen simuladas hasta que exista la API de B). Contrato en §4.1. Pendiente
> (Persona B): `tenant/0007_guest_parking_areas`, acceso de huéspedes, seguridad, parqueos, áreas
> comunes y la app. Habilitada por la bandera `reservations` del tenant; `parking` y
> `shared_areas` tienen bandera propia.

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

### 4.1 Contrato implementado (Persona A, 2026-11-22)

Todo bajo `/api/v1`, con la bandera `reservations` (sin ella: 403 "Este módulo no está activo en tu
empresa."). Errores con el formato de siempre (`detail` y `errors[].location`/`message` en español).
Fechas `YYYY-MM-DD` en la zona del tenant; la salida es exclusiva (sale el 24 y otra entra el 24 sin
cruce). Horas `HH:MM`. Montos en la moneda del tenant. OpenAPI completo en `/docs`.

**Canales** (`reservations.read` para leer, `reservations.manage` para escribir)

* `GET /channels` → `ChannelRead[]`: `id, name, kind (direct|booking|airbnb|agency|other),
  requires_deposit, has_checkin, default_deposit_amount, is_active, feeds_count, upcoming_count`.
  El seed crea Directo (depósito y check-in), Booking.com y Airbnb (sin ninguno de los dos).
* `POST /channels` `{name, kind, requires_deposit, has_checkin, default_deposit_amount?}`;
  `PATCH /channels/{id}` (mismos campos y `is_active`). Nombre único sin distinguir mayúsculas (422).

**Calendarios iCal** (`reservations.manage`)

* `GET /ical-feeds` (todos) y `GET /properties/{id}/ical-feeds` → `FeedRead`: `id, property_id,
  property_code, property_name, channel_id, channel_name, channel_kind, url, is_active,
  last_synced_at, last_success_at, last_error, events_count`.
* `POST /properties/{id}/ical-feeds` `{channel_id, url}` (uno por propiedad y canal: 422),
  `PATCH /ical-feeds/{id}` `{url?, is_active?}`, `DELETE /ical-feeds/{id}` (las reservas importadas
  se quedan).
* `POST /ical-feeds/sync` (todas) y `POST /ical-feeds/{id}/sync` → `SyncResult[]`: `feed_id,
  property_code, channel_name, ok, error, events, created, updated, cancelled, conflicts`.
* URL solo `https` y a IP pública (el fetcher valida cada IP resuelta y cada redirección: sin SSRF);
  en el entorno local se aceptan `http` e IP privadas para los calendarios de prueba
  `GET /dev/ical/{archivo}` que sirve la API (no existe fuera de local).
* `last_error` va en palabras: "El canal respondió 404.", "No es un calendario iCal.", y los
  cruces: "No se importaron eventos que se cruzan con reservas de ARGOS: …".

**Reservas** (`reservations.read` con alcance; escribir con `reservations.manage`)

* `GET /reservations?from&to&property_id&channel_id&guest_id&status&incomplete&q&order&cursor&limit`
  → `{items: ReservationRead[], next_cursor}`. `ReservationRead`: `id, code (ARG-XXXXXX),
  property_id/code/name, channel_id/name/kind, requires_deposit, has_checkin, source
  (manual|ical|api), external_ref, external_summary, primary_guest_id, guest_name, guest_email,
  guests_count, guests_pending, status (pending|confirmed|checked_in|checked_out|cancelled|no_show),
  incomplete, check_in_date, check_out_date, check_in_time, check_out_time, nights, checked_in_at,
  checked_out_at, adults, children, total_amount, currency, deposit_amount, deposit_status
  (none|pending|received|returned|retained_partial|retained_full), notes, cancelled_at,
  cancel_reason, created_at, updated_at`.
* `GET /reservations/today` → `{available, arrivals, departures, in_house, incomplete,
  checkin_time}` (lo usa el Inicio). `GET /reservations/{id}` → `ReservationDetail` = lo anterior más
  `guests[]` (con `documents[]` si hay `guests.read`), `deposit`, `inspections[]` y `events[]`
  (línea de tiempo).
* `POST /reservations` `{property_id, channel_id, check_in_date, check_out_date, check_in_time?,
  check_out_time?, adults, children, total_amount?, deposit_amount?, primary_guest_id? | guest?
  (GuestCreate), notes?, send_email}` → `ReservationDetail` 201. Con huésped queda `confirmed` (y
  manda el correo si `send_email`); sin él, `pending`. Sin `deposit_amount`, toma el del canal si
  pide depósito.
* `PATCH /reservations/{id}` (fechas, horas, canal, personas, montos, notas). Cambiar fechas de una
  importada las marca como manuales: el iCal ya no las mueve.
* `POST /reservations/{id}/confirm` `{send_email}` (exige huésped principal: 422),
  `/cancel` y `/no-show` `{reason}` (motivo obligatorio), `/check-in` y `/check-out`
  (`reservations.checkin`), `/resend` (reenvía la confirmación; 422 sin correo).
* Cruce de fechas: lo rechaza la BD (`EXCLUDE` con `btree_gist`) y la API responde 422 con
  `errors[0].location = "body.check_in_date"` y "Se cruza con ARG-… de Nombre (5 dic al 8 dic)."
* Check-in en canales con `has_checkin`: todos los huéspedes registrados (documento y las dos
  fotos) y, si hay depósito, recibido. En canales sin check-in formal, entrada y salida pasan solas
  a su hora (trabajo `reservation_status`).

**Huéspedes**

* `GET /guests?q&blacklisted&cursor&limit` y `GET /guests/{id}` (`guests.read`) → `GuestRead`:
  `id, full_name, email, phone, document_type (dpi|passport), document_number, nationality, notes,
  blacklisted, blacklist_reason, stays, last_stay, next_stay, created_at, updated_at`; la ficha suma
  `documents[]` y `reservations[]`.
* `POST /guests` (`guests.manage`) y `PATCH /guests/{id}` (`guests.manage` o
  `reservations.checkin`; la lista negra solo con `guests.manage`: 403). Documento repetido:
  `POST /guests` responde 422 ("Ya hay un huésped con ese documento."); el `guest` que viene dentro de
  una reserva reutiliza al huésped existente (no se duplica). DPI: 13 dígitos; pasaporte: 5 a 20
  alfanuméricos.
* `POST /reservations/{id}/guests` `{guest_id? | guest?, is_primary}` y
  `DELETE /reservations/{id}/guests/{guest_id}` (`guests.manage` o `reservations.checkin`). Un
  huésped en lista negra no se puede agregar (422).
* Fotos del documento: se suben con `POST /files/uploads` (módulo `guests`, tipos `id_front` e
  `id_back`, permiso `reservations.checkin`) y se ligan con `POST /guests/{id}/documents`
  `{kind, file_id}` (reemplaza la anterior del mismo lado). Para verlas:
  `GET /guests/{id}/documents/{file_id}/url` (`guests.documents`) → `{url, expires_at}`, que queda en
  la bitácora como `guest.document_viewed`. `GET /files/{id}/url` las rechaza. Vencen 90 días después
  de la última salida y `retention_cleanup` las borra de S3 (el número de documento se queda).

**Depósito** (`deposits.read` / `deposits.manage`)

* `GET /reservations/{id}/deposit` → `{available, amount, status, received, returned, retained,
  balance, charges, inspection_required, transactions[]}` (`charges` = costo de los hallazgos con
  cargo al depósito).
* `POST /reservations/{id}/deposit/transactions` `{type (received|returned|retained), amount, method
  (cash|card|transfer|other), reference?, notes?}`. Recibir hasta el monto; devolver o retener solo
  con la inspección `post_departure`; retener solo si hay hallazgos con cargo al depósito y hasta su
  costo; con cargos, primero se retiene y luego se devuelve el resto. El estado se recalcula de los
  movimientos y cada uno manda correo al huésped.

**Inspecciones** (`tasks.validate`)

* `POST /reservations/{id}/inspections` `{kind (pre_arrival|post_departure), notes?, task_id?,
  photo_file_ids[]}`: una por tipo; `pre_arrival` antes del check-in y `post_departure` después del
  check-out. Fotos con `POST /files/uploads` (módulo `reservations`, tipo `inspection_photo`).
* `POST /inspections/{id}/findings` `{area, description, severity (low|medium|high),
  estimated_cost?, charge_to_deposit, photo_file_ids[], create_ticket}`: con `create_ticket` abre la
  incidencia en Mantenimiento (`ticket_id` y `ticket_number` en la respuesta).
  `DELETE /inspections/{id}/findings/{finding_id}` (no si el depósito ya se liquidó).

**Visibilidad**

* Alcance por propiedad como en el resto (404 fuera de alcance).
* Seguridad (`security.dashboard` sin `reservations.manage` ni `reservations.checkin`): solo
  reservas con entrada o salida hoy y las que están en casa.
* Correo, teléfono y documentos del huésped solo con `guests.read`; URL de las fotos solo con
  `guests.documents`.

**Eventos** (`events.Bus`, síncronos dentro de la transacción; `Data` es
`reservations.ReservationEvent{Reservation ReservationRead, Previous *ReservationRead}`)

* `reservation.confirmed`, `reservation.updated` (con `Previous`), `reservation.cancelled` (también
  `no_show`), `reservation.checked_in`, `reservation.checked_out`.

**Enganches para B**

* `reservations.Service.SetGuestAccess(fn GuestAccessIssuer)`: se llama al confirmar (y al reenviar),
  dentro de la transacción, y devuelve `AccessInfo{Link, Code}` que va en el correo
  (`argos://guest?token=…` y el código). Sin él, el correo sale sin enlace ni código.
* Tarea de limpieza: suscribirse a `reservation.confirmed` (crear la tarea `cleaning` del día de
  salida con `reservation_id`), a `reservation.updated` (moverla si cambió la salida) y a
  `reservation.cancelled` (cancelarla).
* Alarmas de seguridad: programar `security_alarms` con `reservation.confirmed` y
  `reservation.updated`; cancelarlas con `reservation.cancelled` y `reservation.checked_out`.
* `inspections.task_id` y `tasks.reservation_id` ya tienen FK si la tabla `tasks` existe (la
  migración las agrega condicionalmente).
* `maintenance_tickets.reported_by_guest_id` ya apunta a `guests` para `POST /guest/tickets`.

**Trabajos y correos**

* `ical_sync` cada 30 min y `reservation_status` cada hora, por empresa con la bandera
  `reservations`. `reservation_reminder` se programa al confirmar para la víspera a las 18:00 de la
  zona del tenant (dedupe por reserva y fecha). `retention_cleanup` cada hora, de plataforma.
* Plantillas `reservation_confirmed`, `reservation_reminder`, `reservation_cancelled` y
  `deposit_update`. Las instrucciones del tenant aceptan `{{huesped}}`, `{{propiedad}}`,
  `{{fecha_entrada}}` y `{{hora_entrada}}`.

**`POST /public/reservations`** (solo contrato; la clave API llega en fase 6): mismo cuerpo que
`POST /reservations` más `external_ref` (obligatorio y único por propiedad; la BD ya tiene el índice
`(property_id, external_ref)`), y la reserva queda con `source = "api"`. Respuesta `ReservationRead`
201; un reintento con el mismo `external_ref` devuelve la existente con 200 sin duplicar; 422 si se
cruza.

**Diferencias con el plan**

* El documento del huésped es opcional al crear (se exige en el registro del check-in).
* Columnas de más: `guests.blacklist_reason`, `reservations.manual_fields` (en lugar de
  `synced_fields` en eventos) y `reservations.external_summary` (lo que trae el iCal).
* Una inspección por tipo por reserva; un solo paquete `reservations` (canales, huéspedes,
  depósitos e inspecciones juntos).
* Estados automáticos en canales sin check-in formal; los trabajos corren cada hora como en fase 3.
* El iCal se lee con un parser propio (`internal/core/ical`), sin dependencia nueva.
* `btree_gist` va en `shared/0004_btree_gist`; la facturación de fase 6 pasa a `shared/0005_billing`.

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
