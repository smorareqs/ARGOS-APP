import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/tasks/models/task_detail.dart';
import 'package:argos_app/features/tasks/presentation/providers/task_detail_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// B6 · Insumos: cuánto se usó de cada consumible en custodia (jabón,
/// shampoo, papel…). Los blancos y las llaves no se consumen: se concilian
/// al cerrar. Se guarda también sin conexión.
Future<void> showConsumptionSheet(BuildContext context, TaskDetail task) =>
    showArgosSheet<void>(context, builder: (_) => _ConsumptionSheet(task: task));

class _ConsumptionSheet extends ConsumerStatefulWidget {
  const _ConsumptionSheet({required this.task});

  final TaskDetail task;

  @override
  ConsumerState<_ConsumptionSheet> createState() => _ConsumptionSheetState();
}

class _ConsumptionSheetState extends ConsumerState<_ConsumptionSheet> {
  final _used = <String, int>{};
  var _saving = false;

  List<CustodyLine> get _consumables =>
      widget.task.custody.where((c) => !c.returnable && c.quantity >= 1).toList();

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(taskDetailControllerProvider(widget.task.id).notifier)
          .addConsumptions({for (final e in _used.entries) e.key: e.value.toDouble()});
      if (!mounted) return;
      showToast(context, 'Insumos guardados.');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _consumables;
    final total = _used.values.fold<int>(0, (a, b) => a + b);
    return SheetScaffold(
      title: 'Insumos usados',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EmptyState(
                icon: CustomIcons.equipment,
                title: 'Sin consumibles en tu custodia',
                message: 'Saca artículos de la bodega en Inventario para registrarlos aquí.',
                actionLabel: 'Ir a Inventario',
                onAction: () {
                  Navigator.of(context).pop();
                  context.push('/inventory');
                },
              ),
            )
          else ...[
            Text(
              'Lo que uses sale de tu custodia. Los blancos y llaves se devuelven al cerrar.',
              style: CustomTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: CustomColors.divider),
                itemBuilder: (context, i) {
                  final c = items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: CustomTypography.cardTitle),
                              const SizedBox(height: 2),
                              Text(
                                'Tienes ${_fmt(c.quantity)} ${c.unit}',
                                style: CustomTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        NumberStepper(
                          value: _used[c.itemId] ?? 0,
                          max: c.quantity.floor(),
                          semanticLabel: 'Cantidad usada de ${c.name}',
                          onChanged: (v) => setState(() => _used[c.itemId] = v),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: total == 0 ? 'Guardar insumos' : 'Guardar $total ${total == 1 ? 'artículo' : 'artículos'}',
              isLoading: _saving,
              onPressed: total == 0 || _saving ? null : _save,
            ),
          ],
        ],
      ),
    );
  }
}

String _fmt(double v) => v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(2);
