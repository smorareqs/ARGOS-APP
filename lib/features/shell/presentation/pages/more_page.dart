import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/chat/presentation/widgets/chat_entry_tile.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// C11 · Más (supervisor y admin): perfil y accesos a las secciones que no
/// caben en la barra inferior.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    if (state is! AuthSignedIn) return const SizedBox.shrink();
    final session = state.session;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('Más', style: CustomTypography.pageTitle),
          ),
          const SizedBox(height: CustomDimensions.spacingLg),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppListTile(
              leading: Avatar(name: session.user.fullName),
              title: session.user.fullName,
              subtitle: 'Perfil · ${session.roleName}',
              onTap: () => context.push('/profile'),
            ),
          ),
          const SizedBox(height: CustomDimensions.spacingLg),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const ChatEntryTile(),
                if (session.permissions.contains('inventory.read'))
                  AppListTile(
                    icon: CustomIcons.equipment,
                    title: 'Inventario',
                    subtitle: 'Mi custodia, sacar artículos y reposición',
                    onTap: () => context.push('/inventory'),
                  ),
                if (session.can('maintenance.read'))
                  AppListTile(
                    icon: CustomIcons.tickets,
                    title: 'Incidencias',
                    subtitle: 'Reportadas en tus propiedades',
                    onTap: () => context.push('/tickets'),
                  ),
                if (session.permissions.contains('metrics.team') || session.permissions.contains('metrics.all'))
                  AppListTile(
                    icon: CustomIcons.metrics,
                    title: 'Métricas del equipo',
                    subtitle: 'Ranking por rol, semana o mes',
                    onTap: () => context.push('/metrics/team'),
                  ),
                if (session.permissions.contains('metrics.all'))
                  AppListTile(
                    icon: CustomIcons.reports,
                    title: 'Reportes del mes',
                    subtitle: 'Ocupación, limpiezas e incidencias por propiedad',
                    onTap: () => context.push('/reports'),
                  ),
                if (session.permissions.contains('hr.attendance.own'))
                  AppListTile(
                    icon: CustomIcons.time,
                    title: 'Mi asistencia',
                    subtitle: 'Marcar entrada y salida',
                    onTap: () => context.push('/attendance'),
                  ),
                AppListTile(
                  icon: CustomIcons.notifications,
                  title: 'Notificaciones',
                  subtitle: 'Qué te llega al teléfono y al correo',
                  onTap: () => context.push('/profile/notifications'),
                ),
                AppListTile(
                  icon: CustomIcons.sync,
                  title: 'Sincronización',
                  subtitle: 'Fotos y cambios pendientes de enviar',
                  onTap: () => context.push('/sync'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
