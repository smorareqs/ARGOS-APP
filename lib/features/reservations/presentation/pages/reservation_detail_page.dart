import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/hospitality/data/hospitality_repository.dart';
import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:argos_app/features/hospitality/models/reservation.dart';
import 'package:argos_app/features/reservations/presentation/widgets/reservation_sheets.dart';
import 'package:argos_app/features/security/presentation/widgets/security_widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// C6 · Detalle de reserva: estado, fechas y código; huéspedes con su
/// registro, depósito, parqueo, áreas, inspecciones y línea de tiempo. La
/// acción principal cambia con el estado (check-in, check-out, inspección).
class ReservationDetailPage extends ConsumerStatefulWidget {
  const ReservationDetailPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  ConsumerState<ReservationDetailPage> createState() => _ReservationDetailPageState();
}

class _ReservationDetailPageState extends ConsumerState<ReservationDetailPage> {
  var _busy = false;

  String get _id => widget.reservationId;

  Future<void> _reload() => ref.refresh(reservationDetailProvider(_id).future).then((_) {}, onError: (_) {});

  bool _can(String permission) {
    final auth = ref.read(sessionControllerProvider);
    return auth is AuthSignedIn && auth.session.can(permission);
  }

  bool get _parkingOn {
    final auth = ref.read(sessionControllerProvider);
    return auth is AuthSignedIn && (auth.session.tenant.features['parking'] ?? false);
  }

  Future<void> _checkIn(ReservationDetail d) async {
    final blockers = d.checkInBlockers(DateTime.now());
    if (blockers.isNotEmpty) {
      await showArgosSheet<void>(context, builder: (_) => CheckInBlockersSheet(blockers: blockers));
      return;
    }
    final r = d.reservation;
    final ok = await showConfirmSheet(
      context,
      title: 'Confirmar check-in',
      message:
          '${r.displayName} entra a ${r.propertyName} ahora (${hhmm(DateTime.now())}). '
          'Sale el ${shortDay(r.checkOutDate)} a las ${r.checkOutTime}. Le enviamos el acceso a la app por correo.',
      confirmLabel: 'Confirmar check-in',
    );
    if (!ok) return;
    await _run(() => ref.read(hospitalityRepositoryProvider).checkIn(_id), 'Check-in hecho. ¡Bienvenidos!');
  }

  Future<void> _checkOut(ReservationDetail d) async {
    final r = d.reservation;
    final ok = await showConfirmSheet(
      context,
      title: 'Confirmar check-out',
      message:
          '${r.displayName} deja ${r.propertyName}. Se cancelan sus alarmas de salida y se libera el parqueo al terminar el día.',
      confirmLabel: 'Hacer check-out',
    );
    if (!ok) return;
    final done = await _run(() => ref.read(hospitalityRepositoryProvider).checkOut(_id), 'Check-out hecho.');
    if (done && mounted && r.hasCheckin && _can('tasks.validate')) {
      final inspect = await showConfirmSheet(
        context,
        title: '¿Inspeccionar ahora?',
        message: 'La inspección de salida registra daños y permite devolver o retener el depósito.',
        confirmLabel: 'Hacer inspección',
        cancelLabel: 'Después',
      );
      if (inspect && mounted) await _inspect('post_departure');
    }
  }

  Future<void> _inspect(String kind) async {
    await context.push('/reservations/$_id/inspection?kind=$kind');
    await _reload();
  }

  Future<bool> _run(Future<Object?> Function() fn, String success) async {
    setState(() => _busy = true);
    try {
      await fn();
      HapticFeedback.mediumImpact();
      if (mounted) showToast(context, success);
      await _reload();
      return true;
    } on Object catch (e) {
      if (mounted) showToast(context, errorMessage(e));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deposit(ReservationDetail d, DepositMode mode) async {
    final saved = await showDepositSheet(context, detail: d, mode: mode);
    if (saved) await _reload();
  }

  Future<void> _guest(ReservationDetail d, [StayGuest? g]) async {
    final saved = await showGuestSheet(context, detail: d, guest: g);
    if (saved) await _reload();
  }

  Future<void> _parking(ReservationDetail d) async {
    final saved = await showParkingSheet(context, detail: d);
    if (saved) await _reload();
  }

  Widget? _footer(ReservationDetail d) {
    final r = d.reservation;
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    if (r.status == ReservationStatus.confirmed && !r.checkInDate.isAfter(day) && _can('reservations.checkin')) {
      return PrimaryButton(
        label: 'Hacer check-in',
        trailingIcon: CustomIcons.checkIn,
        isLoading: _busy,
        onPressed: () => _checkIn(d),
      );
    }
    if (r.status == ReservationStatus.checkedIn && _can('reservations.checkin')) {
      return PrimaryButton(
        label: 'Hacer check-out',
        trailingIcon: CustomIcons.checkOut,
        isLoading: _busy,
        onPressed: () => _checkOut(d),
      );
    }
    if (r.status == ReservationStatus.checkedOut && d.inspection('post_departure') == null && _can('tasks.validate')) {
      return PrimaryButton(
        label: 'Registrar inspección',
        trailingIcon: CustomIcons.inspection,
        onPressed: () => _inspect('post_departure'),
      );
    }
    if (r.status == ReservationStatus.checkedOut && d.deposit.balance > 0 && _can('deposits.manage')) {
      return PrimaryButton(
        label: 'Liquidar depósito',
        trailingIcon: CustomIcons.deposit,
        onPressed: () => _deposit(d, DepositMode.returned),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reservationDetailProvider(_id));
    final d = async.valueOrNull;

    if (d == null) {
      return Scaffold(
        backgroundColor: CustomColors.background,
        appBar: AppBar(backgroundColor: CustomColors.background, elevation: 0, foregroundColor: CustomColors.primary),
        body: async.isLoading
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  Skeleton(width: double.infinity, height: 160, radius: CustomDimensions.radiusCard),
                  SizedBox(height: 14),
                  Skeleton(width: double.infinity, height: 220, radius: CustomDimensions.radiusCard),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: ErrorState(
                  message: async.error is DioException
                      ? 'Sin conexión. La reserva necesita internet.'
                      : errorMessage(async.error ?? 'Error'),
                  onRetry: _reload,
                ),
              ),
      );
    }

    final r = d.reservation;
    final canGuests = _can('reservations.checkin') || _can('guests.manage');
    final today = DateTime.now();
    final blockers =
        r.status == ReservationStatus.confirmed && !r.checkInDate.isAfter(DateTime(today.year, today.month, today.day))
        ? d.checkInBlockers(today)
        : const <String>[];

    return DetailScaffold(
      overline: '${r.propertyCode} · ${r.channelName}'.toUpperCase(),
      title: r.displayName,
      subtitle:
          '${shortDay(r.checkInDate)} → ${shortDay(r.checkOutDate)} · ${r.nights} ${r.nights == 1 ? 'noche' : 'noches'}',
      status: StatusBadge(label: r.status.label, variant: r.status.badge),
      onBack: () => context.pop(),
      banner: blockers.isEmpty ? null : DetailBanner(message: 'Antes del check-in: ${blockers.join(' ')}'),
      footer: _footer(d),
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Stamp(label: 'Llegada', day: r.checkInDate, time: r.checkInTime),
                  ),
                  const Icon(CustomIcons.arrowForward, color: CustomColors.textMuted, size: 18),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _Stamp(label: 'Salida', day: r.checkOutDate, time: r.checkOutTime),
                  ),
                ],
              ),
              const Divider(height: 28, color: CustomColors.divider),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CÓDIGO',
                          style: CustomTypography.label.copyWith(fontSize: 10, color: CustomColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(r.code, style: CustomTypography.mono.copyWith(fontSize: 15)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PERSONAS',
                          style: CustomTypography.label.copyWith(fontSize: 10, color: CustomColors.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(r.people, style: CustomTypography.body.copyWith(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              if (r.notes != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: CustomColors.surfaceSoft, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(CustomIcons.notes, size: 18, color: CustomColors.tealMuted),
                      const SizedBox(width: 8),
                      Expanded(child: Text(r.notes!, style: CustomTypography.body.copyWith(fontSize: 14))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(title: 'Huéspedes · ${d.guests.length}'),
        const SizedBox(height: 10),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final g in d.guests)
                AppListTile(
                  leading: Avatar(name: g.fullName, size: 40),
                  title: g.isPrimary ? '${g.fullName} · principal' : g.fullName,
                  subtitle: r.hasCheckin ? g.missingLabel : (g.email ?? 'Sin correo'),
                  trailing: r.hasCheckin
                      ? Icon(
                          g.registered ? CustomIcons.verified : CustomIcons.pending,
                          color: g.registered ? CustomColors.success : CustomColors.warning,
                          size: 20,
                        )
                      : null,
                  onTap: canGuests ? () => _guest(d, g) : null,
                  showChevron: canGuests,
                ),
              if (d.guests.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aún no hay huéspedes. Agrega al principal para confirmar y hacer el check-in.'),
                ),
              if (canGuests && r.status != ReservationStatus.checkedOut)
                AppListTile(
                  icon: CustomIcons.add,
                  title: 'Agregar huésped',
                  onTap: () => _guest(d),
                  showChevron: false,
                ),
            ],
          ),
        ),
        if (d.deposit.available && (r.needsDeposit || d.deposit.transactions.isNotEmpty)) ...[
          const SizedBox(height: 22),
          const SectionHeader(title: 'Depósito'),
          const SizedBox(height: 10),
          _DepositCard(
            detail: d,
            onReceive: _can('deposits.manage') && d.deposit.received == 0
                ? () => _deposit(d, DepositMode.received)
                : null,
            onReturn: _can('deposits.manage') && d.deposit.balance > 0 && r.status == ReservationStatus.checkedOut
                ? () => _deposit(d, DepositMode.returned)
                : null,
            onRetain: _can('deposits.manage') && d.deposit.balance > 0 && r.status == ReservationStatus.checkedOut
                ? () => _deposit(d, DepositMode.retained)
                : null,
          ),
        ],
        if (_parkingOn) ...[
          const SizedBox(height: 22),
          const SectionHeader(title: 'Parqueo'),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final p in d.parking)
                  AppListTile(
                    leading: PlateTag(p.plate),
                    title: 'Espacio ${p.spaceCode}',
                    subtitle: [p.level, if (p.covered) 'techado'].where((s) => s.isNotEmpty).join(' · '),
                    showChevron: false,
                  ),
                if (d.parking.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Sin espacio asignado.')),
                if (_can('parking.manage') &&
                    r.status != ReservationStatus.checkedOut &&
                    r.status != ReservationStatus.cancelled)
                  AppListTile(
                    icon: CustomIcons.parking,
                    title: 'Asignar espacio',
                    onTap: () => _parking(d),
                    showChevron: false,
                  ),
              ],
            ),
          ),
        ],
        if (d.bookings.isNotEmpty) ...[
          const SizedBox(height: 22),
          SectionHeader(title: 'Áreas reservadas · ${d.bookings.length}'),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final b in d.bookings)
                  AppListTile(
                    icon: CustomIcons.sharedAreas,
                    title: '${b.areaName} · ${b.start}–${b.end}',
                    subtitle: '${shortDay(parseDay(b.date))} · ${b.people} ${b.people == 1 ? 'persona' : 'personas'}',
                    showChevron: false,
                  ),
              ],
            ),
          ),
        ],
        if (r.hasCheckin || d.inspections.isNotEmpty) ...[
          const SizedBox(height: 22),
          const SectionHeader(title: 'Inspecciones'),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final i in d.inspections) _InspectionTile(inspection: i),
                if (d.inspection('pre_arrival') == null &&
                    r.status == ReservationStatus.confirmed &&
                    _can('tasks.validate'))
                  AppListTile(
                    icon: CustomIcons.inspection,
                    title: 'Inspección antes de la llegada',
                    subtitle: 'Fotos de cómo está la propiedad',
                    onTap: () => _inspect('pre_arrival'),
                  ),
                if (d.inspections.isEmpty && !_can('tasks.validate'))
                  const Padding(padding: EdgeInsets.all(16), child: Text('Sin inspecciones.')),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        const SectionHeader(title: 'Línea de tiempo'),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            children: [
              for (var i = 0; i < d.events.length; i++)
                TimelineItem(
                  title: d.events[i].title,
                  time: '${shortDay(d.events[i].createdAt)} · ${hhmm(d.events[i].createdAt)}',
                  detail: d.events[i].actorName,
                  tone: switch (d.events[i].type) {
                    'checked_in' || 'deposit_received' => TimelineTone.success,
                    'checked_out' => TimelineTone.info,
                    'cancelled' || 'no_show' || 'deposit_retained' => TimelineTone.error,
                    'guest_ticket' => TimelineTone.warning,
                    _ => TimelineTone.neutral,
                  },
                  isFirst: i == 0,
                  isLast: i == d.events.length - 1,
                ),
              if (d.events.isEmpty)
                const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('Sin movimientos.')),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.day, required this.time});

  final String label;
  final DateTime day;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: CustomTypography.label.copyWith(fontSize: 10, color: CustomColors.textMuted)),
        const SizedBox(height: 2),
        Text(shortDay(day), style: CustomTypography.garamond(fontSize: 22, color: CustomColors.primary)),
        Text(time, style: CustomTypography.mono.copyWith(fontSize: 13, color: CustomColors.textSecondary)),
      ],
    );
  }
}

class _DepositCard extends StatelessWidget {
  const _DepositCard({required this.detail, this.onReceive, this.onReturn, this.onRetain});

  final ReservationDetail detail;
  final VoidCallback? onReceive;
  final VoidCallback? onReturn;
  final VoidCallback? onRetain;

  @override
  Widget build(BuildContext context) {
    final dep = detail.deposit;
    final cur = detail.reservation.currency;
    final pending = dep.status == 'pending';
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      money(dep.amount ?? 0, cur),
                      style: CustomTypography.garamond(fontSize: 28, color: CustomColors.primary),
                    ),
                    Text(depositLabel(dep.status), style: CustomTypography.bodySmall),
                  ],
                ),
              ),
              StatusBadge(
                label: pending ? 'Pendiente' : (dep.balance > 0 ? 'En garantía' : 'Liquidado'),
                variant: pending
                    ? StatusBadgeVariant.pending
                    : (dep.balance > 0 ? StatusBadgeVariant.inProgress : StatusBadgeVariant.operative),
              ),
            ],
          ),
          if (dep.transactions.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final t in dep.transactions)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      t.type == 'received'
                          ? CustomIcons.add
                          : (t.type == 'returned' ? CustomIcons.arrowBack : CustomIcons.remove),
                      size: 16,
                      color: t.type == 'retained' ? CustomColors.error : CustomColors.tealMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${t.typeLabel} · ${DepositTx.methodLabel(t.method)}${t.reference == null ? '' : ' · ${t.reference}'}',
                        style: CustomTypography.body.copyWith(fontSize: 14),
                      ),
                    ),
                    Text(money(t.amount, cur), style: CustomTypography.mono.copyWith(fontSize: 13.5)),
                  ],
                ),
              ),
          ],
          if (dep.charges > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Hallazgos con cargo: ${money(dep.charges, cur)}',
              style: CustomTypography.bodySmall.copyWith(color: CustomColors.error),
            ),
          ],
          if (dep.inspectionRequired) ...[
            const SizedBox(height: 6),
            Text(
              'Falta la inspección de salida para liquidar.',
              style: CustomTypography.bodySmall.copyWith(color: CustomColors.warning),
            ),
          ],
          if (onReceive != null) ...[
            const SizedBox(height: 14),
            SecondaryButton(label: 'Registrar depósito', onPressed: onReceive),
          ],
          if (onReturn != null || onRetain != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (onReturn != null)
                  Expanded(
                    child: SecondaryButton(label: 'Devolver', onPressed: onReturn),
                  ),
                if (onReturn != null && onRetain != null) const SizedBox(width: 10),
                if (onRetain != null)
                  Expanded(
                    child: TertiaryButton(label: 'Retener', onPressed: onRetain),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InspectionTile extends StatelessWidget {
  const _InspectionTile({required this.inspection});

  final Inspection inspection;

  @override
  Widget build(BuildContext context) {
    final i = inspection;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CustomIcons.inspection, size: 20, color: CustomColors.tealMuted),
              const SizedBox(width: 10),
              Expanded(child: Text(i.label, style: CustomTypography.cardTitle.copyWith(fontSize: 15))),
              Text('${i.photos.length} fotos', style: CustomTypography.bodySmall),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 2),
            child: Text(
              '${i.byName ?? 'Sin nombre'} · ${shortDay(i.performedAt)} ${hhmm(i.performedAt)}',
              style: CustomTypography.bodySmall,
            ),
          ),
          for (final f in i.findings)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: switch (f.severity) {
                        'high' => CustomColors.error,
                        'medium' => CustomColors.warning,
                        _ => CustomColors.textMuted,
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${f.area}: ${f.description}'
                      '${f.estimatedCost == null ? '' : ' · ${money(f.estimatedCost!)}'}'
                      '${f.chargeToDeposit ? ' · al depósito' : ''}'
                      '${f.ticketNumber == null ? '' : ' · ticket #${f.ticketNumber}'}',
                      style: CustomTypography.body.copyWith(fontSize: 13.5),
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
