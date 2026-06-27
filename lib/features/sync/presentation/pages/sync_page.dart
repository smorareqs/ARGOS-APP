import 'package:argos_app/features/sync/models/sync_state.dart';
import 'package:argos_app/features/sync/presentation/providers/sync_provider.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SyncPage extends ConsumerWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sincronización')),
      body: Padding(
        padding: const EdgeInsets.all(CustomDimensions.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (syncState.status == SyncStatus.inProgress) ...[
              Text(
                syncState.currentStep?.name ?? 'Sincronizando...',
                style: CustomTypography.titleMedium,
              ),
              const SizedBox(height: CustomDimensions.spacingMd),
              LinearProgressIndicator(
                value: syncState.currentStep?.progress ?? 0,
                backgroundColor: CustomColors.border,
                color: CustomColors.primary,
              ),
              const SizedBox(height: CustomDimensions.spacingSm),
              Text(
                '${syncState.currentStep?.current ?? 0} / ${syncState.currentStep?.total ?? 0}',
                style: CustomTypography.bodyMedium,
              ),
            ] else if (syncState.status == SyncStatus.completed) ...[
              const Icon(Icons.check_circle, color: CustomColors.primary, size: 64),
              const SizedBox(height: CustomDimensions.spacingMd),
              Text(
                'Sincronización completada',
                style: CustomTypography.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CustomDimensions.spacingLg),
              PrimaryButton(
                label: 'Volver al inicio',
                onPressed: () => context.pop(),
              ),
            ] else ...[
              Text(
                'Selecciona el tipo de sincronización',
                style: CustomTypography.titleMedium,
              ),
              const SizedBox(height: CustomDimensions.spacingLg),
              PrimaryButton(
                label: 'Sincronización completa',
                onPressed: () =>
                    ref.read(syncProvider.notifier).startSync(SyncMode.full),
              ),
              const SizedBox(height: CustomDimensions.spacingMd),
              SecondaryButton(
                label: 'Sincronización incremental',                onPressed: () =>
                    ref.read(syncProvider.notifier).startSync(SyncMode.incremental),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
