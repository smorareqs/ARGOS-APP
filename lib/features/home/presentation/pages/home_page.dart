import 'package:argos_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(CustomIcons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (user) => Padding(
          padding: const EdgeInsets.all(CustomDimensions.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido, ${user?.nombre ?? 'Usuario'}',
                style: CustomTypography.headlineLarge.copyWith(fontSize: 24),
              ),
              const SizedBox(height: CustomDimensions.spacingMd),
              Text(
                'Código: ${user?.codigo ?? '-'}',
                style: CustomTypography.bodyMedium,
              ),
              const SizedBox(height: CustomDimensions.spacingLg),
              PrimaryButton(
                label: 'Sincronizar',
                onPressed: () => context.push('/sync'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
