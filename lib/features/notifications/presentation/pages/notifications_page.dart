import 'package:argos_app/core/router/app_links.dart';
import 'package:argos_app/core/utils/date_labels.dart';
import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/alerts/data/alerts_repository.dart';
import 'package:argos_app/features/alerts/models/alert.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/notifications/models/app_notification.dart';
import 'package:argos_app/features/notifications/presentation/providers/inbox_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// B16 · Avisos (y C4 para supervisión: arriba el panel de alertas con
/// contadores y "Reconocer"). Pestañas Nuevas / Todas, tocar abre la
/// pantalla del aviso, deslizar lo marca leído.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key, this.showBack = false});

  final bool showBack;

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  var _onlyUnread = true;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) ref.read(inboxProvider.notifier).loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool get _supervises {
    final auth = ref.read(sessionControllerProvider);
    return auth is AuthSignedIn && auth.session.can('alerts.read');
  }

  Future<void> _refresh() async {
    await ref.read(inboxProvider.notifier).refresh();
    if (_supervises) ref.invalidate(alertsPanelProvider);
  }

  Future<void> _open(AppNotification n) async {
    await ref.read(inboxProvider.notifier).markRead(n.id);
    if (mounted) openAppRoute(context, n.appRoute);
  }

  Future<void> _markAll() async {
    try {
      await ref.read(inboxProvider.notifier).markAllRead();
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(inboxProvider);
    final inbox = async.valueOrNull;
    final supervises = ref.watch(
      sessionControllerProvider.select((s) => s is AuthSignedIn && s.session.can('alerts.read')),
    );

    final children = <Widget>[];
    if (inbox?.cachedAt != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: OfflineBar(detail: 'mostrando avisos guardados ${DateLabels.relative(inbox!.cachedAt!)}'),
        ),
      );
    }
    if (supervises) children.add(const _AlertsPanel());

    if (inbox == null && async.isLoading) {
      for (var i = 0; i < 5; i++) {
        children.add(
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Skeleton(width: double.infinity, height: 64, radius: CustomDimensions.radiusCard),
          ),
        );
      }
    } else if (inbox == null) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorState(
            message: async.error is DioException
                ? 'Sin conexión y sin avisos guardados.'
                : errorMessage(async.error ?? 'Error'),
            onRetry: _refresh,
          ),
        ),
      );
    } else {
      final shown = _onlyUnread ? inbox.items.where((n) => n.unread).toList() : inbox.items;
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: FilterChips<bool>(
                  options: [
                    FilterOption(value: true, label: 'Nuevas', count: inbox.unread),
                    const FilterOption(value: false, label: 'Todas'),
                  ],
                  selected: {_onlyUnread},
                  onChanged: (s) => setState(() => _onlyUnread = s.isEmpty ? _onlyUnread : s.first),
                ),
              ),
              if (inbox.unread > 0)
                TextButton(
                  onPressed: _markAll,
                  child: Text(
                    'Marcar todas',
                    style: CustomTypography.verdana(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: CustomColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
      if (shown.isEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            child: EmptyState(
              icon: CustomIcons.notifications,
              title: _onlyUnread ? 'Estás al día' : 'Todavía no tienes avisos',
              message: _onlyUnread
                  ? 'Aquí aparecen las tareas nuevas, los cambios y lo que necesita tu atención.'
                  : 'Cuando algo cambie en tus tareas o incidencias te avisamos aquí.',
              actionLabel: _onlyUnread && inbox.items.isNotEmpty ? 'Ver todas' : null,
              onAction: _onlyUnread && inbox.items.isNotEmpty ? () => setState(() => _onlyUnread = false) : null,
            ),
          ),
        );
      } else {
        String? lastGroup;
        final tiles = <Widget>[];
        for (final n in shown) {
          final group = _group(n.createdAt);
          if (group != lastGroup) {
            if (tiles.isNotEmpty) children.add(_card(tiles.toList()));
            tiles.clear();
            children.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Text(group.toUpperCase(), style: CustomTypography.label),
              ),
            );
            lastGroup = group;
          }
          tiles.add(
            Dismissible(
              key: ValueKey('n-${n.id}'),
              direction: n.unread ? DismissDirection.endToStart : DismissDirection.none,
              confirmDismiss: (_) async {
                await ref.read(inboxProvider.notifier).markRead(n.id);
                return false; // la fila se queda, ya leída
              },
              background: Container(
                color: CustomColors.tealWashed,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CustomIcons.doneAll, color: CustomColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Leído'),
                  ],
                ),
              ),
              child: NotificationTile(
                icon: n.icon,
                tone: n.tone,
                title: n.title,
                body: n.body,
                time: _time(n.createdAt),
                unread: n.unread,
                onTap: () => _open(n),
              ),
            ),
          );
        }
        if (tiles.isNotEmpty) children.add(_card(tiles));
        if (inbox.loadingMore) {
          children.add(
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: CustomColors.primary)),
            ),
          );
        }
      }
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
                  Expanded(child: Text(supervises ? 'Alertas' : 'Avisos', style: CustomTypography.pageTitle)),
                  AppIconButton(
                    icon: CustomIcons.filter,
                    semanticLabel: 'Preferencias de avisos',
                    onPressed: () => context.push('/profile/notifications'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: CustomColors.primary,
                onRefresh: _refresh,
                child: ListView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 32),
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> tiles) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CustomColors.surfaceSoft,
          borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
          border: Border.all(color: CustomColors.border),
        ),
        child: Column(
          children: [
            for (final (i, t) in tiles.indexed) ...[
              if (i > 0) const Divider(height: 1, color: CustomColors.divider),
              t,
            ],
          ],
        ),
      ),
    ),
  );

  static String _group(DateTime at) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Esta semana';
    return 'Antes';
  }

  static String _time(DateTime at) {
    final now = DateTime.now();
    if (now.difference(at).inHours < 24 && at.day == now.day) {
      final m = now.difference(at).inMinutes;
      if (m < 1) return 'ahora';
      if (m < 60) return '$m min';
      return '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    }
    return DateLabels.relative(at, now: now);
  }
}

/// C4 · Panel: alertas abiertas por tipo y las más recientes con "Reconocer".
class _AlertsPanel extends ConsumerWidget {
  const _AlertsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(alertsPanelProvider);
    final data = async.valueOrNull;
    if (data == null) {
      if (async.hasError) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Skeleton(width: double.infinity, height: 120, radius: CustomDimensions.radiusCard),
      );
    }
    final (summary, alerts) = data;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Panel', style: CustomTypography.cardTitle)),
                if (summary.fresh > 0)
                  StatusBadge(label: '${summary.fresh} sin reconocer', variant: StatusBadgeVariant.incident)
                else
                  const StatusBadge(label: 'Todo en orden', variant: StatusBadgeVariant.operative),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Counter(value: summary.open, label: 'Abiertas'),
                _Counter(value: summary.high, label: 'Graves', color: CustomColors.error),
                _Counter(value: summary.fresh, label: 'Nuevas', color: CustomColors.secondary),
              ],
            ),
            if (summary.byType.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (type, count) in summary.byType)
                    AppChip(label: '${OpsAlert.typeLabel(type)} · $count'),
                ],
              ),
            ],
            for (final a in alerts.take(3)) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: CustomColors.divider),
              const SizedBox(height: 12),
              _AlertRow(alert: a),
            ],
          ],
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.value, required this.label, this.color = CustomColors.primary});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value', style: CustomTypography.display.copyWith(fontSize: 28, color: color)),
        Text(label, style: CustomTypography.bodySmall),
      ],
    ),
  );
}

class _AlertRow extends ConsumerStatefulWidget {
  const _AlertRow({required this.alert});

  final OpsAlert alert;

  @override
  ConsumerState<_AlertRow> createState() => _AlertRowState();
}

class _AlertRowState extends ConsumerState<_AlertRow> {
  late OpsAlert _alert = widget.alert;
  var _busy = false;

  Future<void> _ack() async {
    setState(() => _busy = true);
    try {
      await ref.read(alertsRepositoryProvider).acknowledge(_alert.id);
      final auth = ref.read(sessionControllerProvider);
      final me = auth is AuthSignedIn ? auth.session.user.fullName : 'Tú';
      if (mounted) setState(() => _alert = _alert.acknowledge(me));
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _alert;
    final color = a.severity == 'high' ? CustomColors.error : CustomColors.warning;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.message, style: CustomTypography.body.copyWith(fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                [
                  ?a.propertyCode,
                  DateLabels.relative(a.createdAt),
                  if (a.acknowledged) 'reconocida${a.acknowledgedByName == null ? '' : ' por ${a.acknowledgedByName}'}',
                ].join(' · '),
                style: CustomTypography.bodySmall,
              ),
            ],
          ),
        ),
        if (!a.acknowledged)
          TextButton(
            onPressed: _busy ? null : _ack,
            child: Text(
              'Reconocer',
              style: CustomTypography.verdana(fontSize: 12, fontWeight: FontWeight.bold, color: CustomColors.primary),
            ),
          ),
      ],
    );
  }
}
