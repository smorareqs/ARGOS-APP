import 'package:argos_app/features/hr/data/hr_repository.dart';
import 'package:argos_app/features/hr/models/hr.dart';
import 'package:argos_app/features/hr/presentation/widgets/hr_widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _ranges = [('week', 'Semana'), ('month', 'Mes')];

// ── B19 · Mis métricas ──────────────────────────────────

/// B19 · Mis métricas: período (semana o mes), cuatro cifras con su
/// tendencia, barras por día, mi puesto en mi rol y mis metas.
class MyMetricsPage extends ConsumerStatefulWidget {
  const MyMetricsPage({super.key});

  @override
  ConsumerState<MyMetricsPage> createState() => _MyMetricsPageState();
}

class _MyMetricsPageState extends ConsumerState<MyMetricsPage> {
  var _range = 'week';

  Future<void> _refresh() => ref.refresh(myMetricsProvider(_range).future).then((_) {}, onError: (_) {});

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myMetricsProvider(_range));
    final m = async.valueOrNull;

    Widget body;
    if (m == null && async.isLoading) {
      body = hrLoading(first: 200);
    } else if (m == null) {
      body = hrError(async.error, _refresh);
    } else {
      final me = m.me, prev = m.previous;
      final week = _range == 'week';
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          PeriodSwitch(options: _ranges, value: _range, onChanged: (r) => setState(() => _range = r)),
          const SizedBox(height: 16),
          MetricGrid(
            tiles: [
              MetricTile(icon: CustomIcons.cleaning, label: 'Limpiezas', value: '${me.cleanings}', delta: me.cleanings - prev.cleanings),
              MetricTile(
                icon: CustomIcons.time,
                label: 'Tiempo promedio',
                value: me.avgMinutes == 0 ? '—' : '${me.avgMinutes}',
                suffix: me.avgMinutes == 0 ? null : 'min',
                delta: me.avgMinutes == 0 || prev.avgMinutes == 0 ? null : me.avgMinutes - prev.avgMinutes,
                lowerIsBetter: true,
              ),
              MetricTile(
                icon: CustomIcons.doneAll,
                label: 'Checklist completo',
                value: me.cleanings == 0 ? '—' : me.checklist.toStringAsFixed(me.checklist == 100 ? 0 : 1),
                suffix: me.cleanings == 0 ? null : '%',
                delta: me.cleanings == 0 || prev.cleanings == 0 ? null : double.parse((me.checklist - prev.checklist).toStringAsFixed(1)),
              ),
              MetricTile(icon: CustomIcons.alarm, label: 'Retrasos', value: '${me.late}', delta: me.late - prev.late, lowerIsBetter: true),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(title: week ? 'Esta semana' : 'Este mes'),
          const SizedBox(height: 8),
          AppCard(child: DayBars(days: m.perDay)),
          if (me.rankOf > 1) ...[const SizedBox(height: 14), _RankCard(me: me)],
          const SizedBox(height: 22),
          SectionHeader(title: 'Mis metas · ${m.goals.length}'),
          const SizedBox(height: 8),
          if (m.goals.isEmpty)
            const EmptyState(
              icon: CustomIcons.metrics,
              title: 'Sin metas activas',
              message: 'Cuando RRHH publique una meta con premio, la verás aquí.',
            )
          else
            for (final g in m.goals) ...[GoalCard(goal: g), const SizedBox(height: 10)],
        ],
      );
    }

    return HrPage(title: 'Mis métricas', overline: 'Desempeño', onRefresh: _refresh, body: body);
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.me});

  final PersonMetrics me;

  @override
  Widget build(BuildContext context) {
    final top = me.rank <= 3;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: top ? CustomColors.warningSoft : CustomColors.surface,
        borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
        border: Border.all(color: top ? CustomColors.secondary.withValues(alpha: 0.35) : CustomColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: top ? CustomColors.secondary : CustomColors.track, shape: BoxShape.circle),
            child: Text(
              '#${me.rank}',
              style: CustomTypography.cardTitle.copyWith(color: top ? Colors.white : CustomColors.textPrimary, fontSize: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  me.rank == 1 ? '¡Vas en primer lugar!' : 'Puesto ${me.rank} de ${me.rankOf}',
                  style: CustomTypography.cardTitle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'Entre ${me.role.isEmpty ? 'tu equipo' : me.role.toLowerCase()} · por limpiezas y puntualidad',
                  style: CustomTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Métricas del equipo (supervisor) ─────────────────────

/// Métricas del equipo: totales y ranking por rol (C11 · Métricas de equipo).
class TeamMetricsPage extends ConsumerStatefulWidget {
  const TeamMetricsPage({super.key});

  @override
  ConsumerState<TeamMetricsPage> createState() => _TeamMetricsPageState();
}

class _TeamMetricsPageState extends ConsumerState<TeamMetricsPage> {
  var _range = 'week';

  Future<void> _refresh() => ref.refresh(teamMetricsProvider(_range).future).then((_) {}, onError: (_) {});

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teamMetricsProvider(_range));
    final t = async.valueOrNull;

    Widget body;
    if (t == null && async.isLoading) {
      body = hrLoading(first: 120);
    } else if (t == null) {
      body = hrError(async.error, _refresh);
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          PeriodSwitch(options: _ranges, value: _range, onChanged: (r) => setState(() => _range = r)),
          const SizedBox(height: 16),
          MetricGrid(
            tiles: [
              MetricTile(icon: CustomIcons.cleaning, label: 'Limpiezas', value: '${t.cleanings}'),
              MetricTile(icon: CustomIcons.doneAll, label: 'A tiempo', value: '${t.onTime}', suffix: '%'),
            ],
          ),
          for (final role in t.roles) ...[
            const SizedBox(height: 22),
            SectionHeader(title: role.$2),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, p) in t.people.where((p) => p.roleKey == role.$1).indexed) ...[
                    if (i > 0) const Divider(height: 1, color: CustomColors.divider, indent: 16, endIndent: 16),
                    _RankRow(person: p),
                  ],
                ],
              ),
            ),
          ],
          if (t.people.isEmpty) ...[
            const SizedBox(height: 30),
            const EmptyState(icon: CustomIcons.team, title: 'Sin datos del equipo', message: 'Aún no hay limpiezas terminadas.'),
          ],
        ],
      );
    }
    return HrPage(title: 'Métricas del equipo', overline: 'Ranking por rol', onRefresh: _refresh, body: body);
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.person});

  final PersonMetrics person;

  @override
  Widget build(BuildContext context) {
    final p = person;
    final medal = switch (p.rank) {
      1 => const Color(0xFFC5873C),
      2 => const Color(0xFF9AA3A8),
      3 => const Color(0xFFA9714B),
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${p.rank}',
              textAlign: TextAlign.center,
              style: CustomTypography.cardTitle.copyWith(fontSize: 16, color: medal ?? CustomColors.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          Avatar(name: p.name, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CustomTypography.label.copyWith(color: CustomColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  p.cleanings == 0
                      ? (p.tickets > 0 ? '${p.tickets} reportes' : 'Sin limpiezas')
                      : '${p.onTime}% a tiempo · ${p.avgMinutes} min · ${p.late} tarde',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CustomTypography.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${p.cleanings}', style: CustomTypography.data.copyWith(fontSize: 18)),
              Text('limpiezas', style: CustomTypography.bodySmall.copyWith(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── E3 · Reportes del propietario ────────────────────────

/// E3 · Reportes: mes, ocupación, limpiezas, incidencias y tiempo de
/// resolución, y el detalle por propiedad.
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key, this.showBack = false});

  final bool showBack;

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  String get _key => monthKey(_month);

  Future<void> _refresh() => ref.refresh(monthReportProvider(_key).future).then((_) {}, onError: (_) {});

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(monthReportProvider(_key));
    final r = async.valueOrNull;
    final current = monthKey(DateTime.now()) == _key;
    final label = monthLabel(_month);

    Widget body;
    if (r == null && async.isLoading) {
      body = hrLoading(first: 180);
    } else if (r == null) {
      body = hrError(async.error, _refresh);
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            children: [
              AppIconButton(
                icon: Icons.chevron_left_rounded,
                semanticLabel: 'Mes anterior',
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
              ),
              Expanded(
                child: Text(
                  label[0].toUpperCase() + label.substring(1),
                  textAlign: TextAlign.center,
                  style: CustomTypography.cardTitle.copyWith(fontSize: 17),
                ),
              ),
              AppIconButton(
                icon: Icons.chevron_right_rounded,
                semanticLabel: 'Mes siguiente',
                onPressed: current ? null : () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MetricGrid(
            tiles: [
              MetricTile(icon: CustomIcons.reservations, label: 'Ocupación', value: '${r.occupancy}', suffix: '%'),
              MetricTile(icon: CustomIcons.cleaning, label: 'Limpiezas', value: '${r.cleanings}'),
              MetricTile(icon: CustomIcons.incident, label: 'Incidencias', value: '${r.tickets}'),
              MetricTile(icon: CustomIcons.time, label: 'Tiempo de resolución', value: hoursLabel(r.resolutionHours)),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(title: 'Por propiedad · ${r.properties.length}'),
          const SizedBox(height: 8),
          if (r.properties.isEmpty)
            const EmptyState(icon: CustomIcons.properties, title: 'Sin propiedades', message: 'Aún no tienes propiedades asignadas.')
          else
            for (final p in r.properties) ...[_PropertyReportCard(report: p, days: r.days), const SizedBox(height: 10)],
        ],
      );
    }

    return HrPage(title: 'Reportes', overline: 'Mis propiedades', showBack: widget.showBack, onRefresh: _refresh, body: body);
  }
}

class _PropertyReportCard extends StatelessWidget {
  const _PropertyReportCard({required this.report, required this.days});

  final PropertyReport report;
  final int days;

  @override
  Widget build(BuildContext context) {
    final p = report;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(p.code, style: CustomTypography.mono.copyWith(fontSize: 13, color: CustomColors.tealMuted)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: CustomTypography.cardTitle.copyWith(fontSize: 15)),
              ),
              Text('${p.occupancy}%', style: CustomTypography.data.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(value: p.occupancy / 100, fillColor: CustomColors.primary),
          const SizedBox(height: 8),
          Text(
            '${p.nights} de $days noches · ${p.cleanings} limpiezas · '
            '${p.tickets == 1 ? '1 incidencia' : '${p.tickets} incidencias'}'
            '${p.resolutionHours > 0 ? ' · resueltas en ${hoursLabel(p.resolutionHours)}' : ''}',
            style: CustomTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
