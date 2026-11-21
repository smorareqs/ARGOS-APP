import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Logotipo oficial ARGOS — una casa trazada con la greca griega en un solo
/// trazo (Argos, el guardián de la mitología griega) + wordmark EB Garamond
/// con tracking amplio. Mismo trazo que `ARGOS-WEB/public/brand`.
class ArgosLogo extends StatelessWidget {
  const ArgosLogo({
    super.key,
    this.showWordmark = true,
    this.size = 38,
    this.color = CustomColors.primary,
  });

  /// Muestra el texto "ARGOS" junto al símbolo.
  final bool showWordmark;

  /// Lado del símbolo; el wordmark escala con él.
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: ArgosMarkPainter(color: color)),
    );

    if (!showWordmark) return Semantics(label: 'ARGOS', child: mark);

    return Semantics(
      label: 'ARGOS',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            mark,
            SizedBox(width: size * 0.3),
            Text(
              'ARGOS',
              style: CustomTypography.garamond(
                fontSize: size * 0.68,
                fontWeight: FontWeight.w600,
                color: color,
              ).copyWith(letterSpacing: size * 0.68 * 0.18, height: 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinta el símbolo en una cuadrícula de 48 escalada al tamaño disponible.
/// Trazo SVG: `M7 43V20.5L24 7l17 13.5V43H15.5V26.5h17V35H23.5`.
class ArgosMarkPainter extends CustomPainter {
  const ArgosMarkPainter({required this.color, this.strokeWidth = 4.6});

  final Color color;

  /// En unidades de la cuadrícula de 48.
  final double strokeWidth;

  static final Path _mark = Path()
    ..moveTo(7, 43)
    ..lineTo(7, 20.5)
    ..lineTo(24, 7)
    ..lineTo(41, 20.5)
    ..lineTo(41, 43)
    ..lineTo(15.5, 43)
    ..lineTo(15.5, 26.5)
    ..lineTo(32.5, 26.5)
    ..lineTo(32.5, 35)
    ..lineTo(23.5, 35);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 48;
    canvas
      ..save()
      ..translate(
        (size.width - 48 * scale) / 2,
        (size.height - 48 * scale) / 2,
      )
      ..scale(scale);
    canvas.drawPath(
      _mark,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.miter
        ..strokeCap = StrokeCap.butt,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(ArgosMarkPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
