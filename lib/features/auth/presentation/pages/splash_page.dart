import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A1 · Arranque — logo sobre teal mientras se decide a dónde ir.
/// La decisión la toma `SessionController.boot`; el router navega.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ArgosLogo(size: 44, color: Colors.white),
            const SizedBox(height: CustomDimensions.spacingXl),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white.withValues(alpha: 0.6),
                semanticsLabel: 'Cargando',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
