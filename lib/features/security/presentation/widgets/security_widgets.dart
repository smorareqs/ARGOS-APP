import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/hospitality/data/hospitality_repository.dart';
import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:argos_app/features/hospitality/models/reservation.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Placa en estilo de matrícula (mono, borde).
class PlateTag extends StatelessWidget {
  const PlateTag(this.plate, {super.key, this.dark = false});

  final String plate;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.12) : CustomColors.surfaceSoft,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: 0.3) : CustomColors.borderField),
      ),
      child: Text(
        plate,
        style: CustomTypography.mono.copyWith(
          fontSize: 12,
          letterSpacing: 0.8,
          color: dark ? Colors.white : CustomColors.primary,
        ),
      ),
    );
  }
}

/// Una estancia del tablero: hora grande, propiedad, huésped y placas.
class StayCard extends StatelessWidget {
  const StayCard({super.key, required this.stay, required this.time, this.alarm, this.onTap});

  final BoardStay stay;

  /// Hora que importa en la sección (entrada o salida).
  final String time;
  final SecurityAlarm? alarm;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = alarm;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(time, style: CustomTypography.mono.copyWith(fontSize: 16, color: CustomColors.primary)),
                const SizedBox(height: 2),
                Text(
                  stay.propertyCode,
                  style: CustomTypography.label.copyWith(fontSize: 10, color: CustomColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stay.guestName, style: CustomTypography.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text('${stay.propertyName} · ${stay.people}', style: CustomTypography.bodySmall),
                if (stay.plates.isNotEmpty || a != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final p in stay.plates) PlateTag(p),
                      if (a != null) AlarmPill(alarm: a),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(CustomIcons.chevronRight, color: CustomColors.textMuted, size: 20),
        ],
      ),
    );
  }
}

/// "Sonando", "18:30" o "Atendida" con su color.
class AlarmPill extends StatelessWidget {
  const AlarmPill({super.key, required this.alarm});

  final SecurityAlarm alarm;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, text) = switch (alarm.status) {
      AlarmStatus.fired => (CustomColors.errorSoft, CustomColors.error, 'Sonando'),
      AlarmStatus.scheduled => (CustomColors.warningSoft, CustomColors.warning, 'Alarma ${hhmm(alarm.fireAt)}'),
      AlarmStatus.attended => (CustomColors.successSoft, CustomColors.success, 'Atendida'),
      AlarmStatus.cancelled => (CustomColors.neutralSoft, CustomColors.textSecondary, 'Cancelada'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(CustomDimensions.radiusPill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CustomIcons.alarm, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(text, style: CustomTypography.label.copyWith(fontSize: 11, color: fg)),
        ],
      ),
    );
  }
}

/// Tarjeta de una alarma de salida (D2).
class AlarmCard extends StatelessWidget {
  const AlarmCard({super.key, required this.alarm, required this.onAttend, this.onOpen});

  final SecurityAlarm alarm;
  final VoidCallback? onAttend;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final a = alarm;
    final done = !a.open;
    final firing = a.status == AlarmStatus.fired;
    return AppCard(
      onTap: onOpen,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
          border: firing ? Border.all(color: CustomColors.error.withValues(alpha: 0.5), width: 1.5) : null,
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: done
                        ? CustomColors.neutralSoft
                        : (firing ? CustomColors.errorSoft : CustomColors.warningSoft),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(done ? CustomIcons.doneAll : CustomIcons.alarm, color: a.tone, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${a.exact ? 'Salida' : 'Salida en 30 min'} · ${a.propertyCode}',
                        style: CustomTypography.cardTitle.copyWith(
                          fontSize: 16,
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: done ? CustomColors.textSecondary : CustomColors.primary,
                        ),
                      ),
                      Text('${a.guestName} · ${a.propertyName}', style: CustomTypography.bodySmall),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(hhmm(a.fireAt), style: CustomTypography.mono.copyWith(fontSize: 15, color: a.tone)),
                    Text(a.status.label, style: CustomTypography.label.copyWith(fontSize: 10.5, color: a.tone)),
                  ],
                ),
              ],
            ),
            if (a.plates.isNotEmpty || a.notes != null || a.attendedByName != null) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final p in a.plates) PlateTag(p)]),
              if (a.attendedByName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Atendió ${a.attendedByName}${a.attendedAt == null ? '' : ' a las ${hhmm(a.attendedAt!)}'}'
                    '${a.notes == null ? '' : ' · "${a.notes}"'}',
                    style: CustomTypography.bodySmall,
                  ),
                ),
            ],
            if (onAttend != null && a.open) ...[
              const SizedBox(height: 12),
              PrimaryButton(label: 'Marcar atendida', trailingIcon: CustomIcons.check, onPressed: onAttend),
            ],
          ],
        ),
      ),
    );
  }
}

/// Hoja para marcar una alarma atendida con nota opcional. Devuelve true si
/// se marcó.
Future<bool> showAttendSheet(BuildContext context, WidgetRef ref, SecurityAlarm alarm) async {
  final done = await showArgosSheet<bool>(context, builder: (_) => _AttendSheet(alarm: alarm));
  return done ?? false;
}

class _AttendSheet extends ConsumerStatefulWidget {
  const _AttendSheet({required this.alarm});

  final SecurityAlarm alarm;

  @override
  ConsumerState<_AttendSheet> createState() => _AttendSheetState();
}

class _AttendSheetState extends ConsumerState<_AttendSheet> {
  final _notes = TextEditingController();
  var _busy = false;

  static const _quick = ['Salió a tiempo', 'Entregó llaves en garita', 'Pidió salida tarde', 'No responde'];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(hospitalityRepositoryProvider).attend(widget.alarm.id, _notes.text);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showToast(context, errorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.alarm;
    return SheetScaffold(
      title: 'Marcar atendida',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${a.guestName} · ${a.propertyCode} · salida ${a.checkOutTime}', style: CustomTypography.body),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final q in _quick)
                AppChip(
                  label: q,
                  onTap: () => setState(() {
                    _notes.text = q;
                    _notes.selection = TextSelection.collapsed(offset: q.length);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Nota (opcional)',
            field: AppTextField(controller: _notes, hintText: 'Qué pasó', maxLines: 3),
          ),
          const SizedBox(height: 18),
          PrimaryButton(label: 'Marcar atendida', isLoading: _busy, onPressed: _save),
        ],
      ),
    );
  }
}

/// D3 · Ficha de un huésped activo para seguridad: sin documentos ni
/// contacto.
Future<void> showStaySheet(BuildContext context, {required String reservationId, BoardStay? preview}) =>
    showArgosSheet<void>(
      context,
      builder: (_) => _StaySheet(reservationId: reservationId, preview: preview),
    );

class _StaySheet extends ConsumerWidget {
  const _StaySheet({required this.reservationId, this.preview});

  final String reservationId;
  final BoardStay? preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reservationDetailProvider(reservationId));
    final d = async.valueOrNull;
    final p = preview;
    final name = d?.reservation.displayName ?? p?.guestName ?? '';
    final today = DateTime.now();
    final todayBookings = [
      for (final b in d?.bookings ?? const <AreaBooking>[])
        if (b.date == dayKey(today)) b,
    ];

    return SheetScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: CustomTypography.pageTitle.copyWith(fontSize: 24))),
              if (d != null) StatusBadge(label: d.reservation.status.label, variant: d.reservation.status.badge),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              d?.reservation.propertyName ?? p?.propertyName,
              d?.reservation.propertyCode ?? p?.propertyCode,
            ].whereType<String>().join(' · '),
            style: CustomTypography.bodySmall,
          ),
          const SizedBox(height: 16),
          if (d == null && async.isLoading)
            const Skeleton(width: double.infinity, height: 160, radius: CustomDimensions.radiusCard)
          else if (d == null)
            ErrorState(
              message: errorMessage(async.error ?? 'Error'),
              onRetry: () => ref.invalidate(reservationDetailProvider(reservationId)),
            )
          else ...[
            _InfoRow(
              icon: CustomIcons.checkIn,
              label: 'Llegada',
              value: '${shortDay(d.reservation.checkInDate)} · ${d.reservation.checkInTime}',
            ),
            _InfoRow(
              icon: CustomIcons.checkOut,
              label: 'Salida',
              value: '${shortDay(d.reservation.checkOutDate)} · ${d.reservation.checkOutTime}',
            ),
            _InfoRow(icon: CustomIcons.people, label: 'Personas', value: d.reservation.people),
            _InfoRow(icon: CustomIcons.reservations, label: 'Código', value: d.reservation.code, mono: true),
            if (d.guests.length > 1)
              _InfoRow(
                icon: CustomIcons.guest,
                label: 'Acompañantes',
                value: d.guests.where((g) => !g.isPrimary).map((g) => g.fullName).join(', '),
              ),
            const SizedBox(height: 10),
            const SectionHeader(title: 'Vehículos'),
            const SizedBox(height: 8),
            if (d.parking.isEmpty)
              Text('Sin parqueo asignado.', style: CustomTypography.bodySmall)
            else
              for (final s in d.parking)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      PlateTag(s.plate),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Espacio ${s.spaceCode}${s.level.isEmpty ? '' : ' · ${s.level}'}',
                          style: CustomTypography.body,
                        ),
                      ),
                    ],
                  ),
                ),
            if (todayBookings.isNotEmpty) ...[
              const SizedBox(height: 10),
              const SectionHeader(title: 'Áreas hoy'),
              const SizedBox(height: 8),
              for (final b in todayBookings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${b.start}–${b.end} · ${b.areaName} · ${b.people} ${b.people == 1 ? 'persona' : 'personas'}',
                    style: CustomTypography.body,
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.mono = false});

  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: CustomColors.tealMuted),
          const SizedBox(width: 10),
          SizedBox(width: 104, child: Text(label, style: CustomTypography.bodySmall)),
          Expanded(
            child: Text(
              value,
              style: mono
                  ? CustomTypography.mono.copyWith(fontSize: 14)
                  : CustomTypography.body.copyWith(fontSize: 14.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un contador del encabezado oscuro del tablero.
class BoardCounter extends StatelessWidget {
  const BoardCounter({super.key, required this.value, required this.label, this.alert = false});

  final int value;
  final String label;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: CustomTypography.garamond(
              fontSize: 30,
              color: alert && value > 0 ? CustomColors.secondary : Colors.white,
            ),
          ),
          Text(label, style: CustomTypography.verdana(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}

/// Texto de la reserva en una línea, para listas cortas.
String stayLine(Reservation r) => '${r.propertyCode} · ${r.displayName}';
