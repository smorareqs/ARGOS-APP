# ARGOS PRD — v2

## Plataforma operativa para propiedades de alquiler de corto plazo

> Versión 2 (2026-09-15). Sustituye al PRD inicial e incorpora los requerimientos
> levantados en la reunión con el cliente. Las decisiones tomadas y su fecha
> quedan registradas en [`plans/avance.md`](plans/avance.md). El detalle técnico
> de implementación vive en [`plans/fase0N.md`](plans/).

---

# 1. Resumen del proyecto

ARGOS es una plataforma multi-tenant para empresas que administran propiedades de
alquiler temporal (Airbnb, Booking, venta directa). Centraliza en un solo sistema:

* La operación diaria de limpieza y mantenimiento (itinerarios, checklists, evidencias).
* El inventario de insumos, herramientas y llaves, con control de custodia por colaborador.
* El ciclo de vida de las reservas: huéspedes, check-in / check-out, depósitos, parqueos y
  áreas comunes.
* El personal: asistencia, esquemas de pago, nómina, disciplina, métricas e incentivos.
* La comunicación: notificaciones push y correo, panel de alertas y chat.

Se compone de tres piezas:

| Pieza | Tecnología | Usuarios |
| --- | --- | --- |
| Backend API | Go (huma + chi, pgx) + PostgreSQL 16 + S3 | Todas las interfaces |
| App móvil | Flutter | Colaboradores, supervisores, seguridad, mantenimiento, huéspedes |
| Portal web | Angular 21 | Administradores, supervisores, propietarios, platform admin |

Idioma: español. Moneda por defecto: GTQ. Zona horaria por defecto: America/Guatemala.
Ambos valores son configurables por tenant.

---

# 2. Arquitectura multi-tenant

## 2.1 Jerarquía

```
ARGOS (proveedor, platform_admin)
└── Tenant (empresa administradora o propietario individual)
    ├── Roles del tenant (admin, supervisor, limpieza, mantenimiento, seguridad,
    │                     propietario de unidad, huésped, + roles personalizados)
    ├── Edificios y propiedades
    ├── Colaboradores y sus asignaciones
    ├── Reservas y huéspedes
    └── Inventario, mantenimiento, nómina, chat, bitácora
```

## 2.2 Aislamiento de datos (requisito crítico)

Ningún usuario de un tenant puede ver, listar, inferir o descargar información de otro
tenant, ni un rol puede ver información que no le corresponde dentro de su propio tenant.
El aislamiento se aplica en cuatro capas independientes, todas obligatorias:

1. **Base de datos:** schema PostgreSQL dedicado por tenant (`tenant_<slug>`). Las tablas
   globales (tenants, usuarios, membresías, roles, jobs) viven en el schema `shared`.
   Cada petición fija el `search_path` con `SET LOCAL` dentro de su transacción, de modo
   que una conexión del pool nunca conserva el schema de una petición anterior.
2. **Autorización por permiso:** cada endpoint declara el permiso que exige. El token
   lleva el tenant activo y el rol; el backend resuelve los permisos del rol en cada
   petición.
3. **Alcance por asignación:** además del permiso, los repositorios filtran por lo que el
   usuario tiene asignado (propiedades asignadas al colaborador, unidades del propietario,
   reserva activa del huésped). Un recurso fuera de alcance responde `404`, nunca `403`,
   para no revelar su existencia.
4. **Archivos:** un único bucket S3 por ambiente con prefijo obligatorio
   `tenants/{tenant_id}/{módulo}/...`. Nunca se expone una clave S3 al cliente sin que el
   backend haya validado permiso y alcance; el acceso es siempre por URL prefirmada de
   corta duración (lectura 5 min, subida 15 min). Los documentos de identidad tienen además
   retención automática (ver 5.7.4).

Un usuario (mismo correo) puede pertenecer a varios tenants con roles distintos. Cada
sesión opera sobre un único tenant activo; cambiar de tenant emite un token nuevo.

---

# 3. Usuarios, roles y permisos

## 3.1 Modelo

* **Permisos**: catálogo fijo definido en el código del backend (ej. `tasks.execute`,
  `hr.payroll.export`). Nunca se crean desde la interfaz.
* **Roles**: agrupan permisos. Al crear un tenant se siembran los roles por defecto de
  la tabla 3.2. El administrador del tenant puede editar los permisos de esos roles y
  crear roles personalizados. Los roles `admin` y `guest` no se pueden borrar ni perder
  sus permisos mínimos.
* **Membresía**: relación usuario ↔ tenant ↔ rol, con estado (invitado, activo,
  suspendido). Es la unidad de autorización.
* **Alcance**: asignaciones concretas (propiedades a colaboradores, unidades a
  propietarios, reserva a huésped) que restringen el rol dentro del tenant.
* **Platform admin**: usuarios de ARGOS sin membresía. Administran tenants, planes y
  facturación. No tienen acceso a los datos operativos de un tenant salvo mediante
  una acción explícita de soporte que queda en la bitácora de plataforma.

## 3.2 Roles por defecto y plataforma de acceso

| Rol | Clave | Web | App | Descripción |
| --- | --- | --- | --- | --- |
| Administrador | `admin` | Sí | Sí | Gestiona toda la operación del tenant |
| Supervisor | `supervisor` | Sí | Sí | Supervisa equipos, reasigna, valida tareas e inspecciones |
| Colaborador de limpieza | `cleaner` | No | Sí | Ejecuta limpiezas, checklists, evidencias, inventario |
| Colaborador de mantenimiento | `maintenance` | No | Sí | Atiende incidencias y mantenimientos preventivos |
| Seguridad | `security` | No | Sí | Consulta llegadas/salidas, huéspedes activos, placas; recibe alarmas de check-out |
| Propietario de unidad | `owner` | Sí | Sí | Solo lectura de sus propiedades: limpiezas, mantenimiento, reservas, reportes |
| Huésped | `guest` | No | Sí | Ve su reserva, reserva áreas comunes, chatea con la empresa |

"Clientes" de una empresa pueden ser propietarios de unidad, huéspedes o ambos, según el
tenant.

## 3.3 Catálogo de permisos

| Módulo | Permisos |
| --- | --- |
| Tenant | `tenant.settings`, `tenant.billing` |
| Usuarios y roles | `users.read`, `users.manage`, `roles.manage` |
| Propiedades | `properties.read`, `properties.manage`, `properties.access_info` |
| Itinerario y tareas | `tasks.read`, `tasks.manage`, `tasks.assign`, `tasks.execute`, `tasks.validate` |
| Inventario | `inventory.read`, `inventory.manage`, `inventory.checkout`, `inventory.reconcile` |
| Mantenimiento | `maintenance.read`, `maintenance.report`, `maintenance.manage`, `maintenance.assign`, `maintenance.execute` |
| Reservas | `reservations.read`, `reservations.manage`, `reservations.checkin` |
| Huéspedes | `guests.read`, `guests.manage`, `guests.documents` |
| Depósitos | `deposits.read`, `deposits.manage` |
| Parqueos | `parking.read`, `parking.manage` |
| Áreas comunes | `shared_areas.manage`, `shared_areas.book`, `shared_areas.read` |
| Seguridad | `security.dashboard` |
| RRHH | `hr.attendance.own`, `hr.attendance.manage`, `hr.payroll.manage`, `hr.payroll.export`, `hr.disciplinary.manage`, `hr.disciplinary.own` |
| Métricas | `metrics.own`, `metrics.team`, `metrics.all` |
| Notificaciones | `alerts.read`, `alerts.manage` |
| Chat | `chat.internal`, `chat.guest` |
| Bitácora | `audit.read` |
| Reportes | `reports.export` |

## 3.4 Matriz de roles por defecto

| Permiso | admin | supervisor | cleaner | maintenance | security | owner | guest |
| --- | :-: | :-: | :-: | :-: | :-: | :-: | :-: |
| tenant.settings, tenant.billing | ✔ | | | | | | |
| users.read | ✔ | ✔ | | | | | |
| users.manage, roles.manage | ✔ | | | | | | |
| properties.read | ✔ | ✔ | asignadas | asignadas | ✔ | propias | reserva |
| properties.manage | ✔ | | | | | | |
| properties.access_info | ✔ | ✔ | asignadas | asignadas | ✔ | | |
| tasks.read | ✔ | ✔ | propias | propias | | propias unidades | |
| tasks.manage, tasks.assign | ✔ | ✔ | | | | | |
| tasks.execute | ✔ | ✔ | ✔ | ✔ | | | |
| tasks.validate | ✔ | ✔ | | | | | |
| inventory.read | ✔ | ✔ | ✔ | ✔ | | | |
| inventory.manage, inventory.reconcile | ✔ | ✔ | | | | | |
| inventory.checkout | ✔ | ✔ | ✔ | ✔ | | | |
| maintenance.read | ✔ | ✔ | asignadas | ✔ | | propias unidades | |
| maintenance.report | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |
| maintenance.manage, maintenance.assign | ✔ | ✔ | | | | | |
| maintenance.execute | ✔ | ✔ | | ✔ | | | |
| reservations.read | ✔ | ✔ | | | hoy | propias unidades | propia |
| reservations.manage, reservations.checkin | ✔ | ✔ | | | | | |
| guests.read | ✔ | ✔ | | | activos | | |
| guests.manage, guests.documents | ✔ | | | | | | |
| deposits.read | ✔ | ✔ | | | | propias unidades | |
| deposits.manage | ✔ | | | | | | |
| parking.read | ✔ | ✔ | | | ✔ | | propia |
| parking.manage | ✔ | ✔ | | | | | |
| shared_areas.manage | ✔ | | | | | | |
| shared_areas.read | ✔ | ✔ | | | ✔ | | ✔ |
| shared_areas.book | ✔ | ✔ | | | | | ✔ |
| security.dashboard | ✔ | ✔ | | | ✔ | | |
| hr.attendance.own | ✔ | ✔ | ✔ | ✔ | ✔ | | |
| hr.attendance.manage, hr.payroll.*, hr.disciplinary.manage | ✔ | | | | | | |
| hr.disciplinary.own | | ✔ | ✔ | ✔ | ✔ | | |
| metrics.own | ✔ | ✔ | ✔ | ✔ | ✔ | | |
| metrics.team | ✔ | ✔ | | | | | |
| metrics.all | ✔ | | | | | propias | |
| alerts.read | ✔ | ✔ | | ✔ | ✔ | | |
| alerts.manage | ✔ | ✔ | | | | | |
| chat.internal | ✔ | ✔ | ✔ | ✔ | ✔ | | |
| chat.guest | ✔ | ✔ | | | | | ✔ |
| audit.read | ✔ | ✔ | | | | | |
| reports.export | ✔ | ✔ | | | | propias | |

"asignadas", "propias", "hoy", "activos", "reserva" indican que el permiso existe pero el
alcance está restringido por asignación (sección 2.2, capa 3).

---

# 4. Identidad y acceso

## 4.1 Autenticación

* Correo y contraseña (bcrypt). Tokens JWT de acceso (15 min) y refresh (60 días,
  rotativo, revocable por dispositivo).
* **Inicio de sesión rápido y recurrente:** en móvil, el refresh token se guarda en
  almacenamiento seguro y se desbloquea con biometría o PIN; el usuario no vuelve a
  escribir su contraseña salvo revocación. En web, sesión persistente de 30 días.
* **Segundo factor (TOTP)** opcional para cualquier usuario; el tenant puede exigirlo a
  los roles administrativos.
* **Selección de tenant:** si el usuario tiene una sola membresía activa, entra directo.
  Si tiene varias, elige empresa y puede cambiar sin cerrar sesión.
* **Huéspedes:** no tienen contraseña. Al confirmarse la reserva reciben por correo un
  enlace mágico y un código de reserva. Con cualquiera de los dos entran a la app en modo
  huésped, con alcance limitado a esa reserva y vigencia hasta 24 h después del check-out.
* **Invitaciones:** el admin invita por correo; el invitado define su contraseña al aceptar.
* Recuperación de contraseña por correo con token de un solo uso.

## 4.2 Dispositivos y sesiones

* Cada refresh token está ligado a un dispositivo (id, nombre, plataforma).
* El usuario ve y revoca sus sesiones. El admin puede revocar todas las sesiones de un
  colaborador al darlo de baja.

---

# 5. Módulos funcionales

## 5.1 Empresa (tenant)

* Datos generales, logo, zona horaria, moneda.
* Banderas de funcionalidad por tenant: parqueos, áreas comunes, reservas, nómina, chat
  con huéspedes, cerraduras inteligentes. Lo desactivado no aparece en las interfaces.
* Gestión de usuarios, invitaciones, roles y permisos.
* Plan y facturación con ARGOS (sección 5.16).

## 5.2 Edificios y propiedades

* **Edificio**: agrupa propiedades que comparten parqueos y áreas comunes. Opcional.
* **Propiedad** (apartamento, casa, habitación): nombre, código, dirección, ubicación,
  edificio, propietarios, plantilla de checklist, información de acceso (llaves, códigos;
  visible solo con `properties.access_info`), estado activo/inactivo.
* Historial de limpiezas, incidencias, reservas e inspecciones por propiedad.
* Activos de la propiedad (sección 5.6).

## 5.3 Colaboradores y asignaciones

* Perfil laboral: código de empleado, puesto, fecha de ingreso, documento, IGSS, NIT,
  esquema de pago, en planilla o no.
* **Asignación de lugares**: el admin define qué propiedades puede atender cada
  colaborador. Un colaborador solo recibe tareas y ve información de esas propiedades.
* Horarios y disponibilidad semanal.

## 5.4 Itinerario y limpiezas

* Tareas de tipo limpieza, inspección, mantenimiento y revisión de salida, con fecha,
  ventana horaria, propiedad, responsable y reserva relacionada (si aplica).
* Vista diaria y semanal en app; calendario y tablero de seguimiento en web.
* Estados: pendiente, en progreso, finalizada, validada, cancelada. Retraso detectado
  automáticamente cuando pasa la ventana sin iniciar o sin terminar.
* Ejecución en app:
  1. Inicio con ubicación GPS y hora.
  2. Checklist por áreas (copiado de la plantilla de la propiedad) con evidencia
     fotográfica obligatoria donde la plantilla lo indique.
  3. Fotos antes y después por área.
  4. Registro de insumos consumidos y reporte de daños.
  5. **Cierre de limpieza (prueba de check-out del colaborador):** no se puede finalizar
     sin las fotos finales obligatorias, la ubicación y el conteo de devolución de
     inventario (sección 5.5). El supervisor valida después.
* Reasignación y reprogramación desde web o por supervisor en app, con notificación.
* Generación automática de tareas de limpieza a partir del check-out de una reserva.

## 5.5 Inventario y custodia

* Bodega central por empresa y bodega por propiedad.
* Artículos: consumibles (unidades), herramientas y llaves (con serie o código).
* Existencias por bodega, mínimos y alertas de inventario bajo.
* Movimientos: entrada, salida, traslado, consumo, ajuste, entrega a colaborador,
  devolución de colaborador.
* **Custodia y conciliación:** cuando un colaborador saca artículos queda registrada la
  cantidad en su custodia. Al cerrar la tarea (o la jornada) debe devolver la misma
  cantidad de herramientas y llaves, y declarar el consumo de consumibles. Toda
  diferencia genera una discrepancia con estado abierta/justificada/cerrada, visible al
  admin y al supervisor. ARGOS no aplica descuentos de sueldo; solo registra.
* Solicitudes de reposición desde la app.

## 5.6 Mantenimiento y activos

* **Activos** por propiedad o edificio: elevadores, cámaras, sistema de agua, pintura,
  electrodomésticos, plomería, electricidad, aire acondicionado, equipos de hotelería y
  otros. Cada activo tiene marca, modelo, serie, proveedor, garantía, estado y documentos
  (contratos, certificados, manuales).
* **Incidencias** reportadas desde la app por cualquier rol (incluidos huéspedes y
  propietarios): fotos, descripción, urgencia, activo afectado. Estados: abierta,
  asignada, en progreso, resuelta, cerrada. Asignación a colaborador de mantenimiento o
  proveedor externo, costo y historial.
* **Mantenimiento preventivo:** planes por activo con frecuencia, responsable o proveedor,
  próxima fecha; generan tareas y recordatorios automáticamente. Vencidos aparecen en el
  panel de alertas.
* Indicadores: incidencias abiertas por propiedad, tiempo de resolución, costos.

## 5.7 Reservas y huéspedes

ARGOS es la fuente de verdad de las reservas del tenant, aunque provengan de otros canales.

### 5.7.1 Canales
* Directo (página propia, teléfono), Booking, Airbnb, agencia de viajes, otro.
* Cada canal define si exige depósito y si tiene check-in / check-out formal.
* Importación de calendarios iCal de Booking y Airbnb por propiedad (sincronización
  periódica) para crear reservas base; el admin completa los datos del huésped.
* Integración con la página web del cliente: se expone un endpoint de recepción de
  reservas con clave API por tenant. La integración concreta se define cuando el cliente
  entregue la información de su sitio (decisión pendiente).

### 5.7.2 Dos flujos de venta
| | Venta directa | Agencia / OTA |
| --- | --- | --- |
| Depósito | Sí: se registra al confirmar, se retiene o devuelve al check-out | No |
| Check-in / check-out | Formal, con registro de huéspedes y hora | No hay; el ciclo es interno |
| Control del estado del lugar | Inspección de salida contra depósito | Inspección "cómo lo dejé / cómo lo dejaron" con fotos antes y después |

### 5.7.3 Reserva
* Propiedad, canal, referencia externa, fechas, huésped principal y acompañantes,
  adultos y niños, monto, moneda, notas.
* Estados: pendiente, confirmada, con check-in, con check-out, cancelada, no-show.
* Al confirmar: correo al huésped con detalle, instrucciones y acceso a la app.
* Al hacer check-out: se genera la tarea de limpieza y, si aplica, la alarma de seguridad.

### 5.7.4 Registro de huéspedes
* Datos obligatorios: nombre, correo, tipo y número de documento (DPI o pasaporte).
* Se piden fotos del documento (frente y reverso). Se conserva el número; las fotos se
  almacenan en S3 con acceso restringido (`guests.documents`) y se **eliminan
  automáticamente 90 días después del check-out**.
* Un huésped recurrente se reutiliza por número de documento dentro del tenant.

### 5.7.5 Depósitos
* Registro de monto, método (efectivo, transferencia, tarjeta), referencia y estado:
  pendiente, recibido, retenido parcial/total, devuelto. Sin pasarela de pago en este
  módulo.

### 5.7.6 Inspecciones
* Inspección previa a la llegada y posterior a la salida con fotos por área y hallazgos
  (descripción, severidad, costo estimado, si se cobra al depósito).

## 5.8 Seguridad y parqueos

* **Tablero de seguridad (app):** llegadas y salidas de hoy, huéspedes activos por
  propiedad, vehículos y placas, áreas comunes reservadas hoy.
* **Alarma de check-out:** a la hora de check-out de cada reserva (configurable, ej.
  30 min antes y a la hora) el personal de seguridad recibe una notificación push y la ve
  en su tablero hasta marcarla como atendida.
* **Parqueos** (bandera por tenant): espacios por edificio o propiedad; asignación a una
  reserva con placa y descripción del vehículo y vigencia; disponibilidad por fecha.

## 5.9 Áreas comunes

* Cada admin registra sus áreas (piscina, BBQ, salón, gimnasio, etc.) con capacidad,
  horario, duración de bloque y máximo de reservas por huésped por día.
* El huésped reserva desde la app; la confirmación es **automática** si hay cupo.
  Recibe correo y push. Puede cancelar.
* El admin y seguridad ven el calendario de uso.

## 5.10 Asistencia y nómina

* **Asistencia:** marcaje de inicio y fin de jornada en la app con GPS y foto opcional.
  El admin puede corregir marcajes con justificación (queda en bitácora).
* **Esquemas de pago por colaborador:** salario fijo mensual, por día trabajado, por hora
  o por limpieza realizada. Cada colaborador tiene marcado si está en planilla.
* **Nómina:** períodos (quincenal o mensual). ARGOS calcula por colaborador: base según
  esquema y asistencia/limpiezas, horas extra registradas, Bono 14, aguinaldo, cuota IGSS
  laboral (cuando está en planilla). Los cálculos son editables antes de cerrar el
  período. No se gestionan descuentos disciplinarios.
* **Exportaciones:** Excel con todos los datos del período y de Bono 14; boleta de pago
  individual en PDF.

## 5.11 Procedimiento disciplinario

* Registro de llamadas de atención (verbal, escrita), suspensión y otros, con fecha,
  descripción, quién la emite, adjuntos en S3 y acuse de recibo del colaborador desde la
  app.
* Historial por colaborador visible al admin y al propio colaborador.

## 5.12 Métricas e incentivos

* Por colaborador: limpiezas realizadas, tiempo promedio, cumplimiento de checklist,
  retrasos, incidencias reportadas, discrepancias de inventario.
* Por equipo y por propiedad. Rankings y metas por período. Incentivos definidos por el
  admin (regla y monto) y calculados al cierre del período; se incluyen en la nómina como
  extra si el admin lo aprueba.

## 5.13 Notificaciones y alertas

* Canales: push (app), correo, y bandeja dentro de app y web. Toda notificación importante
  llega por correo y por la app.
* Eventos: nueva tarea, cambio o reasignación, recordatorio de tarea, tarea retrasada,
  incidencia asignada, mantenimiento vencido, inventario bajo, discrepancia de inventario,
  reserva confirmada (huésped), recordatorio de check-in/check-out (huésped y seguridad),
  reserva de área común, mensaje de chat, acción disciplinaria, nómina disponible.
* **Panel de alertas (web):** activos con falla, mantenimientos vencidos, tareas
  retrasadas, inventario bajo, discrepancias abiertas, alarmas de check-out no atendidas.
  Filtros por prioridad, propiedad y estado.

## 5.14 Chat

* Conversaciones internas (uno a uno y grupales) entre colaboradores, supervisores y
  administradores del tenant.
* Conversación huésped ↔ empresa ligada a la reserva, disponible desde la confirmación
  hasta 24 h después del check-out. La atiende cualquier usuario con `chat.guest`.
* Texto e imágenes. Notificación push de mensajes nuevos.

## 5.15 Bitácora

* Registro cronológico e inmutable por tenant de toda acción relevante: quién, qué,
  sobre qué entidad, cuándo, desde dónde. Filtros por usuario, entidad, propiedad y fecha.
* Bitácora de plataforma separada para acciones de platform admin.

## 5.16 Facturación de tenants (plataforma)

* Planes con límites (propiedades, usuarios, módulos habilitados).
* Suscripción por tenant, ciclo mensual o anual, facturas y pagos por pasarela.
* Pasarela de pago: se integra mediante una interfaz de proveedor; el proveedor concreto
  es decisión pendiente (ver avance.md). Debe operar en Guatemala.
* Un tenant con suscripción vencida entra en modo solo lectura tras un período de gracia.

## 5.17 Integraciones

* iCal de Booking y Airbnb (lectura).
* Correo transaccional: Amazon SES.
* Push: Firebase Cloud Messaging.
* Archivos: Amazon S3.
* Cerraduras inteligentes Nexxt: generación y revocación de códigos de acceso por reserva.
  Depende de acceso a la API del fabricante (decisión pendiente).
* Endpoint de recepción de reservas para la página web del cliente (clave API).

---

# 6. Plataformas

## 6.1 App móvil (Flutter)

| Rol | Pantallas principales |
| --- | --- |
| cleaner / maintenance | Itinerario del día y semana, detalle de tarea, checklist y fotos, inventario en custodia, asistencia, incidencias, chat, notificaciones, mis métricas, mi historial disciplinario |
| supervisor | Todo lo anterior más: equipo, reasignar, validar tareas, inspecciones, alertas |
| security | Tablero de seguridad, alarmas de check-out, huéspedes activos, parqueos, áreas comunes de hoy, incidencias |
| admin | Acceso a lo operativo en modo consulta y acciones rápidas (reasignar, validar, aprobar) |
| owner | Sus propiedades: limpiezas, incidencias, reservas, reportes |
| guest | Mi reserva, instrucciones de acceso, reservar áreas comunes, mi parqueo, chat, reportar problema |

Modo sin conexión: el itinerario del día y sus checklists se guardan localmente; las fotos
y checkpoints se encolan y se suben al recuperar conexión. Sin conexión no se puede iniciar
sesión por primera vez ni cerrar tareas (el cierre exige subir evidencias).

## 6.2 Portal web (Angular)

| Rol | Secciones |
| --- | --- |
| admin | Inicio, propiedades, colaboradores, itinerario, inventario, mantenimiento, reservas, huéspedes, parqueos, áreas comunes, RRHH (asistencia, nómina, disciplina), métricas, alertas, chat, bitácora, configuración (roles, usuarios, banderas, facturación) |
| supervisor | Inicio, itinerario, inventario, mantenimiento, reservas (consulta), alertas, chat, métricas de equipo |
| owner | Inicio con sus unidades, historial, reportes |
| platform_admin | Tenants, planes, suscripciones, bitácora de plataforma |

---

# 7. Requisitos no funcionales

* **Seguridad:** las cuatro capas de aislamiento de 2.2 son obligatorias y tienen pruebas
  automatizadas de aislamiento entre tenants y entre roles. Contraseñas con bcrypt.
  Información de acceso a propiedades cifrada en reposo. Sin secretos en el código.
* **Retención:** fotos de documentos de identidad 90 días tras check-out. Evidencias de
  limpieza e inspecciones: 24 meses. Bitácora: permanente.
* **Trabajo en segundo plano:** cola de trabajos sobre PostgreSQL (sin Redis) con un
  proceso worker: correos, push, recordatorios, alarmas, sincronización iCal, retención,
  generación de tareas y reportes.
* **Tiempo real:** WebSockets para chat y notificaciones en vivo, con fan-out por
  PostgreSQL `LISTEN/NOTIFY`.
* **Infraestructura objetivo:** AWS (S3, SES, base de datos PostgreSQL gestionada) y
  Google (FCM). Sin dependencias de otros proveedores.
* **Localización:** español; fechas y horas en la zona del tenant; moneda del tenant.
* **Auditabilidad:** toda mutación relevante deja rastro en bitácora.

---

# 8. Fuera de alcance de esta versión

* Procesamiento de pagos de huéspedes (solo registro).
* Descuentos de sueldo por daños o faltas.
* Sincronización bidireccional con Booking o Airbnb.
* Portal web para huéspedes.

# 9. Decisiones pendientes

Ver la sección "Decisiones pendientes" de [`plans/avance.md`](plans/avance.md): proveedor
de pasarela de pago, hosting concreto, detalles de la página web del cliente y acceso a la
API de Nexxt.

# 10. Plan por fases

Documentos transversales: [base-de-datos.md](plans/base-de-datos.md) (modelo completo y
migraciones), [ux-ui.md](plans/ux-ui.md) (sistema visual, navegación y fichas de
pantalla) y [reparto.md](plans/reparto.md) (división del trabajo entre dos personas).

| Fase | Contenido | Documento |
| --- | --- | --- |
| 1 | Identidad, tenants, roles y permisos, migraciones multi-schema, S3, cola de trabajos y correo, login real en app y web | [fase01.md](plans/fase01.md) |
| 2 | Propiedades, colaboradores, itinerario y limpiezas, inventario y custodia, bitácora | [fase02.md](plans/fase02.md) |
| 3 | Mantenimiento y activos, notificaciones push, panel de alertas, tiempo real | [fase03.md](plans/fase03.md) |
| 4 | Reservas, huéspedes, depósitos, inspecciones, seguridad, parqueos, áreas comunes, acceso de huéspedes | [fase04.md](plans/fase04.md) |
| 5 | Asistencia, nómina, disciplina, métricas e incentivos | [fase05.md](plans/fase05.md) |
| 6 | Chat, facturación de tenants, integraciones (Nexxt, web del cliente), cierre | [fase06.md](plans/fase06.md) |
