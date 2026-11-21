import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Comparación "antes / después" deslizable — las dos fotos superpuestas y
/// un divisor que se arrastra (o se mueve con las flechas de accesibilidad).
/// Ref: ux-ui.md §2.4 (Fotos) y §2.6 (BeforeAfterPair).
class BeforeAfterPair extends StatefulWidget {
  const BeforeAfterPair({
    super.key,
    required this.before,
    required this.after,
    this.beforeLabel = 'Antes',
    this.afterLabel = 'Después',
    this.aspectRatio = 4 / 3,
    this.initialPosition = 0.5,
  });

  final ImageProvider before;
  final ImageProvider after;
  final String beforeLabel;
  final String afterLabel;
  final double aspectRatio;

  /// 0 = todo "después", 1 = todo "antes".
  final double initialPosition;

  @override
  State<BeforeAfterPair> createState() => _BeforeAfterPairState();
}

class _BeforeAfterPairState extends State<BeforeAfterPair> {
  late double _position = widget.initialPosition.clamp(0.0, 1.0);

  void _move(double delta) =>
      setState(() => _position = (_position + delta).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Comparación ${widget.beforeLabel} y ${widget.afterLabel}',
      value: '${(_position * 100).round()} % ${widget.beforeLabel}',
      increasedValue: '${((_position + 0.1).clamp(0.0, 1.0) * 100).round()} %',
      decreasedValue: '${((_position - 0.1).clamp(0.0, 1.0) * 100).round()} %',
      onIncrease: () => _move(0.1),
      onDecrease: () => _move(-0.1),
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final x = width * _position;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) => _move(d.delta.dx / width),
                onTapDown: (d) =>
                    setState(() => _position = d.localPosition.dx / width),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image(image: widget.after, fit: BoxFit.cover),
                    ClipRect(
                      clipper: _LeftClipper(x),
                      child: Image(image: widget.before, fit: BoxFit.cover),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _Tag(widget.beforeLabel),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: _Tag(widget.afterLabel),
                    ),
                    Positioned(
                      left: x - 1.5,
                      top: 0,
                      bottom: 0,
                      child: const ColoredBox(
                        color: Colors.white,
                        child: SizedBox(width: 3),
                      ),
                    ),
                    Positioned(
                      left: x - 20,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x33003841),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CustomIcons.compare,
                            size: 22,
                            color: CustomColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LeftClipper extends CustomClipper<Rect> {
  _LeftClipper(this.x);

  final double x;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, x, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => old.x != x;
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CustomColors.overlay,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        text.toUpperCase(),
        style: CustomTypography.verdana(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Colors.white,
        ),
      ),
    );
  }
}
