import 'package:argos_app/core/errors/app_failure.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inicio de sesión — fondo teal con marca ARGOS y CTA dorado.
/// El campo de usuario alimenta el `código` del auth offline-first.
/// Ref: ARGOS App · Frame 01 · Inicio de sesión.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _codigoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(
          _codigoController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.hasError && next.error is AppFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((next.error as AppFailure).message)),
        );
      }
    });

    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: CustomColors.primary,
      resizeToAvoidBottomInset: true,
      body: Form(
        key: _formKey,
        child: LoginPanel(
          userController: _codigoController,
          passwordController: _passwordController,
          userLabel: 'Correo o usuario',
          userHint: 'usuario',
          isLoading: isLoading,
          obscurePassword: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          onSubmit: isLoading ? () {} : _submit,
          onForgotPassword: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contacta a tu supervisor para restablecerla.'),
              ),
            );
          },
          footer: 'ARGOS · v1.0 — Tenant: Costa Limpia S.A.',
          userValidator: (value) => (value == null || value.trim().isEmpty)
              ? 'Ingresa tu usuario'
              : null,
          passwordValidator: (value) =>
              (value == null || value.isEmpty) ? 'Ingresa tu contraseña' : null,
        ),
      ),
    );
  }
}
