import 'package:argos_app/core/config/app_config.dart';
import 'package:argos_app/core/device/device_identity.dart';
import 'package:argos_app/features/auth/models/quick_unlock.dart';
import 'package:argos_app/features/auth/models/session.dart';
import 'package:argos_app/features/auth/presentation/providers/account_providers.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/chat/presentation/widgets/chat_entry_tile.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// B17 · Perfil: asistencia, métricas, boletas y disciplina (fase 5) según
/// los permisos; cambiar de empresa, sesiones, avisos, inicio rápido,
/// contraseña y cerrar sesión.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, this.showBack = false});

  /// Abierta desde "Más" (sin pestaña propia).
  final bool showBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider);
    if (state is! AuthSignedIn) return const SizedBox.shrink();
    final session = state.session;
    final online = !state.offline;
    final quickUnlock = ref.watch(quickUnlockControllerProvider).value;
    final version = ref.watch(appVersionProvider).value;
    final showCatalog = kDebugMode || ref.watch(appConfigProvider).useMock;

    const needsConnection = 'Requiere conexión';

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (showBack)
          Align(
            alignment: Alignment.centerLeft,
            child: AppIconButton(
              icon: CustomIcons.arrowBack,
              semanticLabel: 'Volver',
              onPressed: () => context.pop(),
            ),
          )
        else
          const SizedBox(height: 16),
        _Header(session: session),
        const SizedBox(height: CustomDimensions.spacingLg),
        if (_hasWork(session)) ...[
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                if (!showBack) const ChatEntryTile(),
                if (session.can('hr.attendance.own'))
                  AppListTile(
                    icon: CustomIcons.time,
                    title: 'Asistencia',
                    subtitle: 'Marcar entrada y salida, y tu mes',
                    onTap: () => context.push('/attendance'),
                  ),
                if (session.can('metrics.own'))
                  AppListTile(
                    icon: CustomIcons.metrics,
                    title: 'Mis métricas',
                    subtitle: 'Limpiezas, puntualidad y metas',
                    onTap: () => context.push('/metrics'),
                  ),
                if (session.can('hr.attendance.own') && (session.tenant.features['payroll'] ?? false))
                  AppListTile(
                    icon: CustomIcons.document,
                    title: 'Mis boletas',
                    subtitle: 'Tus pagos de cada quincena',
                    onTap: () => context.push('/payslips'),
                  ),
                if (session.can('hr.disciplinary.own'))
                  AppListTile(
                    icon: CustomIcons.notes,
                    title: 'Disciplina',
                    subtitle: 'Llamadas de atención y su acuse',
                    onTap: () => context.push('/disciplinary'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: CustomDimensions.spacingMd),
        ],
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (session.hasOtherTenants)
                AppListTile(
                  icon: CustomIcons.swap,
                  title: 'Cambiar de empresa',
                  subtitle: online ? session.tenant.name : needsConnection,
                  onTap: online ? () => _switchTenant(context, ref, session) : null,
                ),
              AppListTile(
                icon: CustomIcons.devices,
                title: 'Sesiones activas',
                subtitle: online ? null : needsConnection,
                onTap: online ? () => context.push('/profile/sessions') : null,
              ),
              AppListTile(
                icon: CustomIcons.notifications,
                title: 'Notificaciones',
                subtitle: online ? 'Qué te llega al teléfono y al correo' : needsConnection,
                onTap: online ? () => context.push('/profile/notifications') : null,
              ),
              if (session.can('maintenance.report') && !session.can('maintenance.execute'))
                AppListTile(
                  icon: CustomIcons.tickets,
                  title: 'Mis reportes',
                  subtitle: 'Incidencias que reportaste',
                  onTap: () => context.push('/tickets'),
                ),
              AppListTile(
                icon: CustomIcons.fingerprint,
                title: 'Inicio rápido',
                subtitle: _quickUnlockLabel(quickUnlock),
                onTap: () => context.push('/profile/quick-unlock'),
              ),
              AppListTile(
                icon: CustomIcons.key,
                title: 'Cambiar contraseña',
                subtitle: online ? null : needsConnection,
                onTap: online ? () => context.push('/profile/password') : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: CustomDimensions.spacingMd),
        AppCard(
          padding: EdgeInsets.zero,
          child: AppListTile(
            icon: CustomIcons.info,
            title: 'Acerca de',
            subtitle: version == null || version.isEmpty ? 'ARGOS' : 'ARGOS · versión $version',
            showChevron: false,
          ),
        ),
        if (showCatalog) ...[
          const SizedBox(height: CustomDimensions.spacingMd),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppListTile(
              icon: CustomIcons.compare,
              title: 'Catálogo de componentes',
              subtitle: 'Solo en modo de pruebas',
              onTap: () => context.push('/profile/components'),
            ),
          ),
        ],
        const SizedBox(height: CustomDimensions.spacingMd),
        AppCard(
          padding: EdgeInsets.zero,
          child: AppListTile(
            icon: CustomIcons.logout,
            title: 'Cerrar sesión',
            destructive: true,
            showChevron: false,
            onTap: () => _logout(context, ref),
          ),
        ),
      ],
    );

    return showBack
        ? Scaffold(backgroundColor: CustomColors.background, body: SafeArea(child: content))
        : SafeArea(child: content);
  }

  static bool _hasWork(Session s) =>
      s.can('hr.attendance.own') || s.can('metrics.own') || s.can('hr.disciplinary.own');

  static String _quickUnlockLabel(QuickUnlockSettings? settings) {
    if (settings == null) return '';
    if (settings.biometricEnabled && settings.pinEnabled) return 'Huella o rostro y PIN';
    if (settings.biometricEnabled) return 'Huella o rostro';
    if (settings.pinEnabled) return 'PIN';
    return 'Desactivado';
  }

  Future<void> _switchTenant(BuildContext context, WidgetRef ref, Session session) async {
    final chosen = await showArgosSheet<String>(
      context,
      builder: (sheetContext) => SheetScaffold(
        title: 'Cambiar de empresa',
        child: SingleChildScrollView(
          child: TenantPicker(
            options: [
              for (final m in session.memberships)
                TenantOption(
                  id: m.tenantId,
                  name: m.tenantName,
                  roleName: m.roleName,
                  logoUrl: m.tenantLogoUrl,
                ),
            ],
            highlightedId: session.tenant.id,
            highlightLabel: 'Actual',
            onSelect: (option) => Navigator.of(sheetContext).pop(option.id),
          ),
        ),
      ),
    );
    if (chosen == null || chosen == session.tenant.id) return;
    final failure = await ref.read(sessionControllerProvider.notifier).switchTenant(chosen);
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Cerrar sesión',
      message:
          'Saldrás de tu cuenta en este teléfono. Para volver a entrar necesitarás '
          'tu correo y contraseña.',
      confirmLabel: 'Cerrar sesión',
      destructive: true,
    );
    if (confirmed) await ref.read(sessionControllerProvider.notifier).logout();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Avatar(name: session.user.fullName, size: 76),
        const SizedBox(height: 14),
        Text(
          session.user.fullName,
          textAlign: TextAlign.center,
          style: CustomTypography.sectionTitle,
        ),
        const SizedBox(height: 4),
        Text(
          '${session.roleName} · ${session.tenant.name}',
          textAlign: TextAlign.center,
          style: CustomTypography.body.copyWith(color: CustomColors.textBody),
        ),
        const SizedBox(height: 2),
        Text(
          session.user.email,
          textAlign: TextAlign.center,
          style: CustomTypography.bodySmall.copyWith(color: CustomColors.textSecondary),
        ),
      ],
    );
  }
}
