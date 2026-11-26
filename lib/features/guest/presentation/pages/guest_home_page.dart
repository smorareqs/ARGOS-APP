import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/guest/models/guest.dart';
import 'package:argos_app/features/guest/presentation/providers/guest_session.dart';
import 'package:argos_app/features/guest/presentation/widgets/guest_widgets.dart';
import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// F1 · Mi reserva: fechas grandes, llegada y salida, instrucciones de la
/// empresa y accesos a áreas comunes, parqueo, reportar y ayuda. Cambia
/// según el momento: antes de llegar, durante y después (solo lectura).
class GuestHomePage extends ConsumerWidget {
  const GuestHomePage({super.key, this.now});

  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = guestMeOf(ref.watch(guestSessionProvider));
    final async = ref.watch(guestStayProvider);
    final stay = async.valueOrNull;
    Future<void> refresh() => ref.refresh(guestStayProvider.future).then((_) {}, onError: (_) {});

    Widget body;
    if (stay == null && async.isLoading) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Skeleton(width: double.infinity, height: 190, radius: CustomDimensions.radiusCard),
          SizedBox(height: 14),
          Skeleton(width: double.infinity, height: 120, radius: CustomDimensions.radiusCard),
        ],
      );
    } else if (stay == null) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ErrorState(
            message: async.error is DioException
                ? 'Sin conexión. Revisa tu internet.'
                : errorMessage(async.error ?? 'Error'),
            onRetry: refresh,
          ),
        ],
      );
    } else {
      body = _StayView(stay: stay, me: me, now: now ?? DateTime.now());
    }

    return Scaffold(
      backgroundColor: CustomColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (me?.tenantName ?? 'ARGOS').toUpperCase(),
                          style: CustomTypography.label.copyWith(letterSpacing: 1.2, color: CustomColors.textMuted),
                        ),
                        Text(me == null ? 'Mi reserva' : 'Hola, ${me.firstName}', style: CustomTypography.greeting),
                      ],
                    ),
                  ),
                  AppIconButton(
                    icon: CustomIcons.help,
                    semanticLabel: 'Ayuda',
                    onPressed: () => context.push('/guest/help'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(color: CustomColors.primary, onRefresh: refresh, child: body),
            ),
          ],
        ),
      ),
    );
  }
}

class _StayView extends StatelessWidget {
  const _StayView({required this.stay, required this.me, required this.now});

  final GuestStay stay;
  final GuestMe? me;
  final DateTime now;

  Future<void> _open(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && context.mounted) {
      showToast(context, 'No se pudo abrir.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = stay.phase(now);
    final done = phase == StayPhase.after;
    final status = switch (phase) {
      StayPhase.before => 'Te esperamos el ${shortDay(stay.checkInDate)} desde las ${stay.checkInTime}',
      StayPhase.during => 'Estás hospedado · salida ${shortDay(stay.checkOutDate)} a las ${stay.checkOutTime}',
      StayPhase.after => 'Gracias por tu visita',
    };
    final hasPlace = stay.lat != null || (stay.address ?? '').isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // Cabecera: propiedad, fechas grandes y código.
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: CustomColors.primary,
            borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  stay.building,
                  stay.propertyCode,
                ].whereType<String>().where((s) => s.isNotEmpty).join(' · ').toUpperCase(),
                style: CustomTypography.verdana(
                  fontSize: 10.5,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(stay.propertyName, style: CustomTypography.garamond(fontSize: 26, color: Colors.white)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _BigDate(label: 'Llegada', day: stay.checkInDate, time: stay.checkInTime),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(CustomIcons.arrowForward, color: Colors.white.withValues(alpha: 0.5), size: 20),
                  ),
                  _BigDate(label: 'Salida', day: stay.checkOutDate, time: stay.checkOutTime),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(CustomDimensions.radiusPill),
                    ),
                    child: Text(stay.code, style: CustomTypography.mono.copyWith(color: Colors.white, fontSize: 12.5)),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      '${stay.nights} ${stay.nights == 1 ? 'noche' : 'noches'} · ${stay.adults + stay.children} ${stay.adults + stay.children == 1 ? 'persona' : 'personas'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CustomTypography.verdana(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.75)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                done ? CustomIcons.verified : (phase == StayPhase.during ? CustomIcons.checkIn : CustomIcons.time),
                color: done ? CustomColors.success : CustomColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(status, style: CustomTypography.body.copyWith(fontSize: 14.5))),
            ],
          ),
        ),
        if ((me?.smartLocks ?? false) && !done) _LockCard(now: now),
        if (stay.instructions.isNotEmpty && !done) ...[
          const SizedBox(height: 22),
          const SectionHeader(title: 'Instrucciones de acceso'),
          const SizedBox(height: 10),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stay.instructions, style: CustomTypography.body.copyWith(fontSize: 14.5, height: 1.55)),
                if (hasPlace) ...[
                  const SizedBox(height: 14),
                  SecondaryButton(
                    label: 'Cómo llegar',
                    onPressed: () {
                      final dest = stay.lat != null && stay.lng != null
                          ? '${stay.lat},${stay.lng}'
                          : Uri.encodeComponent('${stay.propertyName}, ${stay.address}');
                      _open(context, Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$dest'));
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        const SectionHeader(title: 'Durante tu estancia'),
        const SizedBox(height: 10),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 184,
          ),
          children: [
            if (me?.chat ?? false)
              GuestActionTile(
                icon: CustomIcons.forum,
                title: 'Escribir a la empresa',
                subtitle: done ? 'Ver la conversación' : 'Te responde el equipo',
                onTap: () => context.push('/guest/chat'),
              ),
            if (me?.sharedAreas ?? false)
              GuestActionTile(
                icon: CustomIcons.sharedAreas,
                title: 'Áreas comunes',
                subtitle: stay.bookingsCount > 0
                    ? '${stay.bookingsCount} ${stay.bookingsCount == 1 ? 'reserva' : 'reservas'}'
                    : 'Piscina, salón y más',
                onTap: done ? null : () => context.push('/guest/areas'),
              ),
            if (me?.parking ?? false)
              GuestActionTile(
                icon: CustomIcons.parking,
                title: 'Mi parqueo',
                subtitle: stay.parkingCount > 0 ? 'Tienes espacio asignado' : 'Sin espacio todavía',
                onTap: () => context.push('/guest/parking'),
              ),
            GuestActionTile(
              icon: CustomIcons.incident,
              title: 'Reportar un problema',
              subtitle: 'Agua, luz, limpieza…',
              onTap: done ? null : () => context.push('/guest/report'),
            ),
            GuestActionTile(
              icon: CustomIcons.help,
              title: 'Ayuda',
              subtitle: 'Preguntas y contacto',
              onTap: () => context.push('/guest/help'),
            ),
          ],
        ),
        if (stay.contactPhone != null || stay.contactEmail != null) ...[
          const SizedBox(height: 22),
          SectionHeader(title: 'Contacto · ${stay.contactName}'),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (stay.contactPhone != null)
                  AppListTile(
                    icon: CustomIcons.phone,
                    title: stay.contactPhone!,
                    subtitle: 'Llamar',
                    onTap: () => _open(context, Uri(scheme: 'tel', path: stay.contactPhone)),
                  ),
                if (stay.contactEmail != null)
                  AppListTile(
                    icon: CustomIcons.email,
                    title: stay.contactEmail!,
                    subtitle: 'Escribir un correo',
                    onTap: () => _open(context, Uri(scheme: 'mailto', path: stay.contactEmail)),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BigDate extends StatelessWidget {
  const _BigDate({required this.label, required this.day, required this.time});

  final String label;
  final DateTime day;
  final String time;

  @override
  Widget build(BuildContext context) {
    final parts = shortDay(day).split(' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: CustomTypography.verdana(fontSize: 10, color: Colors.white.withValues(alpha: 0.55), letterSpacing: 1),
        ),
        const SizedBox(height: 2),
        Text('${parts[0]} ${parts[1]}', style: CustomTypography.garamond(fontSize: 30, color: Colors.white)),
        Text(
          '${parts[2]} · $time',
          style: CustomTypography.verdana(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
        ),
      ],
    );
  }
}

/// F1: el código de la puerta inteligente. Aparece 24 h antes de la llegada;
/// antes muestra cuándo estará.
class _LockCard extends ConsumerWidget {
  const _LockCard({required this.now});

  final DateTime now;

  String _when(DateTime d) =>
      '${shortDay(DateTime(d.year, d.month, d.day))} a las ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(guestLockProvider).valueOrNull;
    if (lock == null || !lock.hasLock) return const SizedBox.shrink();
    final code = lock.available ? lock.code : null;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CustomIcons.key, color: CustomColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lock.deviceName?.isNotEmpty == true ? 'Código · ${lock.deviceName}' : 'Código de la puerta',
                    style: CustomTypography.cardTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (code != null) ...[
              Semantics(
                label: 'Código ${code.split('').join(' ')}',
                excludeSemantics: true,
                child: Text(
                  code.split('').join(' '),
                  style: CustomTypography.mono.copyWith(
                    fontSize: 34,
                    letterSpacing: 2,
                    color: CustomColors.textPrimary,
                  ),
                ),
              ),
              if (lock.validFrom != null && lock.validTo != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Sirve desde el ${_when(lock.validFrom!)} hasta el ${_when(lock.validTo!)}.',
                  style: CustomTypography.bodySmall,
                ),
              ],
            ] else
              Text(
                lock.message.isNotEmpty
                    ? lock.message
                    : lock.showsAt != null
                    ? 'Tu código aparecerá aquí el ${_when(lock.showsAt!)}.'
                    : 'Tu código aparecerá aquí 24 horas antes de tu llegada.',
                style: CustomTypography.body.copyWith(fontSize: 14.5),
              ),
          ],
        ),
      ),
    );
  }
}
