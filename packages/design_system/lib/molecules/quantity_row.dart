import 'package:design_system/atoms/number_stepper.dart';
import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Fila de conciliación de custodia ARGOS — artículo, cuánto se llevó
/// (custodia), cuánto devuelve y cuánto consumió. Lo que no cuadra se
/// marca como diferencia (se registrará como discrepancia).
/// Ref: ux-ui.md §2.6 (QuantityRow) y B7.
class QuantityRow extends StatelessWidget {
  const QuantityRow({
    super.key,
    required this.name,
    required this.custody,
    required this.returned,
    required this.consumed,
    required this.onReturnedChanged,
    required this.onConsumedChanged,
    this.unit,
    this.sku,
  });

  final String name;

  /// Unidades que tenía en custodia.
  final int custody;
  final int returned;
  final int consumed;
  final ValueChanged<int>? onReturnedChanged;
  final ValueChanged<int>? onConsumedChanged;
  final String? unit;
  final String? sku;

  /// Positiva: faltan unidades; negativa: sobran.
  int get difference => custody - returned - consumed;

  @override
  Widget build(BuildContext context) {
    final diff = difference;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CustomColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: diff == 0 ? CustomColors.border : CustomColors.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: CustomTypography.cardTitle),
                    if (sku != null)
                      Text(
                        sku!,
                        style: CustomTypography.mono.copyWith(
                          fontSize: 11,
                          color: CustomColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('CUSTODIA', style: CustomTypography.label),
                  Text(
                    '$custody${unit == null ? '' : ' $unit'}',
                    style: CustomTypography.data.copyWith(fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StepperColumn(
                  label: 'DEVUELVO',
                  child: NumberStepper(
                    value: returned,
                    max: custody,
                    semanticLabel: 'Devuelvo $name',
                    onChanged: onReturnedChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StepperColumn(
                  label: 'CONSUMÍ',
                  child: NumberStepper(
                    value: consumed,
                    max: custody,
                    semanticLabel: 'Consumí $name',
                    onChanged: onConsumedChanged,
                  ),
                ),
              ),
            ],
          ),
          if (diff != 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: CustomColors.warningSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                diff > 0
                    ? 'Faltan $diff. Se registrará una diferencia.'
                    : 'Sobran ${-diff}. Revisa las cantidades.',
                style: CustomTypography.verdana(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: CustomColors.warning,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepperColumn extends StatelessWidget {
  const _StepperColumn({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CustomTypography.label),
        const SizedBox(height: 6),
        FittedBox(fit: BoxFit.scaleDown, child: child),
      ],
    );
  }
}
