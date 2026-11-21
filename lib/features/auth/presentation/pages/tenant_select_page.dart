import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A4 · Elegir empresa — la última usada primero y marcada; "Recordar mi
/// elección" salta esta pantalla en los próximos inicios de sesión.
class TenantSelectPage extends ConsumerStatefulWidget {
  const TenantSelectPage({super.key});

  @override
  ConsumerState<TenantSelectPage> createState() => _TenantSelectPageState();
}

class _TenantSelectPageState extends ConsumerState<TenantSelectPage> {
  late bool _remember;
  String? _busyId;
  String? _error;

  @override
  void initState() {
    super.initState();
    final state = ref.read(sessionControllerProvider);
    _remember = state is AuthChoosingTenant && state.remember;
  }

  Future<void> _choose(TenantOption option) async {
    setState(() {
      _busyId = option.id;
      _error = null;
    });
    final failure = await ref
        .read(sessionControllerProvider.notifier)
        .chooseTenant(option.id, remember: _remember);
    if (!mounted) return;
    setState(() {
      _busyId = null;
      _error = failure?.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider);
    if (state is! AuthChoosingTenant) return const SizedBox.shrink();

    return FormScaffold(
      title: 'Elige la empresa',
      subtitle: 'Trabajas en varias empresas. Puedes cambiar después desde tu perfil.',
      onBack: () => ref.read(sessionControllerProvider.notifier).cancelLogin(),
      children: [
        TenantPicker(
          options: [
            for (final m in state.memberships)
              TenantOption(
                id: m.tenantId,
                name: m.tenantName,
                roleName: m.roleName,
                logoUrl: m.tenantLogoUrl,
              ),
          ],
          highlightedId: state.lastTenantId,
          busyId: _busyId,
          onSelect: _choose,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: CustomDimensions.spacingMd),
            child: Text(
              _error!,
              style: CustomTypography.bodySmall.copyWith(color: CustomColors.error),
            ),
          ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Recordar mi elección',
                  style: CustomTypography.body.copyWith(color: CustomColors.primary),
                ),
              ),
              AppToggle(
                value: _remember,
                semanticLabel: 'Recordar mi elección',
                onChanged: _busyId == null
                    ? (value) => setState(() => _remember = value)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
