import 'package:design_system/atoms/app_icon_button.dart';
import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Pantalla de detalle ARGOS — cabecera teal colapsable con título en
/// Garamond, línea secundaria y estado; al hacer scroll se reduce a una barra
/// con el título. Banda de aviso opcional (p. ej. "Debió iniciar a las
/// 09:00"), contenido con scroll y acción principal fija al pie.
/// Ref: ux-ui.md §2.6 (DetailScaffold) y B3.
class DetailScaffold extends StatelessWidget {
  const DetailScaffold({
    super.key,
    required this.title,
    required this.children,
    this.overline,
    this.subtitle,
    this.status,
    this.banner,
    this.actions = const [],
    this.footer,
    this.onBack,
    this.expandedHeight = 196,
  });

  final String title;

  /// Texto pequeño sobre el título (código de propiedad, tipo de tarea).
  final String? overline;

  /// Línea bajo el título (ventana horaria, dirección corta).
  final String? subtitle;

  /// Normalmente un [StatusBadge].
  final Widget? status;

  /// Banda de aviso bajo la cabecera, normalmente un [DetailBanner].
  final Widget? banner;

  /// Iconos a la derecha de la barra (menú "más").
  final List<Widget> actions;
  final List<Widget> children;

  /// Acción principal fija al pie.
  final Widget? footer;
  final VoidCallback? onBack;
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: CustomColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: expandedHeight,
                  backgroundColor: CustomColors.primary,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  leading: onBack == null
                      ? null
                      : AppIconButton(
                          icon: CustomIcons.arrowBack,
                          semanticLabel: 'Volver',
                          color: CustomColors.onPrimary,
                          onPressed: onBack,
                        ),
                  actions: [...actions, const SizedBox(width: 4)],
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      final collapsed = kToolbarHeight + topInset;
                      final t =
                          ((constraints.maxHeight - collapsed) /
                                  (expandedHeight + topInset - collapsed))
                              .clamp(0.0, 1.0);
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Título compacto cuando la cabecera está cerrada.
                          Positioned(
                            left: onBack == null ? 24 : 64,
                            right: 64,
                            top: topInset,
                            height: kToolbarHeight,
                            child: Opacity(
                              opacity: (1 - t * 2).clamp(0.0, 1.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: CustomTypography.cardTitle.copyWith(
                                    color: CustomColors.onPrimary,
                                    fontSize: 19,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Cabecera completa.
                          Positioned(
                            left: 24,
                            right: 24,
                            bottom: 20,
                            child: Opacity(
                              opacity: ((t - 0.35) / 0.65).clamp(0.0, 1.0),
                              child: _ExpandedHeader(
                                title: title,
                                overline: overline,
                                subtitle: subtitle,
                                status: status,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (banner != null) SliverToBoxAdapter(child: banner),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  sliver: SliverList.list(children: children),
                ),
              ],
            ),
          ),
          if (footer != null)
            DecoratedBox(
              decoration: const BoxDecoration(
                color: CustomColors.surface,
                border: Border(top: BorderSide(color: CustomColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                  child: footer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpandedHeader extends StatelessWidget {
  const _ExpandedHeader({
    required this.title,
    this.overline,
    this.subtitle,
    this.status,
  });

  final String title;
  final String? overline;
  final String? subtitle;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (overline != null || status != null)
          Row(
            children: [
              if (overline != null)
                Expanded(
                  child: Text(
                    overline!.toUpperCase(),
                    style: CustomTypography.label.copyWith(
                      color: CustomColors.secondary,
                      letterSpacing: 1.4,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (status != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: CustomColors.surface,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: status,
                ),
            ],
          ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CustomTypography.pageTitle.copyWith(
            color: CustomColors.onPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: CustomTypography.bodySmall.copyWith(
              color: CustomColors.onPrimary.withValues(alpha: 0.78),
            ),
          ),
        ],
      ],
    );
  }
}

/// Banda de aviso a todo lo ancho bajo la cabecera de un [DetailScaffold].
class DetailBanner extends StatelessWidget {
  const DetailBanner({
    super.key,
    required this.message,
    this.icon = CustomIcons.pending,
    this.background = CustomColors.warningSoft,
    this.foreground = CustomColors.warning,
  });

  final String message;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: ColoredBox(
        color: background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: CustomTypography.verdana(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
