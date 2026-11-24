# Fase 6 — Chat, facturación de tenants, integraciones y cierre

> Estado: en curso. Parte de Persona A **hecha** (2026-11-23): migración `shared/0005_billing`,
> módulos `billing` (planes, suscripciones, facturas, `FakeProvider`, `billing_cycle`, solo
> lectura 402, límites del plan, webhooks) y `apikeys` + `POST /public/reservations`, límite de
> peticiones, `/health/ready`, suite de aislamiento generada desde el OpenAPI y OpenAPI exportado a
> `BACKEND/docs`. Web: W-O4 (facturación), integraciones (claves API), W-P2, W-P3 y W-M1 (chat con
> mock hasta la API de B). Contrato en §3.4, §4.3 y §5.1. Pendiente (Persona B): `tenant/0010_chat_locks`,
> `chat`, `locks`, retención completa, observabilidad del worker y la app. El chat con huéspedes se
> habilita con la bandera `guest_chat`; las cerraduras con `smart_locks`.

## 1. Objetivo

* Chat interno y chat huésped ↔ empresa en tiempo real.
* Planes, suscripciones y cobro a los tenants por pasarela.
* Integraciones externas: cerraduras Nexxt y recepción de reservas desde la página web
  del cliente.
* Endurecimiento final: pruebas de aislamiento completas, retención, observabilidad.

## 2. Chat

### 2.1 Modelo (migración `tenant/0010_chat_locks`, Persona B; incluye también las tablas de cerraduras de §4.2)

`conversations`: `kind varchar(8) CHECK IN ('internal','guest')`, `title varchar(128)
null`, `reservation_id uuid FK null` (obligatorio si `guest`), `created_by uuid null`,
`last_message_at timestamptz null`, `is_archived bool`.

`conversation_participants`: `conversation_id FK`, `participant_type varchar(5)
('user','guest')`, `user_id uuid FK shared.users null`, `guest_id uuid FK guests null`,
`joined_at`, `last_read_at timestamptz null`, `muted bool`. `UNIQUE (conversation_id,
user_id)` y `UNIQUE (conversation_id, guest_id)` parciales.

`messages`: `conversation_id FK`, `sender_type`, `sender_user_id`, `sender_guest_id`,
`body text null`, `file_id uuid FK files null`, `created_at`, `deleted_at`. Índice
`(conversation_id, created_at)`.

### 2.2 Reglas

* Conversaciones internas: cualquiera con `chat.internal` puede crear 1:1 o grupo con
  miembros del mismo tenant. Un admin puede unirse a cualquier grupo.
* Conversación de huésped: se crea automáticamente al confirmar la reserva (bandera
  activa), con el huésped y con todos los usuarios con `chat.guest`. Se archiva 24 h
  después del check-out; el huésped pierde acceso con su token.
* Un participante solo lee mensajes de conversaciones donde figura (404 en otras).
* Tiempo real por `WS /ws` (fase 3): al insertar un mensaje se hace
  `NOTIFY chat_<tenant_id>` con el id; cada instancia de API reenvía a los sockets de los
  participantes conectados. Los desconectados reciben push `chat_message`.
* Imágenes por `files` (`module='chat'`), máximo 10 MB.

### 2.3 Endpoints

`GET /chat/conversations`, `POST /chat/conversations`, `GET /chat/conversations/{id}/messages?before=`,
`POST /chat/conversations/{id}/messages`, `POST .../read`, `POST .../participants`,
`DELETE .../participants/{id}`, y para huésped `GET /guest/chat`, `POST /guest/chat/messages`.

### 2.4 App y web

* App: pestaña Chat (lista con no leídos, conversación con burbujas, adjuntar foto),
  para huésped una sola conversación con la empresa.
* Web: panel de chat con lista de conversaciones internas y de huéspedes (con badge de
  reserva y propiedad), respuestas rápidas.

## 3. Facturación de tenants (schema `shared`, migración `shared/0005_billing`)

### 3.1 Modelo

`plans`: `key varchar(32) unique`, `name`, `price_monthly numeric(12,2)`,
`price_yearly numeric(12,2)`, `currency char(3)`, `limits jsonb`
(`max_properties`, `max_users`, `features: [...]`), `is_active`.

`subscriptions`: `tenant_id FK unique`, `plan_id FK`, `cycle varchar(8) ('monthly',
'yearly')`, `status varchar(16) CHECK IN ('trialing','active','past_due','suspended',
'cancelled')`, `current_period_start`, `current_period_end`, `trial_ends_at`,
`grace_days smallint default 7`, `provider varchar(32)`, `provider_customer_id`,
`provider_subscription_id`, `cancel_at_period_end bool`.

`invoices`: `tenant_id FK`, `subscription_id FK`, `number varchar(32) unique`,
`period_start`, `period_end`, `subtotal`, `tax`, `total`, `currency`, `status
('draft','open','paid','void','uncollectible')`, `due_at`, `paid_at`, `pdf_key`.

`payments`: `invoice_id FK`, `provider`, `provider_payment_id`, `amount`, `currency`,
`status ('pending','succeeded','failed','refunded')`, `raw jsonb`, `created_at`.

`payment_events` (webhooks recibidos): `provider`, `event_id unique`, `type`, `payload
jsonb`, `processed_at`.

### 3.2 Reglas

* `PaymentProvider` es una interfaz (`create_customer`, `create_subscription`,
  `create_checkout`, `cancel`, `parse_webhook`). Implementación inicial:
  **decisión pendiente** (ver avance.md). Se entrega además un `FakeProvider` para
  local y pruebas.
* Job diario `billing_cycle`: genera factura al inicio de cada período; `past_due` si
  vence sin pago; tras `grace_days` → `suspended`: el middleware de fase 1 pone al tenant
  en **solo lectura** (toda petición mutante responde 402 con mensaje) salvo endpoints
  de facturación; platform admin puede reactivar.
* Límites del plan: `properties.manage` valida `max_properties`; invitaciones validan
  `max_users`; las banderas del tenant solo pueden activar `features` incluidas en el
  plan.
* Todo evento de facturación va a `platform_audit_log`.

### 3.3 Endpoints

Tenant (`tenant.billing`): `GET /billing/subscription`, `GET /billing/invoices`,
`GET /billing/invoices/{id}/pdf`, `POST /billing/checkout`, `POST /billing/cancel`.
Plataforma: `GET/POST/PATCH /platform/plans`, `GET /platform/subscriptions`,
`POST /platform/subscriptions/{id}/reactivate`, `POST /platform/tenants/{id}/trial`.
Webhook público: `POST /public/billing/webhook/{provider}` con verificación de firma.

### 3.4 Contrato implementado (Persona A, 2026-11-23)

Todo bajo `/api/v1`. Montos con IVA incluido (12 %: `subtotal + tax = total`). Fechas ISO 8601.

**Empresa** (`tenant.billing`; sigue funcionando en solo lectura)

* `GET /billing/subscription` → `Overview`: `subscription`, `usage` (`properties`, `users` —
  membresías sin huéspedes más invitaciones pendientes—, `storage_bytes`) y `plans` (los que se
  pueden contratar). `SubscriptionRead`: `id, tenant_id, tenant_name, tenant_slug, plan_id, plan_key,
  plan_name, cycle (monthly|yearly), price, currency, limits {max_properties, max_users, features[]},
  status (trialing|active|past_due|suspended|cancelled), status_label, read_only,
  current_period_start, current_period_end, trial_ends_at, grace_days, cancel_at_period_end,
  provider, payment_method, status_changed_at, open_invoice? (la pendiente más antigua),
  suspends_at, failed_payments (90 días), last_payment_at`.
* `GET /billing/invoices` → `InvoiceRead[]`: `id, tenant_id, number (ARG-AAAA-NNNNNN),
  description, plan_name, period_start, period_end, subtotal, tax, total, currency, status
  (open|paid|void|uncollectible), due_at, paid_at, last_error, created_at`.
* `GET /billing/invoices/{id}/pdf`: la factura en PDF (ajena: 404).
* `POST /billing/checkout` `{plan_key?, cycle?}` → `{status (succeeded|failed|redirect), message,
  redirect_url, overview}`. Con cambio de plan o de ciclo: valida que el uso quepa (422 "El plan
  Inicio permite 8 propiedades y tienes 12…"), apaga las banderas que el plan nuevo no incluye, anula
  lo pendiente, abre el período desde hoy y emite la factura. Luego cobra la pendiente. Sin nada que
  pagar: 422. Un pago deja la suscripción `active` (una empresa suspendida o cancelada vuelve a operar).
* `POST /billing/cancel` (no renueva; al terminar el período pasa a `cancelled`) y `/resume`.

**Plataforma** (administración de ARGOS)

* `GET /platform/plans`, `POST /platform/plans` `{key, name, description?, price_monthly,
  price_yearly, currency?, limits, sort_order?}` (clave repetida: 409), `PATCH /platform/plans/{id}`
  (`is_active: false` deja de ofrecerlo; quien lo tiene lo conserva).
* `GET /platform/subscriptions?status=` (suspendidas y vencidas primero),
  `POST /platform/subscriptions/{id}/reactivate` `{days}` (activa y da `days` para pagar),
  `POST /platform/tenants/{id}/trial` `{days, plan_key?}`, `GET /platform/tenants/{id}/invoices` y
  `GET /platform/invoices/{id}/pdf`. `POST /platform/tenants` acepta `plan_key` y `trial_days`
  (por defecto: prueba de 14 días en Completo).
* Todo evento de facturación queda en `platform_audit_log` (`plan.created`, `plan.updated`,
  `billing.invoice_issued`, `billing.payment_succeeded`, `billing.payment_failed`,
  `billing.plan_changed`, `billing.status_changed`, `billing.cancel_scheduled`, `billing.reactivated`,
  `billing.trial_started`).

**Webhook público**: `POST /public/billing/webhook/{provider}` con `X-Argos-Signature:
sha256=<HMAC-SHA256 del cuerpo>` (secreto `ARGOS_BILLING_WEBHOOK_SECRET`). Cuerpo de `fake`: `{id,
type (payment.succeeded|payment.failed), invoice_number, payment_id?, amount?, method?, reason?}`.
Idempotente por `(provider, id)`. Firma inválida 401, pasarela desconocida 404.

**Reglas tal como quedaron**

* Planes sembrados: Inicio (Q690/mes, 8 propiedades, 10 personas, reservas), Operación (Q1,450, 25,
  30, reservas, parqueos, áreas comunes, nómina) y Completo (Q2,900, sin límites, todo). Anual = 10
  mensualidades.
* `billing_cycle` (diario, trabajo de plataforma): una prueba vencida abre el primer período y lo
  factura; un período vencido se renueva y factura (no a una empresa suspendida); la factura vence a los
  5 días: `past_due`, y tras `grace_days` (7) `suspended`. Cancelación programada: `cancelled` al
  terminar el período. Cada paso avisa por correo (`billing_notice`) a quien tiene `tenant.billing`.
* Solo lectura (`suspended` y `cancelled`): toda escritura responde **402** "Tu empresa está en solo
  lectura por un pago pendiente…" salvo `/billing/*` y `/auth/*`. `GET /auth/me` trae
  `tenant.billing_status` y `tenant.read_only` para que web y app muestren el aviso.
* Límites del plan: `POST /properties` (422 al llegar a `max_properties`), invitaciones (422 al llegar
  a `max_users`, contando invitaciones pendientes) y banderas (la plataforma no puede activar una que
  el plan no incluye: 422 "El plan Mini no incluye Nómina."). Sin suscripción no hay límites.
* Las empresas que existían al migrar quedaron activas en Completo. Una empresa nueva empieza en prueba.

**Diferencias con lo planeado**: `invoices.pdf_key` existe pero el PDF se genera al pedirlo (con
`core/pdf`); `payments.failure_reason`, `subscriptions.payment_method` y `status_changed_at` son
columnas nuevas; `POST /billing/resume` y `GET /platform/tenants/{id}/invoices` son rutas extra.
Cambiar de plan no prorratea: anula lo pendiente y cobra el período nuevo completo.

## 4. Integraciones

### 4.1 Claves API y recepción de reservas (`shared/0005_billing` incluye `api_keys`)

`api_keys`: `tenant_id FK`, `name`, `key_prefix char(8)`, `key_hash char(64) unique`,
`scopes jsonb` (`['reservations:write']`), `last_used_at`, `revoked_at`, `created_by`.

`POST /public/reservations` (cabecera `X-Api-Key`): contrato definido en fase 4
(propiedad por `code`, fechas, huésped principal, canal `direct`, monto). Crea la reserva
`source='api'` en `pending` y notifica al admin. Rate limit 60/min por clave. La
integración concreta con la web del cliente se decide cuando entreguen su información.

### 4.2 Cerraduras inteligentes Nexxt (`tenant/0010_chat_locks` incluye estas tablas)

`lock_devices`: `property_id FK`, `provider varchar(16) default 'nexxt'`,
`external_id varchar(128)`, `name`, `is_active`, `credentials` cifradas.

`lock_access_codes`: `device_id FK`, `reservation_id FK`, `code varchar(16)` cifrado,
`valid_from`, `valid_to`, `status ('scheduled','active','revoked','failed')`,
`provider_ref`, `last_error`.

Reglas: al confirmar una reserva en propiedad con cerradura se encola `lock_provision`
(crea código válido desde `check_in` hasta `check_out + 2 h`); al cancelar o hacer
check-out se encola `lock_revoke`. El código se muestra al huésped en "Mi reserva" solo
desde 24 h antes del check-in. Interfaz `LockProvider` con `FakeLockProvider`; la
implementación real depende de obtener acceso a la API de Nexxt (decisión pendiente).

### 4.3 Contrato implementado: claves API y reservas del sitio (Persona A, 2026-11-23)

* `GET /api-keys`, `POST /api-keys` `{name, scopes?}` → 201 con `key` (la única vez que viaja;
  formato `argos_<48 hex>`), `POST /api-keys/{id}/revoke`. Permiso `tenant.settings`. Se guarda
  solo el SHA-256; la lista muestra `prefix`, `last_used_at`, `revoked_at` y quién la creó.
* `POST /public/reservations` con `X-Api-Key`: `{property_code, check_in_date, check_out_date,
  adults?, children?, total_amount?, guest {full_name, email?, phone?, document_type?,
  document_number?, nationality?}, external_ref?, notes?}` → 201 `{id, code, status: "pending",
  property_code, property_name, check_in_date, check_out_date, nights}`. Entra al canal Directo con
  `source = 'api'`, avisa por correo (`reservation_requested`) a quien tiene `reservations.manage` y
  publica `reservation.requested` (Data `ReservationEvent`).
* Errores: 401 clave inválida o revocada, 403 sin alcance `reservations:write` o sin la bandera
  `reservations`, 402 empresa en solo lectura, 404 código de propiedad, 422 fechas o cruce, 429 más de
  60 por minuto con la misma clave (`ARGOS_RATE_LIMIT_API_KEY`) con `Retry-After`.

## 5. Endurecimiento y cierre

* Suite de aislamiento completa: por cada endpoint del router se genera automáticamente
  un test paramétrico que lo invoca con cada rol de `tenant_a` contra recursos de
  `tenant_b` y verifica 401/403/404. Los endpoints se registran con metadatos
  (`permission`, `scope_kind`) para que el generador sepa qué esperar.
* Revisión de claves S3: script que recorre `files` de cada tenant y valida prefijo.
* Retención: job `retention_cleanup` cubre DPI (90 días), evidencias (24 meses),
  `files.pending` (24 h), notificaciones leídas (180 días), jobs `done` (30 días).
* Observabilidad: logs JSON con `tenant_id`, `request_id`, `user_id`; métricas de
  worker (cola pendiente, fallos) y health extendido (`/health/ready` verifica BD, S3 y
  head de migraciones).
* Rate limiting por IP y por usuario en auth y endpoints públicos.
* Backups: instantáneas diarias de la BD gestionada y verificación mensual de
  restauración en staging.
* Documentación final: README de cada repo, OpenAPI exportado a `BACKEND/docs`, guía de
  operación (crear tenant, migrar, rotar claves, restaurar).

### 5.1 Hecho por Persona A (2026-11-23)

* **Suite de aislamiento generada** (`internal/server/phase6_integration_test.go`,
  `TestIsolationGenerated`): lee `/api/v1/openapi.json` y recorre todas las operaciones (174). Sin
  token, toda ruta protegida responde 401. Con la sesión de la administradora de otra empresa, toda ruta
  con id apuntando a recursos reales de Garrent (propiedad, edificio, plantilla, ficha, proveedor,
  activo, incidencia, reserva, huésped, canal, período, línea, acción, clave, factura, suscripción,
  archivo, membresía, rol) responde 400/403/404/405/422; nunca 2xx ni 5xx. Una ruta nueva entra sola.
* **Límite de peticiones** (`internal/core/ratelimit`, ventana fija en memoria, sin Redis): por IP en
  `/auth/login`, `/auth/password/*`, `/auth/select-tenant` y `/auth/refresh`
  (`ARGOS_RATE_LIMIT_AUTH`, 60/min) y en `/public/*` (`ARGOS_RATE_LIMIT_PUBLIC`, 300/min); por clave
  en reservas públicas (60/min). 429 con `Retry-After`. Con varias instancias el límite es por
  instancia.
* **`GET /health/ready`**: 200 `{status: ready}` si la BD responde, S3 responde y no hay migraciones
  pendientes en `shared` ni en ninguna empresa; 503 si no. Incluye la cola (`pending`, `running`,
  `failed_24h`, `oldest_pending_seconds`).
* **Logs**: el registro de acceso lleva `request_id`, `tenant_id` y `user_id`.
* **OpenAPI exportado** a `BACKEND/docs/openapi.yaml` y `.json`, y **guía de operación** en
  `BACKEND/docs/operacion.md` (crear empresa, migrar, rotar claves, respaldos y restauración,
  facturación y límites).
* Retención completa y métricas del worker quedan para Persona B (reparto.md §4, fase 6).

## 6. Criterios de aceptación

Un huésped escribe por el chat y un supervisor responde desde la web en tiempo real; un
tenant sin pago pasa a solo lectura y vuelve a operar al pagar; la suite de aislamiento
recorre todos los endpoints sin fugas; una reserva enviada por la clave API de la web del
cliente aparece en el calendario del tenant.
