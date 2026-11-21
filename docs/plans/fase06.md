# Fase 6 — Chat, facturación de tenants, integraciones y cierre

> Estado: pendiente. Requiere fases 3 y 4. El chat con huéspedes se habilita con la
> bandera `guest_chat`; las cerraduras con `smart_locks`.

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

## 3. Facturación de tenants (schema `shared`, migración `shared/0003_billing`)

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

## 4. Integraciones

### 4.1 Claves API y recepción de reservas (`shared/0003_billing` incluye `api_keys`)

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

## 6. Criterios de aceptación

Un huésped escribe por el chat y un supervisor responde desde la web en tiempo real; un
tenant sin pago pasa a solo lectura y vuelve a operar al pagar; la suite de aislamiento
recorre todos los endpoints sin fugas; una reserva enviada por la clave API de la web del
cliente aparece en el calendario del tenant.
