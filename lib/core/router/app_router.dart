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
import 'package:argos_app/features/dev/presentation/pages/component_catalog_page.dart';
import 'package:argos_app/features/profile/presentation/pages/profile_page.dart';
import 'package:argos_app/features/shell/presentation/pages/home_shell_page.dart';
import 'package:argos_app/features/sync/presentation/pages/sync_page.dart';
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
      GoRoute(path: '/sync', builder: (context, state) => const SyncPage()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
}
