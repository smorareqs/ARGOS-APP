import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/tickets/data/tickets_repository.dart';
import 'package:argos_app/features/tickets/presentation/widgets/ticket_card.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _Filter { active, resolved, all }

/// B13 · Mis tickets. Mantenimiento ve las asignadas a sí ([mine]); el resto
/// ve las que reportó. Más urgentes y más viejas primero.
class TicketsPage extends ConsumerStatefulWidget {
  const TicketsPage({super.key, this.mine = true, this.showBack = false});

  final bool mine;
  final bool showBack;

  @override
  ConsumerState<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends ConsumerState<TicketsPage> {
  var _filter = _Filter.active;

  Future<void> _refresh() =>
      ref.refresh(ticketListProvider(mine: widget.mine).future).then((_) {}, onError: (_) {});

  Future<void> _report() async {
    final id = await context.push<String>('/tickets/new');
    if (id != null) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ticketListProvider(mine: widget.mine));
    final list = async.valueOrNull;

    Widget body;
    if (list == null && async.isLoading) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < 4; i++) ...[
            const Skeleton(width: double.infinity, height: 110, radius: CustomDimensions.radiusCard),
            const SizedBox(height: 12),
          ],
        ],
      );
    } else if (list == null) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ErrorState(
            message: async.error is DioException
                ? 'Sin conexión. Las incidencias necesitan internet.'
                : errorMessage(async.error ?? 'Error'),
            onRetry: _refresh,
          ),
        ],
      );
    } else {
      final active = list.where((t) => t.status.active).toList();
      final resolved = list.where((t) => !t.status.active).toList();
      final shown = sortByUrgency(switch (_filter) {
        _Filter.active => active,
        _Filter.resolved => resolved,
        _Filter.all => list,
      });
      body = ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          FilterChips<_Filter>(
            options: [
              FilterOption(value: _Filter.active, label: 'Activas', count: active.length),
              FilterOption(value: _Filter.resolved, label: 'Resueltas', count: resolved.length),
              FilterOption(value: _Filter.all, label: 'Todas', count: list.length),
            ],
            selected: {_filter},
            onChanged: (s) => setState(() => _filter = s.isEmpty ? _filter : s.first),
          ),
          const SizedBox(height: 14),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: EmptyState(
                icon: CustomIcons.tickets,
                title: switch (_filter) {
                  _Filter.active => widget.mine ? 'No tienes incidencias pendientes' : 'Nada pendiente',
                  _Filter.resolved => 'Aún no hay resueltas',
                  _Filter.all => widget.mine ? 'Sin incidencias asignadas' : 'No has reportado incidencias',
                },
                message: widget.mine
                    ? 'Cuando te asignen una, te avisamos y aparece aquí.'
                    : 'Si encuentras un daño, repórtalo y mantenimiento lo atiende.',
                actionLabel: 'Reportar incidencia',
                onAction: _report,
              ),
            )
          else
            for (final t in shown)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TicketCard(
                  ticket: t,
                  onTap: () async {
                    await context.push('/tickets/${t.id}');
                    await _refresh();
                  },
                ),
              ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: CustomColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(widget.showBack ? 8 : 24, 16, 16, 8),
              child: Row(
                children: [
                  if (widget.showBack)
                    IconButton(
                      tooltip: 'Volver',
                      icon: const Icon(CustomIcons.arrowBack, color: CustomColors.primary),
                      onPressed: () => context.pop(),
                    ),
                  Expanded(
                    child: Text(widget.mine ? 'Tickets' : 'Mis reportes', style: CustomTypography.pageTitle),
                  ),
                  AppIconButton(icon: CustomIcons.add, semanticLabel: 'Reportar incidencia', onPressed: _report),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(color: CustomColors.primary, onRefresh: _refresh, child: body),
            ),
          ],
        ),
      ),
    );
  }
}
