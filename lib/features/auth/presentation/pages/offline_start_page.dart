import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A10 · Sin conexión al iniciar (primer arranque, sin sesión guardada).
class OfflineStartPage extends ConsumerWidget {
  const OfflineStartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: CustomColors.background,
      body: SafeArea(
        child: EmptyState(
          icon: CustomIcons.offline,
          title: 'Necesitas conexión para entrar la primera vez',
          message:
              'Conéctate a internet o a una red wifi. Después podrás ver tu '
              'agenda aunque no tengas señal.',
          actionLabel: 'Reintentar',
          onAction: () => ref.read(sessionControllerProvider.notifier).boot(),
        ),
      ),
    );
  }
}
