import 'package:argos_app/core/router/router_notifier.dart';
import 'package:argos_app/features/auth/presentation/pages/accept_invitation_page.dart';
import 'package:argos_app/features/auth/presentation/pages/active_sessions_page.dart';
import 'package:argos_app/features/auth/presentation/pages/change_password_page.dart';
import 'package:argos_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:argos_app/features/auth/presentation/pages/login_page.dart';
import 'package:argos_app/features/auth/presentation/pages/offline_start_page.dart';
import 'package:argos_app/features/auth/presentation/pages/quick_unlock_page.dart';
import 'package:argos_app/features/auth/presentation/pages/splash_page.dart';
import 'package:argos_app/features/auth/presentation/pages/tenant_select_page.dart';
import 'package:argos_app/features/auth/presentation/pages/totp_page.dart';
import 'package:argos_app/features/auth/presentation/pages/unlock_page.dart';
import 'package:argos_app/features/chat/presentation/pages/chat_list_page.dart';
import 'package:argos_app/features/chat/presentation/pages/chat_thread_page.dart';
import 'package:argos_app/features/dev/presentation/pages/component_catalog_page.dart';
import 'package:argos_app/features/guest/presentation/pages/guest_areas_page.dart';
import 'package:argos_app/features/guest/presentation/pages/guest_home_page.dart';
import 'package:argos_app/features/guest/presentation/pages/guest_login_page.dart';
import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:argos_app/features/profile/presentation/pages/profile_page.dart';
import 'package:argos_app/features/reservations/presentation/pages/guest_document_page.dart';
import 'package:argos_app/features/reservations/presentation/pages/inspection_page.dart';
import 'package:argos_app/features/reservations/presentation/pages/reservation_detail_page.dart';
import 'package:argos_app/features/shell/presentation/pages/home_shell_page.dart';
import 'package:argos_app/features/sync/presentation/pages/sync_page.dart';
import 'package:argos_app/features/tasks/models/task_summary.dart';
import 'package:argos_app/features/inventory/presentation/pages/inventory_page.dart';
import 'package:argos_app/features/notifications/presentation/pages/notification_preferences_page.dart';
import 'package:argos_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:argos_app/features/tickets/presentation/pages/report_ticket_page.dart';
import 'package:argos_app/features/tickets/presentation/pages/ticket_detail_page.dart';
import 'package:argos_app/features/tickets/presentation/pages/tickets_page.dart';
import 'package:argos_app/features/tasks/presentation/pages/task_close_page.dart';
import 'package:argos_app/features/tasks/presentation/pages/task_detail_page.dart';
import 'package:argos_app/features/tasks/presentation/pages/task_execution_page.dart';
import 'package:argos_app/features/hr/presentation/pages/attendance_page.dart';
import 'package:argos_app/features/hr/presentation/pages/disciplinary_page.dart';
import 'package:argos_app/features/hr/presentation/pages/metrics_pages.dart';
import 'package:argos_app/features/hr/presentation/pages/payslips_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final guard = RouterNotifier(ref);
  ref.onDispose(guard.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: guard,
    redirect: (context, state) => guard.redirect(state),
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/offline', builder: (context, state) => const OfflineStartPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/login/totp', builder: (context, state) => const TotpPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/select-tenant',
        builder: (context, state) => const TenantSelectPage(),
      ),
      GoRoute(
        path: '/quick-unlock',
        builder: (context, state) =>
            const QuickUnlockPage(mode: QuickUnlockMode.offer),
      ),
      GoRoute(path: '/unlock', builder: (context, state) => const UnlockPage()),
      GoRoute(
        path: '/invite',
        builder: (context, state) => AcceptInvitationPage(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: '/home/:tab',
        // Misma clave para todas las pestañas: el shell no se reconstruye y
        // cada pestaña conserva su estado.
        pageBuilder: (context, state) => NoTransitionPage(
          key: const ValueKey('home-shell'),
          child: HomeShellPage(tabId: state.pathParameters['tab']!),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(showBack: true),
      ),
      GoRoute(
        path: '/profile/sessions',
        builder: (context, state) => const ActiveSessionsPage(),
      ),
      GoRoute(
        path: '/profile/quick-unlock',
        builder: (context, state) =>
            const QuickUnlockPage(mode: QuickUnlockMode.settings),
      ),
      GoRoute(
        path: '/profile/password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/profile/components',
        builder: (context, state) => const ComponentCatalogPage(),
      ),
      GoRoute(
        path: '/tasks/:id',
        builder: (context, state) => TaskDetailPage(
          taskId: state.pathParameters['id']!,
          preview: state.extra is TaskSummary ? state.extra! as TaskSummary : null,
        ),
      ),
      GoRoute(
        path: '/tasks/:id/run',
        builder: (context, state) => TaskExecutionPage(taskId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tasks/:id/close',
        builder: (context, state) => TaskClosePage(taskId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tasks/:id/done',
        builder: (context, state) => TaskClosedPage(
          taskId: state.pathParameters['id']!,
          discrepancies: state.extra is int ? state.extra! as int : 0,
        ),
      ),
      GoRoute(path: '/inventory', builder: (context, state) => const InventoryPage(showBack: true)),
      GoRoute(path: '/sync', builder: (context, state) => const SyncPage()),
      // Fase 3: avisos e incidencias.
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(showBack: true),
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (context, state) => const NotificationPreferencesPage(),
      ),
      GoRoute(
        path: '/tickets',
        builder: (context, state) => TicketsPage(
          mine: state.uri.queryParameters['mine'] == 'true',
          showBack: true,
        ),
      ),
      GoRoute(
        path: '/tickets/new',
        builder: (context, state) => ReportTicketPage(
          propertyId: state.uri.queryParameters['property_id'],
          propertyLabel: state.uri.queryParameters['property'],
        ),
      ),
      GoRoute(
        path: '/tickets/:id',
        builder: (context, state) => TicketDetailPage(ticketId: state.pathParameters['id']!),
      ),
      // Fase 4: reservas del supervisor (C6–C10).
      GoRoute(
        path: '/reservations/:id',
        builder: (context, state) => ReservationDetailPage(reservationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reservations/:id/inspection',
        builder: (context, state) => InspectionPage(
          reservationId: state.pathParameters['id']!,
          kind: state.uri.queryParameters['kind'] == 'pre_arrival' ? 'pre_arrival' : 'post_departure',
        ),
      ),
      GoRoute(
        path: '/guests/:id/document',
        builder: (context, state) => GuestDocumentPage(
          guestId: state.pathParameters['id']!,
          guestName: state.uri.queryParameters['name'],
          propertyCode: state.uri.queryParameters['property'],
        ),
      ),
      // Fase 4: modo huésped (A9, F1–F9).
      GoRoute(
        path: '/guest-login',
        builder: (context, state) => GuestLoginPage(token: state.uri.queryParameters['token']),
      ),
      GoRoute(path: '/guest', builder: (context, state) => const GuestHomePage()),
      GoRoute(path: '/guest/areas', builder: (context, state) => const GuestAreasPage()),
      GoRoute(
        path: '/guest/areas/:id',
        builder: (context, state) => GuestAreaPage(
          areaId: state.pathParameters['id']!,
          area: state.extra is SharedArea ? state.extra! as SharedArea : null,
        ),
      ),
      GoRoute(path: '/guest/parking', builder: (context, state) => const GuestParkingPage()),
      GoRoute(path: '/guest/report', builder: (context, state) => const GuestReportPage()),
      GoRoute(path: '/guest/help', builder: (context, state) => const GuestHelpPage()),
      GoRoute(path: '/guest/chat', builder: (context, state) => const GuestChatPage()),
      // Fase 6: chat del equipo y con huéspedes.
      GoRoute(
        path: '/chat',
        builder: (context, state) => ChatListPage(initialKind: state.uri.queryParameters['kind'] ?? 'internal'),
      ),
      GoRoute(path: '/chat/:id', builder: (context, state) => ChatThreadPage(id: state.pathParameters['id']!)),
      // Fase 5: asistencia, boletas, disciplina, métricas y reportes.
      GoRoute(path: '/attendance', builder: (context, state) => const AttendancePage()),
      GoRoute(
        path: '/payslips',
        builder: (context, state) => PayslipsPage(openId: state.uri.queryParameters['entry']),
      ),
      GoRoute(path: '/disciplinary', builder: (context, state) => const DisciplinaryPage()),
      GoRoute(
        path: '/disciplinary/:id',
        builder: (context, state) => DisciplinaryDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/metrics', builder: (context, state) => const MyMetricsPage()),
      GoRoute(path: '/metrics/team', builder: (context, state) => const TeamMetricsPage()),
      GoRoute(path: '/reports', builder: (context, state) => const ReportsPage(showBack: true)),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
}
