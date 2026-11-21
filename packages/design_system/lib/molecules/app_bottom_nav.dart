import 'package:design_system/atoms/nav_tab_item.dart';
import 'package:design_system/tokens/custom_colors.dart';
import 'package:flutter/material.dart';

/// Un destino de la [AppBottomNav].
class NavDestination {
  const NavDestination({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Barra de navegación inferior ARGOS — superficie blanca elevada.
/// Ref: ARGOS App · bottom tab bar del Itinerario.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.destinations,
    required this.currentIndex,
    this.onSelect,
  });

  final List<NavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CustomColors.surface,
        border: Border(
          top: BorderSide(color: CustomColors.primary.withValues(alpha: 0.08)),
        ),
        boxShadow: [
          BoxShadow(
            color: CustomColors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < destinations.length; i++)
                NavTabItem(
                  icon: destinations[i].icon,
                  label: destinations[i].label,
                  active: i == currentIndex,
                  onTap: onSelect == null ? null : () => onSelect!(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
