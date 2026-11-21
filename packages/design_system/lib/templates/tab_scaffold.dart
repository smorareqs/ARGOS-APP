import 'package:design_system/molecules/app_bottom_nav.dart';
import 'package:design_system/tokens/custom_colors.dart';
import 'package:flutter/material.dart';

/// Contenedor de las pestañas principales — barra inferior por rol, banda
/// superior opcional (p. ej. [OfflineBar]) y cuerpos que conservan su estado
/// al cambiar de pestaña.
/// Ref: ux-ui.md §2.6 (TabScaffold) y §4.1.
class TabScaffold extends StatelessWidget {
  const TabScaffold({
    super.key,
    required this.destinations,
    required this.bodies,
    required this.currentIndex,
    required this.onSelect,
    this.banner,
  }) : assert(destinations.length == bodies.length);

  final List<NavDestination> destinations;
  final List<Widget> bodies;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// Banda fija sobre el contenido (sin conexión, solo lectura).
  final Widget? banner;

  @override
  Widget build(BuildContext context) {
    final content = IndexedStack(index: currentIndex, children: bodies);
    return Scaffold(
      backgroundColor: CustomColors.background,
      bottomNavigationBar: AppBottomNav(
        destinations: destinations,
        currentIndex: currentIndex,
        onSelect: onSelect,
      ),
      body: banner == null
          ? content
          : Column(
              children: [
                SafeArea(bottom: false, child: banner!),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: content,
                  ),
                ),
              ],
            ),
    );
  }
}
