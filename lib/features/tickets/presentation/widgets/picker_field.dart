import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Campo que abre una hoja para elegir (propiedad, activo…).
class PickerField extends StatelessWidget {
  const PickerField({super.key, required this.value, required this.placeholder, this.icon, this.onTap});

  final String? value;
  final String placeholder;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final empty = value == null || value!.isEmpty;
    return Semantics(
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CustomDimensions.radiusField),
        child: Container(
          constraints: const BoxConstraints(minHeight: CustomDimensions.fieldHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: onTap == null ? CustomColors.surfaceSoft : CustomColors.surface,
            borderRadius: BorderRadius.circular(CustomDimensions.radiusField),
            border: Border.all(color: CustomColors.borderField),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: CustomColors.tealMuted),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  empty ? placeholder : value!,
                  style: CustomTypography.body.copyWith(
                    color: empty ? CustomColors.textMuted : CustomColors.textPrimary,
                  ),
                ),
              ),
              if (onTap != null) const Icon(CustomIcons.expand, size: 20, color: CustomColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lo elegido en [showOptionSheet]; `value` null = la opción "ninguno".
class Picked<T> {
  const Picked(this.value);
  final T? value;
}

/// Hoja con búsqueda para elegir una opción. Devuelve null si se cerró sin
/// elegir.
Future<Picked<T>?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required String Function(T) label,
  String Function(T)? subtitle,
  String Function(T)? group,
  bool searchable = false,
  String? noneLabel,
}) {
  return showArgosSheet<Picked<T>>(
    context,
    builder: (_) => _OptionSheet<T>(
      title: title,
      options: options,
      label: label,
      subtitle: subtitle,
      group: group,
      searchable: searchable,
      noneLabel: noneLabel,
    ),
  );
}

class _OptionSheet<T> extends StatefulWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.label,
    this.subtitle,
    this.group,
    this.searchable = false,
    this.noneLabel,
  });

  final String title;
  final List<T> options;
  final String Function(T) label;
  final String Function(T)? subtitle;
  final String Function(T)? group;
  final bool searchable;
  final String? noneLabel;

  @override
  State<_OptionSheet<T>> createState() => _OptionSheetState<T>();
}

class _OptionSheetState<T> extends State<_OptionSheet<T>> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.toLowerCase();
    final shown = widget.options.where((o) {
      if (q.isEmpty) return true;
      return widget.label(o).toLowerCase().contains(q) ||
          (widget.subtitle?.call(o).toLowerCase().contains(q) ?? false);
    }).toList();
    final rows = <Widget>[];
    String? lastGroup;
    for (final o in shown) {
      final g = widget.group?.call(o);
      if (g != null && g != lastGroup) {
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
            child: Text(g.toUpperCase(), style: CustomTypography.label),
          ),
        );
        lastGroup = g;
      }
      rows.add(
        AppListTile(
          title: widget.label(o),
          subtitle: widget.subtitle?.call(o),
          showChevron: false,
          onTap: () => Navigator.of(context).pop(Picked<T>(o)),
        ),
      );
    }
    return SheetScaffold(
      title: widget.title,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.searchable) ...[
              AppTextField(
                hintText: 'Buscar',
                prefixIcon: CustomIcons.search,
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
              const SizedBox(height: 8),
            ],
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  if (widget.noneLabel != null)
                    AppListTile(
                      title: widget.noneLabel!,
                      icon: CustomIcons.help,
                      showChevron: false,
                      onTap: () => Navigator.of(context).pop(Picked<T>(null)),
                    ),
                  ...rows,
                  if (rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: EmptyState(icon: CustomIcons.search, title: 'Sin resultados'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
