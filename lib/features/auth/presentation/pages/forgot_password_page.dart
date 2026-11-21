import 'dart:async';

import 'package:argos_app/core/utils/validators.dart';
import 'package:argos_app/features/auth/presentation/providers/account_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A7 · Recuperar contraseña. El enlace del correo abre la página web de
/// restablecer (W-A4); aquí solo se pide y se confirma el envío.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  static const _resendWait = 60;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _error;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final failure = await ref
        .read(passwordActionsProvider.notifier)
        .requestReset(_emailController.text);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = failure?.message;
      if (failure == null) _sent = true;
    });
    if (failure == null) _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendWait);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _secondsLeft <= 1) {
        timer.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return FormScaffold(
        title: 'Revisa tu correo',
        subtitle:
            'Si ${_emailController.text.trim()} tiene una cuenta, te enviamos un '
            'enlace para crear una contraseña nueva. Vence en 1 hora.',
        onBack: () => context.pop(),
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SecondaryButton(
              label: 'Volver a iniciar sesión',
              onPressed: () => context.pop(),
            ),
            const SizedBox(height: CustomDimensions.spacingSm),
            TertiaryButton(
              label: _secondsLeft > 0
                  ? 'Reenviar en $_secondsLeft s'
                  : 'Reenviar enlace',
              onPressed: _secondsLeft > 0 || _isLoading ? null : _send,
            ),
          ],
        ),
        children: const [
          EmptyState(icon: CustomIcons.invitation, title: 'Enlace enviado'),
        ],
      );
    }

    return FormScaffold(
      title: 'Recuperar contraseña',
      subtitle: 'Escribe el correo con el que ingresas y te enviaremos un enlace.',
      onBack: () => context.pop(),
      footer: PrimaryButton(
        label: 'Enviar enlace',
        isLoading: _isLoading,
        onPressed: _send,
      ),
      children: [
        Form(
          key: _formKey,
          child: LabeledField(
            label: 'Correo electrónico',
            field: AppTextField(
              controller: _emailController,
              hintText: 'nombre@empresa.com',
              prefixIcon: CustomIcons.email,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
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
