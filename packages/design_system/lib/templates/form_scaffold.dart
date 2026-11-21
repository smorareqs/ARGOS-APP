import 'package:design_system/atoms/app_icon_button.dart';
import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Pantalla de formulario — título en Garamond, contenido con scroll y la
/// acción principal fija al pie (sobre el teclado y la zona segura).
/// Ref: ux-ui.md §2.5 ("botón principal fijo al pie") y §2.6 (FormScaffold).
class FormScaffold extends StatelessWidget {
  const FormScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Acción principal (y secundarias) fijas al pie.
  final Widget? footer;

  /// Si es null no se muestra la flecha de regreso.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 56,
              child: Align(
                alignment: Alignment.centerLeft,
                child: onBack == null
                    ? null
                    : AppIconButton(
                        icon: CustomIcons.arrowBack,
                        semanticLabel: 'Volver',
                        onPressed: onBack,
                      ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  Text(title, style: CustomTypography.pageTitle),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(subtitle!, style: CustomTypography.body),
                  ],
                  const SizedBox(height: 24),
                  ...children,
                ],
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}
