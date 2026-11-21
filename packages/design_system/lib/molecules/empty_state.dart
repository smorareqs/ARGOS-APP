import 'package:design_system/atoms/secondary_button.dart';
import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Estado vacío — ilustración (icono en círculo teal lavado), título, una
/// frase y acción opcional si el rol puede crear.
/// Ref: ux-ui.md §3.1 (Vacío) y §2.4 (ilustraciones).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: CustomColors.tealWashed,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: CustomColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: CustomTypography.sectionTitle,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: CustomTypography.body,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              SecondaryButton(
                label: actionLabel!,
                onPressed: onAction,
                isExpanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
