import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/guest/data/guest_repository.dart';
import 'package:argos_app/features/guest/models/guest.dart';
import 'package:argos_app/features/guest/presentation/providers/guest_session.dart';
import 'package:argos_app/features/guest/presentation/widgets/guest_widgets.dart';
import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// F3 · Áreas comunes de mi edificio y F5 · Mis reservas de áreas (cancelar
/// hasta 1 h antes).
class GuestAreasPage extends ConsumerWidget {
  const GuestAreasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(guestAreasProvider);
    final data = async.valueOrNull;
    Future<void> refresh() => ref.refresh(guestAreasProvider.future).then((_) {}, onError: (_) {});

    Future<void> cancel(AreaBooking b) async {
      final ok = await showConfirmSheet(
        context,
        title: 'Cancelar tu reserva',
        message: '${b.areaName}, ${shortDay(parseDay(b.date))} de ${b.start} a ${b.end}.',
        confirmLabel: 'Cancelar reserva',
        cancelLabel: 'Mantener',
        destructive: true,
      );
      if (!ok) return;
      try {
        await ref.read(guestRepositoryProvider).cancel(b.id);
        if (context.mounted) showToast(context, 'Reserva cancelada.');
        await refresh();
      } catch (e) {
        if (context.mounted) showToast(context, errorMessage(e));
      }
    }

    Widget body;
    if (data == null && async.isLoading) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < 3; i++) ...[
            const Skeleton(width: double.infinity, height: 96, radius: CustomDimensions.radiusCard),
            const SizedBox(height: 12),
          ],
        ],
      );
    } else if (data == null) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [ErrorState(message: errorMessage(async.error ?? 'Error'), onRetry: refresh)],
      );
    } else {
      final now = DateTime.now();
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (data.areas.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: EmptyState(
                icon: CustomIcons.sharedAreas,
                title: 'Tu edificio no tiene áreas para reservar',
                message: 'Si tienes dudas, pregunta en la recepción.',
              ),
            )
          else
            for (final a in data.areas)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  onTap: () => context.push('/guest/areas/${a.id}', extra: a),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      AreaArtBox(art: a.photo),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.name, style: CustomTypography.cardTitle),
                            const SizedBox(height: 2),
                            Text('${a.hours} · bloques de ${a.block} min', style: CustomTypography.bodySmall),
                            Text(
                              'Hasta ${a.capacity} personas · máximo ${a.maxPerDay} por día',
                              style: CustomTypography.bodySmall.copyWith(color: CustomColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(CustomIcons.chevronRight, color: CustomColors.textMuted),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 14),
          SectionHeader(title: 'Mis reservas', number: data.bookings.isEmpty ? null : '${data.bookings.length}'),
          const SizedBox(height: 10),
          if (data.bookings.isEmpty)
            Text('Aún no tienes áreas reservadas.', style: CustomTypography.bodySmall)
          else
            for (final b in data.bookings)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BookingTile(booking: b, onCancel: b.cancellable(now) ? () => cancel(b) : null),
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
            const GuestHeader(title: 'Áreas comunes'),
            Expanded(
              child: RefreshIndicator(color: CustomColors.primary, onRefresh: refresh, child: body),
            ),
          ],
        ),
      ),
    );
  }
}

/// F4 · Reservar área: día dentro de la estancia, bloques (libre, lleno o
/// pasado), cuántas personas y confirmación inmediata.
class GuestAreaPage extends ConsumerStatefulWidget {
  const GuestAreaPage({super.key, required this.areaId, this.area});

  final String areaId;
  final SharedArea? area;

  @override
  ConsumerState<GuestAreaPage> createState() => _GuestAreaPageState();
}

class _GuestAreaPageState extends ConsumerState<GuestAreaPage> {
  DateTime? _day;
  String? _start;
  int _people = 1;
  bool _busy = false;

  Future<void> _book(SharedArea area, AreaSlot slot) async {
    setState(() => _busy = true);
    try {
      final b = await ref.read(guestRepositoryProvider).book(area.id, _day!, slot.start, _people);
      HapticFeedback.mediumImpact();
      ref.invalidate(guestAreasProvider);
      ref.invalidate(guestStayProvider);
      if (!mounted) return;
      await showArgosSheet<void>(
        context,
        builder: (ctx) => SheetScaffold(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 76,
                decoration: const BoxDecoration(color: CustomColors.successSoft, shape: BoxShape.circle),
                child: const Icon(CustomIcons.check, color: CustomColors.success, size: 34),
              ),
              const SizedBox(height: 16),
              Text('¡Listo!', style: CustomTypography.sectionTitle),
              const SizedBox(height: 6),
              Text(
                '${b.areaName}\n${shortDay(parseDay(b.date))} de ${b.start} a ${b.end}',
                textAlign: TextAlign.center,
                style: CustomTypography.body,
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Entendido', onPressed: () => Navigator.of(ctx).pop()),
            ],
          ),
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
      ref.invalidate(guestSlotsProvider((area.id, dayKey(_day!))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final areas = ref.watch(guestAreasProvider).valueOrNull;
    final area = widget.area ?? areas?.areas.where((a) => a.id == widget.areaId).firstOrNull;
    final stay = ref.watch(guestStayProvider).valueOrNull;
    if (area == null || stay == null) {
      return const Scaffold(
        backgroundColor: CustomColors.background,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator(color: CustomColors.primary)),
        ),
      );
    }
    final today = DateUtils.dateOnly(DateTime.now());
    final days = stay.days.where((d) => !d.isBefore(today) && d.difference(today).inDays <= area.advanceDays).toList();
    final day = _day ?? (days.isEmpty ? null : days.first);
    _day = day;
    final mine = (areas?.bookings ?? const <AreaBooking>[])
        .where((b) => b.areaId == area.id && day != null && b.date == dayKey(day))
        .map((b) => b.start)
        .toSet();
    final slotsAsync = day == null ? null : ref.watch(guestSlotsProvider((area.id, dayKey(day))));
    final slots = slotsAsync?.valueOrNull;
    final selected = slots?.where((s) => s.start == _start).firstOrNull;

    return Scaffold(
      backgroundColor: CustomColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GuestHeader(title: area.name, subtitle: '${area.building} · ${area.hours}'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (area.rules.isNotEmpty)
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(CustomIcons.info, color: CustomColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(area.rules, style: CustomTypography.bodySmall.copyWith(height: 1.5))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  const SectionHeader(title: 'Día'),
                  const SizedBox(height: 10),
                  if (days.isEmpty)
                    Text('No quedan días de tu estancia para reservar.', style: CustomTypography.bodySmall)
                  else
                    SizedBox(
                      height: 76,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: days.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final d = days[i];
                          return SizedBox(
                            width: 48,
                            child: Row(
                              children: [
                                WeekDayChip(
                                  weekday: ['L', 'M', 'M', 'J', 'V', 'S', 'D'][d.weekday - 1],
                                  day: '${d.day}',
                                  selected: d == day,
                                  onTap: () => setState(() {
                                    _day = d;
                                    _start = null;
                                  }),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),
                  SectionHeader(title: 'Horario', number: 'Máx. ${area.maxPerDay} por día'),
                  const SizedBox(height: 10),
                  if (slotsAsync == null)
                    const SizedBox.shrink()
                  else if (slots == null && slotsAsync.isLoading)
                    const Skeleton(width: double.infinity, height: 120, radius: CustomDimensions.radiusCard)
                  else if (slots == null)
                    ErrorState(
                      message: errorMessage(slotsAsync.error ?? 'Error'),
                      onRetry: () => ref.invalidate(guestSlotsProvider((area.id, dayKey(day!)))),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in slots)
                          _SlotChip(
                            slot: s,
                            mine: mine.contains(s.start),
                            selected: s.start == _start,
                            onTap: s.available && !mine.contains(s.start)
                                ? () => setState(() => _start = s.start)
                                : null,
                          ),
                      ],
                    ),
                  const SizedBox(height: 22),
                  const SectionHeader(title: '¿Cuántas personas?'),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: NumberStepper(
                      value: _people,
                      min: 1,
                      max: selected == null ? area.capacity : selected.left.clamp(1, area.capacity),
                      unit: _people == 1 ? 'persona' : 'personas',
                      semanticLabel: 'Personas',
                      onChanged: (v) => setState(() => _people = v),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(
                label: selected == null ? 'Elige un horario' : 'Reservar ${selected.start} – ${selected.end}',
                isLoading: _busy,
                onPressed: selected == null || _people > selected.left ? null : () => _book(area, selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({required this.slot, required this.mine, required this.selected, this.onTap});

  final AreaSlot slot;
  final bool mine;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, note) = switch ((mine, selected, slot.available)) {
      (true, _, _) => (CustomColors.secondary, CustomColors.onSecondary, CustomColors.secondary, 'Tuya'),
      (_, true, _) => (CustomColors.primary, Colors.white, CustomColors.primary, '${slot.left} libres'),
      (_, _, true) => (CustomColors.surface, CustomColors.primary, CustomColors.primary, '${slot.left} libres'),
      _ => (CustomColors.surfaceSoft, CustomColors.textMuted, CustomColors.border, slot.past ? 'Pasó' : 'Lleno'),
    };
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: 'De ${slot.start} a ${slot.end}, $note',
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 98,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                Text(slot.start, style: CustomTypography.mono.copyWith(fontSize: 15, color: fg)),
                const SizedBox(height: 2),
                Text(note, style: CustomTypography.verdana(fontSize: 10.5, color: fg.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// F6 · Mi parqueo.
class GuestParkingPage extends ConsumerWidget {
  const GuestParkingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(guestParkingProvider);
    final list = async.valueOrNull;
    Future<void> refresh() => ref.refresh(guestParkingProvider.future).then((_) {}, onError: (_) {});

    Widget body;
    if (list == null && async.isLoading) {
      body = const Padding(
        padding: EdgeInsets.all(16),
        child: Skeleton(width: double.infinity, height: 220, radius: CustomDimensions.radiusCard),
      );
    } else if (list == null) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [ErrorState(message: errorMessage(async.error ?? 'Error'), onRetry: refresh)],
      );
    } else if (list.isEmpty) {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          EmptyState(
            icon: CustomIcons.parking,
            title: 'Aún no tienes parqueo',
            message: 'Si llegas en carro, pide un espacio a la recepción con tu placa.',
          ),
        ],
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          for (final p in list) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CustomColors.primary,
                borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
              ),
              child: Column(
                children: [
                  Text(
                    'TU ESPACIO',
                    style: CustomTypography.verdana(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(p.spaceCode, style: CustomTypography.garamond(fontSize: 64, color: Colors.white)),
                  Text(
                    [p.building, p.level, if (p.covered) 'techado'].where((s) => s.isNotEmpty).join(' · '),
                    style: CustomTypography.verdana(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppListTile(icon: CustomIcons.car, title: p.plate, subtitle: 'Placa registrada', showChevron: false),
                  AppListTile(
                    icon: CustomIcons.calendar,
                    title: '${shortDay(parseDay(p.from))} → ${shortDay(parseDay(p.to))}',
                    subtitle: 'Vigente durante tu estancia',
                    showChevron: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Muestra tu placa en la garita. Si cambias de carro, avisa a la recepción.',
            textAlign: TextAlign.center,
            style: CustomTypography.bodySmall,
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
            const GuestHeader(title: 'Mi parqueo'),
            Expanded(
              child: RefreshIndicator(color: CustomColors.primary, onRefresh: refresh, child: body),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lo que pasa, en chips (F7). La urgencia sale del tipo.
enum _Problem {
  cleaning('Limpieza', CustomIcons.cleaning, 'low'),
  air('Aire', Icons.ac_unit_rounded, 'medium'),
  water('Agua', Icons.water_drop_outlined, 'high'),
  light('Luz', Icons.lightbulb_outline_rounded, 'high'),
  noise('Ruido', Icons.volume_up_outlined, 'medium'),
  other('Otro', CustomIcons.more, 'medium');

  const _Problem(this.label, this.icon, this.urgency);
  final String label;
  final IconData icon;
  final String urgency;
}

/// F7 · Reportar un problema: qué pasa y una descripción.
class GuestReportPage extends ConsumerStatefulWidget {
  const GuestReportPage({super.key});

  @override
  ConsumerState<GuestReportPage> createState() => _GuestReportPageState();
}

class _GuestReportPageState extends ConsumerState<GuestReportPage> {
  _Problem? _kind;
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final kind = _kind!;
    setState(() => _busy = true);
    try {
      final desc = _text.text.trim();
      final number = await ref
          .read(guestRepositoryProvider)
          .report(
            title: desc.isEmpty
                ? 'Problema de ${kind.label.toLowerCase()}'
                : '${kind.label}: ${desc.length > 80 ? '${desc.substring(0, 80)}…' : desc}',
            description: desc,
            urgency: kind.urgency,
          );
      if (!mounted) return;
      showToast(context, 'Recibimos tu reporte #$number. Te ayudamos pronto.');
      context.pop();
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Reportar un problema',
      subtitle: 'Lo recibe el equipo de mantenimiento.',
      onBack: () => context.pop(),
      footer: PrimaryButton(label: 'Enviar reporte', isLoading: _busy, onPressed: _kind == null ? null : _send),
      children: [
        LabeledField(
          label: '¿Qué pasa?',
          field: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _Problem.values)
                ChoiceChip(
                  avatar: Icon(p.icon, size: 18, color: _kind == p ? Colors.white : CustomColors.primary),
                  label: Text(p.label),
                  selected: _kind == p,
                  showCheckmark: false,
                  selectedColor: CustomColors.primary,
                  labelStyle: CustomTypography.verdana(
                    fontSize: 13,
                    color: _kind == p ? Colors.white : CustomColors.textPrimary,
                  ),
                  onSelected: (_) => setState(() => _kind = p),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LabeledField(
          label: 'Cuéntanos más (opcional)',
          field: AppTextField(controller: _text, hintText: 'Ej. la ducha del baño principal no calienta', maxLines: 4),
        ),
      ],
    );
  }
}

/// F9 · Ayuda: preguntas frecuentes, contacto y cerrar sesión de huésped.
class GuestHelpPage extends ConsumerWidget {
  const GuestHelpPage({super.key});

  static const _faq = [
    (
      '¿A qué hora puedo entrar y salir?',
      'La hora de llegada y de salida está en Mi reserva. Si necesitas otro horario, pregunta a la recepción.',
    ),
    (
      '¿Cómo reservo la piscina u otra área?',
      'En Áreas comunes eliges el día y el horario. La confirmación es inmediata y puedes cancelar hasta 1 hora antes.',
    ),
    (
      'Algo no funciona en la propiedad',
      'Usa "Reportar un problema". Lo recibe el equipo de mantenimiento al momento.',
    ),
    ('¿Hasta cuándo puedo usar la app?', 'Hasta 24 horas después de tu salida. Después, la sesión se cierra sola.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = guestMeOf(ref.watch(guestSessionProvider));
    final stay = ref.watch(guestStayProvider).valueOrNull;
    return Scaffold(
      backgroundColor: CustomColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GuestHeader(title: 'Ayuda'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  for (final (q, a) in _faq)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: Text(
                              q,
                              style: CustomTypography.body.copyWith(fontSize: 14.5, fontWeight: FontWeight.w600),
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                            iconColor: CustomColors.primary,
                            children: [Text(a, style: CustomTypography.bodySmall.copyWith(height: 1.5))],
                          ),
                        ),
                      ),
                    ),
                  if (stay?.contactPhone != null) ...[
                    const SizedBox(height: 12),
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: AppListTile(
                        icon: CustomIcons.phone,
                        title: stay!.contactPhone!,
                        subtitle: 'Contacto de ${stay.contactName}',
                        showChevron: false,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (me != null)
                    Text(
                      'Entraste como ${me.name} · ${me.reservationCode}',
                      textAlign: TextAlign.center,
                      style: CustomTypography.bodySmall,
                    ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Cerrar sesión de huésped',
                    onPressed: () async {
                      final ok = await showConfirmSheet(
                        context,
                        title: 'Cerrar sesión',
                        message: 'Para volver a entrar necesitas tu código y tu correo.',
                        confirmLabel: 'Cerrar sesión',
                      );
                      if (ok) await ref.read(guestSessionProvider.notifier).signOut();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Atajo para pruebas y la app: el huésped de la sesión o null.
GuestMe? currentGuest(WidgetRef ref) => guestMeOf(ref.watch(guestSessionProvider));
