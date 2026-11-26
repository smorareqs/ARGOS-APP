import 'package:argos_app/core/utils/date_labels.dart';
import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/inventory/data/inventory_repository.dart';
import 'package:argos_app/features/inventory/models/my_inventory.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// B9 · Inventario: mi custodia por categoría, "Sacar artículos" (B10) y
/// "Solicitar reposición" (B11), y mis solicitudes con su estado.
class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key, this.showBack = false});

  final bool showBack;

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  InventoryCategory? _filter;

  Future<void> _refresh() => ref.refresh(myInventoryProvider.future).then((_) {}, onError: (_) {});

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myInventoryProvider);
    final data = async.valueOrNull;
    final inv = data?.$1;
    final cachedAt = data?.$2;

    Widget body;
    if (inv == null && async.isLoading) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var i = 0; i < 4; i++) ...[
            const Skeleton(width: double.infinity, height: 64, radius: CustomDimensions.radiusCard),
            const SizedBox(height: 10),
          ],
        ],
      );
    } else if (inv == null) {
      body = ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ErrorState(
            message: async.error is DioException
                ? 'Sin conexión y sin una copia guardada de tu inventario.'
                : errorMessage(async.error ?? 'Error'),
            onRetry: _refresh,
          ),
        ],
      );
    } else {
      final categories = {for (final c in inv.custody) c.category}.toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      final shown = inv.custody.where((c) => _filter == null || c.category == _filter).toList();
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (cachedAt != null) ...[
            OfflineBar(detail: 'mostrando datos guardados ${DateLabels.relative(cachedAt)}'),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Sacar artículos',
                  onPressed: inv.warehouses.isEmpty ? null : () => _checkout(inv),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SecondaryButton(label: 'Pedir reposición', onPressed: () => _restock(inv)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Text('Mi custodia', style: CustomTypography.sectionTitle)),
              Text(
                '${inv.custody.length} ${inv.custody.length == 1 ? 'artículo' : 'artículos'}',
                style: CustomTypography.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (categories.length > 1) ...[
            FilterChips<InventoryCategory?>(
              padding: EdgeInsets.zero,
              options: [
                FilterOption(value: null, label: 'Todo', count: inv.custody.length),
                for (final c in categories)
                  FilterOption(
                    value: c,
                    label: c.label,
                    count: inv.custody.where((e) => e.category == c).length,
                  ),
              ],
              selected: {_filter},
              onChanged: (s) => setState(() => _filter = s.isEmpty ? null : s.first),
            ),
            const SizedBox(height: 12),
          ],
          if (inv.custody.isEmpty)
            const EmptyState(
              icon: CustomIcons.equipment,
              title: 'No tienes artículos en custodia',
              message: 'Saca de la bodega lo que necesites para tus limpiezas.',
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, c) in shown.indexed) ...[
                    if (i > 0) const Divider(height: 1, color: CustomColors.divider),
                    _CustodyTile(entry: c),
                  ],
                ],
              ),
            ),
          if (inv.requests.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('Mis solicitudes', style: CustomTypography.sectionTitle),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, r) in inv.requests.take(10).indexed) ...[
                    if (i > 0) const Divider(height: 1, color: CustomColors.divider),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.summary, style: CustomTypography.body),
                                const SizedBox(height: 4),
                                Text(
                                  [DateLabels.relative(r.at), if (r.note != null) r.note!].join(' · '),
                                  style: CustomTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            label: r.statusLabel,
                            variant: switch (r.status) {
                              'fulfilled' || 'approved' => StatusBadgeVariant.operative,
                              'rejected' => StatusBadgeVariant.incident,
                              _ => StatusBadgeVariant.pending,
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
                  Expanded(child: Text('Inventario', style: CustomTypography.pageTitle)),
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

  Future<void> _checkout(MyInventory inv) async {
    final done = await showArgosSheet<bool>(context, builder: (_) => _CheckoutSheet(inventory: inv));
    if (done == true && mounted) {
      showToast(context, 'Artículos agregados a tu custodia.');
      await _refresh();
    }
  }

  Future<void> _restock(MyInventory inv) async {
    final done = await showArgosSheet<bool>(context, builder: (_) => _RestockSheet(inventory: inv));
    if (done == true && mounted) {
      showToast(context, 'Solicitud enviada. Te avisaremos cuando la atiendan.');
      await _refresh();
    }
  }
}

class _CustodyTile extends StatelessWidget {
  const _CustodyTile({required this.entry});

  final CustodyEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: CustomColors.tealWashed, borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon(entry.category), size: 20, color: CustomColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: CustomTypography.cardTitle),
                const SizedBox(height: 2),
                Text(
                  [
                    entry.category.label,
                    if (entry.returnable) 'se devuelve',
                    if (entry.since != null) 'desde ${DateLabels.relative(entry.since!)}',
                  ].join(' · '),
                  style: CustomTypography.bodySmall,
                ),
              ],
            ),
          ),
          Text('${_fmt(entry.qty)} ${entry.unit}', style: CustomTypography.data.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}

IconData _icon(InventoryCategory c) => switch (c) {
  InventoryCategory.linens => CustomIcons.sharedAreas,
  InventoryCategory.amenities => CustomIcons.cleaning,
  InventoryCategory.cleaning => CustomIcons.cleaning,
  InventoryCategory.kitchen => CustomIcons.property,
  InventoryCategory.keys => CustomIcons.key,
};

String _fmt(double v) => v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(2);

/// B10 · Sacar artículos: bodega, buscador, cantidad por artículo y
/// existencia disponible.
class _CheckoutSheet extends ConsumerStatefulWidget {
  const _CheckoutSheet({required this.inventory});

  final MyInventory inventory;

  @override
  ConsumerState<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<_CheckoutSheet> {
  late String _warehouse = widget.inventory.warehouses.first.id;
  final _qty = <String, int>{};
  var _query = '';
  var _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(inventoryRepositoryProvider).checkout(_warehouse, _qty);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        showToast(context, e is DioException ? 'Necesitas conexión para sacar artículos.' : errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final items = widget.inventory
        .stockIn(_warehouse)
        .where((i) => q.isEmpty || i.name.toLowerCase().contains(q) || i.sku.toLowerCase().contains(q))
        .toList();
    final total = _qty.values.fold<int>(0, (a, b) => a + b);
    return SheetScaffold(
      title: 'Sacar artículos',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.inventory.warehouses.length > 1) ...[
            Wrap(
              spacing: 8,
              children: [
                for (final w in widget.inventory.warehouses)
                  ChoiceChip(
                    label: Text(w.propertyCode == null ? w.name : '${w.name} · ${w.propertyCode}'),
                    selected: _warehouse == w.id,
                    onSelected: (_) => setState(() {
                      _warehouse = w.id;
                      _qty.clear();
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          SearchField(hintText: 'Buscar artículo o código', minLength: 1, onSearch: (v) => setState(() => _query = v)),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: CustomColors.divider),
              itemBuilder: (context, i) {
                final it = items[i];
                final max = it.available.floor();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.name, style: CustomTypography.cardTitle),
                            Text(
                              max == 0 ? 'Sin existencia' : 'Hay ${_fmt(it.available)} ${it.unit}',
                              style: CustomTypography.bodySmall.copyWith(
                                color: max == 0 ? CustomColors.error : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      NumberStepper(
                        value: _qty[it.id] ?? 0,
                        max: max,
                        semanticLabel: 'Sacar ${it.name}',
                        onChanged: max == 0 ? null : (v) => setState(() => _qty[it.id] = v),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: total == 0 ? 'Confirmar salida' : 'Confirmar salida · $total',
            isLoading: _saving,
            onPressed: total == 0 || _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

/// B11 · Solicitar reposición: artículos, cantidad y nota.
class _RestockSheet extends ConsumerStatefulWidget {
  const _RestockSheet({required this.inventory});

  final MyInventory inventory;

  @override
  ConsumerState<_RestockSheet> createState() => _RestockSheetState();
}

class _RestockSheetState extends ConsumerState<_RestockSheet> {
  final _qty = <String, int>{};
  final _note = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(inventoryRepositoryProvider).requestRestock(items: _qty, note: _note.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        showToast(context, e is DioException ? 'Necesitas conexión para enviar la solicitud.' : errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wh = widget.inventory.warehouses.firstOrNull?.id ?? '';
    final items = widget.inventory.stockIn(wh)..sort((a, b) => a.available.compareTo(b.available));
    final total = _qty.values.fold<int>(0, (a, b) => a + b);
    return SheetScaffold(
      title: 'Pedir reposición',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'El administrador la revisa y te avisa cuando esté lista. Primero los que menos quedan.',
            style: CustomTypography.bodySmall,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: CustomColors.divider),
              itemBuilder: (context, i) {
                final it = items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.name, style: CustomTypography.cardTitle),
                            Text('En bodega: ${_fmt(it.available)} ${it.unit}', style: CustomTypography.bodySmall),
                          ],
                        ),
                      ),
                      NumberStepper(
                        value: _qty[it.id] ?? 0,
                        max: 999,
                        step: it.unit == 'unidad' ? 6 : 1,
                        semanticLabel: 'Pedir ${it.name}',
                        onChanged: (v) => setState(() => _qty[it.id] = v),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(controller: _note, hintText: 'Nota (opcional)', maxLines: 2),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Enviar solicitud',
            isLoading: _saving,
            onPressed: total == 0 || _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
