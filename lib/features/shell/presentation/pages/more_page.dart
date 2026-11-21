import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// C11 · Más (supervisor y admin). En la fase 1 solo lleva al perfil; las
/// demás entradas (inventario, incidencias, inspecciones, chat, métricas de
/// equipo) se agregan con sus fases.
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
        ],
      ),
    );
  }
}
