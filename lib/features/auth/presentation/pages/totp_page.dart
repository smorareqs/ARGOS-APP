import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A3 · Código de verificación (TOTP). Se envía solo al completar los 6
/// dígitos; si es incorrecto, el campo se marca en rojo y se limpia.
class TotpPage extends ConsumerStatefulWidget {
  const TotpPage({super.key});

  @override
  ConsumerState<TotpPage> createState() => _TotpPageState();
}

class _TotpPageState extends ConsumerState<TotpPage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text;
    if (_isLoading) return;
    if (code.length != 6) {
      setState(() => _error = 'Escribe los 6 dígitos del código.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final failure = await ref
        .read(sessionControllerProvider.notifier)
        .submitTotp(code);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = failure?.message;
    });
    if (failure != null) _codeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: 'Código de verificación',
      subtitle:
          'Abre tu app de autenticación y escribe el código de 6 dígitos de ARGOS.',
      onBack: () => ref.read(sessionControllerProvider.notifier).cancelLogin(),
      footer: PrimaryButton(
        label: 'Verificar',
        isLoading: _isLoading,
        onPressed: _submit,
      ),
      children: [
        OtpField(
          controller: _codeController,
          hasError: _error != null,
          enabled: !_isLoading,
          onChanged: (value) {
            // Se limpia al escribir, no al vaciar el campo tras un error.
            if (_error != null && value.isNotEmpty) setState(() => _error = null);
          },
          onCompleted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: CustomDimensions.spacingMd),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: CustomTypography.bodySmall.copyWith(color: CustomColors.error),
          ),
        ],
      ],
    );
  }
}
