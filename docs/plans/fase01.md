# Fase 1 — Fundaciones: identidad, tenants, roles y permisos

> Estado: pendiente. Registrar avances y decisiones en [avance.md](avance.md).

## 1. Objetivo

Dejar el sistema con una base de seguridad completa y probada antes de construir
cualquier módulo de negocio:

* Multi-tenant por schema con migraciones separadas para `shared` y para tenants.
* Usuarios con membresías en varios tenants, roles por tenant y catálogo de permisos.
* Autenticación completa: login, refresh rotativo, biometría en app, 2FA opcional,
  invitaciones, recuperación de contraseña, sesiones por dispositivo.
* Almacenamiento S3 con prefijo por tenant y URLs prefirmadas.
* Cola de trabajos sobre PostgreSQL y correo por SES (necesarios para invitaciones).
* Pruebas automáticas de aislamiento entre tenants y entre roles.
* App y web con login real contra el backend.

Fuera de esta fase: cualquier tabla de negocio (propiedades, tareas, etc.).

## 2. Decisiones técnicas de la fase

| Tema | Decisión |
| --- | --- |
| Aislamiento BD | Schema por tenant. `SET LOCAL search_path` por transacción (no `SET` de sesión). |
| Modelos y SQL | Sin ORM: structs con tags `db` y SQL explícito (pgx). Tablas globales siempre calificadas (`shared.users`); tablas de tenant **sin schema** (se resuelven por `search_path`). |
| Migraciones | Dos conjuntos SQL embebidos en el binario: `migrations/shared` y `migrations/tenant`, cada schema con su tabla `schema_migrations`. Se escriben a mano (no hay autogeneración, por eso no hace falta un schema `tenant_template`). Ya implementado. |
| Permisos | Enum en código (`Permission`). Roles en BD (`shared.roles`) con `role_permissions`. |
| Token | JWT HS256. Access 15 min con claims `sub`, `tid` (tenant), `mid` (membership), `rk` (role key), `pv` (permissions version). Refresh opaco (random 256 bits), guardado hasheado (SHA-256), rotativo. |
| Resolución de permisos | En cada petición: se cargan de BD los permisos del rol (cache en memoria por proceso, TTL 60 s, invalidado por `pv`). |
| Huéspedes | No usan `shared.users`. Tienen token propio con claim `typ=guest` (fase 4). El middleware de esta fase ya contempla el tipo. |
| Cola de trabajos | Tabla `shared.jobs` + worker con `SELECT ... FOR UPDATE SKIP LOCKED`. Sin Redis. |
| Correo | Amazon SES vía AWS SDK for Go v2 (`sesv2`). Plantillas `html/template` embebidas en `internal/core/mail/templates`. |
| Archivos | Amazon S3 vía AWS SDK for Go v2 (`s3` y `s3.PresignClient`). Un bucket por ambiente. En local: LocalStack o MinIO en docker-compose (solo desarrollo). |
| 2FA | TOTP (`github.com/pquerna/otp`), secreto cifrado con clave `ARGOS_FIELD_ENCRYPTION_KEY` (AES-256-GCM). |
| Cifrado de campos | Tipo `EncryptedString` en `internal/core/security` (implementa `sql.Scanner` y `driver.Valuer`, AES-256-GCM de la biblioteca estándar) para totp_secret y, en fase 2, información de acceso a propiedades. |

## 3. Backend

### 3.1 Migraciones `shared` y `tenant`

**Ya implementado** en la migración del backend a Go (2026-10-22); esta fase solo agrega
archivos. Detalle del formato y reglas en `BACKEND/migrations/README.md`.

```
BACKEND/migrations/
├── migrations.go                 # embebe shared/ y tenant/ en el binario
├── shared/
│   ├── 0001_initial.sql          (existente; adopta sin cambios la BD creada por Alembic)
│   └── 0002_identity.sql | .go   (esta fase, ver 3.4)
└── tenant/
    └── 0001_tenant_base.sql      (esta fase)
```

* Motor en `internal/core/migrate`: cada schema guarda sus versiones en su propia tabla
  `"<schema>".schema_migrations`; las migraciones de tenant se escriben sin schema y el
  motor fija `search_path` al schema del tenant seguido de `shared`.
* Cada schema se migra en una transacción, con bloqueo consultivo para que dos procesos
  no migren el mismo schema a la vez.
* `migrate tenant` recorre todos los tenants de `shared.tenants` (activos o no, para que
  ningún schema quede desfasado al reactivarlo) o uno con `-tenant <slug>`.

Comandos oficiales (ya documentados en el README del backend):

```bash
argos migrate up                              # shared y después todos los tenants
argos migrate shared up|down|status
argos migrate tenant up|status                # todos los tenants
argos migrate tenant up -tenant garrent       # un solo tenant
argos migrate tenant down -tenant <slug|all>  # down exige -tenant explícito
```

Reglas:

* Orden de despliegue: `shared` primero, luego `tenant` (`argos migrate up` lo hace).
* La API ya se niega a arrancar si `shared` tiene migraciones pendientes. Falta en esta
  fase: el mismo chequeo en el worker, y que un tenant con migraciones pendientes se
  marque `is_active=false` temporalmente y se registre en log (nunca se opera con un
  schema desfasado).
* CI: las pruebas de integración aplican `shared` en una BD vacía (Testcontainers). Esta
  fase agrega una prueba que aplica también `tenant`, crea dos tenants y revierte con
  `down`. No hay autogeneración, así que no existe la detección de drift entre modelos y
  migraciones.

### 3.2 Alta de tenant (provisioning)

`tenants.Service.CreateTenant` ya ejecuta los pasos 1 a 3 en **una sola transacción**
(si algo falla no queda ni el registro ni el schema). Esta fase agrega los pasos 4 a 6
dentro de la misma transacción:

1. Insertar `shared.tenants`.
2. `CREATE SCHEMA "tenant_<slug>"` (falla si ya existe: nunca se adopta un schema previo).
3. Aplicar las migraciones de tenant a ese schema (`migrate.Set.Up` con la misma
   transacción).
4. Sembrar roles por defecto (`shared.roles` + `shared.role_permissions`) para el tenant
   a partir de la matriz del PRD sección 3.4.
5. Crear la membresía `admin` para el usuario indicado (existente o invitado por correo).
6. Registrar en `shared.platform_audit_log`.

### 3.3 Modelo de datos: schema `shared`

Convenciones para todas las tablas del proyecto:

* `id UUID PK DEFAULT gen_random_uuid()`, `created_at`, `updated_at` (timestamptz,
  `now()`), declaradas en cada migración (no hay ORM).
* Nombres en inglés, snake_case, plural.
* Borrado lógico solo donde se indique (`deleted_at`).
* Enumeraciones como `VARCHAR` con `CHECK` (no tipos ENUM de Postgres, para simplificar
  migraciones).

#### `shared.tenants` (modificar)

| Columna | Tipo | Notas |
| --- | --- | --- |
| slug | varchar(63) unique | existente |
| name | varchar(255) | existente |
| schema_name | varchar(63) unique | existente |
| is_active | bool | existente |
| timezone | varchar(64) not null default 'America/Guatemala' | nuevo |
| currency | char(3) not null default 'GTQ' | nuevo |
| logo_key | varchar(512) null | clave S3, nuevo |
| features | jsonb not null default '{}' | banderas: `parking`, `shared_areas`, `reservations`, `payroll`, `guest_chat`, `smart_locks` |
| settings | jsonb not null default '{}' | otras configuraciones (horas de alarma, etc.) |
| require_2fa_roles | jsonb not null default '[]' | lista de role keys que exigen TOTP |

#### `shared.users` (modificar)

| Columna | Tipo | Notas |
| --- | --- | --- |
| email | varchar(320) unique (citext o lower index) | existente |
| hashed_password | varchar(255) null | pasa a nullable: un invitado aún no tiene contraseña |
| full_name | varchar(255) | existente |
| phone | varchar(32) null | nuevo |
| is_active | bool | existente |
| is_platform_admin | bool default false | nuevo; sustituye a `role = platform_admin` |
| totp_secret | varchar(255) null | cifrado (AES-256-GCM, ver §2) |
| totp_enabled | bool default false | |
| password_changed_at | timestamptz null | |
| last_login_at | timestamptz null | |
| ~~role~~, ~~tenant_id~~, ~~is_owner~~ | | **se eliminan** tras migrar datos a `memberships` |

#### `shared.roles` (nueva)

| Columna | Tipo | Notas |
| --- | --- | --- |
| tenant_id | uuid FK tenants ON DELETE CASCADE | |
| key | varchar(64) | `admin`, `supervisor`, `cleaner`, `maintenance`, `security`, `owner`, `guest` o personalizado |
| name | varchar(128) | |
| description | text null | |
| is_system | bool | true para los siete por defecto; no se pueden borrar |
| permissions_version | int default 1 | se incrementa en cada cambio; viaja en el JWT (`pv`) |

Restricciones: `UNIQUE (tenant_id, key)`. Índice en `tenant_id`.

#### `shared.role_permissions` (nueva)

| Columna | Tipo |
| --- | --- |
| role_id | uuid FK roles ON DELETE CASCADE |
| permission | varchar(64) |

PK compuesta `(role_id, permission)`. `CHECK` no aplica; la validación contra el enum
se hace en el service.

#### `shared.memberships` (nueva)

| Columna | Tipo | Notas |
| --- | --- | --- |
| user_id | uuid FK users ON DELETE CASCADE | |
| tenant_id | uuid FK tenants ON DELETE CASCADE | |
| role_id | uuid FK roles ON DELETE RESTRICT | |
| status | varchar(16) CHECK IN ('invited','active','suspended') | |
| invited_by | uuid FK users null | |
| joined_at | timestamptz null | |

Restricciones: `UNIQUE (user_id, tenant_id)`; `CHECK` en service de que `role.tenant_id
= tenant_id`. Índices en `tenant_id` y `user_id`.

#### `shared.refresh_tokens` (nueva)

| Columna | Tipo | Notas |
| --- | --- | --- |
| user_id | uuid FK users ON DELETE CASCADE | |
| tenant_id | uuid FK tenants ON DELETE CASCADE null | empresa activa de la sesión (null = modo plataforma); la usa `/auth/refresh` para emitir el access token del mismo tenant |
| token_hash | char(64) unique | SHA-256 del token opaco |
| family_id | uuid | para detectar reutilización tras rotación |
| device_id | varchar(128) | generado por el cliente y persistido |
| device_name | varchar(128) null | "iPhone de Ana" |
| platform | varchar(16) CHECK IN ('android','ios','web') | |
| expires_at | timestamptz | 60 días |
| revoked_at | timestamptz null | |
| last_used_at | timestamptz null | |
| ip | inet null | |

Índices: `user_id`, `(family_id)`.

#### `shared.one_time_tokens` (nueva)

| Columna | Tipo | Notas |
| --- | --- | --- |
| user_id | uuid FK users ON DELETE CASCADE null | null en invitaciones a correos sin usuario |
| purpose | varchar(32) CHECK IN ('password_reset','invitation','email_verify','magic_login') | |
| token_hash | char(64) unique | |
| payload | jsonb default '{}' | ej. tenant_id y role_id de la invitación |
| expires_at | timestamptz | reset 1 h; invitación 7 días |
| used_at | timestamptz null | |

#### `shared.invitations` (nueva)

| Columna | Tipo | Notas |
| --- | --- | --- |
| tenant_id | uuid FK tenants ON DELETE CASCADE | |
| email | varchar(320) | |
| role_id | uuid FK roles | |
| invited_by | uuid FK users | |
| token_id | uuid FK one_time_tokens | |
| status | varchar(16) CHECK IN ('pending','accepted','expired','revoked') | |
| accepted_at | timestamptz null | |

`UNIQUE (tenant_id, email) WHERE status = 'pending'` (índice parcial).

#### `shared.device_tokens` (nueva; usada por push en fase 3)

| Columna | Tipo |
| --- | --- |
| user_id | uuid FK users ON DELETE CASCADE |
| fcm_token | varchar(512) unique |
| platform | varchar(16) |
| last_seen_at | timestamptz |

#### `shared.jobs` (nueva)

| Columna | Tipo | Notas |
| --- | --- | --- |
| tenant_id | uuid FK tenants null | null = trabajo de plataforma |
| type | varchar(64) | `send_email`, `send_push`, `ical_sync`, `retention_cleanup`, ... |
| payload | jsonb | |
| status | varchar(16) CHECK IN ('pending','running','done','failed','cancelled') | |
| scheduled_at | timestamptz default now() | permite programar recordatorios |
| attempts | int default 0 | |
| max_attempts | int default 5 | |
| locked_at | timestamptz null | |
| locked_by | varchar(64) null | id del worker |
| last_error | text null | |
| finished_at | timestamptz null | |
| dedupe_key | varchar(128) null | `UNIQUE WHERE status IN ('pending','running')` para no duplicar recordatorios |

Índice `(status, scheduled_at)`. El worker toma trabajos con:

```sql
UPDATE shared.jobs SET status='running', locked_at=now(), locked_by=:w, attempts=attempts+1
WHERE id = (SELECT id FROM shared.jobs WHERE status='pending' AND scheduled_at <= now()
            ORDER BY scheduled_at FOR UPDATE SKIP LOCKED LIMIT 1)
RETURNING *;
```

Reintentos con backoff exponencial (1, 2, 4, 8, 16 min). Trabajos con `tenant_id` se
ejecutan con el `search_path` de ese tenant. Tras 15 min en `running` sin terminar se
consideran huérfanos y vuelven a `pending`.

#### `shared.platform_audit_log` (nueva)

| Columna | Tipo |
| --- | --- |
| actor_user_id | uuid FK users null |
| tenant_id | uuid null |
| action | varchar(64) |
| entity | varchar(64) |
| entity_id | uuid null |
| metadata | jsonb |
| ip | inet null |
| created_at | timestamptz |

Sin `updated_at`. Solo inserciones (revocar permisos UPDATE/DELETE al usuario de la app
sobre esta tabla mediante un `GRANT` en la migración).

### 3.4 Migración `shared/0002_identity`

Pasos en `upgrade()`, en este orden:

1. Alterar `tenants`: agregar `timezone`, `currency`, `logo_key`, `features`, `settings`,
   `require_2fa_roles`.
2. Alterar `users`: agregar `phone`, `is_platform_admin`, `totp_secret`, `totp_enabled`,
   `password_changed_at`, `last_login_at`; hacer `hashed_password` nullable.
3. Crear `roles`, `role_permissions`, `memberships`, `refresh_tokens`,
   `one_time_tokens`, `invitations`, `device_tokens`, `jobs`, `platform_audit_log`.
4. **Migración de datos** (dentro de la misma revisión):
   * `UPDATE shared.users SET is_platform_admin = true WHERE role = 'platform_admin'`.
   * Por cada tenant existente: insertar los siete roles por defecto con sus permisos.
     La matriz vive solo en `internal/modules/authz/default_roles.go`; para no duplicarla
     en SQL, `0002_identity` se escribe como migración Go. El motor hoy solo lee `.sql`:
     en esta fase se le agrega el registro de migraciones Go (versión + función que recibe
     la transacción), aplicadas en el mismo orden y con la misma tabla de versiones.
   * Por cada usuario con `tenant_id`: insertar membresía con el rol cuyo `key` coincide
     con `users.role` (`employee` → `cleaner`), `status='active'`, `joined_at=created_at`.
5. Eliminar columnas `users.role`, `users.tenant_id`, `users.is_owner` y su índice.

La sección down invierte los pasos y reconstruye `role`/`tenant_id` a partir de la primera
membresía activa (documentar que es una reversión con pérdida si había varias).

### 3.5 Modelo de datos: schema de tenant (migración `tenant/0001_tenant_base`)

Solo dos tablas transversales; el resto llega en fases posteriores.

#### `files`

| Columna | Tipo | Notas |
| --- | --- | --- |
| s3_key | varchar(512) unique | siempre con prefijo `tenants/{tenant_id}/` |
| module | varchar(32) | `tasks`, `maintenance`, `guests`, `hr`, `chat`, `tenant` |
| kind | varchar(32) | `before`, `after`, `evidence`, `damage`, `id_front`, `id_back`, `document`, `avatar`, `attachment` |
| entity_type | varchar(64) null | tabla lógica a la que pertenece |
| entity_id | uuid null | |
| content_type | varchar(128) | |
| size_bytes | bigint | |
| sha256 | char(64) null | |
| uploaded_by_user_id | uuid FK shared.users null | |
| uploaded_by_guest_id | uuid null | fase 4 |
| status | varchar(16) CHECK IN ('pending','ready','deleted') | `pending` hasta confirmar la subida |
| expires_at | timestamptz null | retención automática (fase 4 la usa para DPI) |
| deleted_at | timestamptz null | |

Índices: `(entity_type, entity_id)`, `(expires_at) WHERE expires_at IS NOT NULL`.

#### `audit_log`

| Columna | Tipo |
| --- | --- |
| actor_user_id | uuid FK shared.users null |
| actor_guest_id | uuid null |
| action | varchar(64) |
| entity | varchar(64) |
| entity_id | uuid null |
| property_id | uuid null (índice; se llena cuando aplica para filtrar) |
| before | jsonb null |
| after | jsonb null |
| ip | inet null |
| user_agent | varchar(256) null |
| created_at | timestamptz |

Solo inserciones. Índices en `created_at`, `(entity, entity_id)`, `actor_user_id`,
`property_id`.

### 3.6 Módulo `authz` (nuevo) y cambios en `auth`

```
internal/modules/authz/
├── permissions.go     # type Permission string + constantes con todo el catálogo del PRD 3.3
├── default_roles.go   # DefaultRoles: map[string][]Permission = matriz PRD 3.4
├── model.go           # Role, RolePermission, Membership
├── repository.go
├── service.go         # crear/editar roles, sembrar defaults, resolver permisos con cache
├── schemas.go
└── errors.go
```

`internal/api/dependencies.go` (`Guard`):

* Transacciones: ya resuelto. `database.InTx` hace `SET LOCAL search_path` en cada
  transacción con el schema que el middleware deja en el contexto
  (`database.WithTenantSchema`); sin tenant, solo `"shared"`.
* `Authenticated` pasa a resolver el principal: valida JWT, distingue `typ` (`user` |
  `guest`), carga usuario y membresía, verifica `status='active'`, verifica
  `tenant.is_active`, marca el contexto con el schema del tenant, resuelve permisos del
  rol y deja en el contexto `Principal{User, Tenant, Membership, RoleKey, Permissions}`
  (hoy deja solo el usuario).
* `RequirePermission(perms...)`: middleware; 403 si falta alguno. Se elimina
  `RequireRole` junto con `auth/roles.go` y `HasAtLeast`.
* `RequirePlatformAdmin`.
* `ScopeResolver`: helper inyectable que expone `property_ids_for(principal)` y similares
  (se completa en fase 2). Los repositorios de negocio reciben el scope y filtran siempre.

Reglas de código obligatorias (añadir a `BACKEND/docs/ARCHITECTURE.md`):

* Todo endpoint bajo `/api/v1` excepto `auth/*`, `health` y `public/*` declara
  `Middlewares: guard.RequirePermission(...)` (o su grupo lo aplica con `UseMiddleware`).
* Todo repositorio de tenant recibe `scope` y lo aplica en `WHERE`; un `GetByID` fuera
  del scope devuelve `nil` (el endpoint responde 404).
* Está prohibido construir claves S3 fuera de `storage.Service.BuildKey(tenantID, ...)`.

### 3.7 Autenticación: endpoints

| Método y ruta | Descripción |
| --- | --- |
| `POST /auth/login` | email + password (+ `totp_code` si aplica) + `device`. Devuelve `memberships[]` y, si solo hay una, `access_token` + `refresh_token`. Si hay varias, `selection_token` (5 min). |
| `POST /auth/select-tenant` | `selection_token` o refresh válido + `tenant_id` → `access_token` + `refresh_token`. |
| `POST /auth/refresh` | rota el refresh; si se presenta uno ya rotado de la misma `family_id`, revoca toda la familia. |
| `POST /auth/logout` | revoca el refresh actual. |
| `GET /auth/me` | usuario, tenant activo, rol, permisos, banderas del tenant. |
| `GET/DELETE /auth/sessions` | lista y revoca dispositivos. |
| `POST /auth/password/forgot` y `/reset` | token de un solo uso por correo. |
| `POST /auth/password/change` | requiere contraseña actual; revoca las demás sesiones. |
| `POST /auth/totp/setup`, `/confirm`, `/disable` | 2FA. |
| `POST /auth/invitations/accept` | token → crea contraseña (si no existía) y activa membresía. |
| `POST /tenants/{id}/invitations` | `users.manage`. Envía correo con enlace. |
| `GET/POST/PATCH/DELETE /tenants/{id}/roles` | `roles.manage`. Al editar, `permissions_version += 1`. |
| `GET/PATCH /tenants/{id}/members`, `PATCH .../members/{id}/role`, `.../suspend` | `users.manage`. |
| `GET/PATCH /tenants/{id}/settings` | `tenant.settings`. |
| `POST /files/presign-upload`, `POST /files/{id}/confirm`, `GET /files/{id}/url` | ver 3.8. |
| `POST /platform/tenants`, `GET /platform/tenants`, `PATCH .../{id}` | `RequirePlatformAdmin`. |

Si un usuario tiene `is_platform_admin` y además membresías, el login lo trata como
usuario normal; el modo plataforma se activa con `POST /auth/select-tenant`
enviando `platform: true`.

Tiempos: access 15 min, refresh 60 días (móvil) / 30 días (web), selección 5 min.
Bloqueo por fuerza bruta: 10 intentos fallidos en 15 min por correo+IP → 429.

#### 3.7.1 Contrato JSON de autenticación

Lo que la app consume desde la fase 1; la app lo implementa contra un mock HTTP
(`--dart-define=ARGOS_MOCK=true`) hasta que el backend esté en `main`. Si el backend
cambia algo, se actualiza esta sección en el mismo PR.

Convenciones:

* JSON en snake_case; fechas ISO 8601 en UTC.
* Errores en RFC 9457 (`application/problem+json`), como el backend actual: mensaje
  para el usuario en `detail`; en 422, cada campo en `errors[]` con `location`.
* `device` = `{"id": "<uuid generado y guardado por el cliente>", "name": "Pixel 7",
  "platform": "android" | "ios" | "web"}`.
* El access token lleva además el claim `sid` (id de la sesión, la familia del refresh)
  para marcar la sesión actual en `/auth/sessions`.
* En endpoints autenticados, 401 significa siempre "token inválido o vencido": la app
  renueva el token una vez y reintenta. Los errores de negocio usan 403, 404 o 422.

**Respuesta de sesión** (login, select-tenant, aceptar invitación):

```json
{
  "status": "authenticated",
  "access_token": "…",
  "refresh_token": "…",
  "expires_in": 900,
  "memberships": [
    {"tenant_id": "…", "tenant_name": "Garrent", "tenant_logo_url": null,
     "role_key": "cleaner", "role_name": "Colaborador de limpieza"}
  ]
}
```

Con varias membresías activas: `"status": "select_tenant"`, `"selection_token"` (5 min)
y `memberships`, sin tokens.

| Endpoint | Cuerpo | Respuestas |
| --- | --- | --- |
| `POST /auth/login` | `email`, `password`, `totp_code` (opcional), `device` | 200 respuesta de sesión · 401 credenciales incorrectas o código TOTP incorrecto · 403 cuenta sin membresías activas · 428 falta el código TOTP · 429 bloqueo, con header `Retry-After` en segundos |
| `POST /auth/select-tenant` | `tenant_id` y además `selection_token` + `device` (tras el login) o `refresh_token` (cambio de empresa con sesión abierta) | 200 respuesta de sesión · 401 token vencido · 404 sin membresía en ese tenant |
| `POST /auth/refresh` | `refresh_token`, `device_id` | 200 `{access_token, refresh_token, expires_in}` · 401 vencido, revocado o reutilizado |
| `POST /auth/logout` | `refresh_token` | 204, también si ya estaba revocado |
| `GET /auth/me` | — | 200, ver abajo |
| `GET /auth/sessions` | — | 200 `[{id, device_name, platform, last_used_at, created_at, current}]` |
| `DELETE /auth/sessions/{id}` | — | 204 · 404 si no es una sesión del usuario |
| `DELETE /auth/sessions` | — | 204; revoca todas menos la actual |
| `POST /auth/password/forgot` | `email` | 202 siempre (no revela si el correo existe) |
| `POST /auth/password/change` | `current_password`, `new_password` | 204 · 422 contraseña actual incorrecta o nueva inválida |
| `GET /auth/invitations/{token}` | — | 200 `{tenant_name, role_name, email, user_exists}` · 404 vencida, usada o revocada |
| `POST /auth/invitations/accept` | `token`, `password` (la actual si `user_exists`, la nueva si no), `full_name` (solo si no existe), `device` | Igual que el login |

`GET /auth/me` (en modo plataforma `tenant` y `role` son `null`, y `user.is_platform_admin`
es `true`):

```json
{
  "user": {"id": "…", "email": "ana@garrent.gt", "full_name": "Ana López", "totp_enabled": false},
  "tenant": {"id": "…", "name": "Garrent", "logo_url": null, "timezone": "America/Guatemala",
             "currency": "GTQ", "features": {"reservations": true, "parking": false,
             "shared_areas": true, "guest_chat": false}},
  "role": {"key": "cleaner", "name": "Colaborador de limpieza"},
  "permissions": ["tasks.read", "tasks.execute", "inventory.read"],
  "memberships": [{"tenant_id": "…", "tenant_name": "Garrent", "tenant_logo_url": null,
                   "role_key": "cleaner", "role_name": "Colaborador de limpieza"}]
}
```

### 3.8 Servicio de archivos (S3)

`internal/core/storage` → `storage.Service`:

* `BuildKey(tenantID, module, kind, filename) -> "tenants/{tenant_id}/{module}/{yyyy}/{mm}/{uuid}.{ext}"`.
* `PresignUpload(ctx, key, contentType, maxBytes)`: POST prefirmado con condición de
  tamaño y content-type; 15 min.
* `PresignDownload(ctx, key)`: 5 min.
* `Delete(ctx, key)`.
* `AssertTenantKey(key, tenantID)`: devuelve error si el prefijo no coincide. Se llama
  antes de firmar cualquier descarga.

Flujo de subida: el cliente pide `presign-upload` con `module`, `kind`, `entity`,
`content_type`, `size` → el backend valida permiso sobre la entidad, crea `files`
en `pending` y devuelve la URL → el cliente sube → `confirm` verifica con `HEAD` que el
objeto existe y marca `ready`. Los `pending` de más de 24 h se borran (job
`storage_cleanup`).

Política IAM del backend: solo `s3:PutObject`, `GetObject`, `DeleteObject`, `HeadObject`
sobre `arn:aws:s3:::<bucket>/tenants/*`. Bucket privado, sin ACLs, cifrado SSE-S3,
versionado desactivado, regla de ciclo de vida para abortar multipart huérfanos.

### 3.9 Cola de trabajos y correo

* `internal/core/jobs`: `Enqueue(ctx, q, Job{Type, Payload, TenantID, ScheduledAt,
  DedupeKey})` (recibe la transacción del servicio, así el trabajo se encola junto con el
  cambio que lo origina), registro de handlers y worker (subcomando `argos worker` en
  `cmd/argos/worker.go`, concurrencia configurable con goroutines, polling 1 s con
  `LISTEN jobs_new` para despertar).
* `internal/core/mail`: `mail.Service.Send(ctx, to, template, data)` con SES; en `local`
  y `testing` escribe el correo a log en lugar de enviarlo.
* Handlers de esta fase: `send_email`, `storage_cleanup`.
* Nuevas variables: `ARGOS_AWS_REGION`, `ARGOS_S3_BUCKET`, `ARGOS_S3_ENDPOINT_URL`
  (solo local), `ARGOS_SES_FROM`, `ARGOS_FIELD_ENCRYPTION_KEY`, `ARGOS_APP_BASE_URL`,
  `ARGOS_WEB_BASE_URL`, `ARGOS_WORKER_CONCURRENCY`. Credenciales AWS por el mecanismo
  estándar del SDK (rol IAM en despliegue; variables en local).
* `docker-compose.yml`: agregar servicio `worker` (misma imagen, comando `argos worker`) y
  `localstack` (S3 + SES simulados) solo para desarrollo.

### 3.10 Pruebas obligatorias

Integración (Testcontainers), fixture que crea `tenant_a` y `tenant_b` con un admin y un
cleaner cada uno:

1. Un token de `tenant_a` no puede leer, listar ni modificar nada de `tenant_b` (404).
2. Un `cleaner` recibe 403 en todo endpoint que exija permisos que no tiene.
3. Editar un rol invalida los tokens anteriores en la siguiente petición (`pv`).
4. Refresh reutilizado revoca la familia completa.
5. `presign-download` de una clave con prefijo de otro tenant falla (404) aunque el
   `file_id` exista.
6. Migraciones: shared + tenant aplican en BD vacía y `down` revierte cada una.
7. Provisioning de tenant deja el schema en head y los siete roles sembrados.
8. Usuario con dos membresías recibe `selection_token` y puede cambiar de tenant; los
   datos vistos cambian con el tenant.
9. Cuenta suspendida o tenant inactivo → 401 en `/auth/me`.

### 3.11 Limpieza de código existente

* Eliminar `internal/modules/auth/roles.go`, `Guard.RequireRole` y todo uso de
  `Role`/`HasAtLeast`.
* `argos seed platform-admin` ya existe (`cmd/argos/seed.go`); agregar el subcomando
  `demo-tenant` (crea tenant demo con usuarios de cada rol).
* Actualizar `README.md` y `docs/ARCHITECTURE.md` del backend con las reglas de 3.6.

## 4. App móvil (Flutter)

### 4.1 Cambios estructurales

* **Eliminar el login local con MD5** (`core/utils/md5_hash.dart`,
  `auth_local_datasource` como verificador de contraseña). Drift deja de guardar
  contraseñas. La tabla `usuarios` se reemplaza por `session_cache` (usuario, tenant,
  rol, permisos, banderas) para arrancar sin red.
* Nuevo `AuthRemoteDataSource` (Dio) con los endpoints de 3.7.
* `AuthInterceptor`: agrega `Authorization`, y ante 401 intenta un único refresh
  (con mutex para no lanzar refresh en paralelo); si falla, cierra sesión.
* `SecureStorageService`: guarda `refresh_token`, `device_id` (generado una vez),
  `biometric_enabled`, `pin_hash` (argon2/bcrypt vía `flutter_bcrypt` o similar).
* Dependencias nuevas: `local_auth`, `uuid`, `connectivity_plus`, `package_info_plus`.

### 4.2 Flujo de sesión

1. Arranque: si hay refresh token → pedir biometría o PIN → `POST /auth/refresh` → a
   la pantalla principal del rol. Si no hay red y hay `session_cache`, entra en modo
   sin conexión (solo lectura; fase 2 define qué se ve).
2. Sin refresh token → pantalla de login (correo + contraseña, TOTP si el backend lo
   pide con `428`).
3. Varias membresías → pantalla de selección de empresa; se recuerda la última.
4. Tras login exitoso: ofrecer activar biometría o PIN (obligatorio elegir uno para
   "inicio rápido"; se puede omitir y usar contraseña siempre).
5. Cambiar de empresa desde el menú de perfil sin cerrar sesión.

### 4.3 Pantallas de la fase

* Login, TOTP, selección de empresa, configurar PIN/biometría, desbloqueo, recuperar
  contraseña (abre enlace web), aceptar invitación (deep link `argos://invite?token=`),
  perfil (datos, sesiones activas, cambiar contraseña, activar 2FA).
* Shell por rol: `GoRouter` con `ShellRoute` y pestañas definidas por rol; la lista de
  permisos del `session_cache` decide qué rutas existen. Una ruta sin permiso redirige a
  inicio.

### 4.4 Diseño de navegación por rol

| Rol | Pestañas |
| --- | --- |
| cleaner / maintenance | Hoy, Semana, Inventario, Alertas, Perfil |
| supervisor / admin | Hoy, Equipo, Alertas, Más |
| security | Seguridad, Alertas, Perfil |
| owner | Mis propiedades, Reportes, Perfil |
| guest | Mi reserva, Áreas, Chat, Ayuda |

En esta fase solo se implementa el shell y la pestaña Perfil; las demás muestran un
marcador "próximamente" para poder probar la navegación por rol.

## 5. Portal web (Angular)

* `core/auth`: `auth-api.service.ts` (puro), `session.store.ts` (signals: usuario,
  tenant, rol, permisos, banderas), interceptor con refresh único en paralelo, guard
  `permissionGuard(perm)` y `platformAdminGuard`, directiva `*argosCan="'users.manage'"`.
* Páginas: login (con TOTP), selección de empresa, olvidé contraseña, restablecer,
  aceptar invitación, perfil y sesiones.
* Configuración del tenant: datos, banderas (solo lectura del plan), usuarios y
  membresías (invitar, cambiar rol, suspender), roles (tabla de permisos por módulo con
  casillas; los roles de sistema muestran candado en permisos mínimos).
* Plataforma (`platform_admin`): lista y alta de tenants, activar/desactivar, ver
  bitácora de plataforma.
* Layout principal: el menú lateral se construye desde los permisos y banderas.
* Persistencia: refresh token en `localStorage` con `device_id`; sesión 30 días.

## 6. Criterios de aceptación de la fase

* Todas las pruebas de 3.10 pasan en CI.
* Un admin de Garrent invita a un colaborador, este acepta desde el móvil, entra con
  biometría en el segundo arranque y ve solo las pestañas de su rol.
* Un usuario con membresía en dos empresas cambia entre ellas en app y web.
* Platform admin crea un tenant desde la web y el schema queda migrado y con roles.
* Ningún endpoint de negocio existe aún sin `RequirePermission`.
