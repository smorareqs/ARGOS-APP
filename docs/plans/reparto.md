# ARGOS — Reparto del trabajo entre dos personas

> Objetivo: que Persona A y Persona B avancen en paralelo sin tocar los mismos archivos
> ni esperarse. El reparto es por **módulo**, no por repositorio: cada carpeta del
> backend tiene un solo dueño, la web es de A y la app es de B. Los puntos de contacto
> se resuelven con contratos de API publicados antes de construir y con un orden fijo
> para las migraciones.

## 1. Perfil de cada persona

| | Persona A · "Núcleo y web" | Persona B · "Campo y app" |
| --- | --- | --- |
| Repos | BACKEND (núcleo y módulos administrativos) + WEB | APP + BACKEND (módulos que consume la app) |
| Enfoque | Seguridad, multi-tenant, datos maestros, reservas, nómina, portal de administración | Ejecución en campo, offline, cámara, notificaciones, huésped, seguridad, chat |
| Es dueña de | `src/core/*`, `src/api/dependencies.py`, `migrations/shared/*`, `tests/conftest.py`, todo `WEB/` | todo `APP/` (incluido `packages/design_system`), worker y handlers de jobs de sus módulos |

## 2. Mapa de propiedad de archivos (evita colisiones)

### BACKEND

| Ruta | Dueño | Regla para el otro |
| --- | --- | --- |
| `src/core/` (config, database, security, storage, mail, jobs, notifications base) | A | B abre PR pequeño y A revisa el mismo día |
| `src/api/dependencies.py` | A | ídem |
| `src/api/v1/router.py` | compartido | solo se **agregan líneas** `include_router`; una línea por módulo; nunca reordenar |
| `src/modules/models_registry.py` | compartido | solo se agregan imports; uno por módulo |
| `src/modules/<módulo>/` | dueño del módulo (tabla §4) | el otro no edita; si necesita algo, lo pide por issue o PR |
| `migrations/shared/versions/` | A | B nunca crea migraciones shared |
| `migrations/tenant/versions/` | quien es dueño de las tablas | numeración fija (§5); B genera la suya solo después de que la de A de la misma fase esté en `main` |
| `src/worker.py` y `src/core/jobs/registry.py` | A crea la infraestructura; ambos registran handlers | el registro de handlers es append-only |
| `tests/conftest.py` | A | fixtures nuevas: B las propone en PR |
| `tests/unit/<módulo>/`, `tests/integration/<módulo>/` | dueño del módulo | — |
| `scripts/seed.py` | A la estructura; cada uno la sección de sus módulos | funciones `seed_<módulo>()` separadas |
| `README.md`, `docs/ARCHITECTURE.md` | A | B agrega secciones de sus módulos al final |

### WEB
Todo es de A. B no toca el repo.

### APP
Todo es de B, incluido `packages/design_system`. A no toca el repo.

### Documentación (`APP/docs/plans`)
`avance.md` lo escriben ambos: cada uno agrega sus líneas bajo la fecha, con prefijo
`[A]` o `[B]`. Nunca reescribir líneas del otro. Los `fase0N.md` se modifican solo por
acuerdo y quien lo modifica lo anota en avance.md.

## 3. Reglas de trabajo en paralelo

1. **Contrato antes que código.** Cuando un módulo de una persona será consumido por la
   otra (la web de A consume `tasks` de B; la app de B consume `properties` de A), el
   dueño publica primero los schemas Pydantic y el listado de endpoints (ya están en
   cada `fase0N.md`; si algo cambia, se actualiza el documento en el mismo PR). El
   consumidor construye contra un mock hasta que el endpoint real esté en `main`.
   * Web: `*-api.service.ts` con implementación mock detrás de una bandera de entorno.
   * App: `MockRemoteDataSource` por feature, activada por `--dart-define=ARGOS_MOCK=true`.
2. **La migración de A va primero en cada fase.** Es el primer PR de la fase; B genera la
   suya con `down_revision` apuntando a la de A. Nunca dos cabezas de Alembic.
3. **Ramas cortas.** `feat/f<fase>-<módulo>` desde `main`, PR de menos de 500 líneas
   cuando se pueda, rebase diario sobre `main`. La rama `dev/sebas` actual se fusiona a
   `main` al iniciar la fase 1.
4. **Revisión cruzada obligatoria** en cualquier PR que toque archivos compartidos
   (router, registry, conftest, core, seed). En el resto, revisión opcional pero el otro
   debe poder leerlo.
5. **Hito de integración por fase.** Cada fase tiene un punto donde ambos conectan
   (tabla §4). Antes del hito cada uno prueba con mocks; después, con el backend real en
   `docker compose`. El hito se marca en avance.md.
6. **Seed compartido.** Cada uno mantiene la semilla de sus módulos para que el otro
   pueda probar con datos reales sin pedirle nada.
7. **Si uno termina antes**, toma el primer ítem de la lista "Si sobra tiempo" de su
   columna en §4; nunca empieza a tocar módulos del otro.

## 4. Reparto por fase

### Fase 1 — Fundaciones

| | Persona A | Persona B |
| --- | --- | --- |
| Backend | Todo el backend de la fase: reestructura Alembic (`shared` y `tenant`), `shared/0002_identity`, `tenant/0001_tenant_base`, módulo `authz` (permisos, roles, membresías), módulo `auth` (login, refresh, TOTP, invitaciones, reset, sesiones), `tenants` (provisioning, settings, platform), `core/storage` (S3), `core/jobs` (cola y worker), `core/mail` (SES), `files` (presign, confirm), pruebas de aislamiento §3.10, `scripts/seed.py`, CI | Nada (ver "arranque") |
| Frontend | WEB: `core/auth`, interceptor, guards, directiva `*argosCan`, W-A1–W-A5, main-layout con sidebar por permisos, W-O1 (parcial), W-O2, W-O3 (permission-matrix), W-P1, W-P4 | APP: eliminar login MD5, `AuthRemoteDataSource`, interceptor con refresh único, `SecureStorageService` nuevo, `device_id`, biometría y PIN, A1–A10, B17, B18, TabScaffold y shell por rol con pestañas vacías, `session_cache` en Drift, `MockRemoteDataSource` de auth |
| Arranque de B mientras A construye el backend | — | 1) Componentes nuevos del design system de fases 1 y 2 (IconButton, PinField, OtpField, Avatar, Skeleton, Toggle, Stepper, Checkbox grande, PhotoThumb, OfflineBar, ListTile, EmptyState, ErrorState, ConfirmSheet, SearchField, FilterChips, ChecklistItemRow, PhotoGrid, BeforeAfterPair, QuantityRow, TimelineItem, FormScaffold, DetailScaffold, SheetScaffold). 2) Cámara integrada con compresión y marca de agua. 3) Cola local `pending_uploads` en Drift con reintento (`workmanager`). 4) Pantallas de acceso contra el mock |
| Hito de integración | A entrega `docker compose up` con auth funcionando y seed `demo-tenant`; B conecta A2–A8 y B17–B18 al backend real | |
| Si sobra tiempo | Empezar `tenant/0002_properties` | Pantalla B1 con datos mock según ficha |

### Fase 2 — Operación

| | Persona A | Persona B |
| --- | --- | --- |
| Migración tenant | `0002_properties`: buildings, properties, property_owners, property_assignments, employees, employee_schedules, checklist_templates, checklist_template_items | `0003_tasks_inventory`: tasks, task_checklist_items, task_events, task_consumptions, warehouses, inventory_items, inventory_stock, inventory_movements, employee_custody, inventory_discrepancies, restock_requests |
| Módulos backend | `properties` (edificios, propiedades, acceso cifrado, propietarios, asignaciones), `employees` (perfil, horario), `checklists`, `audit` (servicio de bitácora que todos usan), `ScopeResolver` en `authz`, `sync` (`GET /sync/bootstrap`) | `tasks` (crear, asignar, reprogramar, iniciar, checklist, consumos, cierre con conciliación, validar, eventos, job `mark_late_tasks`), `inventory` (todo), handlers de jobs de sus módulos |
| Frontend | WEB: W-B1 (parcial), W-C1–W-C4, W-D1–W-D2 (sin RRHH), W-E1–W-E4, W-F1–W-F6, W-N1, componentes data-table, detail-drawer, week-calendar, checklist-editor, file-uploader, user-picker | APP: B1–B11, C1–C3, C11, E1–E2 (limpiezas), modo sin conexión completo, sync real |
| Dependencias cruzadas | La web de itinerario e inventario consume `tasks` e `inventory` de B (contrato en fase02 §4) | La app consume `properties`, `sync` y `audit` de A |
| Hito de integración | Migración `0002` en `main` como primer PR de la fase → B genera `0003`. Hito final: flujo F2 completo (crear tarea en web, ejecutar y cerrar en app, validar en web) | |
| Si sobra tiempo | `0004_maintenance` | Escáner de código de barras en B10 |

### Fase 3 — Mantenimiento y notificaciones

| | Persona A | Persona B |
| --- | --- | --- |
| Migración tenant | `0004_maintenance`: vendors, assets, maintenance_plans, maintenance_tickets, ticket_events, alerts | `0005_notifications`: notifications, notification_preferences |
| Módulos backend | `maintenance` (vendors, assets, planes, tickets, job `maintenance_due`, `low_stock`), `alerts` (crear/reconocer/resolver, integraciones con tasks e inventory por eventos) | `notifications` (`NotificationService`, handlers `send_push` con FCM y `send_email` usando `core/mail` de A, preferencias, `POST /devices`), `realtime` (`WS /ws` con LISTEN/NOTIFY), enganche de todos los eventos de fases 2 y 3 (tabla fase03 §4) |
| Frontend | WEB: W-G1–W-G5, W-L1, notification-tray y campana (consume API de B), W-B1 completo | APP: B12–B14, B16, C4, F7 (contrato), `firebase_messaging`, deep links desde push |
| Hito de integración | Un ticket creado en app aparece en kanban web; una alerta de retraso llega por push al supervisor | |
| Si sobra tiempo | `0006_reservations` | Resumen diario por correo para admin |

### Fase 4 — Reservas y hospitalidad

| | Persona A | Persona B |
| --- | --- | --- |
| Migración tenant | `0006_reservations`: booking_channels, property_ical_feeds, guests, reservations, reservation_guests, reservation_events, deposit_transactions, inspections, inspection_findings; FK `tasks.reservation_id` y `maintenance_tickets.reported_by_guest_id` | `0007_guest_parking_areas`: guest_access_tokens, security_alarms, parking_spots, parking_assignments, shared_areas, shared_area_bookings |
| Módulos backend | `reservations` (canales, reservas, confirmar/cancelar/check-in/check-out, correo al huésped, generación de tarea de limpieza, job `ical_sync`), `guests` (registro, documentos con retención 90 días, job `retention_cleanup`), `deposits`, `inspections`, contrato de `POST /public/reservations` | `guest_access` (`POST /guest/auth`, principal `guest`, endpoints `/guest/*`), `security` (tablero, alarmas, job que programa y dispara alarmas a partir del evento de confirmación de A), `parking`, `shared_areas` (reserva con bloqueo y capacidad) |
| Frontend | WEB: W-H1–W-H6, W-I1–W-I2, W-O1 (reservas y alarmas), occupancy-calendar | APP: A9, C5–C10 (check-in, registro y captura de DPI, depósito, inspección), D1–D3, E2 (reservas), F1–F7, F9, DocumentCapture |
| Dependencias cruzadas | A emite un evento de dominio `reservation.confirmed` / `.cancelled` / `.checked_out` (job) que B consume para alarmas y tokens de huésped | B consume `reservations` y `guests` de A en la app |
| Hito de integración | Flujo F4 (check-in en app sobre reserva creada en web) y F5 (alarma a seguridad) y F6 (huésped reserva área) | |
| Si sobra tiempo | `0008_payroll` | Búsqueda por placa en D1 |

### Fase 5 — RRHH y métricas

| | Persona A | Persona B |
| --- | --- | --- |
| Migración tenant | `0008_payroll`: payroll_settings, payroll_periods, payroll_entries, disciplinary_actions | `0009_attendance_metrics`: attendance_records, performance_snapshots, goals, incentive_awards |
| Módulos backend | `payroll` (cómputo por esquema, Bono 14, aguinaldo, IGSS, estados, Excel con openpyxl, boleta PDF), `disciplinary` | `attendance` (marcaje, cierre automático, correcciones), `metrics` (job `performance_snapshot`, endpoints me/team/all/properties), `incentives` (metas, evaluación, aprobación) |
| Frontend | WEB: W-D2 (pestañas RRHH), W-J1–W-J5, W-K1–W-K2, payroll-grid | APP: B15, B19–B21, C1 (asistencia), E3, PayslipViewer, ClockButton |
| Dependencias cruzadas | `payroll.compute` lee `attendance_records` y `incentive_awards` de B (solo lectura por repositorio propio) | — |
| Hito de integración | Flujo F7: marcajes de app reflejados en nómina web; boleta visible en app | |
| Si sobra tiempo | Exportar CSV de asistencia | Gráfico de tendencia en B19 |

### Fase 6 — Chat, facturación, integraciones y cierre

| | Persona A | Persona B |
| --- | --- | --- |
| Migraciones | `shared/0003_billing`: plans, subscriptions, invoices, payments, payment_events, api_keys | `tenant/0010_chat_locks`: conversations, conversation_participants, messages, lock_devices, lock_access_codes |
| Módulos backend | `billing` (`PaymentProvider`, `FakeProvider`, job `billing_cycle`, modo solo lectura 402 en `dependencies.py`, webhooks), `api_keys` + `public` (`POST /public/reservations` real), generador de pruebas de aislamiento por endpoint, rate limiting, `/health/ready` | `chat` (conversaciones, mensajes, WS, push de mensajes, creación automática para huéspedes), `locks` (`LockProvider`, `FakeLockProvider`, jobs `lock_provision` y `lock_revoke`), jobs de retención completos y observabilidad del worker |
| Frontend | WEB: W-M1 (chat-panel, consume API de B), W-O4, W-P2–W-P3, guía de operación | APP: B22–B23, F8, código de cerradura en F1 |
| Hito de integración | Chat huésped ↔ web en tiempo real; tenant suspendido en solo lectura en app y web | |
| Cierre | A: OpenAPI exportado, README de backend y web | B: README de app, pruebas de aislamiento de la app (rol equivocado no ve pestañas) |

## 5. Numeración fija de migraciones

| Entorno | Revisión | Dueño | Fase |
| --- | --- | --- | --- |
| shared | `0002_identity` | A | 1 |
| shared | `0003_billing` | A | 6 |
| tenant | `0001_tenant_base` | A | 1 |
| tenant | `0002_properties` | A | 2 |
| tenant | `0003_tasks_inventory` | B | 2 |
| tenant | `0004_maintenance` | A | 3 |
| tenant | `0005_notifications` | B | 3 |
| tenant | `0006_reservations` | A | 4 |
| tenant | `0007_guest_parking_areas` | B | 4 |
| tenant | `0008_payroll` | A | 5 |
| tenant | `0009_attendance_metrics` | B | 5 |
| tenant | `0010_chat_locks` | B | 6 |

Cada migración de B de una fase tiene `down_revision` = la de A de la misma fase (o la
anterior de B si A no tiene en esa fase, como en la 6). Si alguien necesita una columna
en una tabla del otro (ej. `tasks.reservation_id`), la agrega **el dueño de la tabla**
en su propia migración de la fase, a petición del otro.

## 6. Módulos backend por dueño (resumen)

| Persona A | Persona B |
| --- | --- |
| core, authz, auth, tenants, files, audit, properties, employees, checklists, sync, maintenance, alerts, reservations, guests, deposits, inspections, payroll, disciplinary, billing, api_keys, public | tasks, inventory, notifications, realtime, guest_access, security, parking, shared_areas, attendance, metrics, incentives, chat, locks |

## 7. Ritual mínimo

* Cada mañana: `git pull --rebase` en los tres repos y leer los PR abiertos del otro.
* Cada vez que se cierra un ítem: una línea en avance.md con `[A]` o `[B]`.
* Al llegar a un hito de integración: sesión conjunta de una hora con `docker compose`
  levantado, ambos flujos probados y avance.md actualizado con "Hito fase N alcanzado".
* Cualquier cambio a un contrato ya publicado se avisa antes de fusionar y se actualiza
  el `fase0N.md`.
