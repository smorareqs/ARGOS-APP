import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_motion.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Hoja inferior ARGOS — radio 24 arriba, asa, título en Garamond y
/// contenido con margen seguro inferior.
/// Ref: ux-ui.md §2.4 (hojas) y §2.6 (SheetScaffold).
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CustomColors.borderField,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (title != null) ...[
            Text(title!, style: CustomTypography.sectionTitle),
            const SizedBox(height: 12),
          ],
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// Abre una hoja inferior con el estilo ARGOS (scrim teal y radio 24).
Future<T?> showArgosSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: CustomColors.surface,
    barrierColor: CustomColors.overlay,
    sheetAnimationStyle: AnimationStyle(
      duration: CustomMotion.resolve(context, CustomMotion.slow),
      reverseDuration: CustomMotion.resolve(context, CustomMotion.base),
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: builder,
  );
}
