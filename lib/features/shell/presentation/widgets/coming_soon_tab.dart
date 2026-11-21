import 'package:argos_app/features/shell/models/shell_tab.dart';
import 'package:argos_app/features/shell/presentation/pages/home_shell_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Pestaña aún sin contenido: llega en una fase posterior.
class ComingSoonTab extends StatelessWidget {
  const ComingSoonTab({super.key, required this.tab});

  final ShellTab tab;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: EmptyState(
        icon: shellTabIcon(tab),
        title: tab.label,
        message: 'Esta sección llega en una próxima versión de ARGOS.',
      ),
    );
  }
}
