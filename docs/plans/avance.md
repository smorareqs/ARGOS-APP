# ARGOS — Avance y decisiones

Bitácora del proyecto. Se anota aquí toda decisión (con fecha) y todo lo realizado, en
orden cronológico. El PRD vigente es [`../ARGOS PRD.md`](../ARGOS%20PRD.md) v2; los
planes por fase están en esta carpeta.

## Estado por fase

| Fase | Documento | Estado | Notas |
| --- | --- | --- | --- |
| 1 | [fase01.md](fase01.md) | Pendiente | Identidad, tenants, roles y permisos, migraciones, S3, jobs y correo |
| 2 | [fase02.md](fase02.md) | Pendiente | Propiedades, colaboradores, itinerario, inventario, bitácora |
| 3 | [fase03.md](fase03.md) | Pendiente | Mantenimiento, activos, notificaciones, alertas |
| 4 | [fase04.md](fase04.md) | Pendiente | Reservas, huéspedes, seguridad, parqueos, áreas comunes |
| 5 | [fase05.md](fase05.md) | Pendiente | Asistencia, nómina, disciplina, métricas |
| 6 | [fase06.md](fase06.md) | Pendiente | Chat, facturación, integraciones, cierre |

## Punto de partida (2026-09-15)

Lo que existe en los repos antes de iniciar la fase 1:

* **BACKEND**: FastAPI + SQLAlchemy async + PostgreSQL 16 + Alembic. Multi-tenant por
  schema ya implementado (`shared` + `tenant_<slug>`), una migración inicial (tenants,
  users), roles fijos en código (platform_admin, admin, supervisor, employee), login JWT
  básico. La fase 1 reestructura todo esto.
* **APP** (Flutter): login local contra SQLite con hash MD5 (sin backend), sync
  simulado, pantallas de login, sync e itinerario. La fase 1 elimina el login local.
* **WEB** (Angular 21 + Tailwind): login y dashboard con datos mock.

## Decisiones

### 2026-09-15 — Reunión de requerimientos con el cliente y cierre del PRD v2

Ideas recogidas del cliente e incorporadas al PRD: mantenimiento de elevadores y equipos
de hotelería; notificaciones por correo y app; alarma a seguridad para check-out; control
de parqueos; control de pago por trabajo realizado y asignación de lugares por
colaborador; inventario con devolución obligatoria; prueba de check-out del personal de
limpieza; registro de huéspedes; dos flujos de venta (directa con depósito, agencia/OTA
interno con fotos antes/después); cerraduras Nexxt; áreas compartidas reservables;
correo de reserva al huésped; vínculo con la página web; nombre, correo y DPI o pasaporte
con fotos; Excel de Bono 14 y boleta de pago; procedimiento disciplinario; chat; inicio de
sesión rápido y recurrente.

Decisiones tomadas en la sesión de planificación (respuestas del equipo):

1. **"Clientes" de un tenant** pueden ser propietarios de unidad, huéspedes o ambos. Se
   modelan como dos roles: `owner` y `guest`.
2. **Permisos**: catálogo fijo en código; roles por tenant con permisos editables y roles
   personalizados; siete roles sembrados por defecto.
3. **Alcance por asignación** obligatorio además del rol (propiedades asignadas, unidades
   propias, reserva del huésped). Fuera de alcance responde 404.
4. **Un usuario puede pertenecer a varios tenants** (tabla de membresías). Es raro pero
   posible.
5. **Huéspedes sin contraseña**: enlace mágico y código de reserva por correo.
6. **S3** con prefijo por tenant y URLs prefirmadas. Proveedor: AWS S3.
7. **ARGOS es la fuente de verdad de las reservas**, aunque vengan de otros canales.
8. **Canales**: importación iCal de Booking y Airbnb; Nexxt es un sistema de cerraduras
   inteligentes (integración en fase 6); la integración con la página web del cliente
   queda pendiente de información (se deja un endpoint público con clave API).
9. **Dos flujos de venta** confirmados (directa vs agencia/OTA).
10. **Depósitos** solo se registran (sin pasarela). Sí se necesita **pasarela de pago
    para cobrar a los tenants** (facturación de plataforma, fase 6).
11. **Fotos de DPI/pasaporte** se conservan **90 días** después del check-out y luego se
    borran automáticamente; el número se conserva.
12. **Áreas comunes**: cada admin registra las suyas; la reserva se confirma
    automáticamente si hay cupo.
13. **Parqueos** son opcionales por tenant (bandera); seguridad los consulta.
14. **Seguridad** solo ve llegadas/salidas, huéspedes activos, placas y alarmas.
15. **Asistencia** con GPS y foto opcional. **Esquemas de pago**: salario fijo, por día,
    por hora o por limpieza.
16. **Nómina**: ARGOS calcula (Bono 14, aguinaldo, IGSS) pero no es obligatorio; hay
    colaboradores fuera de planilla (`on_payroll`).
17. **ARGOS no gestiona descuentos de sueldo**; el módulo disciplinario solo registra
    llamadas de atención, suspensiones y similares.
18. **Cierre de limpieza** exige fotos finales, GPS y conciliación de inventario; las
    diferencias se registran como discrepancias.
19. **Inventario**: bodega central y bodega por propiedad.
20. **Offline**: itinerario del día en solo lectura y cola de subida de fotos.
21. **Login rápido**: refresh token largo + biometría o PIN en móvil; sesión de 30 días
    en web. **2FA (TOTP) opcional**; el tenant puede exigirlo a admins.
22. **Chat**: interno y también huésped ↔ empresa.
23. **Sin Redis.** Infraestructura solo con AWS y Google: cola de trabajos sobre
    PostgreSQL, SES para correo, FCM para push, S3 para archivos, WebSockets con
    `LISTEN/NOTIFY` para tiempo real.
24. **Mantenimiento ampliado** con catálogo de activos, preventivos, proveedores y
    documentos.
25. **Supervisores usan app y web; huéspedes solo app.**

Decisiones técnicas derivadas (detalladas en fase01.md):

* Dos entornos Alembic (`shared` y `tenant`) con schema `tenant_template` para
  autogenerar; `SET LOCAL search_path` por transacción.
* Se elimina el login local con MD5 de la app; la app autentica siempre contra el backend
  y Drift solo cachea.
* Enumeraciones como `varchar` + `CHECK` (no tipos ENUM de Postgres).
* `files` y `audit_log` son las únicas tablas de tenant en fase 1.

### 2026-10-22 — Backend migrado de Python (FastAPI) a Go

El backend se reescribió en Go antes de iniciar la fase 1, mientras el código existente
era pequeño (health, auth y tenants). Equivalencias:

| Antes (Python) | Ahora (Go) |
| --- | --- |
| FastAPI + Uvicorn | huma v2 sobre chi v5: OpenAPI 3.1 generado del código, Swagger UI en `/docs` |
| SQLAlchemy async + asyncpg | pgx v5 con SQL explícito, sin ORM |
| Alembic | Migrador propio: SQL embebido en el binario, conjuntos `shared` y `tenant`, tabla `schema_migrations` por schema |
| Pydantic | Structs con tags de validación (huma) y normalización en el servicio |
| Poetry | Go modules |
| Ruff + MyPy | golangci-lint v2 + compilador; `depguard` impide que `internal/modules` importe HTTP |
| Pytest + Testcontainers | `go test` + Testcontainers (build tag `integration`) |
| bcrypt / PyJWT | `x/crypto/bcrypt` / `golang-jwt/v5`; los hashes existentes siguen siendo válidos |
| `python -m scripts.seed_platform_admin` | `argos seed platform-admin` |

Decisiones derivadas:

* Un solo binario `argos` con subcomandos (`serve`, `migrate`, `seed`; el worker de la
  fase 1 será `argos worker`). Imagen de producción distroless de unos 16 MB.
* El alta de tenant inserta el registro, crea el schema y aplica las migraciones de
  tenant en **una sola transacción**: si algo falla no queda nada que limpiar.
* Sin autogeneración de migraciones: desaparece el schema `tenant_template`. Las
  migraciones se ordenan por número (reemplaza `down_revision`); el migrador se detiene
  si una versión queda detrás de otra ya aplicada.
* `0002_identity` (fase 1) será una migración Go para reutilizar la matriz de roles sin
  duplicarla en SQL; agregar migraciones Go al motor es tarea de la fase 1.
* Una base creada por Alembic se adopta sin cambios (`0001_initial` usa `IF NOT EXISTS`
  con los mismos nombres de tablas, índices y constraints).

Cambios de contrato respecto del backend Python:

* `POST /auth/register` exige `platform_admin`. Antes era público y aceptaba `role` en
  el cuerpo, así que cualquiera podía crearse una cuenta `platform_admin`.
* Un refresh token ya no sirve como token de acceso (antes no se validaba el claim
  `type`).
* Errores en formato RFC 9457 (`application/problem+json`): el mensaje sigue en
  `detail`; los 422 listan cada campo en `errors[]` con su `location` (antes FastAPI
  usaba `detail: [{loc, msg}]`). Los cuerpos JSON con campos desconocidos responden 422
  (antes se ignoraban).
* Slug de tenant: de 2 a 56 caracteres, empieza y termina en letra o número. Antes la
  expresión rechazaba los slugs de 2 caracteres y los de 57 a 63 fallaban con 500 por
  exceder el largo máximo de un identificador de PostgreSQL.
* `tenant_id` inexistente al registrar responde 422 (antes 500); el token de un usuario
  borrado responde 401 (antes 404).
* Configuración: `ARGOS_CORS_ORIGINS` pasa a lista separada por comas (antes JSON);
  `ARGOS_DB_POOL_SIZE` y `ARGOS_DB_MAX_OVERFLOW` se reemplazan por `ARGOS_DB_MAX_CONNS`;
  nueva `ARGOS_HTTP_PORT`. La API no arranca si `shared` tiene migraciones pendientes.

## Decisiones pendientes

| Tema | Qué falta | Fase que lo necesita | Propuesta |
| --- | --- | --- | --- |
| Pasarela de pago para tenants | Elegir proveedor que opere en Guatemala | 6 | Evaluar Recurrente (GT), PayPal y Stripe vía entidad extranjera; diseñar contra la interfaz `PaymentProvider` para no bloquear |
| Hosting | Definir despliegue (ECS/Fargate vs EC2, RDS, dominio, certificados) | 1 (staging) | ECS Fargate + RDS PostgreSQL + S3 + SES en una sola región |
| Página web del cliente | Tecnología del sitio y cómo envía reservas | 4/6 | Endpoint `POST /public/reservations` con clave API; pedir al cliente acceso al sitio |
| Nexxt | Acceso a API o SDK del fabricante | 6 | Pedir al cliente el modelo exacto de cerradura y cuenta de desarrollador |
| Entorno S3 local | LocalStack vs MinIO en docker-compose | 1 | LocalStack (cubre S3 y SES) |
| Horas por defecto de check-in/check-out y anticipación de alarma | Confirmar con el cliente | 4 | 15:00 / 11:00, alarma 30 min antes y a la hora |

## Realizado

### 2026-09-15
* Reescrito el PRD a v2 con todos los módulos, roles, catálogo de permisos y matriz por
  rol.
* Creados los planes fase01 a fase06 y este documento.
* Creado [base-de-datos.md](base-de-datos.md): vista consolidada del modelo (schemas,
  tablas por módulo, qué migración crea cada una, diagrama de relaciones, reglas de
  aislamiento, retención, índices y semillas).
* Creado [ux-ui.md](ux-ui.md): sistema visual (tokens existentes más los nuevos de
  estado), inventario de componentes por capa y fase, patrones transversales, navegación
  por rol, flujos críticos, ficha de cada pantalla de app y web, notificaciones y
  correos, lista de verificación y mapa pantalla ↔ fase.

* Creado [reparto.md](reparto.md): división del trabajo entre Persona A (núcleo del
  backend, módulos administrativos y web) y Persona B (app, design system y módulos de
  campo del backend), con mapa de propiedad de archivos, reglas de trabajo en paralelo,
  reparto por fase con hitos de integración y numeración fija de migraciones.
* Las migraciones de tenant se renumeraron para que cada persona tenga las suyas
  (0002 a 0010; ver tabla en base-de-datos.md §2). Los fase0N.md quedaron actualizados.

Decisiones de diseño tomadas al escribir ux-ui.md:
* Se mantienen la paleta teal/dorado y la tipografía EB Garamond + Verdana. Se agregan
  tokens semánticos de estado (`warning`, fondos `*Soft`, `overlay`, `offline`).
* El cuerpo de texto en app sube de 14 a 16 px.
* Modo oscuro fuera de esta versión; los tokens quedan semánticos para añadirlo después.
* Iconos Material Symbols Rounded en ambas plataformas con el mismo catálogo de nombres.
* Lo que el rol no puede hacer no se muestra; solo se deshabilita lo bloqueado por estado.

### 2026-10-22
* Backend reescrito en Go (ver la decisión del mismo día). Pruebas unitarias y de
  integración con Testcontainers pasan con `-race`; golangci-lint sin observaciones.
* Verificado sobre una base creada con la migración Alembic original y datos del backend
  Python: `argos migrate up` la adopta sin cambios de DDL y los usuarios existentes
  inician sesión con sus contraseñas.
* Planes actualizados para Go: PRD (tabla de piezas); fase01 §2, §3.1, §3.2, §3.4,
  §3.6, §3.8, §3.9, §3.10 y §3.11; fase02 (orden de migraciones); fase03 §4; fase04
  (iCal); fase05 (Excel y PDF); base-de-datos.md; reparto.md (mapa de archivos y orden de
  migraciones).

### 2026-11-19
* [A] Portal web, primera versión funcional contra mocks (`WEB/`, rama `dev/sebas`). Cuatro
  pantallas: acceso (W-A1 con 2FA, W-A2 elegir empresa, W-A3 recuperar contraseña), inicio
  (W-B1), propiedades (W-C1 con detalle en panel lateral y alta) y colaboradores (W-D1 + W-O2:
  roles, suspender, cerrar sesiones, invitaciones). Shell con sidebar por permisos y banderas,
  topbar con cambio de empresa, `permissionGuard`, `*argosCan`, interceptor con refresh único,
  toasts con deshacer y diálogos de confirmación. Secciones de fases siguientes visibles como
  "Pronto". 11 pruebas unitarias (menú por rol, flujo de acceso 401/428/selección).
* [A] Investigación de referencias (Apple HIG y apple.com, tokens de airbnb.com, guías de One
  UI) documentada en `WEB/docs/DISENO.md`. Tokens nuevos en la web: estados `*Soft`,
  `warning`, `overlay`, elevación en capas, duraciones y resortes propios como CSS `linear()`.
  Se mantienen paleta y tipografías.
* [A] Corregido en la web: `angular.json` no tenía `fileReplacements` para development, así que
  `npm start` usaba siempre `environment.ts` de producción.

Decisiones (web):
* Los `*-api.service.ts` son clases abstractas con implementación HTTP y mock; el token
  `USE_MOCKS` (true en development) elige cuál. El mock persiste en `localStorage`.
* Las tiendas de pantalla se proveen en el componente, no en la ruta (los providers de ruta
  no se destruyen al salir). Al cambiar de empresa se recrea la página activa.
* Mientras no haya fotos en S3, las propiedades usan una portada ilustrada generada por código.

Contratos que la web asume y que faltan en los fase0N.md (revisar al construir el backend):
* `GET /dashboard` (agregado de W-B1; forma en `WEB/src/app/features/dashboard/models`) y
  `POST /alerts/{id}/acknowledge` · `/reopen` (fase 3).
* `GET /properties` incluye campos agregados para W-C1: `today_status`, `open_incidents`,
  `last_cleaning_at`, `assigned[]`, `owners[]`, `has_access_info`, `zone`; y acepta
  `fields=id,code,name` para selectores.
* `GET /tenants/{id}/invitations?status=pending`, `POST .../invitations/{id}/resend`,
  `DELETE .../invitations/{id}`, `POST .../members/{id}/reactivate` y
  `DELETE .../members/{id}/sessions` (revocar sesiones de un colaborador, PRD §4.2).
* Reglas de negocio que el mock ya aplica: no suspender la propia cuenta, debe quedar al menos
  un administrador activo, 422 con `errors[].location = body.email` si el correo ya es
  miembro o tiene invitación pendiente, 422 en `body.code` si el código de propiedad existe.
* [A] La web se levanta con Docker (`WEB/docker-compose.yml`): servicio `web` con `ng serve` y
  recarga en caliente en el puerto 4200, y perfil `demo` con build optimizado en nginx (4280).
  Ambos usan mocks; no requieren el backend.
* [A] Web: sitio público en `/` (antes del login) que presenta ARGOS como plataforma
  multiempresa, con fotografía real (Antigua, Atitlán, interiores y equipos trabajando), una
  captura real del panel y piezas de la interfaz: hero, operación, panel, multiempresa,
  seguridad, "Por qué ARGOS" y "Solicitar demo". Las fotos son de Unsplash y Wikimedia
  Commons (créditos en el pie); hay que reemplazarlas por fotos propias antes de producción.
* [A] Logotipo oficial: una casa trazada con la greca griega en un solo trazo (Argos, el
  guardián de la mitología griega). SVG en `WEB/public/brand/` (incluye ícono de app);
  concepto en `WEB/docs/DISENO.md`. Pendiente para la app (B): reemplazar `ArgosLogo`
  (anillo y punto) por este símbolo.
* [A] Login rediseñado: formulario a la izquierda y fotos de propiedades a la derecha, cada una
  con su estado en ARGOS; enlaces a la landing y a "Solicitar demo".
* [A] Botones y controles de la web con radios más rectos (8 px; tarjetas 12 px).
* [A] Contrato nuevo que asume la web: `POST /public/demo-requests` (público, sin sesión;
  `full_name`, `company`, `email`, `phone`, `properties`). Necesita limitación de frecuencia.
* [A] Backend fase 1, núcleo de identidad: migraciones `shared/0002_identity` (tenants y
  users ampliados, roles, role_permissions, memberships, refresh_tokens, one_time_tokens,
  invitations, device_tokens, jobs, platform_audit_log; migra los datos existentes) y
  `tenant/0001_tenant_base` (files, audit_log). Módulo `authz` (catálogo de permisos y
  matriz de 7 roles del PRD; `migrate up` la sincroniza en todos los tenants). `auth` con el
  contrato §3.7.1: login multiempresa, select-tenant, refresh rotativo con detección de
  reutilización, logout, `/me`, bloqueo 429 por intentos y 202 en forgot. Guard con
  `RequirePermission` y `RequirePlatformAdmin`; tenants pasan a `/platform/tenants` y el alta
  siembra los roles. `argos seed demo-tenant`. Pruebas de integración de §3.10 (casos 3, 4,
  7, 8 y 9) en verde contra PostgreSQL real.
* [A] Diferencia con el plan: `refresh_tokens.tenant_id` (empresa activa de la sesión).
  Documentado en fase01.md §3.3.
* [A] Pendiente de fase 1 en backend: alta y verificación TOTP (hoy una cuenta con TOTP
  recibe 428 y no puede entrar), invitaciones, `/auth/sessions`, cambio y restablecimiento
  de contraseña con correo, S3, cola de trabajos y `platform_audit_log` al dar de alta.
* [A] Docker: `WEB/docker-compose.yml` incluye `BACKEND/docker-compose.yml`; `npm run
  docker:up` levanta web + API + PostgreSQL + migraciones + `seed`. La web usa la API real
  para el acceso y mocks por módulo para lo que aún no existe (aviso "Simulado" en pantalla).
* [A] Web: la landing pasa a Plus Jakarta Sans (las referencias usan una sola sans), fondos
  por sección (crema, blanco y bloque teal) con curvas de nivel como textura, foto del hero
  en arco, 14 ilustraciones propias en lugar de íconos de línea y retratos ilustrados
  generados por nombre en lugar de iniciales (en toda la web). El login y el panel conservan
  EB Garamond + Verdana.
* [A] Web (21-11): Plus Jakarta Sans en toda la web (también acceso y panel; la app sigue en
  EB Garamond + Verdana). Avatares con DiceBear · Notionists (CC0) cargados aparte del bundle
  inicial. Logos de empresa (`app-tenant-mark`) en "Elige una empresa", la barra superior y la
  landing: logos inventados para las empresas del seed mientras la API no tenga logos (S3) y,
  sin logo, una marca abstracta generada (nunca iniciales). Ilustraciones propias también en
  las tarjetas de tarea y del acceso, y cabecera de la landing blanca con filete.
* [A] Web (21-11): todas las pantallas del portal de las fases 2 a 5 construidas contra mocks
  (proceso del skill `argos-redesign`: referencias de Guesty, Breezeway, Linear, Stripe y
  Hospitable; capturas a 1440 y 390 px). Itinerario (W-E1–E4: semana por persona o
  propiedad con arrastrar para reasignar/reprogramar con motivo, tablero del día, ficha y
  alta de tarea), Inventario (W-F1–F6), Mantenimiento (W-G1–G5: tablero por estado,
  activos, calendario de preventivos, proveedores e indicadores), Reservas (W-H1–H6:
  calendario de ocupación con barras por canal, lista, ficha, alta con validación de
  solapamiento, huéspedes, canales e iCal), Áreas comunes (W-I2), Parqueos (W-I1),
  RRHH (W-J1–J5: asistencia del mes, nómina con planilla editable en revisión, disciplina y
  configuración), Métricas (W-K1–K2), Alertas (W-L1), Bitácora (W-N1) y Configuración
  (W-O1, W-O3 con matriz de permisos, W-O4). Se retiró la pantalla "Próximamente".
* [A] Cada módulo tiene su `*-api.service.ts` (contrato HTTP de su fase) y su mock con aviso
  "Simulado"; cambiar a la API real es poner su bandera en `false` en `MOCK_MODULES`. Los
  mocks se derivan de las mismas propiedades y personas del seed para que los módulos
  cuenten la misma historia.
* [A] Pendiente en web: fichas completas W-C2 (propiedad) y W-D2 (colaborador), W-C3
  edificios, W-C4 plantillas de checklist, W-M1 chat, W-P1–P4 plataforma e importación CSV de
  artículos. La facturación (W-O4) muestra datos de muestra hasta la fase 6.

### 2026-11-21

* [B] Entorno de desarrollo de la app en Windows: Flutter 3.35.7 (la 3.50 no es compatible con Gradle 8.12 / AGP 8.9.1 del proyecto) y JDK 17 (el Java 25 de Android Studio no sirve para Gradle 8.12). Guía en [`../DESARROLLO.md`](../DESARROLLO.md).
* [B] `.vscode/launch.json` con dos configuraciones (datos de prueba con `ARGOS_MOCK=true` y backend local) y `usesCleartextTraffic` solo en el manifest de debug para hablar con el backend local por http desde el emulador.
* [B] Pendiente: 4 pruebas fallan con `flutter test` (3 del flujo de login en `test/widget_test.dart` y 1 de `test/itinerary_page_test.dart` que depende de la fecha).
