import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Avatar circular — imagen si hay URL, si no iniciales en Garamond sobre
/// dorado (personas) o teal lavado (empresas).
/// Ref: ux-ui.md §2.6 (Avatar).
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 42,
    this.variant = AvatarVariant.person,
  });

  /// Nombre del que se extraen las iniciales.
  final String name;
  final String? imageUrl;
  final double size;
  final AvatarVariant variant;

  /// Hasta dos iniciales: primera y última palabra.
  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isPerson = variant == AvatarVariant.person;
    final background = isPerson ? CustomColors.secondary : CustomColors.tealWashed;
    final foreground = isPerson ? Colors.white : CustomColors.primary;

    return Semantics(
      label: name,
      image: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(shape: BoxShape.circle, color: background),
        child: imageUrl == null
            ? Text(
                initialsOf(name),
                style: CustomTypography.garamond(
                  fontSize: size * 0.4,
                  color: foreground,
                ),
              )
            : Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Text(
                  initialsOf(name),
                  style: CustomTypography.garamond(
                    fontSize: size * 0.4,
                    color: foreground,
                  ),
                ),
              ),
      ),
    );
  }
}

enum AvatarVariant { person, company }
