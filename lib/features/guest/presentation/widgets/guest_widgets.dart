import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Cabecera de las pantallas del huésped: volver y título.
class GuestHeader extends StatelessWidget {
  const GuestHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Volver',
            icon: const Icon(CustomIcons.arrowBack, color: CustomColors.primary),
            onPressed: () => context.canPop() ? context.pop() : context.go('/guest'),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: CustomTypography.pageTitle),
                if (subtitle != null) Text(subtitle!, style: CustomTypography.bodySmall),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Acceso grande de "Mi reserva" (áreas, parqueo, reportar, ayuda).
class GuestActionTile extends StatelessWidget {
  const GuestActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: CustomColors.surface,
        borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
        child: InkWell(
          borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
              border: Border.all(color: CustomColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: CustomColors.tealWashed, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: CustomColors.primary, size: 22),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: CustomTypography.cardTitle.copyWith(fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: CustomTypography.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ilustración de un área común (color e icono por tipo).
class AreaArtBox extends StatelessWidget {
  const AreaArtBox({super.key, required this.art, this.size = 56});

  final AreaArt art;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [art.color, Color.lerp(art.color, Colors.black, 0.25)!],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(art.icon, color: Colors.white, size: size * 0.48),
    );
  }
}

/// Tarjeta de un bloque reservado, con cancelar opcional.
class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.booking, this.onCancel, this.showGuest = false});

  final AreaBooking booking;
  final VoidCallback? onCancel;
  final bool showGuest;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: CustomColors.tealWashed, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text(b.start, style: CustomTypography.mono.copyWith(fontSize: 15, color: CustomColors.primary)),
                Text(b.end, style: CustomTypography.mono.copyWith(fontSize: 11, color: CustomColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.areaName, style: CustomTypography.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(
                  showGuest
                      ? '${b.guestName} · ${b.propertyCode} · ${b.people} ${b.people == 1 ? 'persona' : 'personas'}'
                      : '${shortDay(parseDay(b.date))} · ${b.people} ${b.people == 1 ? 'persona' : 'personas'}',
                  style: CustomTypography.bodySmall,
                ),
              ],
            ),
          ),
          if (onCancel != null) TextButton(onPressed: onCancel, child: const Text('Cancelar')),
        ],
      ),
    );
  }
}
