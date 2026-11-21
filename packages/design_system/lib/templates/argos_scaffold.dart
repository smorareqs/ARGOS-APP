import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:flutter/material.dart';

/// Plantilla base de pantalla ARGOS — fija el fondo arena y un padding de
/// contenido consistente. Las *screens* de la app la usan como cimiento.
class ArgosScaffold extends StatelessWidget {
  const ArgosScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.padded = true,
    this.backgroundColor = CustomColors.background,
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;

  /// Aplica el padding de contenido estándar.
  final bool padded;
  final Color backgroundColor;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: padded
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CustomDimensions.spacingLg,
                  vertical: CustomDimensions.spacingLg,
                ),
                child: body,
              )
            : body,
      ),
    );
  }
}
