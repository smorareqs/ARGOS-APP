import 'package:design_system/atoms/tertiary_button.dart';
import 'package:design_system/molecules/app_card.dart';
import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Estado de error — tarjeta con la causa y "Reintentar".
/// Ref: ux-ui.md §3.1 (Error).
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Reintentar',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CustomIcons.error, size: 32, color: CustomColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: CustomTypography.body.copyWith(color: CustomColors.textBody),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TertiaryButton(label: retryLabel, onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
