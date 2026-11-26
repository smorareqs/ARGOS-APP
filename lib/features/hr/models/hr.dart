import 'package:design_system/design_system.dart';

/// Modelos de la fase 5 en la app: marcaje (B15), boletas (B20), disciplina
/// (B21), métricas propias y del equipo (B19) y el reporte del propietario
/// (E3). Siguen las respuestas del backend (`attendance`, `payroll`,
/// `disciplinary`, `metrics`).

String _s(Object? v, [String def = '']) => v is String ? v : def;
String? _sn(Object? v) => v is String && v.isNotEmpty ? v : null;
int _i(Object? v) => v is num ? v.toInt() : 0;
double _d(Object? v) => v is num ? v.toDouble() : 0;
bool _b(Object? v) => v == true;
DateTime? _t(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
List<Map<String, dynamic>> _l(Object? v) => [
  for (final it in v is List ? v : const [])
    if (it is Map) Map<String, dynamic>.from(it),
];

const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
const _monthsLong = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];
const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

/// "07:58".
String hm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// "Jue 22".
String weekdayDay(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day}';

/// "noviembre 2026".
String monthLabel(DateTime m) => '${_monthsLong[m.month - 1]} ${m.year}';

/// "2026-11".
String monthKey(DateTime m) => '${m.year}-${m.month.toString().padLeft(2, '0')}';

/// "22 oct".
String dayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// 485 → "8 h 05 min"; 45 → "45 min".
String durationLabel(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60, m = minutes % 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')} min';
}

/// Montos en quetzales: "Q3,836.63".
String quetzales(double v) {
  final neg = v < 0;
  final fixed = v.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final buf = StringBuffer();
  for (var i = 0; i < parts[0].length; i++) {
    if (i > 0 && (parts[0].length - i) % 3 == 0) buf.write(',');
    buf.write(parts[0][i]);
  }
  return '${neg ? '-' : ''}Q$buf.${parts[1]}';
}

// ── Asistencia ───────────────────────────────────────────

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.userId,
    required this.employeeName,
    required this.date,
    required this.clockIn,
    this.clockOut,
    this.workedMinutes,
    this.source = 'app',
    this.autoclosed = false,
    this.editReason,
    this.late = false,
    this.offSchedule = false,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
    id: _s(j['id']),
    employeeId: _s(j['employee_id']),
    userId: _s(j['user_id']),
    employeeName: _s(j['employee_name']),
    date: _s(j['date']),
    clockIn: _t(j['clock_in_at']) ?? DateTime(1970),
    clockOut: _t(j['clock_out_at']),
    workedMinutes: j['worked_minutes'] is num ? _i(j['worked_minutes']) : null,
    source: _s(j['source'], 'app'),
    autoclosed: _b(j['autoclosed']),
    editReason: _sn(j['edit_reason']),
    late: _b(j['late']),
    offSchedule: _b(j['off_schedule']),
  );

  final String id;
  final String employeeId;
  final String userId;
  final String employeeName;

  /// Día (hora de la empresa) en que empezó: `yyyy-mm-dd`.
  final String date;
  final DateTime clockIn;
  final DateTime? clockOut;
  final int? workedMinutes;
  final String source;
  final bool autoclosed;
  final String? editReason;
  final bool late;
  final bool offSchedule;

  bool get open => clockOut == null;
  bool get manual => source == 'manual';

  /// Minutos trabajados hasta [now] si sigue abierto.
  int minutesAt(DateTime now) => workedMinutes ?? now.difference(clockIn).inMinutes.clamp(0, 24 * 60);
}

class ScheduleSlot {
  const ScheduleSlot(this.weekday, this.startsAt, this.endsAt);

  factory ScheduleSlot.fromJson(Map<String, dynamic> j) => ScheduleSlot(_i(j['weekday']), _s(j['starts_at']), _s(j['ends_at']));

  /// 0 = domingo … 6 = sábado (como el backend).
  final int weekday;
  final String startsAt;
  final String endsAt;
}

class AttendanceMonth {
  const AttendanceMonth({
    required this.month,
    required this.items,
    this.open,
    this.workedMinutes = 0,
    this.daysWorked = 0,
    this.lateCount = 0,
    this.schedule = const [],
  });

  factory AttendanceMonth.fromJson(Map<String, dynamic> j) => AttendanceMonth(
    month: _s(j['month']),
    open: j['open'] is Map ? AttendanceRecord.fromJson(Map<String, dynamic>.from(j['open'] as Map)) : null,
    items: [for (final it in _l(j['items'])) AttendanceRecord.fromJson(it)],
    workedMinutes: _i(j['worked_minutes']),
    daysWorked: _i(j['days_worked']),
    lateCount: _i(j['late_count']),
    schedule: [for (final it in _l(j['schedule'])) ScheduleSlot.fromJson(it)],
  );

  final String month;
  final AttendanceRecord? open;
  final List<AttendanceRecord> items;
  final int workedMinutes;
  final int daysWorked;
  final int lateCount;
  final List<ScheduleSlot> schedule;

  /// Horario de ese día ("07:00 – 15:00"), o null si no le toca.
  String? scheduleFor(DateTime day) {
    final dow = day.weekday % 7;
    final slots = schedule.where((s) => s.weekday == dow).toList();
    if (slots.isEmpty) return null;
    return slots.map((s) => '${s.startsAt} – ${s.endsAt}').join(' · ');
  }
}

// ── Boletas ──────────────────────────────────────────────

class Payslip {
  const Payslip({
    required this.id,
    required this.periodName,
    required this.periodStart,
    required this.periodEnd,
    required this.net,
    required this.gross,
    required this.lines,
    required this.deductions,
    this.payType = '',
    this.daysWorked = 0,
    this.hoursWorked = 0,
    this.cleanings = 0,
    this.url,
  });

  factory Payslip.fromJson(Map<String, dynamic> j) {
    final earn = <(String, double)>[
      ('Salario base', _d(j['base_amount'])),
      ('Horas extra', _d(j['overtime_amount'])),
      ('Incentivos por metas', _d(j['incentives_amount'])),
      ('Bonificación incentivo', _d(j['incentive_bonus_amount'])),
      ('Bono 14', _d(j['bonus14_amount'])),
      ('Aguinaldo', _d(j['aguinaldo_amount'])),
      ('Otros ingresos', _d(j['other_earnings'])),
    ];
    final ded = <(String, double)>[('IGSS laboral', _d(j['igss_employee'])), ('Otros descuentos', _d(j['other_deductions']))];
    return Payslip(
      id: _s(j['id']),
      periodName: _s(j['period_name']),
      periodStart: _s(j['period_start']),
      periodEnd: _s(j['period_end']),
      net: _d(j['net_amount']),
      gross: _d(j['gross_amount']),
      lines: [
        for (final l in earn)
          if (l.$2 != 0 || l.$1 == 'Salario base') l,
      ],
      deductions: [
        for (final l in ded)
          if (l.$2 != 0 || l.$1 == 'IGSS laboral') l,
      ],
      payType: _s(j['pay_type']),
      daysWorked: _d(j['days_worked']),
      hoursWorked: _d(j['hours_worked']),
      cleanings: _i(j['cleanings_count']),
      url: _sn(j['payslip_url']),
    );
  }

  final String id;
  final String periodName;
  final String periodStart;
  final String periodEnd;
  final double net;
  final double gross;

  /// Devengos que no son cero (el salario base siempre).
  final List<(String, double)> lines;
  final List<(String, double)> deductions;
  final String payType;
  final double daysWorked;
  final double hoursWorked;
  final int cleanings;

  /// URL firmada del PDF (vence en minutos).
  final String? url;

  double get totalDeductions => deductions.fold(0, (a, l) => a + l.$2);

  /// "10 días trabajados", "16 h trabajadas" o "20 limpiezas".
  String get basis => switch (payType) {
    'per_day' => '${_trim(daysWorked)} días trabajados',
    'per_hour' => '${_trim(hoursWorked)} h trabajadas',
    'per_cleaning' => '$cleanings limpiezas',
    _ => 'Salario fijo',
  };

  static String _trim(double v) => v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);
}

// ── Disciplina ───────────────────────────────────────────

class DisciplinaryAttachment {
  const DisciplinaryAttachment(this.name, this.contentType, this.url);

  final String name;
  final String contentType;
  final String url;

  bool get isImage => contentType.startsWith('image/');
}

class DisciplinaryAction {
  const DisciplinaryAction({
    required this.id,
    required this.type,
    required this.occurredOn,
    required this.description,
    this.issuedBy,
    this.suspensionFrom,
    this.suspensionTo,
    this.acknowledgedAt,
    this.note,
    this.attachments = const [],
  });

  factory DisciplinaryAction.fromJson(Map<String, dynamic> j) => DisciplinaryAction(
    id: _s(j['id']),
    type: _s(j['type']),
    occurredOn: _s(j['occurred_on']),
    description: _s(j['description']),
    issuedBy: _sn(j['issued_by_name']),
    suspensionFrom: _sn(j['suspension_from']),
    suspensionTo: _sn(j['suspension_to']),
    acknowledgedAt: _t(j['acknowledged_at']),
    note: _sn(j['acknowledgement_note']),
    attachments: [
      for (final a in _l(j['attachments'])) DisciplinaryAttachment(_s(a['name'], 'Adjunto'), _s(a['content_type']), _s(a['url'])),
    ],
  );

  final String id;
  final String type;
  final String occurredOn;
  final String description;
  final String? issuedBy;
  final String? suspensionFrom;
  final String? suspensionTo;
  final DateTime? acknowledgedAt;
  final String? note;
  final List<DisciplinaryAttachment> attachments;

  bool get pending => acknowledgedAt == null;

  String get typeLabel => switch (type) {
    'verbal' => 'Llamada de atención',
    'written' => 'Amonestación escrita',
    'suspension' => 'Suspensión',
    _ => 'Otra acción',
  };

  StatusBadge get badge => pending
      ? const StatusBadge(label: 'Por confirmar', variant: StatusBadgeVariant.inProgress)
      : const StatusBadge(label: 'Recibida', variant: StatusBadgeVariant.operative);
}

// ── Métricas ─────────────────────────────────────────────

class PersonMetrics {
  const PersonMetrics({
    required this.id,
    required this.name,
    this.role = '',
    this.roleKey = '',
    this.cleanings = 0,
    this.onTime = 0,
    this.avgMinutes = 0,
    this.late = 0,
    this.returned = 0,
    this.checklist = 0,
    this.tickets = 0,
    this.rank = 0,
    this.rankOf = 0,
  });

  factory PersonMetrics.fromJson(Map<String, dynamic> j) => PersonMetrics(
    id: _s(j['id']),
    name: _s(j['name']),
    role: _s(j['role']),
    roleKey: _s(j['role_key']),
    cleanings: _i(j['cleanings']),
    onTime: _i(j['on_time']),
    avgMinutes: _i(j['avg_minutes']),
    late: _i(j['late']),
    returned: _i(j['returned']),
    checklist: _d(j['checklist_compliance']),
    tickets: _i(j['tickets_reported']),
    rank: _i(j['rank']),
    rankOf: _i(j['rank_of']),
  );

  final String id;
  final String name;
  final String role;
  final String roleKey;
  final int cleanings;
  final int onTime;
  final int avgMinutes;
  final int late;
  final int returned;
  final double checklist;
  final int tickets;
  final int rank;
  final int rankOf;
}

class DayCount {
  const DayCount(this.date, this.count);

  final String date;
  final int count;
}

List<DayCount> _days(Object? v) => [for (final d in _l(v)) DayCount(_s(d['date']), _i(d['count']))];

class GoalProgress {
  const GoalProgress({
    required this.id,
    required this.title,
    required this.target,
    required this.current,
    required this.unit,
    required this.reward,
    required this.lowerIsBetter,
    required this.met,
    required this.period,
  });

  factory GoalProgress.fromJson(Map<String, dynamic> j) => GoalProgress(
    id: _s(j['id']),
    title: _s(j['title']),
    target: _d(j['target']),
    current: _d(j['current']),
    unit: _s(j['unit']),
    reward: _s(j['reward']),
    lowerIsBetter: _b(j['lower_is_better']),
    met: _b(j['met']),
    period: _s(j['period']),
  );

  final String id;
  final String title;
  final double target;
  final double current;
  final String unit;
  final String reward;
  final bool lowerIsBetter;
  final bool met;
  final String period;

  /// 0–1 para la barra: hacia la meta (o, si menos es mejor, lo que queda).
  double get progress {
    if (lowerIsBetter) {
      if (current <= target) return 1;
      return target <= 0 ? 0 : (target / current).clamp(0, 1).toDouble();
    }
    return target <= 0 ? 1 : (current / target).clamp(0, 1).toDouble();
  }

  static String _n(double v) => v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);

  /// "18 de 30 limpiezas" o "1 de máximo 1 retrasos".
  String get label => lowerIsBetter ? '${_n(current)} $unit · máximo ${_n(target)}' : '${_n(current)} de ${_n(target)} $unit';
}

class MyMetrics {
  const MyMetrics({required this.range, required this.me, required this.previous, required this.perDay, required this.goals});

  factory MyMetrics.fromJson(Map<String, dynamic> j) => MyMetrics(
    range: _s(j['range']),
    me: PersonMetrics.fromJson(Map<String, dynamic>.from(j['me'] as Map? ?? const {})),
    previous: PersonMetrics.fromJson(Map<String, dynamic>.from(j['previous'] as Map? ?? const {})),
    perDay: _days(j['per_day']),
    goals: [for (final g in _l(j['goals'])) GoalProgress.fromJson(g)],
  );

  final String range;
  final PersonMetrics me;
  final PersonMetrics previous;
  final List<DayCount> perDay;
  final List<GoalProgress> goals;
}

class TeamMetrics {
  const TeamMetrics({required this.range, required this.people, required this.cleanings, required this.onTime, required this.avgMinutes});

  factory TeamMetrics.fromJson(Map<String, dynamic> j) {
    final t = Map<String, dynamic>.from(j['totals'] as Map? ?? const {});
    return TeamMetrics(
      range: _s(j['range']),
      people: [for (final p in _l(j['people'])) PersonMetrics.fromJson(p)],
      cleanings: _i(t['cleanings']),
      onTime: _i(t['on_time']),
      avgMinutes: _i(t['avg_minutes']),
    );
  }

  final String range;
  final List<PersonMetrics> people;
  final int cleanings;
  final int onTime;
  final int avgMinutes;

  /// Roles presentes, en orden de aparición: (clave, nombre).
  List<(String, String)> get roles {
    final out = <(String, String)>[];
    for (final p in people) {
      if (!out.any((r) => r.$1 == p.roleKey)) out.add((p.roleKey, p.role.isEmpty ? 'Equipo' : p.role));
    }
    return out;
  }
}

// ── Reporte del propietario ──────────────────────────────

class PropertyReport {
  const PropertyReport({
    required this.code,
    required this.name,
    required this.occupancy,
    required this.nights,
    required this.cleanings,
    required this.tickets,
    required this.resolutionHours,
  });

  factory PropertyReport.fromJson(Map<String, dynamic> j) => PropertyReport(
    code: _s(j['code']),
    name: _s(j['name']),
    occupancy: _i(j['occupancy']),
    nights: _i(j['nights_booked']),
    cleanings: _i(j['cleanings']),
    tickets: _i(j['tickets']),
    resolutionHours: _d(j['avg_resolution_hours']),
  );

  final String code;
  final String name;
  final int occupancy;
  final int nights;
  final int cleanings;
  final int tickets;
  final double resolutionHours;
}

class MonthReport {
  const MonthReport({
    required this.month,
    required this.days,
    required this.occupancy,
    required this.cleanings,
    required this.tickets,
    required this.resolutionHours,
    required this.properties,
  });

  factory MonthReport.fromJson(Map<String, dynamic> j) {
    final t = Map<String, dynamic>.from(j['totals'] as Map? ?? const {});
    return MonthReport(
      month: _s(j['month']),
      days: _i(j['days']),
      occupancy: _i(t['occupancy']),
      cleanings: _i(t['cleanings']),
      tickets: _i(t['tickets']),
      resolutionHours: _d(t['avg_resolution_hours']),
      properties: [for (final p in _l(j['properties'])) PropertyReport.fromJson(p)],
    );
  }

  final String month;
  final int days;
  final int occupancy;
  final int cleanings;
  final int tickets;
  final double resolutionHours;
  final List<PropertyReport> properties;
}

/// "3.5 h" o "—".
String hoursLabel(double h) => h <= 0 ? '—' : (h < 1 ? '${(h * 60).round()} min' : '${h.toStringAsFixed(h < 10 ? 1 : 0)} h');
