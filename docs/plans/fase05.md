# Fase 5 — Asistencia, nómina, disciplina, métricas e incentivos

> Estado: en curso. Parte de Persona A **hecha** (2026-11-23): migración `tenant/0008_payroll`,
> módulos `payroll` (períodos, cálculo por esquema, Bono 14, aguinaldo, IGSS, bonificación
> incentivo, revisión con historial, cierre, Excel y boletas PDF) y `disciplinary` (acciones con
> adjuntos, correo, acuse), con la web conectada (W-D2 pestañas Nómina y Disciplina, W-J2 a W-J5 y
> payroll-grid). W-J1 asistencia y W-K1–K2 métricas siguen simuladas hasta que exista la API de B.
> Contrato en §4.1. Pendiente (Persona B): `tenant/0009_attendance_metrics`, `attendance`,
> `metrics`, `incentives` y la app. La nómina se habilita con la bandera `payroll` del tenant;
> disciplina no depende de la bandera.

## 1. Objetivo

* Saber si cada colaborador trabajó (marcaje con GPS) y cuánto se le paga según su
  esquema (fijo mensual, por día, por hora, por limpieza).
* Calcular nómina por período con Bono 14, aguinaldo e IGSS para quienes están en
  planilla, con cifras editables antes de cerrar; exportar Excel y boletas PDF.
* Registrar el procedimiento disciplinario (sin descuentos de sueldo).
* Métricas por colaborador, equipo y propiedad; metas e incentivos.

## 2. Modelo de datos (migraciones `tenant/0008_payroll` y `tenant/0009_attendance_metrics`)

Reparto (ver [reparto.md](reparto.md)): `0008_payroll` (Persona A) crea
`payroll_settings`, `payroll_periods`, `payroll_entries` y `disciplinary_actions`.
`0009_attendance_metrics` (Persona B) crea `attendance_records`,
`performance_snapshots`, `goals` e `incentive_awards`.

### `attendance_records`

| Columna | Tipo | Notas |
| --- | --- | --- |
| employee_id | uuid FK employees | |
| clock_in_at | timestamptz | |
| clock_out_at | timestamptz null | |
| in_lat, in_lng, out_lat, out_lng | numeric(9,6) null | |
| in_photo_file_id, out_photo_file_id | uuid FK files null | |
| source | varchar(8) CHECK IN ('app','manual') | |
| edited_by | uuid FK null, edited_at, edit_reason text null | correcciones del admin |
| worked_minutes | int generado en service al cerrar | |

Índice `(employee_id, clock_in_at)`. Un marcaje abierto por empleado (índice parcial
único `WHERE clock_out_at IS NULL`).

### `payroll_periods`

`name varchar(64)`, `kind varchar(16) CHECK IN ('biweekly','monthly')`, `period_start`,
`period_end date`, `status varchar(16) CHECK IN ('draft','review','closed')`,
`closed_by`, `closed_at`, `export_file_id uuid FK files null`.
`EXCLUDE` de solapamiento por `kind`.

### `payroll_entries`

| Columna | Tipo | Notas |
| --- | --- | --- |
| period_id | uuid FK ON DELETE CASCADE | |
| employee_id | uuid FK | |
| pay_type, pay_rate | snapshot del empleado | |
| on_payroll | bool snapshot | |
| days_worked | numeric(5,2) | días con marcaje válido |
| hours_worked | numeric(7,2) | |
| cleanings_count | int | tareas `cleaning` validadas en el período |
| base_amount | numeric(12,2) | según esquema (ver 3) |
| overtime_amount | numeric(12,2) default 0 | horas extra registradas manualmente |
| incentives_amount | numeric(12,2) default 0 | de `incentive_awards` aprobados |
| other_earnings | numeric(12,2) default 0 | |
| bonus14_amount | numeric(12,2) default 0 | solo en el período que incluye el 15 de julio |
| aguinaldo_amount | numeric(12,2) default 0 | período que incluye el 15 de diciembre |
| igss_employee | numeric(12,2) default 0 | 4.83 % de base + extras si `on_payroll` |
| other_deductions | numeric(12,2) default 0 | ISR u otros que el admin ingrese manualmente |
| gross_amount, net_amount | numeric(12,2) | |
| adjustments | jsonb | lista {concepto, monto, nota} editable |
| notes | text null | |
| payslip_file_id | uuid FK files null | |

`UNIQUE (period_id, employee_id)`.

`payroll_settings` (una fila): `igss_employee_rate numeric(5,4) default 0.0483`,
`bonus14_month smallint default 7`, `aguinaldo_month smallint default 12`,
`monthly_days smallint default 30`, `daily_hours smallint default 8`.

### `disciplinary_actions`

| Columna | Tipo |
| --- | --- |
| employee_id | uuid FK |
| type | varchar(16) CHECK IN ('verbal','written','suspension','other') |
| occurred_on | date |
| description | text |
| issued_by | uuid FK |
| suspension_from, suspension_to | date null |
| acknowledged_at | timestamptz null (acuse desde la app) |
| acknowledgement_note | text null |

Adjuntos por `files` (`entity_type='disciplinary_action'`).

### Métricas e incentivos

`performance_snapshots` (materializada por job diario): `employee_id`, `date`,
`cleanings_done`, `avg_minutes`, `checklist_compliance numeric(5,2)`, `late_count`,
`tickets_reported`, `discrepancies_open`. `UNIQUE (employee_id, date)`.

`goals`: `name`, `metric varchar(32)` (cleanings_done, checklist_compliance,
late_count…), `target numeric`, `comparator varchar(2)` (`>=`, `<=`),
`period_kind varchar(16)` (weekly, monthly), `applies_to varchar(8)` (all, role, user),
`applies_id uuid null`, `incentive_amount numeric(12,2) null`, `is_active`.

`incentive_awards`: `goal_id`, `employee_id`, `period_start`, `period_end`,
`achieved_value numeric`, `amount numeric(12,2)`, `status varchar(16) CHECK IN
('pending','approved','rejected','paid')`, `approved_by`, `payroll_entry_id uuid null`.

## 3. Reglas de negocio

* **Marcaje**: `POST /attendance/clock-in` y `/clock-out` con GPS obligatorio, foto
  opcional. Si hay un marcaje abierto de más de 16 h el job `attendance_autoclose` lo
  cierra a 16 h y avisa al admin. Correcciones manuales exigen `edit_reason` y van a
  bitácora.
* **Cálculo de base** al generar el período (`POST /payroll/periods/{id}/compute`):
  * `fixed_monthly`: `pay_rate` (quincenal: `pay_rate / 2`).
  * `per_day`: `days_worked × pay_rate`, donde un día cuenta si tiene ≥ 1 marcaje
    cerrado con `worked_minutes ≥ settings.min_minutes_for_day` (default 240).
  * `per_hour`: `hours_worked × pay_rate`.
  * `per_cleaning`: `cleanings_count × pay_rate`, con tareas `validated` cuyo
    `finished_at` cae en el período.
* **Bono 14**: en el período que contiene el 1 de julio, para `on_payroll`, promedio
  del salario ordinario devengado de julio a junio anteriores (suma de `base_amount +
  overtime_amount` de las entradas cerradas de los últimos 12 meses / 12, proporcional
  si tiene menos de un año). **Aguinaldo**: igual, en el período que contiene el 1 de
  diciembre, con el año diciembre-noviembre. Ambos editables.
* **IGSS**: `igss_employee = (base + overtime + other_earnings) × rate` solo si
  `on_payroll`. Bono 14 y aguinaldo no pagan IGSS.
* `gross = base + overtime + incentives + other_earnings + bonus14 + aguinaldo`;
  `net = gross − igss_employee − other_deductions`.
* Estados: `draft` (se puede recomputar), `review` (edición manual de montos),
  `closed` (inmutable; genera Excel y boletas; notifica "nómina disponible" a cada
  colaborador con su boleta).
* **Excel** (`excelize`): hoja "Nómina" (una fila por colaborador con todas las
  columnas de `payroll_entries` y datos del empleado: código, nombre, DPI, IGSS, NIT,
  puesto, esquema), hoja "Bono 14" (cuando aplica: promedio, meses, monto), hoja
  "Asistencia" (días y horas por colaborador). **Boleta PDF** (`maroto`): logo del
  tenant, período, datos del colaborador, devengos, deducciones, neto.
* **Disciplina**: crear acción notifica al colaborador (push + correo) y exige acuse en
  la app; el admin ve pendientes de acuse. Nunca modifica nómina.
* **Métricas**: job diario `performance_snapshot`; endpoints agregan por rango.
  Rankings solo entre colaboradores del mismo tenant y rol.
* **Incentivos**: job al cierre de cada semana/mes evalúa `goals` y crea
  `incentive_awards` `pending`; el admin aprueba; al computar la nómina se suman los
  aprobados del período y quedan `paid` al cerrar.

## 4. Endpoints

| Ruta | Permiso |
| --- | --- |
| `POST /attendance/clock-in`, `/clock-out`, `GET /attendance/me` | `hr.attendance.own` |
| `GET /attendance?employee&from&to`, `PATCH /attendance/{id}`, `POST /attendance` (manual) | `hr.attendance.manage` |
| `GET/POST /payroll/periods`, `POST .../compute`, `PATCH .../entries/{id}`, `POST .../review`, `POST .../close` | `hr.payroll.manage` |
| `GET /payroll/periods/{id}/export.xlsx`, `GET /payroll/entries/{id}/payslip.pdf` | `hr.payroll.export` |
| `GET /payroll/me` (mis boletas) | `hr.attendance.own` |
| `GET/PUT /payroll/settings` | `hr.payroll.manage` |
| `GET/POST /disciplinary`, `GET /disciplinary?employee=` | `hr.disciplinary.manage` |
| `GET /disciplinary/me`, `POST /disciplinary/{id}/acknowledge` | `hr.disciplinary.own` |
| `GET /metrics/me`, `/metrics/team`, `/metrics/all`, `/metrics/properties` | `metrics.own` / `metrics.team` / `metrics.all` |
| `GET/POST/PATCH /goals`, `GET /incentives`, `POST /incentives/{id}/approve|reject` | `hr.payroll.manage` |

### 4.1 Contrato implementado (Persona A, 2026-11-23)

Todo bajo `/api/v1`. Las rutas de `/payroll` piden la bandera `payroll` (sin ella: 403 "Este
módulo no está activo en tu empresa."); `/disciplinary` no. Fechas `YYYY-MM-DD`, montos en la
moneda del tenant redondeados a 2 decimales. Lo ajeno o fuera de alcance responde **404**. OpenAPI
completo en `/docs`.

**Configuración** (`hr.payroll.manage`)

* `GET /payroll/settings` → `Settings`: `igss_employee_rate` (0.0483), `igss_employer_rate`
  (0.1267), `incentive_bonus_monthly` (250), `bonus14_month` (7), `aguinaldo_month` (12),
  `monthly_days` (30), `daily_hours` (8), `min_minutes_for_day` (240), `updated_at`.
* `PUT /payroll/settings` con los mismos campos (sin `updated_at`). Va a bitácora.

**Períodos** (leer: `hr.payroll.manage` o `hr.payroll.export`; escribir: `hr.payroll.manage`)

* `GET /payroll/periods` → `PeriodRead[]` (recientes primero): `id, name, kind (biweekly|monthly),
  period_start, period_end, status (draft|review|closed), computed_at, reviewed_at, closed_at,
  closed_by_name, employees_count, gross_total, igss_total, net_total, bonus14, aguinaldo (si ese
  período los paga), has_export, created_at, updated_at`.
* `GET /payroll/periods/{id}` → `PeriodDetail` = lo anterior más `entries: Line[]`, `totals`
  (`days, hours, cleanings, base, overtime, incentives, other_earnings, incentive_bonus, bonus14,
  aguinaldo, gross, igss, other_deductions, net, igss_employer`), `currency` y `sources`
  (`attendance, tasks, incentives`: `false` si la tabla de B aún no existe).
* `POST /payroll/periods` `{name?, kind, period_start, period_end}` → 201. Sin nombre se arma
  ("Quincena 1–15 nov 2026", "Noviembre 2026"). Máximo 62 días; dos del mismo tipo no se cruzan
  (`EXCLUDE` en BD → 422 "Ya hay un período de ese tipo que se cruza con esas fechas.").
* `DELETE /payroll/periods/{id}` solo en borrador (409 si no).
* `POST /payroll/periods/{id}/compute` (solo `draft`, 409 si no): borra y vuelve a crear las
  líneas. `/review` (draft → review; 422 "Calcula el período antes…" sin líneas), `/reopen`
  (review → draft) y `/close` (review → closed). Cerrado es inmutable: 409 "El período está
  cerrado y no se puede cambiar."

**Líneas** (`Line`)

* Campos: `id, period_id, employee_id, user_id, employee_code, full_name, position, pay_type
  (fixed_monthly|per_day|per_hour|per_cleaning), pay_rate, on_payroll, attendance_source
  (attendance|schedule), days_worked, hours_worked, cleanings_count, base_amount, overtime_amount,
  incentives_amount, other_earnings, incentive_bonus_amount, bonus14_amount, aguinaldo_amount,
  igss_employee, other_deductions, gross_amount, net_amount, bonus_detail, manual_fields[],
  history[], notes, has_payslip, updated_at`. Código, nombre, puesto, esquema y tarifa son una
  foto del momento del cálculo.
* `bonus_detail`: `{bonus14?, aguinaldo?}`, cada uno `{kind, window_start, window_end,
  months_history, months_estimated, earnings, amount}` para explicar la cifra.
* `PATCH /payroll/periods/{id}/entries/{entry_id}` (`hr.payroll.manage`, solo en `review`;
  409 si no): cualquiera de `days_worked, hours_worked, cleanings_count, base_amount,
  overtime_amount, incentives_amount, other_earnings, incentive_bonus_amount, bonus14_amount,
  aguinaldo_amount, other_deductions`, más `notes` y `reason`. Si cambian días, horas o
  limpiezas y la base no se tocó, la base se recalcula con la tarifa. IGSS, devengado y líquido se
  recalculan siempre. Cada campo cambiado entra a `manual_fields` y a `history[]`
  (`field, from, to, actor_id, actor_name, at, note`). Sin cambios: 422 "No hay cambios.".
* `GET /payroll/entries?employee_id=` (`hr.payroll.manage`) → `EmployeeEntry[]` = `Line` +
  `period_name, period_start, period_end, period_status` (ficha del colaborador, W-D2).

**Mis boletas (app, B20)**

* `GET /payroll/me` (`hr.attendance.own`) → `MyPayslip[]`: solo períodos **cerrados**, como
  `EmployeeEntry` más `payslip_url` (S3 prefirmada, 15 min) y `expires_at`. 404 "No tienes
  ficha laboral en esta empresa." si el usuario no tiene ficha.
* `GET /payroll/entries/{id}/payslip.pdf`: con `hr.payroll.export|manage` cualquier línea; con
  `hr.attendance.own` solo la propia de un período cerrado (si no, 404).

**Descargas** (`hr.payroll.export` o `hr.payroll.manage`)

* `GET /payroll/periods/{id}/export.xlsx`: hojas "Nómina" (todas las columnas y totales),
  "Bono 14" / "Aguinaldo" (si el período los paga: ventana, meses con historial y estimados,
  devengado, monto) y "Asistencia" (fuente, días, horas, limpiezas).
* `GET /payroll/periods/{id}/payslips.pdf`: todas las boletas, una por página.
* Responden el archivo con `Content-Disposition: attachment; filename="nomina-quincena-….xlsx"`
  (expuesto por CORS para que la web use ese nombre).

**Disciplina**

* `GET /disciplinary?employee_id&pending&cursor&limit` (`hr.disciplinary.manage`) →
  `{items: ActionRead[], next_cursor}`. `ActionRead`: `id, employee_id, user_id, employee_name,
  employee_code, position, type (verbal|written|suspension|other), occurred_on, description,
  issued_by, issued_by_name, suspension_from, suspension_to, acknowledged_at,
  acknowledgement_note, attachments[] ({file_id, name, content_type, url, expires_at}),
  created_at, updated_at`.
* `POST /disciplinary` (`hr.disciplinary.manage`) `{employee_id, type, occurred_on,
  description (≥ 10), suspension_from?, suspension_to?, attachment_file_ids[]}` → 201. Los
  adjuntos se suben antes con `POST /files/presign-upload` (módulo `disciplinary`, tipo `attachment`:
  PDF o imagen, 15 MB) y `POST /files/{id}/confirm`. Fechas de suspensión solo en `suspension` y obligatorias ahí.
  Manda el correo `disciplinary_notice` y publica `disciplinary.created`.
* `GET /disciplinary/me` (`hr.disciplinary.own`) → `ActionRead[]` propias.
* `GET /disciplinary/{id}`: con `manage` cualquiera; con `own` solo la propia (si no, 404).
* `POST /disciplinary/{id}/acknowledge` (`hr.disciplinary.own`, solo la propia) `{note?}`: una
  vez (422 "Ya diste acuse de esta acción."). Publica `disciplinary.acknowledged`.

**Reglas de cálculo tal como quedaron**

* Días y horas: de `attendance_records` si la tabla existe (un día cuenta con
  `worked_minutes ≥ min_minutes_for_day`); si no, del horario semanal de la ficha
  (`employee_schedules`, o lunes a viernes × `daily_hours`) dentro de los días contratados.
  `attendance_source` dice cuál se usó.
* Base: fijo mensual = tarifa (mitad en quincena) prorrateada por días contratados; por día,
  hora o limpieza = cantidad × tarifa.
* Bonificación incentivo (Decreto 37-2001): `incentive_bonus_monthly` al mes, la mitad por
  quincena, solo `on_payroll`, sin IGSS.
* IGSS laboral = (base + extras + otros devengos) × tasa, solo `on_payroll`.
  `gross = base + extras + incentivos + otros + bonificación incentivo + Bono 14 + aguinaldo`;
  `net = gross − IGSS − otros descuentos`. `totals.igss_employer` informa la cuota patronal.
* Bono 14 y aguinaldo: se pagan en el período que toca los días 1–15 del mes configurado
  (julio y diciembre), salvo que ya se hayan pagado en otro período de esa ventana. Monto =
  salario diario × días contratados en la ventana (12 meses que terminan el día anterior) ÷ 365
  × 12. El salario diario sale de lo devengado (base + extras) en períodos cerrados en ARGOS;
  los días sin historial se estiman con ese salario diario o, sin historial, con el salario
  mensual actual × 12 / 365. Así quien tiene menos de un año recibe la parte proporcional.
* Al cerrar: guarda el Excel y una boleta por línea en S3 (`tenants/{tenant_id}/payroll/…`, filas
  en `files` con módulo `payroll`), marca `incentive_awards` aprobados como `paid` con
  `payroll_entry_id` (si la tabla existe), envía `payslip_available` a quien tenga correo y
  publica `payroll.closed`.

**Tablas de Persona B que lee el cálculo (solo si existen, con `to_regclass`)**

| Tabla | Columnas que usa |
| --- | --- |
| `attendance_records` | `employee_id, clock_in_at, clock_out_at, worked_minutes` (solo cerrados) |
| `tasks` | `assigned_to` (user_id), `type = 'cleaning'`, `status = 'validated'`, `finished_at` |
| `incentive_awards` | `employee_id, amount, status ('approved' → 'paid'), period_end, payroll_entry_id` |

**Eventos** (bus interno; B engancha push en `notifications`)

| Evento | `Data` |
| --- | --- |
| `payroll.closed` | `payroll.ClosedEvent{Period PeriodRead; Entries []{EntryID, EmployeeID, UserID, NetAmount}}` |
| `disciplinary.created` | `disciplinary.ActionRead` |
| `disciplinary.acknowledged` | `disciplinary.ActionRead` |

**Diferencias con lo planeado**

* Excel y PDF con generadores propios (`core/xlsx`, `core/pdf`) en lugar de `excelize` y
  `maroto`: sin dependencias nuevas. Se puede cambiar sin tocar el contrato.
* Columnas extra en `payroll_entries`: `incentive_bonus_amount` (bonificación de ley),
  `attendance_source`, `bonus_detail`, `manual_fields`, `history`, `notes` y la foto del
  colaborador. Los "ajustes" quedaron como `other_earnings`/`other_deductions` + nota.
* Estados extra: `reopen` (revisión → borrador) y borrar un borrador.
* Bono 14 y aguinaldo con salario diario × días ÷ 365 × 12 (no "suma / 12"), para que los
  esquemas por limpieza o por hora sin historial no den 0.
* Disciplina no depende de la bandera `payroll`. `GET /employees` también responde a
  `hr.payroll.manage`, `hr.disciplinary.manage` y `hr.attendance.manage` (para elegir colaborador).

## 5. App móvil

* Asistencia: botón grande de entrada/salida con estado actual, historial mensual.
* Mis boletas (PDF en visor), mis métricas (tarjetas y tendencia), mi historial
  disciplinario con acuse.
* Supervisor: métricas de equipo y ranking.

## 6. Portal web

* RRHH: asistencia (tabla por día con mapa de marcajes, correcciones), nómina (períodos,
  cómputo, edición en tabla, cierre, descargas), disciplina (alta con adjuntos, estado de
  acuse), configuración de nómina.
* Métricas: tablero por colaborador, equipo y propiedad; metas e incentivos.

## 7. Pruebas

* Cada esquema de pago calcula correctamente con casos de borde (día con dos marcajes,
  marcaje cruzando medianoche, tarea validada fuera del período).
* Bono 14 proporcional para ingreso a mitad de año; IGSS solo `on_payroll`.
* Un período `closed` no se recomputa (409).
* Colaborador solo ve sus boletas, marcajes y acciones (404 en ajenos).
* Excel y PDF se generan con los datos del período y quedan en `files` bajo el prefijo
  del tenant.

## 8. Criterios de aceptación

El admin cierra la quincena: la nómina refleja los marcajes y limpiezas reales, descarga
el Excel y las boletas, cada colaborador recibe la suya en la app, y una llamada de
atención queda registrada con acuse del colaborador sin tocar la nómina.
