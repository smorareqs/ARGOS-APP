import 'package:argos_app/core/utils/date_labels.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/itinerary/presentation/pages/itinerary_page.dart';
import 'package:argos_app/features/profile/presentation/pages/profile_page.dart';
import 'package:argos_app/features/shell/models/shell_tab.dart';
import 'package:argos_app/features/shell/presentation/pages/more_page.dart';
import 'package:argos_app/features/shell/presentation/widgets/coming_soon_tab.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Shell por rol: barra inferior con los destinos de la sesión. En la fase 1
/// solo "Hoy" (cabecera) y "Perfil" tienen contenido; el resto muestra
/// "próximamente" para poder probar la navegación por rol (fase01.md §4.4).
class HomeShellPage extends ConsumerWidget {
  const HomeShellPage({super.key, required this.tabId});

  final String tabId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    if (state is! AuthSignedIn) return const SizedBox.shrink();

    final tabs = tabsForSession(state.session);
    final index = tabs.indexWhere((t) => t.id == tabId).clamp(0, tabs.length - 1);
    void open(ShellTab tab) => context.go('/home/${tab.id}');

    return TabScaffold(
      destinations: [
        for (final tab in tabs) NavDestination(icon: shellTabIcon(tab), label: tab.label),
      ],
      currentIndex: index,
      onSelect: (i) => open(tabs[i]),
      banner: state.offline
          ? OfflineBar(
              detail: state.cachedAt == null
                  ? 'mostrando datos guardados'
                  : 'mostrando datos guardados ${DateLabels.relative(state.cachedAt!)}',
            )
          : null,
      bodies: [
        for (final tab in tabs)
          switch (tab) {
            ShellTab.today => ItineraryPage(
              onOpenProfile: tabs.contains(ShellTab.profile)
                  ? () => open(ShellTab.profile)
                  : () => context.push('/profile'),
            ),
            ShellTab.profile => const ProfilePage(),
            ShellTab.more => const MorePage(),
            _ => ComingSoonTab(tab: tab),
          },
      ],
    );
  }
}

IconData shellTabIcon(ShellTab tab) => switch (tab) {
  ShellTab.today => CustomIcons.today,
  ShellTab.week => CustomIcons.week,
  ShellTab.tickets => CustomIcons.tickets,
  ShellTab.inventory => CustomIcons.equipment,
  ShellTab.team => CustomIcons.team,
  ShellTab.reservations => CustomIcons.reservations,
  ShellTab.security => CustomIcons.security,
  ShellTab.alarms => CustomIcons.alarm,
  ShellTab.sharedAreas => CustomIcons.sharedAreas,
  ShellTab.alerts => CustomIcons.alerts,
  ShellTab.properties => CustomIcons.properties,
  ShellTab.reports => CustomIcons.reports,
  ShellTab.more => CustomIcons.more,
  ShellTab.profile => CustomIcons.person,
};
