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
