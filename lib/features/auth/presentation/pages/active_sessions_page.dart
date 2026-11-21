import 'package:argos_app/core/errors/app_failure.dart';
import 'package:argos_app/core/utils/date_labels.dart';
import 'package:argos_app/features/auth/models/account.dart';
import 'package:argos_app/features/auth/presentation/providers/account_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// B18 · Sesiones activas: dispositivos con sesión abierta, cerrar uno o
/// todos los demás.
class ActiveSessionsPage extends ConsumerWidget {
  const ActiveSessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(activeSessionsProvider);

    return FormScaffold(
      title: 'Sesiones activas',
      subtitle: 'Dispositivos donde tu cuenta está abierta.',
      onBack: () => context.pop(),
      footer: switch (sessions) {
        AsyncData(:final value) when value.any((s) => !s.current) =>
          TertiaryButton(
            label: 'Cerrar sesión en todos los demás',
            onPressed: () => _revokeOthers(context, ref),
          ),
        _ => null,
      },
      children: [
        sessions.when(
          loading: () => const Column(
            children: [Skeleton.card(), SizedBox(height: 12), Skeleton.card()],
          ),
          error: (error, _) => ErrorState(
            message: error is AppFailure
                ? error.message
                : 'No pudimos cargar tus sesiones.',
            onRetry: () => ref.invalidate(activeSessionsProvider),
          ),
          data: (list) => AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final session in list)
                  _SessionTile(
                    session: session,
                    onRevoke: session.current
                        ? null
                        : () => _revoke(context, ref, session),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    DeviceSession session,
  ) async {
    final name = _deviceLabel(session);
    final confirmed = await showConfirmSheet(
      context,
      title: 'Cerrar sesión en $name',
      message: 'Quien use ese dispositivo tendrá que volver a ingresar.',
      confirmLabel: 'Cerrar sesión',
      destructive: true,
    );
    if (!confirmed) return;
    final failure = await ref.read(activeSessionsProvider.notifier).revoke(session.id);
    if (context.mounted) _toast(context, failure?.message ?? 'Sesión cerrada en $name.');
  }

  Future<void> _revokeOthers(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Cerrar en todos los demás',
      message: 'Se cerrará tu sesión en todos los dispositivos excepto este.',
      confirmLabel: 'Cerrar sesiones',
      destructive: true,
    );
    if (!confirmed) return;
    final failure = await ref.read(activeSessionsProvider.notifier).revokeOthers();
    if (context.mounted) {
      _toast(context, failure?.message ?? 'Sesiones cerradas en los demás dispositivos.');
    }
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

String _deviceLabel(DeviceSession session) =>
    session.deviceName ??
    switch (session.platform) {
      'ios' => 'iPhone',
      'web' => 'Navegador',
      _ => 'Teléfono Android',
    };

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, this.onRevoke});

  final DeviceSession session;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final icon = switch (session.platform) {
      'ios' => CustomIcons.phoneIphone,
      'web' => CustomIcons.web,
      _ => CustomIcons.phoneAndroid,
    };
    return AppListTile(
      icon: icon,
      title: _deviceLabel(session),
      subtitle: session.current
          ? 'Este dispositivo'
          : 'Último uso: ${DateLabels.relative(session.lastUsedAt)}',
      showChevron: false,
      trailing: onRevoke == null
          ? const Icon(CustomIcons.check, color: CustomColors.success)
          : TextButton(
              onPressed: onRevoke,
              child: Text(
                'Cerrar',
                style: CustomTypography.verdana(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: CustomColors.error,
                ),
              ),
            ),
    );
  }
}
