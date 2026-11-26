# ARGOS — Avance y decisiones

Bitácora del proyecto. Se anota aquí toda decisión (con fecha) y todo lo realizado, en
orden cronológico. El PRD vigente es [`../ARGOS PRD.md`](../ARGOS%20PRD.md) v2; los
planes por fase están en esta carpeta.

## Estado por fase

| Fase | Documento | Estado | Notas |
| --- | --- | --- | --- |
| 1 | [fase01.md](fase01.md) | En curso | Backend y web hechos (2026-11-21); falta la app de B y dos pendientes de A |
| 2 | [fase02.md](fase02.md) | En curso | Parte de A hecha (2026-11-21); faltan tareas e inventario de B |
| 3 | [fase03.md](fase03.md) | En curso | Parte de A hecha (2026-11-22); faltan notificaciones y la app de B |
| 4 | [fase04.md](fase04.md) | En curso | Parte de A hecha (2026-11-22); faltan acceso de huéspedes, seguridad, parqueos, áreas comunes y la app de B |
| 5 | [fase05.md](fase05.md) | En curso | Parte de A hecha (2026-11-23): nómina y disciplina; faltan asistencia, métricas, incentivos y la app de B |
| 6 | [fase06.md](fase06.md) | En curso | Parte de A hecha (2026-11-23): facturación, claves API, reservas del sitio, aislamiento, límites, OpenAPI; faltan chat, cerraduras, retención y la app de B |

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
| Pasarela de pago para tenants | Elegir proveedor que opere en Guatemala | 6 | Evaluar Recurrente (GT), PayPal y Stripe vía entidad extranjera. Ya existe la interfaz `billing.Provider` con `FakeProvider` (fase06 §3.4): el proveedor real es un archivo más y `ARGOS_BILLING_PROVIDER` |
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
* [B] Pruebas en verde (63 de la app y 9 del design system). EB Garamond empaquetada en `packages/design_system/assets/fonts` (OFL): la app ya no descarga fuentes.
* [B] Design system de fases 1 y 2 completo: NumberStepper, AppCheckbox (32 dp), PhotoThumb, SearchField, FilterChips, PhotoGrid, ChecklistItemRow, BeforeAfterPair, QuantityRow, TimelineItem y DetailScaffold (+ DetailBanner). Catálogo para verlos en Perfil › "Catálogo de componentes" (solo con `ARGOS_MOCK` o en depuración).
* [B] Cámara integrada (B5): obturador de 72 dp, flash, cambio de cámara, miniaturas y guía "antes". Fotos a 1600 px, JPEG 80, marca de agua con fecha, hora y código de propiedad.
* [B] Cola `pending_uploads` (Drift v3) con presign → subida → confirm (fase01 §3.8), reintento con espera creciente (15 s a 30 min), y rutas simuladas de `/files`. Por ahora sube con la app abierta; falta decidir el trabajo en segundo plano (`workmanager`) por la rotación del refresh token.
* [B] Contrato de auth revisado contra `internal/api/v1/auth.go`: coincide; se corrigió `device.name` (ya no se manda `null`).
* [B] Para A: la app acepta en `presign-upload` tanto `{file_id, upload_url, method: "PUT", headers}` como un POST prefirmado de S3 con `fields`. Falta en el backend: `/files/*`, `/auth/sessions`, `/auth/password/change` e invitaciones (la app los usa del mock).
* [B] Logo oficial (casa con greca, mismo trazo que `ARGOS-WEB/public/brand`) en `ArgosLogo`, la pantalla de acceso, el ícono adaptativo de Android y la pantalla de arranque. La app se llama "ARGOS" en el teléfono.
* [B] B1 "Hoy" con datos simulados: resumen en la cabecera, semana, filtros, TaskCard por tarea (la en progreso arriba con acento), deslizar para actualizar, estado vacío y copia sin conexión (tabla `api_cache`, Drift v4). Tocar una tarea abre una primera versión de B3 con DetailScaffold. Contrato supuesto: `GET /tasks?date=` → `{items: [...]}` con `property {id, code, name, address}` y `checklist {done, total}` (para A). La tarjeta de asistencia queda para la fase 5.
* [B] Pendiente por decidir: subida de fotos en segundo plano con `workmanager` (riesgo de rotación del refresh token).


### 2026-11-21
* [A] **Fase 1 completa en backend y web** (rama `dev/sebas`). A partir de aquí se avanza
  por fases entregando cada función completa (API real + web conectada), no pantallas con
  datos simulados. La app sigue siendo de B; los contratos que puede reusar están en
  fase01.md §3.7.2.
* [A] Backend: 2FA por TOTP (alta con QR, confirmación, desactivación; secreto cifrado con
  AES-256-GCM, sin dependencias nuevas), sesiones por dispositivo (listar, cerrar una,
  cerrar las demás), cambio y restablecimiento de contraseña con correo, perfil
  (`PATCH /auth/me`), invitaciones (crear, listar, reenviar, cancelar, ver y aceptar con
  cuenta nueva o existente), miembros (cambiar rol, suspender, reactivar, cerrar sesiones),
  roles personalizados, configuración de la empresa con logo, archivos en S3 (subida
  prefirmada, confirmación con HEAD, descarga firmada, limpieza), cola de trabajos
  (`argos worker`: SKIP LOCKED, LISTEN, reintentos 1-16 min, huérfanos, recurrentes,
  payload borrado en correos), correo con plantillas (SES o log + `tmp/mail`), bitácora de
  empresa y de plataforma, y consola de plataforma (alta de empresa con administración por
  membresía o invitación, módulos, suspender/reactivar, bitácora).
* [A] Pruebas: §3.10 casos 1, 2, 3 (también con roles personalizados) y 5 nuevos, más
  flujos de invitación, contraseña, 2FA, sesiones, miembros, roles, archivos, configuración,
  plataforma y cola de trabajos. Todo en verde contra PostgreSQL real; golangci-lint sin
  observaciones.
* [A] Docker: servicios `worker` y `rustfs` (emulador S3) en `BACKEND/docker-compose.yml`.
  Detalle y variables nuevas en fase01.md §3.9.
* [A] Web conectada a la API real en Acceso (W-A1 a W-A5: login con 2FA real, elegir
  empresa o "Administración ARGOS", recuperar, restablecer y aceptar invitación), Mi perfil
  (datos, contraseña, 2FA con QR, sesiones), Colaboradores (W-D1 + W-O2), Configuración
  (W-O1 con logo en S3, W-O3 con roles personalizados) y Plataforma (W-P1 empresas, W-P4
  bitácora). La facturación (W-O4) sigue con datos de muestra hasta la fase 6
  (bandera `billing`).
* [A] Dependencias nuevas aprobadas: AWS SDK for Go v2 (s3, sesv2, config) y `qrcode`
  (npm, QR del 2FA).

Decisiones (2026-11-21):
* Los siete roles de sistema son de solo lectura en cada empresa; se ajustan permisos con
  roles personalizados (p. ej. duplicando uno). Motivo: `migrate up` sincroniza la matriz
  del PRD y sobrescribiría los cambios de una empresa.
* Nadie da un permiso que no tiene (al invitar, cambiar rol o editar un rol), salvo los de
  alcance propio (`*.own`).
* Las banderas de módulos son de solo lectura para la empresa; las cambia la plataforma.
* S3 local: RustFS (resuelve la decisión pendiente "LocalStack vs MinIO"). SES no se
  emula en local.
* Subida de archivos por PUT prefirmado con tipo y tamaño firmados (en vez de POST con
  política).

Para B (app), lo que ya puede consumir contra el backend real (fase01.md §3.7.2):
* `PATCH /auth/me`, `GET/DELETE /auth/sessions`, `POST /auth/password/change`,
  `POST /auth/password/forgot`, `POST /auth/totp/setup|confirm|disable`.
* `GET /auth/invitations/{token}` y `POST /auth/invitations/accept` (deep link
  `argos://invite?token=`; el correo hoy enlaza a la web `/invitacion?token=`).
* `POST /files/presign-upload`, `PUT` a S3, `POST /files/{id}/confirm`,
  `GET /files/{id}/url` (cada fase registra sus tipos de archivo).
* Login: `platform_admin` en la respuesta y `select-tenant` con `platform: true` (la app
  no tiene consola de plataforma; puede ignorarlo).

Pendiente de A en fase 1: exigir 2FA por rol (`require_2fa_roles`), marcar inactivo un
tenant con migraciones pendientes y agregar las reglas de §3.6 a
`BACKEND/docs/ARCHITECTURE.md`.

* [A] **Fase 2, parte de A, completa en backend y web** (rama `dev/sebas`). Migraciones
  `shared/0003_role_scope` (`roles.scoped`) y `tenant/0002_properties`. Módulos `properties`
  (propiedades, edificios, acceso cifrado con AES-256-GCM y consulta en bitácora, propietarios y
  asignados por propiedad o por persona, portada en S3), `checklists`, `employees` (ficha laboral y
  horario), lectura de la bitácora (`GET /audit` con cursor), `ScopeResolver`
  (`authz.ResolvePropertyScope`) y `sync` (`GET /sync/bootstrap`). Las invitaciones con
  `property_ids` ahora crean las asignaciones al aceptarse y Colaboradores cuenta las propiedades
  reales de cada persona. Utilidades de núcleo para B: `core/paging` (cursor) y `core/optional`
  (PATCH con null). Contrato completo en fase02.md §4.1.
* [A] Pruebas de integración de la fase 2 en verde contra PostgreSQL real: alcance por rol (limpieza
  solo ve lo asignado y recibe 404 por id; el propietario solo lo suyo; seguridad y supervisión todo;
  otra empresa nada), acceso cifrado en la base y registrado al consultarlo, ciclo de vida de la
  propiedad con paginación, asignaciones e invitación con propiedades, rol personalizado con alcance,
  plantillas, fichas laborales (sin valores de documentos en la bitácora), páginas de la bitácora y
  bootstrap con alcance. golangci-lint sin observaciones.
* [A] Seed: edificios, 17 propiedades, 2 plantillas, asignaciones y 7 fichas laborales en Garrent y
  Costa Limpia (las mismas propiedades que contaba el mock de la web), con personas nuevas para ver el
  alcance: Diego Castillo (mantenimiento), Isabel Monzón (propietaria), Pedro Ajú y Rosa Xol
  (limpieza en Costa Limpia).
* [A] Web conectada a la API real: Propiedades (W-C1) con pestañas Edificios (W-C3) y Checklists (W-C4,
  editor con secciones que se arrastran y vista previa como en la app), ficha de propiedad (W-C2,
  `/propiedades/CODIGO`: datos, acceso con quién lo consultó, checklist, asignados, propietarios e
  historial, foto de portada), ficha de colaborador (W-D2 sin RRHH, `/colaboradores/:id`: perfil,
  laboral, horario y propiedades), Bitácora (W-N1) y alcance de roles personalizados en W-O3.
  Inicio, Itinerario e Inventario siguen simulados hasta las APIs de tareas e inventario (B).

Decisiones (2026-11-21, fase 2):
* El alcance es un atributo del rol (`roles.scoped`), no se deduce de permisos: así un rol
  personalizado duplicado de limpieza sigue viendo solo lo asignado. Los roles de sistema lo toman de
  la matriz en código. Requirió `shared/0003_role_scope`; la facturación pasa a `shared/0004_billing`
  (reparto.md §5 actualizado; B nunca crea migraciones shared).
* Limpieza y mantenimiento ven la información de acceso solo con tarea del día: el módulo de tareas de
  B registra esa regla con `properties.Service.SetAccessGate`. Hasta entonces reciben 403.
* Diferencias con el plan en `0002_properties`: `zone` en edificios y propiedades,
  `cover_file_id` (foto de portada) y `access_info_updated_at`; el código es único entre propiedades no
  borradas. Leer plantillas pide `properties.read` (la app las necesita sin conexión).
* Los mocks de propiedades y bitácora se conservan con el contrato nuevo solo para el modo demo
  (`npm run docker:demo`); en desarrollo ya no se usan.

Para B (app y módulos `tasks`/`inventory`), lo que ya puede consumir o usar (fase02.md §4.1):
* `GET /sync/bootstrap`, `GET /properties` (+ `/{id}`), `GET /properties/{id}/access-info`,
  `GET /buildings`, `GET /checklist-templates`, `PUT /properties/{id}/assignments`, `GET /audit`.
* Enganches: `authz.ResolvePropertyScope`, `properties.Service.SetAccessGate`, `audit.Record` con
  `PropertyID`, `core/paging`, `core/optional`, `files.Rules` (agregar `tasks/before|after|evidence`).
* `tenant/0003_tasks_inventory` ya puede generarse sobre `0002_properties`.

### 2026-11-22
* [A] **Fase 3, parte de A, completa en backend y web** (rama `dev/sebas`). Migración
  `tenant/0004_maintenance` (proveedores, activos, preventivos, incidencias con línea de tiempo y
  alertas). Módulos `maintenance` (proveedores, activos con documentos en S3, preventivos, incidencias
  con folio, fotos, asignación, inicio, resolución con costo, cierre, rechazo y reapertura,
  indicadores), `alerts` (levantar sin duplicar, reconocer, resolver a mano o sola, contadores por
  tipo) y `dashboard` (`GET /dashboard` para el Inicio). Bus de eventos de núcleo
  (`internal/core/events`) y trabajos `maintenance_due` y `low_stock`, cada hora y por empresa con la
  hora de su zona. El bootstrap de la app suma los activos del alcance. Contrato en fase03.md §5.1.
* [A] Pruebas de integración de la fase 3 en verde contra PostgreSQL real: alcance de incidencias por
  rol (404 fuera de alcance, también al reportar), ciclo completo de una incidencia con eventos y
  bitácora, alerta de falla de activo que se levanta y se resuelve sola, preventivo que genera su
  incidencia y su alerta de vencido y avanza al resolverse, `low_stock` con tablas mínimas de
  inventario, documentos de activos e indicadores con el Inicio. golangci-lint sin observaciones.
* [A] Seed: 5 proveedores, 12 activos, 7 preventivos y 12 incidencias en Garrent (con seis meses de
  historial para los indicadores) y 2, 3, 2 y 3 en Costa Limpia.
* [A] Web conectada a la API real: Mantenimiento con Incidencias (W-G1, tablero por estado y tabla,
  ficha con asignar, iniciar, resolver con fotos y costo, cerrar, rechazar y reabrir), Activos (W-G2,
  ficha con documentos, preventivos e incidencias), Preventivos (W-G3, calendario y "lo que toca"),
  Proveedores (W-G4) e Indicadores (W-G5); Alertas (W-L1) e Inicio (W-B1) con alertas, incidencias,
  preventivos, mapa y actividad reales. Limpiezas, cumplimiento, ranking y llegadas del Inicio se
  marcan "Muestra" hasta que existan tareas y reservas. La campana abre la bandeja de notificaciones
  con datos simulados (bandera `notifications`) hasta que B publique su API.

Decisiones (2026-11-22, fase 3):
* `maintenance_tickets.property_id` es opcional y hay `building_id`: el preventivo de un elevador es
  del edificio, no de una propiedad. Lo ven quienes tengan alguna propiedad de ese edificio.
* Reportar sobre una propiedad fuera de alcance responde 404 (no 422), como pide fase03 §8.
* Los trabajos corren cada hora en vez de una vez al día: así "hoy" es el de la zona de cada empresa y
  un reinicio no se salta el día. Son idempotentes (índice único de incidencia abierta por preventivo y
  de alerta abierta por causa).
* Los eventos de dominio son síncronos y corren dentro de la transacción del cambio: un suscriptor solo
  debe encolar trabajos. Sin Redis ni colas externas.
* `low_stock` agrupa por artículo (una alerta con sus bodegas bajo mínimo) para no llenar el panel.
* Un mes sin incidencias resueltas no se dibuja como "0 horas" en el indicador de resolución.

Para B (app y módulos `tasks`, `inventory`, `notifications`), lo que ya puede consumir o usar
(fase03.md §5.1):
* App: `POST /tickets` (con fotos `maintenance/ticket_photo`), `GET /tickets?mine=true`,
  `GET /tickets/{id}`, `POST /tickets/{id}/start` y `/resolve` (fotos `maintenance/ticket_resolution`),
  `GET /assets?property_id=`, `GET /alerts` y `/alerts/summary` (badge), y `assets[]` en
  `GET /sync/bootstrap`.
* Enganches: `maintenance.Service.SetTaskLinker` (crear la tarea al asignar) y `ResolveFromTask` (cerrar
  la incidencia al cerrar la tarea), `alerts.Service.Raise` y `alerts.ResolveFor` (`task_late`,
  `discrepancy_open`, `checkout_alarm_unattended`), `dashboard.Service.SetTasksSource` (Inicio) y
  `events.Bus.Subscribe` con `ticket.created`, `ticket.assigned`, `ticket.resolved`, `maintenance.due` y
  `alert.raised` para notificar.
* La web ya consume `GET /notifications?limit=30`, `POST /notifications/{id}/read` y
  `POST /notifications/read-all`, y navega a `data.route` (fase03.md §5.1). Con ese contrato basta
  apagar el mock `notifications`.
* `low_stock` ya lee `inventory_items`, `inventory_stock` y `warehouses` tal como están en fase02 §2.
* [A] **Fase 4, parte de A, completa en backend y web** (rama `dev/sebas`). Migraciones
  `shared/0004_btree_gist` y `tenant/0006_reservations` (canales, calendarios iCal, huéspedes,
  reservas con `EXCLUDE` que impide cruces, huéspedes por reserva, línea de tiempo, movimientos de
  depósito, inspecciones y hallazgos). Módulo `reservations` con canales, iCal (parser propio en
  `internal/core/ical`, a prueba de SSRF), reservas y su ciclo (confirmar, cancelar, no llegó,
  check-in, check-out, reenviar), directorio de huéspedes con lista negra, fotos del documento
  privadas (solo `guests.documents`, con bitácora), depósito con sus reglas e inspecciones con
  hallazgos que abren incidencias en Mantenimiento. Trabajos `ical_sync` (30 min),
  `reservation_status` y `retention_cleanup` (cada hora) y `reservation_reminder` (víspera, 18:00 de
  la empresa). Correos de confirmación, recordatorio, cancelación y depósito. Eventos
  `reservation.confirmed`, `.updated`, `.cancelled`, `.checked_in` y `.checked_out`. El Inicio toma
  llegadas, salidas y estancias de la API. Contrato en fase04.md §4.1.
* [A] Pruebas de integración de la fase 4 en verde contra PostgreSQL real: ciclo de una reserva
  directa (registro, depósito, check-in, check-out, inspección, retención y devolución), alcance por
  propiedad y de seguridad, documentos privados y su retención a los 90 días, sincronización iCal
  (alta, cambio, cancelación por desaparecer, cruces reportados, fechas editadas a mano que el iCal
  ya no mueve), estados automáticos y el Inicio, cancelación, no llegó y confirmación. golangci-lint
  sin observaciones.
* [A] Seed: 18 huéspedes (uno en lista negra) y 18 reservas en todos los estados en Garrent, con 5
  calendarios iCal locales (uno apunta a un 404 a propósito), y 4 huéspedes, 5 reservas y 1
  calendario en Costa Limpia. En local la API sirve calendarios de prueba en `/dev/ical/{archivo}`
  (`ARGOS_SEED_ICAL_BASE` cambia la base).
* [A] Web conectada a la API real: Reservas con calendario de ocupación (W-H1, arrastrar para crear),
  lista (W-H2), ficha con huéspedes y registro del documento, depósito, inspecciones y línea de
  tiempo (W-H3), alta y edición con aviso de cruce en vivo (W-H4), directorio de huéspedes con lista
  negra (W-H5) y canales con calendarios iCal (W-H6). Parqueos (W-I1) y áreas comunes (W-I2) siguen
  con datos simulados hasta que B publique su API. Flujos recorridos en el navegador contra la API.
* [A] Navegación: el sidebar fijo pasa a ser un panel flotante que sale del botón de menú de la
  topbar (se asoma al pasar el cursor en escritorio y se fija con un clic); el contenido usa el
  100 % del ancho. Lo pidió Persona A.
* [A] Botones: la acción principal pasa de dorado (`#c5873c`, texto blanco 3.0:1, no cumplía WCAG AA)
  a terracota (`--color-action: #b5582a`, 4.8:1) y los secundarios a teal lavado con texto teal, para
  que haya un solo color sólido por pantalla. Los enlaces de acción usan el mismo terracota. El dorado
  queda como acento de marca. Propuesta evaluada en tablero de comparación; pendiente de que
  Persona A la confirme.

Decisiones (2026-11-22, fase 4):
* `btree_gist` vive en `shared` (`shared/0004_btree_gist`), así el `EXCLUDE` funciona en cada schema
  de empresa con `search_path = tenant_x, shared`. La facturación de fase 6 pasa a `shared/0005_billing`.
* El documento del huésped es opcional al crear; se exige en el registro previo al check-in.
* Una reserva creada con huésped queda confirmada; sin huésped, por confirmar (como dice §3).
* En canales sin check-in formal (Booking.com, Airbnb), la entrada y la salida pasan solas a su hora.
* Cambiar a mano las fechas de una reserva importada las marca en `manual_fields`; el iCal ya no las
  mueve. Si un evento iCal se cruza con una reserva de ARGOS, no se importa y se reporta en
  `last_error` del calendario.
* `GET /files/{id}/url` rechaza las fotos del documento: solo salen por
  `GET /guests/{id}/documents/{file_id}/url`, que exige `guests.documents` y deja bitácora.
* Un huésped nuevo dentro de una reserva con un documento que ya existe reutiliza al existente.

Para B (app y módulos de acceso de huéspedes, seguridad, parqueos y áreas comunes), lo que ya puede
consumir o usar (fase04.md §4.1):
* App (supervisor y seguridad): `GET /reservations/today`, `GET /reservations?from&to`,
  `GET /reservations/{id}`, `POST /reservations/{id}/check-in` y `/check-out`, registro de huéspedes
  (`POST /reservations/{id}/guests`, `PATCH /guests/{id}`, fotos `guests/id_front` e `id_back` +
  `POST /guests/{id}/documents`), depósito (`POST /reservations/{id}/deposit/transactions`) e
  inspecciones (`POST /reservations/{id}/inspections` con fotos `reservations/inspection_photo`,
  `POST /inspections/{id}/findings`).
* Enganches: `reservations.Service.SetGuestAccess` (enlace y código en el correo de confirmación) y
  `events.Bus.Subscribe` con `reservation.confirmed`, `.updated`, `.cancelled`, `.checked_in` y
  `.checked_out` para la tarea de limpieza, las alarmas de seguridad y las notificaciones.
* `maintenance_tickets.reported_by_guest_id` ya existe para `POST /guest/tickets`.
* La web ya tiene Parqueos y Áreas comunes con mocks; con los contratos de fase04 §4 basta apagar
  `parking` y `sharedAreas` en `MOCK_MODULES`.

### 2026-11-23

* [A] **Fase 5, parte de A, completa en backend y web** (rama `dev/sebas`). Migración
  `tenant/0008_payroll` (configuración, períodos con `EXCLUDE` que impide cruces del mismo tipo,
  líneas con foto del colaborador e historial de correcciones, acciones disciplinarias). Módulo
  `payroll`: períodos quincenales o mensuales, cálculo por esquema (fijo, por día, por hora, por
  limpieza), bonificación incentivo, IGSS, Bono 14 y aguinaldo proporcionales, revisión con
  corrección por celda, cierre que guarda Excel y boletas en S3, manda la boleta por correo y
  publica `payroll.closed`. Módulo `disciplinary`: llamadas de atención, amonestaciones y
  suspensiones con adjuntos, correo al colaborador y acuse. Excel y PDF con generadores propios
  (`internal/core/xlsx` y `internal/core/pdf`), sin dependencias nuevas. Contrato en fase05.md §4.1.
* [A] Pruebas de integración de la fase 5 en verde contra PostgreSQL real: ciclo completo de un
  período (crear, calcular, revisar, corregir, cerrar, descargas, 409 al tocar uno cerrado),
  Bono 14 y aguinaldo con ingreso a mitad de año, configuración y disciplina (alta con adjunto,
  acuse una sola vez, 404 en ajenas). Pruebas unitarias del cálculo, del Excel y del PDF.
  golangci-lint sin observaciones. La suite completa se corre con `go test -p 1 -tags integration
  ./...` (los paquetes comparten la base de pruebas).
* [A] Corregido en reservas y mantenimiento: los filtros con lista vacía usaban
  `cardinality(NULL)`, que es NULL, y dejaban pasar duplicados (el seed fallaba al repetirse).
  CORS expone `Content-Disposition` para que las descargas lleguen con su nombre.
* [A] Seed: Garrent tiene la bandera `payroll`, tres quincenas cerradas (oct y nov) con
  correcciones de ejemplo, una abierta en borrador y tres acciones disciplinarias (una con acuse).
* [A] Web conectada a la API real: RRHH con pestañas Nómina (períodos, planilla editable en
  revisión, ficha de la línea con explicación del Bono 14 o aguinaldo e historial, descargas),
  Disciplina (alta con adjuntos, pendientes de acuse) y Configuración de nómina (W-J2 a W-J5). La
  ficha del colaborador suma las pestañas Nómina y Disciplina (W-D2). Asistencia (W-J1) y Métricas
  (W-K1–K2) siguen con datos simulados (bandera `attendance` y `metrics` en `MOCK_MODULES`) hasta que
  B publique su API. Flujos recorridos en el navegador contra la API.

Decisiones (2026-11-23, fase 5):
* Bono 14 y aguinaldo = salario diario × días contratados en la ventana ÷ 365 × 12. El salario diario
  sale de lo devengado en períodos cerrados en ARGOS; sin historial se usa el salario mensual actual.
  Se pagan en el período que toca los días 1–15 de julio o diciembre (configurable), una vez.
* Sin marcajes (mientras no exista `attendance_records`), días y horas salen del horario semanal de
  la ficha; la línea lo dice en `attendance_source` y la web lo avisa.
* Las correcciones solo se hacen en revisión; volver a borrador y recalcular las borra (la web lo
  advierte). Un borrador se puede borrar; uno cerrado nunca cambia.
* La bonificación incentivo de ley (Q250 al mes) va en su propia columna, solo para quien está en
  planilla y sin IGSS.
* Disciplina no depende de la bandera `payroll`: cualquier empresa la puede usar.

Para B (asistencia, métricas, incentivos y la app), lo que ya puede consumir o usar (fase05.md §4.1):
* App: `GET /payroll/me` (mis boletas con URL prefirmada de 15 min, para B20 y PayslipViewer) y
  `GET /payroll/entries/{id}/payslip.pdf` (la propia); `GET /disciplinary/me`,
  `GET /disciplinary/{id}` y `POST /disciplinary/{id}/acknowledge` `{note?}` (B21).
* Lo que el cálculo lee de tus tablas, solo si existen: `attendance_records` (`employee_id,
  clock_in_at, clock_out_at, worked_minutes`, solo cerrados), `tasks` (`assigned_to, type =
  'cleaning', status = 'validated', finished_at`) e `incentive_awards` (`employee_id, amount,
  status 'approved'`, `period_end`; al cerrar pasa a `'paid'` y llena `payroll_entry_id`). Si cambias
  esos nombres, avísame para ajustar `payroll/compute.go`.
* Eventos para push: `payroll.closed` (`ClosedEvent` con `Entries[]{EntryID, EmployeeID, UserID,
  NetAmount}`), `disciplinary.created` y `disciplinary.acknowledged` (`ActionRead`). El correo ya
  lo manda A (`payslip_available`, `disciplinary_notice`).
* La web de Asistencia espera `GET /attendance?from&to&limit` → `{items: AttendanceRecord[],
  next_cursor}` con `id, employee_id, clock_in_at, clock_out_at, source (app|manual), edit_reason,
  worked_minutes, late?, off_schedule?`, y `POST /attendance` `{employee_id, clock_in_at,
  clock_out_at, edit_reason}` para el marcaje manual. Con eso basta apagar `attendance` en
  `MOCK_MODULES`. Métricas usa el contrato de fase05 §4 (`/metrics/*`) con la bandera `metrics`.

* [A] **Fase 6, parte de A, completa en backend y web** (rama `dev/sebas`). Migración
  `shared/0005_billing` (planes, suscripciones, facturas, pagos, eventos de pasarela y claves API).
  Módulo `billing`: planes con límites, prueba al crear una empresa, `billing_cycle` diario (factura,
  vence, suspende, cancela), pago por `Provider` con `FakeProvider` y webhook firmado, factura en PDF,
  empresa en solo lectura (402) y límites del plan en propiedades, invitaciones y banderas. Módulo
  `apikeys` y `POST /public/reservations` (reserva por confirmar desde el sitio del cliente, con
  correo a quien administra reservas). Límite de peticiones por IP y por clave, `/health/ready`,
  `tenant_id` y `user_id` en el registro de acceso, OpenAPI exportado a `BACKEND/docs` y guía de
  operación (`BACKEND/docs/operacion.md`). Contrato en fase06.md §3.4, §4.3 y §5.1.
* [A] Suite de aislamiento generada desde el OpenAPI: 174 operaciones; sin token, todas las protegidas
  dan 401; con la sesión de otra empresa, las 100 con id en la ruta dan 403/404 contra recursos reales.
  No encontró fugas. Pruebas de integración de la fase 6 en verde (ciclo de facturación completo con
  reloj simulado, solo lectura y vuelta a operar al pagar, cambio de plan y límites, webhooks
  idempotentes, reservas públicas con todos sus errores, límite por IP y por clave). golangci-lint sin
  observaciones.
* [A] Seed: Garrent al día en Completo con tres meses pagados y la bandera `guest_chat`; Costa Limpia
  en Operación con la factura del mes vencida y un cobro rechazado (para ver el aviso).
* [A] Web: Facturación (W-O4) con la API real (plan, uso frente a límites, factura pendiente con
  "Pagar", historial con PDF, cambiar de plan mensual o anual, cancelar y deshacer), pestaña
  Integraciones (claves API: la clave se muestra una vez), aviso de pago vencido o solo lectura arriba
  de todo el panel, módulos con candado si el plan no los incluye (W-O1), Plataforma con Planes (W-P2)
  y Suscripciones (W-P3: reactivar, dar prueba, facturas). Chat (W-M1) a tres columnas con datos
  simulados (bandera `chat`) hasta que B publique su API. Flujos recorridos en el navegador.

Decisiones (2026-11-23, fase 6):
* Solo lectura = suscripción `suspended` o `cancelled`; se valida en el Guard (402) y deja pasar
  `/billing/*` y `/auth/*`. La API pública también responde 402.
* Una empresa nueva empieza en prueba de 14 días en Completo; las que existían quedaron activas en
  Completo al migrar.
* Cambiar de plan no prorratea: anula lo pendiente, abre el período desde hoy y cobra el plan nuevo.
  Bajar de plan exige que el uso quepa y apaga las banderas que el plan nuevo no incluye.
* Límites por instancia en memoria (sin Redis, como pide el proyecto); con varias instancias el límite
  efectivo se multiplica. Está en la guía de operación.
* La factura en PDF se genera al pedirla (no se guarda en S3).

Para B (chat, cerraduras, retención y la app), lo que ya puede consumir o usar:
* App: `GET /auth/me` trae `tenant.billing_status` y `tenant.read_only`: con `read_only` la app
  debe mostrar el aviso y esperar 402 en toda escritura (mensaje en `detail`).
* Enganche: `reservation.requested` (Data `ReservationEvent`) cuando llega una reserva del sitio,
  para el push al admin.
* La web de Chat (W-M1) espera este contrato; con él basta apagar `chat` en `MOCK_MODULES`:
  * `GET /chat/conversations?kind=internal|guest` → `{items: Conversation[]}` con `id, kind, title,
    reservation {id, code, property_code, property_name, check_in_date, check_out_date, status,
    guest_name, guests_count} | null, participants [{type (user|guest), id, name, role, photo_url}],
    last_message (Message | null), last_message_at, unread, is_archived`.
  * `GET /chat/conversations/{id}/messages?before=&limit=` → `{items: Message[] (antiguos primero),
    next_cursor}` con `id, conversation_id, sender_type, sender_id, sender_name, body, file_url,
    created_at, mine`.
  * `POST /chat/conversations/{id}/messages` `{body}` → `Message`; `POST .../read`;
    `POST /chat/conversations` `{kind: "internal", title?, user_ids[]}` → `Conversation`.
  * Tiempo real por `WS /ws` con el evento `chat.message` (Data `Message`). Mientras no exista,
    la web consulta cada 15 s. Las respuestas rápidas se guardan en el navegador; si B agrega
    `GET/PUT /chat/quick-replies`, se conecta.
* La guía de operación (`BACKEND/docs/operacion.md`) tiene una sección para los trabajos de B
  (retención, cerraduras) por completar.

* [A] **Pulido visual de la web (2026-11-23).** Íconos con volumen propios (`app-dim-icon`, 19
  objetos con luz, sombra y un gesto al pasar el cursor; ref. Airbnb 2025) en los indicadores, las
  alertas del Inicio, los estados vacíos y el tipo de propiedad (tarjeta, ficha, alta con tarjetas de
  tipo). Mapa del Inicio rehecho con geografía real de Guatemala (costa, lagos, volcanes con humo,
  ríos, carreteras, calles y lugares al acercar) y las propiedades en sus coordenadas: vuelo inicial,
  arrastre, zoom (Ctrl + rueda, doble clic, pellizco), grupos con anillo de estados que se separan,
  edificios como píldora, tarjeta flotante y filtros por estado. Detalle en WEB/docs/DISENO.md.
* [A] `GET /dashboard`: cada pin trae además `type` y `building` (fase03 §4.1). OpenAPI exportado de
  nuevo.

Para B: la app puede usar `pins[].type` y `pins[].building` del Inicio si dibuja un mapa; nada
cambió en los campos que ya existían.

* [A] **Segunda vuelta visual de la web (2026-11-24).** Barra de secciones con íconos con volumen
  (28 objetos), menú en mosaicos de color, mapa real Google Maps 3D en el Inicio (con respaldo
  ilustrado), íconos que sobresalen de las tarjetas, inclinación 3D al pasar el cursor, portadas
  en estilo acuarela y tinta, y menos texto. Detalle en WEB/docs/DISENO.md.
* [A] `GET /client-config` (sesión iniciada): `{maps: {provider: google|none, api_key?, map_id?}}`
  desde `ARGOS_GOOGLE_MAPS_KEY` / `ARGOS_GOOGLE_MAPS_MAP_ID`. Guía en BACKEND/docs/operacion.md §4.1.

Para B: la app puede leer `GET /client-config`, pero para Android/iOS conviene su propia clave de
Maps SDK restringida a la app (la del navegador está restringida por dominio).

* [A] **Tercera vuelta visual (2026-11-24).** Mapa del Inicio en Google Maps 3D vectorial (modo
  ROADMAP, más compacto; satélite opcional) con clave propia en el proyecto THEMIS de Google Cloud.
  Inventario: la lista de artículos muestra nivel contra mínimo y estado; cuatro íconos nuevos de
  objetos de inventario. Detalle en WEB/docs/DISENO.md.
* [A] **Mantenimiento visual (2026-11-24).** Activos e Incidencias (vista de tabla) como listas
  visuales con el objeto de cada categoría; nueve íconos con volumen de activos. El mapa del Inicio
  ya no gira al seleccionar una propiedad.
