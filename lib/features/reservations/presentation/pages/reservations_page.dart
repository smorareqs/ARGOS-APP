import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/hospitality/data/hospitality_repository.dart';
import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:argos_app/features/hospitality/models/reservation.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _Tab { arrivals, departures, inHouse, upcoming }

/// C5 · Reservas de hoy: llegadas, salidas, hospedados y próximas.
class ReservationsPage extends ConsumerStatefulWidget {
  const ReservationsPage({super.key});

  @override
  ConsumerState<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends ConsumerState<ReservationsPage> {
  var _tab = _Tab.arrivals;

  Future<void> _refresh() async {
    ref.invalidate(reservationsUpcomingProvider);
    await ref.refresh(reservationsTodayProvider.future).then((_) {}, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reservationsTodayProvider);
    final list = async.valueOrNull;
    final today = DateTime.now();

    Widget body;
    if (list == null && async.isLoading) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < 4; i++) ...[
            const Skeleton(width: double.infinity, height: 112, radius: CustomDimensions.radiusCard),
            const SizedBox(height: 12),
          ],
        ],
      );
    } else if (list == null) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ErrorState(
            message: async.error is DioException
                ? 'Sin conexión. Las reservas necesitan internet.'
                : errorMessage(async.error ?? 'Error'),
            onRetry: _refresh,
          ),
        ],
      );
    } else {
      final live = list.where((r) => r.status != ReservationStatus.cancelled && r.status != ReservationStatus.noShow);
      final arrivals = live.where((r) => r.arrivesOn(today)).toList()
        ..sort((a, b) => a.checkInTime.compareTo(b.checkInTime));
      final departures = live.where((r) => r.leavesOn(today)).toList()
        ..sort((a, b) => a.checkOutTime.compareTo(b.checkOutTime));
      final inHouse = live.where((r) => r.status == ReservationStatus.checkedIn && !r.leavesOn(today)).toList();
      final upcoming =
          ref
              .watch(reservationsUpcomingProvider)
              .valueOrNull
              ?.where((r) => r.status == ReservationStatus.confirmed || r.status == ReservationStatus.pending)
              .where((r) => r.checkInDate.isAfter(DateTime(today.year, today.month, today.day)))
              .toList() ??
          const <Reservation>[];
      final shown = switch (_tab) {
        _Tab.arrivals => arrivals,
        _Tab.departures => departures,
        _Tab.inHouse => inHouse,
        _Tab.upcoming => upcoming,
      };
      final pendingArrivals = arrivals.where((r) => r.status == ReservationStatus.confirmed).length;

      body = ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: CustomColors.primary,
                borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SummaryChip(value: '${arrivals.length}', label: 'Llegan'),
                  ),
                  Expanded(
                    child: SummaryChip(value: '${departures.length}', label: 'Salen'),
                  ),
                  Expanded(
                    child: SummaryChip(
                      value:
                          '${inHouse.length + departures.where((r) => r.status == ReservationStatus.checkedIn).length}',
                      label: 'En casa',
                    ),
                  ),
                  Expanded(
                    child: SummaryChip(
                      value: '$pendingArrivals',
                      label: 'Check-ins',
                      valueColor: pendingArrivals > 0 ? CustomColors.secondary : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilterChips<_Tab>(
            options: [
              FilterOption(value: _Tab.arrivals, label: 'Llegadas', count: arrivals.length),
              FilterOption(value: _Tab.departures, label: 'Salidas', count: departures.length),
              FilterOption(value: _Tab.inHouse, label: 'Hospedados', count: inHouse.length),
              FilterOption(value: _Tab.upcoming, label: 'Próximas', count: upcoming.length),
            ],
            selected: {_tab},
            onChanged: (s) => setState(() => _tab = s.isEmpty ? _tab : s.first),
          ),
          const SizedBox(height: 14),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: EmptyState(
                icon: CustomIcons.reservations,
                title: switch (_tab) {
                  _Tab.arrivals => 'Nadie llega hoy',
                  _Tab.departures => 'Nadie sale hoy',
                  _Tab.inHouse => 'Sin huéspedes en casa',
                  _Tab.upcoming => 'Sin llegadas esta semana',
                },
                message: 'Las reservas nuevas y las de los calendarios aparecen aquí.',
              ),
            )
          else
            for (final r in shown)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ReservationCard(
                  reservation: r,
                  focus: _tab == _Tab.departures ? ReservationFocus.departure : ReservationFocus.arrival,
                  onTap: () async {
                    await context.push('/reservations/${r.id}');
                    await _refresh();
                  },
                ),
              ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: CustomColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shortDay(today).toUpperCase(),
                    style: CustomTypography.label.copyWith(letterSpacing: 1.2, color: CustomColors.textMuted),
                  ),
                  Text('Reservas', style: CustomTypography.pageTitle),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(color: CustomColors.primary, onRefresh: _refresh, child: body),
            ),
          ],
        ),
      ),
    );
  }
}

enum ReservationFocus { arrival, departure }

/// Tarjeta de una reserva: hora, propiedad, huésped, canal y depósito.
class ReservationCard extends StatelessWidget {
  const ReservationCard({super.key, required this.reservation, this.onTap, this.focus = ReservationFocus.arrival});

  final Reservation reservation;
  final VoidCallback? onTap;
  final ReservationFocus focus;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final departure = focus == ReservationFocus.departure;
    final time = departure ? r.checkOutTime : r.checkInTime;
    final day = departure ? r.checkOutDate : r.checkInDate;
    final now = DateTime.now();
    final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: CustomColors.tealWashed, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text(time, style: CustomTypography.mono.copyWith(fontSize: 15, color: CustomColors.primary)),
                Text(
                  isToday ? (departure ? 'sale' : 'llega') : shortDay(day).split(' ').take(2).join(' '),
                  style: CustomTypography.label.copyWith(fontSize: 10, color: CustomColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.displayName,
                        style: CustomTypography.cardTitle.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusBadge(label: r.status.label, variant: r.status.badge),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.propertyCode} · ${r.propertyName}',
                  style: CustomTypography.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Tag(icon: CustomIcons.people, text: r.people),
                    _Tag(icon: CustomIcons.company, text: r.channelName),
                    if (r.needsDeposit)
                      _Tag(
                        icon: CustomIcons.deposit,
                        text: depositLabel(r.depositStatus),
                        warn: r.depositStatus == 'pending',
                      ),
                    if (r.hasCheckin && r.guestsPending > 0 && r.status == ReservationStatus.confirmed)
                      _Tag(icon: CustomIcons.document, text: 'Registro pendiente', warn: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text, this.warn = false});

  final IconData icon;
  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final fg = warn ? CustomColors.warning : CustomColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: warn ? CustomColors.warningSoft : CustomColors.neutralSoft,
        borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(text, style: CustomTypography.label.copyWith(fontSize: 11, color: fg)),
        ],
      ),
    );
  }
}
