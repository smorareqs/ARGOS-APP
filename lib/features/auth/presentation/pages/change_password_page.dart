import 'package:argos_app/core/utils/validators.dart';
import 'package:argos_app/features/auth/presentation/providers/account_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Perfil · Cambiar contraseña. El backend cierra las demás sesiones.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final failure = await ref
        .read(passwordActionsProvider.notifier)
        .change(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
        );
    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _isLoading = false;
        _error = failure.message;
      });
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contraseña actualizada. Cerramos tu sesión en los demás dispositivos.'),
      ),
    );
    context.pop();
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String? Function(String?) validator,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CustomDimensions.spacingMd),
      child: LabeledField(
        label: label,
        field: AppTextField(
          controller: controller,
          hintText: '••••••••',
          prefixIcon: CustomIcons.lock,
          obscureText: true,
          validator: validator,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Cambiar contraseña',
      subtitle: 'Al cambiarla se cerrará tu sesión en los demás dispositivos.',
      onBack: () => context.pop(),
      footer: PrimaryButton(
        label: 'Guardar contraseña',
        isLoading: _isLoading,
        onPressed: _submit,
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              _field(
                'Contraseña actual',
                _currentController,
                (v) => Validators.required(v, 'Escribe tu contraseña actual.'),
              ),
              _field('Contraseña nueva', _newController, Validators.newPassword),
              _field(
                'Repite la contraseña nueva',
                _confirmController,
                (v) => v == _newController.text ? null : 'Las contraseñas no coinciden.',
              ),
            ],
          ),
        ),
        if (_error != null)
          Text(
            _error!,
            style: CustomTypography.bodySmall.copyWith(color: CustomColors.error),
          ),
      ],
    );
  }
}
