import 'package:argos_app/core/utils/date_labels.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/inventory/presentation/pages/inventory_page.dart';
import 'package:argos_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:argos_app/features/notifications/presentation/providers/inbox_controller.dart';
import 'package:argos_app/features/itinerary/presentation/pages/itinerary_page.dart';
import 'package:argos_app/features/profile/presentation/pages/profile_page.dart';
import 'package:argos_app/features/shell/models/shell_tab.dart';
import 'package:argos_app/features/shell/presentation/pages/more_page.dart';
import 'package:argos_app/features/shell/presentation/widgets/coming_soon_tab.dart';
import 'package:argos_app/features/tasks/presentation/pages/team_page.dart';
import 'package:argos_app/features/tickets/presentation/pages/tickets_page.dart';
import 'package:design_system/design_system.dart';
import 'package:argos_app/features/reservations/presentation/pages/reservations_page.dart';
import 'package:argos_app/features/security/presentation/pages/security_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Shell por rol: barra inferior con los destinos de la sesión (ux-ui.md
/// §4.1). Los destinos de fases que aún no llegan muestran "próximamente".
class HomeShellPage extends ConsumerWidget {
  const HomeShellPage({super.key, required this.tabId});

  final String tabId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    if (state is! AuthSignedIn) return const SizedBox.shrink();

    final tabs = tabsForSession(state.session);
    final unread = ref.watch(unreadNotificationsProvider);
    final index = tabs.indexWhere((t) => t.id == tabId).clamp(0, tabs.length - 1);
    void open(ShellTab tab) => context.go('/home/${tab.id}');

    return TabScaffold(
      destinations: [
        for (final tab in tabs)
          NavDestination(
            icon: shellTabIcon(tab),
            label: tab.label,
            badge: tab == ShellTab.alerts ? unread : 0,
          ),
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
            ShellTab.week => ItineraryPage(
              onOpenProfile: () => open(ShellTab.profile),
            ),
            ShellTab.inventory => const InventoryPage(),
            ShellTab.team => const TeamPage(),
            ShellTab.profile => const ProfilePage(),
            ShellTab.more => const MorePage(),
            ShellTab.alerts => const NotificationsPage(),
            ShellTab.tickets => const TicketsPage(),
            ShellTab.reservations => const ReservationsPage(),
            ShellTab.security => const SecurityBoardPage(),
            ShellTab.alarms => const SecurityAlarmsPage(),
            ShellTab.sharedAreas => const SecurityAreasPage(),
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
