# Fase 5 — Asistencia, nómina, disciplina, métricas e incentivos

> Estado: pendiente. Requiere fase 2 (tareas, empleados) y fase 3 (notificaciones).
> La nómina se habilita con la bandera `payroll` del tenant.

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
