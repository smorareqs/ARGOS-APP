import 'package:argos_app/features/auth/models/quick_unlock.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A6 · Desbloqueo — saludo, biometría automática y PIN como alternativa.
/// Tras 3 PIN incorrectos la sesión exige contraseña.
class UnlockPage extends ConsumerStatefulWidget {
  const UnlockPage({super.key});

  @override
  ConsumerState<UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends ConsumerState<UnlockPage> {
  final _pinController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // La biometría se ofrece sola al abrir (F1 paso 4).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(sessionControllerProvider);
      if (state is AuthLocked && state.settings.biometricEnabled) _biometric();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _biometric() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final unlocked = await ref
        .read(sessionControllerProvider.notifier)
        .unlockWithBiometric();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!unlocked) setState(() => _error = 'No se reconoció tu huella o rostro.');
  }

  Future<void> _pin(String pin) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final check = await ref
        .read(sessionControllerProvider.notifier)
        .unlockWithPin(pin);
    if (!mounted) return;
    _pinController.clear();
    setState(() {
      _busy = false;
      if (check case PinRejected(:final remainingAttempts)) {
        _error = remainingAttempts == 1
            ? 'PIN incorrecto. Te queda 1 intento.'
            : 'PIN incorrecto. Te quedan $remainingAttempts intentos.';
      }
    });
  }

  Future<void> _usePassword() async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'Ingresar con contraseña',
      message:
          'Se cerrará la sesión guardada en este teléfono y tendrás que escribir '
          'tu correo y contraseña.',
      confirmLabel: 'Continuar',
    );
    if (confirmed) await ref.read(sessionControllerProvider.notifier).usePassword();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider);
    if (state is! AuthLocked) return const Scaffold(backgroundColor: CustomColors.primary);
    final session = state.cached;
    final settings = state.settings;

    return Scaffold(
      backgroundColor: CustomColors.primary,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
          children: [
            const Center(child: ArgosLogo(size: 30, color: Colors.white)),
            const SizedBox(height: 40),
            Text(
              session == null ? 'Hola' : 'Hola, ${session.user.firstName}',
              textAlign: TextAlign.center,
              style: CustomTypography.garamond(fontSize: 30, color: Colors.white),
            ),
            if (session != null) ...[
              const SizedBox(height: 6),
              Text(
                session.tenant.name,
                textAlign: TextAlign.center,
                style: CustomTypography.verdana(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 40),
            if (settings.biometricEnabled) ...[
              Center(
                child: BiometricPrompt(
                  onDark: true,
                  isBusy: _busy && _pinController.text.isEmpty,
                  onPressed: _biometric,
                ),
              ),
              const SizedBox(height: 32),
            ],
            if (settings.pinEnabled) ...[
              Text(
                settings.biometricEnabled ? 'O ESCRIBE TU PIN' : 'ESCRIBE TU PIN',
                textAlign: TextAlign.center,
                style: CustomTypography.verdana(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 14),
              PinField(
                controller: _pinController,
                onDark: true,
                hasError: _error != null,
                enabled: !_busy,
                autofocus: !settings.biometricEnabled,
                onCompleted: _pin,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: CustomTypography.verdana(
                    fontSize: 13,
                    color: CustomColors.errorOnDark,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _usePassword,
                child: Text(
                  'Usar contraseña',
                  style: CustomTypography.verdana(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
