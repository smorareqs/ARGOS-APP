import 'dart:async';
import 'dart:io';

import 'package:argos_app/core/location/location_service.dart';
import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/hr/data/hr_repository.dart';
import 'package:argos_app/features/hr/models/hr.dart';
import 'package:argos_app/features/hr/presentation/widgets/hr_widgets.dart';
import 'package:argos_app/features/tickets/presentation/widgets/draft_photos.dart';
import 'package:argos_app/features/uploads/data/repositories/upload_queue.dart';
import 'package:argos_app/features/uploads/models/pending_upload.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// B15 · Asistencia: botón grande de entrada o salida con la hora, el
/// estado de hoy, foto opcional y el historial del mes. Marcar pide la
/// ubicación (obligatoria en el servidor).
class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _photo = DraftPhotos('attendance-selfie', entity: 'attendance');
  late final UploadQueue _queue;
  Timer? _tick;
  var _busy = false;

  String get _key => monthKey(_month);
  bool get _isCurrent => monthKey(DateTime.now()) == _key;

  @override
  void initState() {
    super.initState();
    _queue = ref.read(uploadQueueProvider);
    _tick = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _photo.discard(_queue);
    super.dispose();
  }

  Future<void> _refresh() => ref.refresh(myAttendanceProvider(_key).future).then((_) {}, onError: (_) {});

  Future<void> _punch(bool entering, List<PendingUpload> photos) async {
    if (photos.isNotEmpty && !DraftPhotos.allUploaded(photos)) {
      showToast(context, 'Espera a que termine de subir la foto.');
      return;
    }
    setState(() => _busy = true);
    try {
      final point = await ref.read(locationServiceProvider).current();
      final ids = DraftPhotos.fileIds(photos);
      final r = await ref
          .read(hrRepositoryProvider)
          .clock(entering: entering, lat: point.lat, lng: point.lng, photoFileId: ids.isEmpty ? null : ids.last);
      unawaited(HapticFeedback.mediumImpact());
      await _photo.discard(_queue);
      ref.invalidate(myAttendanceProvider(monthKey(DateTime.now())));
      if (!mounted) return;
      showToast(
        context,
        entering
            ? 'Entrada registrada a las ${hm(r.clockIn)}.'
            : 'Salida registrada a las ${hm(r.clockOut ?? DateTime.now())}. Trabajaste ${durationLabel(r.workedMinutes ?? 0)}.',
      );
    } on LocationException catch (e) {
      if (!mounted) return;
      showToast(context, e.message);
      if (e.openSettings) unawaited(ref.read(locationServiceProvider).openSettings());
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
      // Si el estado cambió en otro teléfono, recarga.
      ref.invalidate(myAttendanceProvider(monthKey(DateTime.now())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _moveMonth(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myAttendanceProvider(_key));
    final data = async.valueOrNull;
    final photos = _photo.of(ref);

    Widget body;
    if (data == null && async.isLoading) {
      body = hrLoading(first: 320);
    } else if (data == null) {
      body = hrError(async.error, _refresh, offline: 'Sin conexión. Para marcar necesitas internet.');
    } else {
      final now = DateTime.now();
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_isCurrent) ...[
            _ClockCard(
              now: now,
              open: data.open,
              schedule: data.scheduleFor(now),
              today: data.items.where((r) => r.date == _dayKey(now)).toList(),
              busy: _busy,
              photos: photos,
              onPunch: (entering) => _punch(entering, photos),
              onPhoto: () => _photo.take(context, ref, module: 'attendance', kind: 'selfie', title: 'Foto del marcaje', maxPhotos: 1),
              onRemovePhoto: () => _photo.discard(_queue),
            ),
            const SizedBox(height: 22),
          ],
          _MonthBar(label: monthLabel(_month), onPrev: () => _moveMonth(-1), onNext: _isCurrent ? null : () => _moveMonth(1)),
          const SizedBox(height: 12),
          MetricGrid(
            tiles: [
              MetricTile(
                icon: CustomIcons.time,
                label: 'Horas del mes',
                value: (data.workedMinutes / 60).toStringAsFixed(data.workedMinutes % 60 == 0 ? 0 : 1),
                suffix: 'h',
              ),
              MetricTile(icon: CustomIcons.calendar, label: 'Días trabajados', value: '${data.daysWorked}'),
            ],
          ),
          const SizedBox(height: 10),
          _LateStrip(count: data.lateCount),
          const SizedBox(height: 22),
          SectionHeader(title: 'Historial · ${data.items.length}'),
          const SizedBox(height: 8),
          if (data.items.isEmpty)
            const EmptyState(icon: CustomIcons.time, title: 'Sin marcajes este mes', message: 'Aquí verás tus entradas y salidas.')
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < data.items.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: CustomColors.divider, indent: 16, endIndent: 16),
                    _HistoryRow(record: data.items[i], now: now),
                  ],
                ],
              ),
            ),
        ],
      );
    }

    return HrPage(title: 'Asistencia', overline: weekdayDay(DateTime.now()), onRefresh: _refresh, body: body);
  }
}

String _dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class _ClockCard extends StatelessWidget {
  const _ClockCard({
    required this.now,
    required this.open,
    required this.schedule,
    required this.today,
    required this.busy,
    required this.photos,
    required this.onPunch,
    required this.onPhoto,
    required this.onRemovePhoto,
  });

  final DateTime now;
  final AttendanceRecord? open;
  final String? schedule;
  final List<AttendanceRecord> today;
  final bool busy;
  final List<PendingUpload> photos;
  final ValueChanged<bool> onPunch;
  final VoidCallback onPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final entering = open == null;
    final closedToday = today.where((r) => !r.open).toList();
    final workedToday = today.fold<int>(0, (a, r) => a + r.minutesAt(now));
    final String status;
    if (!entering) {
      status = 'Entraste a las ${hm(open!.clockIn)} · llevas ${durationLabel(open!.minutesAt(now))}';
    } else if (closedToday.isNotEmpty) {
      status = 'Saliste a las ${hm(closedToday.first.clockOut!)} · hoy ${durationLabel(workedToday)}';
    } else {
      status = 'Aún no marcas tu entrada';
    }
    final photo = photos.lastOrNull;
    final uploading = photo != null && photo.status != UploadStatus.done;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: CustomColors.primary,
        borderRadius: BorderRadius.circular(CustomDimensions.radiusLg),
        boxShadow: CustomShadows.cta,
      ),
      child: Column(
        children: [
          Text(hm(now), style: CustomTypography.display.copyWith(color: Colors.white, fontSize: 48, height: 1, letterSpacing: -1)),
          const SizedBox(height: 6),
          Text(
            schedule == null ? 'Hoy no tienes horario asignado' : 'Tu horario hoy: $schedule',
            style: CustomTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.72)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _ClockButton(entering: entering, busy: busy || uploading, onTap: () => onPunch(entering)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(entering ? CustomIcons.time : CustomIcons.done, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                    style: CustomTypography.label.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CustomIcons.location, size: 15, color: Colors.white70),
              const SizedBox(width: 6),
              Flexible(
                child: Text('Se guarda tu ubicación al marcar', style: CustomTypography.bodySmall.copyWith(color: Colors.white70)),
              ),
              const SizedBox(width: 12),
              if (photo == null)
                _PhotoChip(label: 'Foto (opcional)', icon: CustomIcons.camera, onTap: busy ? null : onPhoto)
              else
                _PhotoChip(
                  label: uploading ? 'Subiendo…' : 'Quitar foto',
                  thumb: File(photo.localPath),
                  onTap: busy ? null : onRemovePhoto,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoChip extends StatelessWidget {
  const _PhotoChip({required this.label, required this.onTap, this.icon, this.thumb});

  final String label;
  final IconData? icon;
  final File? thumb;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
      child: InkWell(
        borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (thumb != null)
                ClipOval(child: Image.file(thumb!, width: 22, height: 22, fit: BoxFit.cover))
              else
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(icon, size: 15, color: Colors.white),
                ),
              const SizedBox(width: 6),
              Text(label, style: CustomTypography.bodySmall.copyWith(color: Colors.white, fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón redondo grande: verde para entrar, ámbar para salir.
class _ClockButton extends StatelessWidget {
  const _ClockButton({required this.entering, required this.busy, required this.onTap});

  final bool entering;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = entering ? CustomColors.success : CustomColors.secondary;
    final label = entering ? 'Marcar entrada' : 'Marcar salida';
    return Semantics(
      button: true,
      label: label,
      child: Container(
        width: 176,
        height: 176,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
        child: Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: busy ? null : onTap,
            child: Center(
              child: busy
                  ? const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(entering ? CustomIcons.login : CustomIcons.logout, size: 40, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(label, style: CustomTypography.button.copyWith(color: Colors.white, fontSize: 15)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({required this.label, required this.onPrev, required this.onNext});

  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIconButton(icon: Icons.chevron_left_rounded, semanticLabel: 'Mes anterior', onPressed: onPrev),
        Expanded(
          child: Text(
            label[0].toUpperCase() + label.substring(1),
            textAlign: TextAlign.center,
            style: CustomTypography.cardTitle.copyWith(fontSize: 17),
          ),
        ),
        AppIconButton(icon: Icons.chevron_right_rounded, semanticLabel: 'Mes siguiente', onPressed: onNext),
      ],
    );
  }
}

class _LateStrip extends StatelessWidget {
  const _LateStrip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ok = count == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ok ? CustomColors.successSoft : CustomColors.warningSoft,
        borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
      ),
      child: Row(
        children: [
          Icon(ok ? CustomIcons.verified : CustomIcons.alarm, size: 18, color: ok ? CustomColors.success : CustomColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ok
                  ? 'Ninguna llegada tarde este mes. ¡Bien!'
                  : count == 1
                  ? '1 llegada tarde este mes (más de 10 min después de tu horario).'
                  : '$count llegadas tarde este mes (más de 10 min después de tu horario).',
              style: CustomTypography.bodySmall.copyWith(color: CustomColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.record, required this.now});

  final AttendanceRecord record;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final day = DateTime.tryParse(r.date) ?? r.clockIn;
    final tags = <Widget>[
      if (r.open) const StatusBadge(label: 'En curso', variant: StatusBadgeVariant.inProgress),
      if (r.late) const StatusBadge(label: 'Tarde', variant: StatusBadgeVariant.incident),
      if (r.autoclosed) const StatusBadge(label: 'Sin salida', variant: StatusBadgeVariant.incident),
      if (r.manual) const StatusBadge(label: 'Corregido'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${day.day}', style: CustomTypography.cardTitle.copyWith(fontSize: 20, height: 1)),
                Text(weekdayDay(day).split(' ').first, style: CustomTypography.bodySmall),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hm(r.clockIn)} – ${r.clockOut == null ? '…' : hm(r.clockOut!)}',
                  style: CustomTypography.body.copyWith(color: CustomColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                if (tags.isNotEmpty) ...[const SizedBox(height: 6), Wrap(spacing: 6, runSpacing: 6, children: tags)],
                if (r.editReason != null) ...[
                  const SizedBox(height: 4),
                  Text('Nota de RRHH: ${r.editReason}', style: CustomTypography.bodySmall),
                ],
              ],
            ),
          ),
          Text(durationLabel(r.minutesAt(now)), style: CustomTypography.label.copyWith(color: CustomColors.textSecondary)),
        ],
      ),
    );
  }
}
