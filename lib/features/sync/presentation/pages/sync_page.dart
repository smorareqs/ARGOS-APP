import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/core/outbox/outbox_providers.dart';
import 'package:argos_app/core/utils/date_labels.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Sincronización: lo que está guardado en el teléfono y aún no llega al
/// servidor (cambios de tareas y fotos). Lo rechazado por el servidor se
/// puede reintentar o descartar.
class SyncPage extends ConsumerWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(_allActionsProvider).valueOrNull ?? const <PendingActionRow>[];
    final uploads = ref.watch(uploadSummaryProvider).valueOrNull;
    final outbox = ref.read(outboxProvider);
    final pendingUploads = uploads?.pending ?? 0;
    final failedUploads = uploads?.failed ?? 0;

    return FormScaffold(
      title: 'Sincronización',
      subtitle: actions.isEmpty && pendingUploads == 0 && failedUploads == 0
          ? 'Todo está enviado'
          : 'Se envía solo en cuanto hay conexión',
      onBack: () => context.pop(),
      footer: SecondaryButton(
        label: 'Enviar ahora',
        onPressed: () {
          outbox.process();
          ref.read(uploadQueueProvider).process();
        },
      ),
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: AppListTile(
            icon: CustomIcons.camera,
            title: 'Fotos',
            subtitle: pendingUploads == 0 && failedUploads == 0
                ? 'Todas subidas'
                : [
                    if (pendingUploads > 0) '$pendingUploads por subir',
                    if (failedUploads > 0) '$failedUploads con error (se reintentan solas)',
                  ].join(' · '),
            showChevron: false,
          ),
        ),
        const SizedBox(height: 24),
        Text('Cambios', style: CustomTypography.sectionTitle),
        const SizedBox(height: 12),
        if (actions.isEmpty)
          const EmptyState(
            icon: CustomIcons.uploadDone,
            title: 'Nada pendiente',
            message: 'Lo que hagas sin conexión aparecerá aquí hasta enviarse.',
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, a) in actions.indexed) ...[
                  if (i > 0) const Divider(height: 1, color: CustomColors.divider),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    child: Row(
                      children: [
                        Icon(
                          a.status == 'error' ? CustomIcons.uploadError : CustomIcons.uploadQueued,
                          color: a.status == 'error' ? CustomColors.error : CustomColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.label, style: CustomTypography.cardTitle),
                              const SizedBox(height: 2),
                              Text(
                                a.status == 'error'
                                    ? 'Rechazado: ${a.lastError ?? 'sin motivo'}'
                                    : [
                                        DateLabels.relative(a.createdAt),
                                        if (a.waitUploads) 'espera las fotos',
                                        if (a.lastError != null) a.lastError!,
                                      ].join(' · '),
                                style: CustomTypography.bodySmall.copyWith(
                                  color: a.status == 'error' ? CustomColors.error : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (a.status == 'error') ...[
                          TextButton(onPressed: () => outbox.retry(a.id), child: const Text('Reintentar')),
                          IconButton(
                            tooltip: 'Descartar',
                            icon: const Icon(CustomIcons.close, color: CustomColors.textSecondary),
                            onPressed: () async {
                              final ok = await showConfirmSheet(
                                context,
                                title: 'Descartar cambio',
                                message: '"${a.label}" no se enviará. Abre la tarea para ver su estado real.',
                                confirmLabel: 'Descartar',
                                destructive: true,
                              );
                              if (ok) await outbox.discard(a.id);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

final _allActionsProvider = StreamProvider.autoDispose<List<PendingActionRow>>(
  (ref) => ref.watch(outboxProvider).watchAll(),
);
