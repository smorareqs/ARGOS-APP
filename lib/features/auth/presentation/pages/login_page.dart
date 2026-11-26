import 'package:argos_app/core/device/device_identity.dart';
import 'package:argos_app/core/utils/validators.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A2 · Iniciar sesión — fondo teal con marca ARGOS y CTA dorado.
/// Según la respuesta, el router lleva a A3 (TOTP), A4 (empresa), A5 (inicio
/// rápido) o a la pantalla principal del rol.
/// Ref: ARGOS App · Frame 01 · Inicio de sesión.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Motivo por el que se llegó aquí (sesión revocada, PIN bloqueado…).
    final state = ref.read(sessionControllerProvider);
    if (state is AuthSignedOut) _error = state.message;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });
    final failure = await ref
        .read(sessionControllerProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = failure?.message;
    });
    if (failure == null) TextInput.finishAutofillContext();
  }

  @override
  Widget build(BuildContext context) {
    final version = ref.watch(appVersionProvider).value;

    return Scaffold(
      backgroundColor: CustomColors.primary,
      resizeToAvoidBottomInset: true,
      body: AutofillGroup(
        child: Form(
          key: _formKey,
          child: LoginPanel(
            userController: _emailController,
            passwordController: _passwordController,
            userLabel: 'Correo electrónico',
            userHint: 'nombre@empresa.com',
            userKeyboardType: TextInputType.emailAddress,
            userAutofillHints: const [AutofillHints.email, AutofillHints.username],
            isLoading: _isLoading,
            obscurePassword: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onSubmit: _submit,
            onForgotPassword: () => context.push('/forgot-password'),
            errorText: _error,
            secondaryLabel: 'Soy huésped, tengo un código',
            onSecondary: () => context.push('/guest-login'),
            footer: version == null || version.isEmpty ? 'ARGOS' : 'ARGOS · v$version',
            userValidator: Validators.email,
            passwordValidator: (value) =>
                Validators.required(value, 'Escribe tu contraseña.'),
          ),
        ),
      ),
    );
  }
}
