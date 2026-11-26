import 'dart:math' as math;

import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/hr/models/hr.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla de la fase 5 abierta desde Perfil o Más: volver, título,
/// subtítulo y el contenido con "tirar para recargar".
class HrPage extends StatelessWidget {
  const HrPage({super.key, required this.title, required this.body, this.overline, this.onRefresh, this.showBack = true, this.trailing});

  final String title;
  final String? overline;
  final Widget body;
  final Future<void> Function()? onRefresh;
  final bool showBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final content = onRefresh == null ? body : RefreshIndicator(color: CustomColors.primary, onRefresh: onRefresh!, child: body);
    return Scaffold(
      backgroundColor: CustomColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(showBack ? 8 : 24, showBack ? 4 : 16, 16, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showBack) ...[
                    AppIconButton(icon: CustomIcons.arrowBack, semanticLabel: 'Volver', onPressed: () => context.pop()),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (overline != null)
                          Text(
                            overline!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CustomTypography.label.copyWith(letterSpacing: 1.2, color: CustomColors.textMuted),
                          ),
                        Text(title, style: CustomTypography.pageTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

/// Lista de esqueletos mientras carga.
Widget hrLoading({int cards = 4, double first = 150}) => ListView(
  padding: const EdgeInsets.all(16),
  physics: const AlwaysScrollableScrollPhysics(),
  children: [
    Skeleton(width: double.infinity, height: first, radius: CustomDimensions.radiusCard),
    for (var i = 0; i < cards; i++) ...[
      const SizedBox(height: 12),
      const Skeleton(width: double.infinity, height: 74, radius: CustomDimensions.radiusCard),
    ],
  ],
);

/// Error con reintento (sin conexión, o lo que diga el servidor).
Widget hrError(Object? error, Future<void> Function() retry, {String offline = 'Sin conexión. Esta pantalla necesita internet.'}) =>
    ListView(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [ErrorState(message: error is DioException ? offline : errorMessage(error ?? 'Error'), onRetry: retry)],
    );

/// Una cifra con su etiqueta y, si hay, la comparación con el período anterior.
class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.label, required this.value, this.icon, this.delta, this.lowerIsBetter = false, this.suffix});

  final String label;
  final String value;
  final String? suffix;
  final IconData? icon;

  /// Diferencia contra el período anterior (positiva = subió).
  final num? delta;
  final bool lowerIsBetter;

  @override
  Widget build(BuildContext context) {
    final d = delta;
    final good = d == null || d == 0 ? null : ((d > 0) != lowerIsBetter);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: CustomColors.surface,
        borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
        border: Border.all(color: CustomColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[Icon(icon, size: 16, color: CustomColors.tealMuted), const SizedBox(width: 6)],
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: CustomTypography.bodySmall),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: CustomTypography.display.copyWith(fontSize: 28, height: 1.05)),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(suffix!, style: CustomTypography.bodySmall),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 18,
            child: d == null
                ? null
                : Row(
                    children: [
                      Icon(
                        d == 0 ? Icons.remove_rounded : (d > 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
                        size: 13,
                        color: good == null ? CustomColors.textMuted : (good ? CustomColors.success : CustomColors.error),
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          d == 0
                              ? 'Igual que antes'
                              : '${d.abs() == d.abs().roundToDouble() ? d.abs().toInt() : d.abs().toStringAsFixed(1)} vs. antes',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: CustomTypography.bodySmall.copyWith(
                            fontSize: 11.5,
                            color: good == null ? CustomColors.textMuted : (good ? CustomColors.success : CustomColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Dos [MetricTile] por fila.
class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: 10),
              Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// Barras por día (limpiezas). Resalta hoy y pone la letra del día debajo.
class DayBars extends StatelessWidget {
  const DayBars({super.key, required this.days, this.height = 120});

  final List<DayCount> days;
  final double height;

  @override
  Widget build(BuildContext context) {
    final top = math.max(1, days.fold<int>(0, (a, d) => math.max(a, d.count)));
    final today = DateUtils.dateOnly(DateTime.now());
    const letters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final dense = days.length > 10;
    return SizedBox(
      height: height + 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in days)
            Expanded(
              child: Builder(
                builder: (context) {
                  final date = DateTime.tryParse(d.date) ?? today;
                  final isToday = DateUtils.isSameDay(date, today);
                  return Semantics(
                    label: '${weekdayDay(date)}: ${d.count} limpiezas',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: dense ? 1.5 : 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 14,
                            child: !dense && d.count > 0
                                ? Text('${d.count}', style: CustomTypography.bodySmall.copyWith(fontSize: 11, height: 1.2))
                                : null,
                          ),
                          const SizedBox(height: 3),
                          AnimatedContainer(
                            duration: CustomMotion.base,
                            height: math.max(3, (height - 16) * d.count / top),
                            decoration: BoxDecoration(
                              color: isToday ? CustomColors.secondary : (d.count == 0 ? CustomColors.track : CustomColors.primary),
                              borderRadius: BorderRadius.circular(dense ? 3 : 6),
                            ),
                          ),
                          const SizedBox(height: 5),
                          SizedBox(
                            height: 16,
                            child: Text(
                              dense ? (date.day % 5 == 0 ? '${date.day}' : '') : letters[date.weekday - 1],
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: CustomTypography.bodySmall.copyWith(
                                fontSize: 11,
                                height: 1.2,
                                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                                color: isToday ? CustomColors.textPrimary : CustomColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Meta con su barra de avance.
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal});

  final GoalProgress goal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(goal.title, style: CustomTypography.cardTitle.copyWith(fontSize: 16))),
              if (goal.met)
                const StatusBadge(label: 'Cumplida', variant: StatusBadgeVariant.operative)
              else
                Text(goal.period, style: CustomTypography.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          ProgressBar(value: goal.progress),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text(goal.label, style: CustomTypography.bodySmall)),
              const Icon(Icons.card_giftcard_rounded, size: 15, color: CustomColors.secondary),
              const SizedBox(width: 4),
              Text(goal.reward, style: CustomTypography.label.copyWith(color: CustomColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Selector de período segmentado (Semana · Mes, etc.).
class PeriodSwitch extends StatelessWidget {
  const PeriodSwitch({super.key, required this.options, required this.value, required this.onChanged});

  final List<(String, String)> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: CustomColors.track, borderRadius: BorderRadius.circular(CustomDimensions.radiusPill)),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: Semantics(
                selected: o.$1 == value,
                button: true,
                child: GestureDetector(
                  onTap: () => onChanged(o.$1),
                  child: AnimatedContainer(
                    duration: CustomMotion.base,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: o.$1 == value ? CustomColors.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
                      boxShadow: o.$1 == value ? CustomShadows.card : null,
                    ),
                    child: Text(
                      o.$2,
                      style: CustomTypography.label.copyWith(color: o.$1 == value ? CustomColors.textPrimary : CustomColors.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
