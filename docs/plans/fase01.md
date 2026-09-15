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
| Modelos ORM | Una sola `Base`/`MetaData`. Tablas globales con `schema="shared"`; tablas de tenant **sin schema** (se resuelven por `search_path`). |
| Migraciones | Dos entornos Alembic: `shared` y `tenant`, cada uno con su carpeta de versiones y su tabla `alembic_version`. Un schema `tenant_template` siempre migrado a head sirve para autogenerar. |
| Permisos | Enum en código (`Permission`). Roles en BD (`shared.roles`) con `role_permissions`. |
| Token | JWT HS256. Access 15 min con claims `sub`, `tid` (tenant), `mid` (membership), `rk` (role key), `pv` (permissions version). Refresh opaco (random 256 bits), guardado hasheado (SHA-256), rotativo. |
| Resolución de permisos | En cada petición: se cargan de BD los permisos del rol (cache en memoria por proceso, TTL 60 s, invalidado por `pv`). |
| Huéspedes | No usan `shared.users`. Tienen token propio con claim `typ=guest` (fase 4). El middleware de esta fase ya contempla el tipo. |
| Cola de trabajos | Tabla `shared.jobs` + worker con `SELECT ... FOR UPDATE SKIP LOCKED`. Sin Redis. |
| Correo | Amazon SES vía `aioboto3`. Plantillas Jinja2 en `src/core/mail/templates`. |
| Archivos | Amazon S3 vía `aioboto3`. Un bucket por ambiente. En local: LocalStack o MinIO en docker-compose (solo desarrollo). |
| 2FA | TOTP (`pyotp`), secreto cifrado con clave `ARGOS_FIELD_ENCRYPTION_KEY` (Fernet). |
| Cifrado de campos | Utilidad `EncryptedString` (SQLAlchemy TypeDecorator con Fernet) para totp_secret y, en fase 2, información de acceso a propiedades. |

## 3. Backend

### 3.1 Reestructura de Alembic

Estructura objetivo:

```
BACKEND/
├── alembic.ini                 # secciones [shared] y [tenant]
├── migrations/
│   ├── shared/
│   │   ├── env.py
│   │   ├── script.py.mako
│   │   └── versions/
│   │       ├── 0001_initial.py            (existente, renombrada: 3f1d8a233b4f)
│   │       └── 0002_identity.py
│   └── tenant/
│       ├── env.py
│       ├── script.py.mako
│       └── versions/
│           └── 0001_tenant_base.py
```

`alembic.ini`:

```ini
[shared]
script_location = migrations/shared
version_table = alembic_version
[tenant]
script_location = migrations/tenant
```

`migrations/shared/env.py` (igual al actual): `include_schemas=True`,
`version_table_schema="shared"`, `include_object` acepta solo objetos con
`schema == "shared"`.

`migrations/tenant/env.py`:

1. Lee `-x tenant=<slug|all>` (por defecto `all`).
2. Resuelve la lista de schemas: si `all`, `SELECT schema_name FROM shared.tenants WHERE is_active`
   más `tenant_template`; si es un slug, solo ese schema.
3. Por cada schema: `SET search_path TO "<schema>", "shared"`, `commit`,
   `connection.dialect.default_schema_name = "<schema>"`, `context.configure(...)` con
   `include_schemas=False`, `version_table_schema="<schema>"`, `include_object` que
   acepta solo objetos con `schema is None`; después `context.run_migrations()`.
4. `revision --autogenerate` en el entorno tenant se ejecuta siempre con
   `-x tenant=template` (schema `tenant_template`), nunca contra un tenant real.

Comandos oficiales (documentar en README del backend):

```bash
poetry run alembic -n shared upgrade head
poetry run alembic -n tenant upgrade head                 # todos los tenants + template
poetry run alembic -n tenant upgrade head -x tenant=garrent
poetry run alembic -n shared revision --autogenerate -m "..."
poetry run alembic -n tenant revision --autogenerate -m "..." -x tenant=template
```

Reglas:

* Orden de despliegue: `shared` primero, luego `tenant`.
* El worker y la API se niegan a arrancar si `shared` no está en head
  (chequeo en `lifespan`). Si un tenant no está en head se marca `is_active=false`
  temporalmente y se registra en log (nunca se opera con un schema desfasado).
* CI: job que levanta Postgres, aplica ambas cabezas en una BD vacía, crea dos tenants y
  corre `alembic -n tenant check -x tenant=template` para detectar drift entre modelos y
  migraciones.

### 3.2 Alta de tenant (provisioning)

`TenantService.create_tenant` pasa a ejecutar, en este orden y en una sola operación
lógica (si algo falla se elimina el schema):

1. Insertar `shared.tenants`.
2. `CREATE SCHEMA "tenant_<slug>"`.
3. Ejecutar migraciones tenant a head para ese schema (`alembic.command.upgrade` en un
   hilo con engine síncrono, `-x tenant=<slug>`).
4. Sembrar roles por defecto (`shared.roles` + `shared.role_permissions`) para el tenant
   a partir de la matriz del PRD sección 3.4.
5. Crear la membresía `admin` para el usuario indicado (existente o invitado por correo).
6. Registrar en `shared.platform_audit_log`.

### 3.3 Modelo de datos: schema `shared`

Convenciones para todas las tablas del proyecto:

* `id UUID PK DEFAULT gen_random_uuid()`, `created_at`, `updated_at` (timestamptz,
  `now()`), vía mixins existentes.
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
| totp_secret | varchar(255) null | cifrado (Fernet) |
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
4. **Migración de datos** (SQL dentro de la misma revisión):
   * `UPDATE shared.users SET is_platform_admin = true WHERE role = 'platform_admin'`.
   * Por cada tenant existente: insertar los siete roles por defecto con sus permisos
     (la matriz vive en `src/modules/authz/default_roles.py`; la migración importa la
     misma constante para no duplicarla).
   * Por cada usuario con `tenant_id`: insertar membresía con el rol cuyo `key` coincide
     con `users.role` (`employee` → `cleaner`), `status='active'`, `joined_at=created_at`.
5. Eliminar columnas `users.role`, `users.tenant_id`, `users.is_owner` y su índice.
6. Crear el schema `tenant_template` si no existe (`CREATE SCHEMA IF NOT EXISTS`).

`downgrade()` invierte los pasos y reconstruye `role`/`tenant_id` a partir de la primera
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
src/modules/authz/
├── permissions.py     # class Permission(StrEnum) con todo el catálogo del PRD 3.3
├── default_roles.py   # DEFAULT_ROLES: dict[role_key, set[Permission]] = matriz PRD 3.4
├── models.py          # Role, RolePermission, Membership
├── repository.py
├── service.py         # crear/editar roles, sembrar defaults, resolver permisos con cache
└── schemas.py
```

`src/api/dependencies.py`:

* `get_session`: abre transacción explícita y hace `SET LOCAL search_path TO "shared"`.
* `get_current_principal`: valida JWT, distingue `typ` (`user` | `guest`), carga usuario
  y membresía, verifica `status='active'`, verifica `tenant.is_active`, ejecuta
  `SET LOCAL search_path TO "<tenant_schema>", "shared"`, resuelve permisos del rol y
  devuelve `Principal(user, tenant, membership, role_key, permissions: frozenset)`.
* `require_permission(*perms)`: dependencia; 403 si falta alguno. Nunca se usa
  `require_role`: se elimina `roles.py` y `has_at_least`.
* `require_platform_admin`.
* `ScopeResolver`: helper inyectable que expone `property_ids_for(principal)` y similares
  (se completa en fase 2). Los repositorios de negocio reciben el scope y filtran siempre.

Reglas de código obligatorias (añadir a `BACKEND/docs/ARCHITECTURE.md`):

* Todo endpoint bajo `/api/v1` excepto `auth/*`, `health` y `public/*` declara
  `Depends(require_permission(...))`.
* Todo repositorio de tenant recibe `scope` y lo aplica en `WHERE`; un `get_by_id` fuera
  del scope devuelve `None` (el endpoint responde 404).
* Está prohibido construir claves S3 fuera de `StorageService.build_key(tenant_id, ...)`.

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
| `POST /platform/tenants`, `GET /platform/tenants`, `PATCH .../{id}` | `require_platform_admin`. |

Si un usuario tiene `is_platform_admin` y además membresías, el login lo trata como
usuario normal; el modo plataforma se activa con `POST /auth/select-tenant`
enviando `platform: true`.

Tiempos: access 15 min, refresh 60 días (móvil) / 30 días (web), selección 5 min.
Bloqueo por fuerza bruta: 10 intentos fallidos en 15 min por correo+IP → 429.

### 3.8 Servicio de archivos (S3)

`src/core/storage.py` → `StorageService`:

* `build_key(tenant_id, module, kind, filename) -> "tenants/{tenant_id}/{module}/{yyyy}/{mm}/{uuid}.{ext}"`.
* `presign_upload(key, content_type, max_bytes)`: POST prefirmado con condición de
  tamaño y content-type; 15 min.
* `presign_download(key)`: 5 min.
* `delete(key)`.
* `assert_tenant_key(key, tenant_id)`: lanza si el prefijo no coincide. Se llama antes de
  firmar cualquier descarga.

Flujo de subida: el cliente pide `presign-upload` con `module`, `kind`, `entity`,
`content_type`, `size` → el backend valida permiso sobre la entidad, crea `files`
en `pending` y devuelve la URL → el cliente sube → `confirm` verifica con `HEAD` que el
objeto existe y marca `ready`. Los `pending` de más de 24 h se borran (job
`storage_cleanup`).

Política IAM del backend: solo `s3:PutObject`, `GetObject`, `DeleteObject`, `HeadObject`
sobre `arn:aws:s3:::<bucket>/tenants/*`. Bucket privado, sin ACLs, cifrado SSE-S3,
versionado desactivado, regla de ciclo de vida para abortar multipart huérfanos.

### 3.9 Cola de trabajos y correo

* `src/core/jobs/`: `enqueue(type, payload, tenant_id=None, scheduled_at=None,
  dedupe_key=None)`, `registry` de handlers, `worker.py` (proceso `python -m src.worker`,
  concurrencia configurable, polling 1 s con `LISTEN jobs_new` para despertar).
* `src/core/mail/`: `MailService.send(to, template, context)` con SES; en `local` y
  `testing` escribe el correo a log en lugar de enviarlo.
* Handlers de esta fase: `send_email`, `storage_cleanup`.
* Nuevas variables: `ARGOS_AWS_REGION`, `ARGOS_S3_BUCKET`, `ARGOS_S3_ENDPOINT_URL`
  (solo local), `ARGOS_SES_FROM`, `ARGOS_FIELD_ENCRYPTION_KEY`, `ARGOS_APP_BASE_URL`,
  `ARGOS_WEB_BASE_URL`, `ARGOS_WORKER_CONCURRENCY`. Credenciales AWS por el mecanismo
  estándar del SDK (rol IAM en despliegue; variables en local).
* `docker-compose.yml`: agregar servicio `worker` (misma imagen, comando distinto) y
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
6. Migraciones: shared + tenant aplican en BD vacía; `alembic check` sin diff.
7. Provisioning de tenant deja el schema en head y los siete roles sembrados.
8. Usuario con dos membresías recibe `selection_token` y puede cambiar de tenant; los
   datos vistos cambian con el tenant.
9. Cuenta suspendida o tenant inactivo → 401 en `/auth/me`.

### 3.11 Limpieza de código existente

* Eliminar `src/modules/auth/roles.py` y todo uso de `Role`/`has_at_least`.
* Eliminar `scripts/seed_platform_admin.py` y reemplazar por `scripts/seed.py` con
  subcomandos: `platform-admin`, `demo-tenant` (crea tenant demo con usuarios de cada rol).
* Actualizar `README.md` y `docs/ARCHITECTURE.md` del backend con las reglas de 3.6 y los
  comandos de 3.1.

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
* Ningún endpoint de negocio existe aún sin `require_permission`.
