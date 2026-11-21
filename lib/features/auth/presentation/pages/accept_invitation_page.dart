import 'package:argos_app/core/errors/app_failure.dart';
import 'package:argos_app/core/utils/validators.dart';
import 'package:argos_app/features/auth/models/account.dart';
import 'package:argos_app/features/auth/presentation/providers/account_providers.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A8 · Aceptar invitación. Se abre con `argos://invite?token=…`. Si el
/// correo ya tiene cuenta, se confirma con la contraseña actual.
class AcceptInvitationPage extends ConsumerStatefulWidget {
  const AcceptInvitationPage({super.key, required this.token});

  final String token;

  @override
  ConsumerState<AcceptInvitationPage> createState() =>
      _AcceptInvitationPageState();
}

class _AcceptInvitationPageState extends ConsumerState<AcceptInvitationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _leave() => context.canPop() ? context.pop() : context.go('/login');

  Future<void> _accept(InvitationInfo info) async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final failure = await ref
        .read(sessionControllerProvider.notifier)
        .acceptInvitation(
          token: widget.token,
          email: info.email,
          password: _passwordController.text,
          fullName: info.userExists ? null : _nameController.text.trim(),
        );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = failure?.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final invitation = ref.watch(invitationInfoProvider(widget.token));

    return invitation.when(
      loading: () => FormScaffold(
        title: 'Invitación',
        onBack: _leave,
        children: const [Skeleton.card(), SizedBox(height: 12), Skeleton.card()],
      ),
      error: (error, _) => _invalid(error),
      data: _form,
    );
  }

  /// Sin red se ofrece reintentar; cualquier otra respuesta (404: vencida o
  /// usada) muestra el motivo que da el servidor.
  Widget _invalid(Object error) {
    return FormScaffold(
      title: 'Invitación',
      onBack: _leave,
      footer: SecondaryButton(
        label: 'Ir a iniciar sesión',
        onPressed: () => context.go('/login'),
      ),
      children: [
        if (error is NetworkFailure)
          ErrorState(
            message: error.message,
            onRetry: () => ref.invalidate(invitationInfoProvider(widget.token)),
          )
        else
          EmptyState(
            icon: CustomIcons.invitation,
            title: error is AppFailure
                ? error.message
                : 'No pudimos abrir la invitación.',
            message:
                'Pide al administrador de tu empresa que te envíe una nueva invitación.',
          ),
      ],
    );
  }

  Widget _form(InvitationInfo info) {
    final exists = info.userExists;
    return FormScaffold(
      title: '${info.tenantName} te invitó',
      subtitle: exists
          ? 'Como ${info.roleName}. Ya tienes cuenta con ${info.email}: '
                'confirma con tu contraseña para unirte.'
          : 'Como ${info.roleName}. Crea tu cuenta con ${info.email}.',
      onBack: _leave,
      footer: PrimaryButton(
        label: exists ? 'Unirme' : 'Crear mi cuenta',
        isLoading: _isLoading,
        onPressed: () => _accept(info),
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!exists) ...[
                LabeledField(
                  label: 'Nombre completo',
                  field: AppTextField(
                    controller: _nameController,
                    hintText: 'Como aparece en tu DPI',
                    prefixIcon: CustomIcons.person,
                    validator: (v) => Validators.required(v, 'Escribe tu nombre.'),
                  ),
                ),
                const SizedBox(height: CustomDimensions.spacingMd),
              ],
              LabeledField(
                label: exists ? 'Tu contraseña' : 'Contraseña',
                field: AppTextField(
                  controller: _passwordController,
                  hintText: '••••••••',
                  prefixIcon: CustomIcons.lock,
                  obscureText: _obscure,
                  suffixIcon: AppIconButton(
                    icon: _obscure ? CustomIcons.visibility : CustomIcons.visibilityOff,
                    semanticLabel: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                    color: CustomColors.textMuted,
                    size: 18,
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: exists
                      ? (v) => Validators.required(v, 'Escribe tu contraseña.')
                      : Validators.newPassword,
                ),
              ),
              if (!exists) ...[
                const SizedBox(height: CustomDimensions.spacingSm),
                _StrengthMeter(strength: Validators.passwordStrength(_passwordController.text)),
                const SizedBox(height: CustomDimensions.spacingMd),
                LabeledField(
                  label: 'Repite la contraseña',
                  field: AppTextField(
                    controller: _confirmController,
                    hintText: '••••••••',
                    prefixIcon: CustomIcons.lock,
                    obscureText: _obscure,
                    validator: (v) => v == _passwordController.text
                        ? null
                        : 'Las contraseñas no coinciden.',
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: CustomDimensions.spacingMd),
          Text(
            _error!,
            style: CustomTypography.bodySmall.copyWith(color: CustomColors.error),
          ),
        ],
      ],
    );
  }
}

/// Medidor de fortaleza: barra + palabra (nunca solo color).
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength});

  final int strength;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (strength) {
      0 => ('', CustomColors.track),
      1 => ('Débil', CustomColors.error),
      2 => ('Aceptable', CustomColors.warning),
      3 => ('Buena', CustomColors.success),
      _ => ('Fuerte', CustomColors.success),
    };
    return Row(
      children: [
        Expanded(child: ProgressBar(value: strength / 4, fillColor: color)),
        const SizedBox(width: 12),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: CustomTypography.bodySmall.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
