import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/hospitality/models/hospitality.dart' show parseDay;
import 'package:argos_app/features/hr/data/hr_repository.dart';
import 'package:argos_app/features/hr/models/hr.dart';
import 'package:argos_app/features/hr/presentation/widgets/hr_widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

String _date(String day) {
  final d = parseDay(day);
  return d.year == 1970 ? day : '${dayMonth(d)} ${d.year}';
}

/// B21 · Disciplina: mis acciones con su estado de acuse. Las pendientes van
/// primero.
class DisciplinaryPage extends ConsumerWidget {
  const DisciplinaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(disciplinaryProvider);
    final list = async.valueOrNull;
    Future<void> refresh() => ref.refresh(disciplinaryProvider.future).then((_) {}, onError: (_) {});

    Widget body;
    if (list == null && async.isLoading) {
      body = hrLoading(cards: 2, first: 110);
    } else if (list == null) {
      body = hrError(async.error, refresh);
    } else if (list.isEmpty) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 40),
          EmptyState(icon: CustomIcons.verified, title: 'Sin acciones disciplinarias', message: 'Tu historial está limpio.'),
        ],
      );
    } else {
      final sorted = [...list]..sort((a, b) => a.pending == b.pending ? b.occurredOn.compareTo(a.occurredOn) : (a.pending ? -1 : 1));
      final pending = sorted.where((a) => a.pending).length;
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (pending > 0) ...[
            DetailBanner(
              icon: CustomIcons.info,
              message: pending == 1
                  ? 'Tienes 1 acción por leer. Confirma que la recibiste.'
                  : 'Tienes $pending acciones por leer. Confirma que las recibiste.',
            ),
            const SizedBox(height: 14),
          ],
          for (final a in sorted) ...[
            AppCard(
              onTap: () => context.push('/disciplinary/${a.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(a.typeLabel, style: CustomTypography.cardTitle.copyWith(fontSize: 16))),
                      a.badge,
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CustomTypography.bodySmall.copyWith(color: CustomColors.textBody),
                  ),
                  const SizedBox(height: 8),
                  Text([_date(a.occurredOn), ?a.issuedBy].join(' · '), style: CustomTypography.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
    }
    return HrPage(title: 'Disciplina', overline: 'Mi historial', onRefresh: refresh, body: body);
  }
}

/// B21 · Detalle: descripción, adjuntos y "Confirmo que la recibí".
class DisciplinaryDetailPage extends ConsumerStatefulWidget {
  const DisciplinaryDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<DisciplinaryDetailPage> createState() => _DisciplinaryDetailPageState();
}

class _DisciplinaryDetailPageState extends ConsumerState<DisciplinaryDetailPage> {
  final _note = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _ack() async {
    setState(() => _busy = true);
    try {
      await ref.read(hrRepositoryProvider).acknowledge(widget.id, _note.text);
      ref.invalidate(disciplinaryProvider);
      if (mounted) showToast(context, 'Listo. Quedó registrado que la recibiste.');
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(disciplinaryProvider);
    final a = async.valueOrNull?.where((x) => x.id == widget.id).firstOrNull;
    Future<void> refresh() => ref.refresh(disciplinaryProvider.future).then((_) {}, onError: (_) {});

    if (a == null) {
      return HrPage(
        title: 'Acción disciplinaria',
        body: async.isLoading
            ? hrLoading(cards: 1)
            : async.hasError
            ? hrError(async.error, refresh)
            : const Center(
                child: EmptyState(icon: CustomIcons.document, title: 'Esta acción ya no está disponible'),
              ),
      );
    }

    return DetailScaffold(
      title: a.typeLabel,
      overline: _date(a.occurredOn),
      subtitle: a.issuedBy == null ? null : 'Registrada por ${a.issuedBy}',
      status: a.badge,
      onBack: () => context.pop(),
      footer: a.pending
          ? PrimaryButton(
              label: 'Confirmo que la recibí',
              trailingIcon: CustomIcons.check,
              isLoading: _busy,
              onPressed: _busy ? null : _ack,
            )
          : null,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('QUÉ PASÓ', style: CustomTypography.label.copyWith(color: CustomColors.textMuted, letterSpacing: 1.1)),
              const SizedBox(height: 8),
              Text(a.description, style: CustomTypography.body.copyWith(color: CustomColors.textPrimary, height: 1.45)),
              if (a.suspensionFrom != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(CustomIcons.calendar, size: 16, color: CustomColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Suspensión del ${_date(a.suspensionFrom!)} al ${_date(a.suspensionTo ?? a.suspensionFrom!)}',
                        style: CustomTypography.label.copyWith(color: CustomColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (a.attachments.isNotEmpty) ...[
          const SizedBox(height: 14),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final f in a.attachments)
                  AppListTile(
                    icon: f.isImage ? CustomIcons.photo : CustomIcons.document,
                    title: f.name,
                    subtitle: 'Toca para abrir',
                    onTap: () => launchUrl(Uri.parse(f.url), mode: LaunchMode.externalApplication),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (a.pending)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu versión (opcional)', style: CustomTypography.cardTitle.copyWith(fontSize: 15)),
                const SizedBox(height: 4),
                Text('Confirmar solo dice que la leíste. Si no estás de acuerdo, escríbelo aquí.', style: CustomTypography.bodySmall),
                const SizedBox(height: 10),
                AppTextField(controller: _note, hintText: 'Escribe tu comentario', maxLines: 4),
              ],
            ),
          )
        else
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(CustomIcons.verified, color: CustomColors.success, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'La recibiste el ${dayMonth(a.acknowledgedAt!)} a las ${hm(a.acknowledgedAt!)}',
                        style: CustomTypography.label.copyWith(color: CustomColors.textPrimary),
                      ),
                      if (a.note != null) ...[
                        const SizedBox(height: 6),
                        Text('“${a.note}”', style: CustomTypography.bodySmall.copyWith(fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
