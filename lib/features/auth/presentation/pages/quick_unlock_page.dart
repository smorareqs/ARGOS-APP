import 'package:argos_app/features/auth/models/quick_unlock.dart';
import 'package:argos_app/features/auth/presentation/providers/account_providers.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Desde dónde se abre A5.
enum QuickUnlockMode {
  /// Justo después de iniciar sesión, con "Ahora no".
  offer,

  /// Desde el perfil, para activar o desactivar cada opción.
  settings,
}

/// A5 · Configurar inicio rápido: biometría (si el teléfono la tiene) o un PIN
/// de 6 dígitos que se escribe dos veces.
class QuickUnlockPage extends ConsumerStatefulWidget {
  const QuickUnlockPage({super.key, required this.mode});

  final QuickUnlockMode mode;

  @override
  ConsumerState<QuickUnlockPage> createState() => _QuickUnlockPageState();
}

enum _Step { choose, pinFirst, pinConfirm }

class _QuickUnlockPageState extends ConsumerState<QuickUnlockPage> {
  _Step _step = _Step.choose;
  final _pinController = TextEditingController();
  String? _firstPin;
  String? _pinError;
  bool _busy = false;

  bool get _isOffer => widget.mode == QuickUnlockMode.offer;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  QuickUnlockController get _controller =>
      ref.read(quickUnlockControllerProvider.notifier);

  void _finishOffer() =>
      ref.read(sessionControllerProvider.notifier).finishQuickUnlockOffer();

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _enableBiometric() async {
    setState(() => _busy = true);
    final enabled = await _controller.enableBiometric();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!enabled) {
      _toast('No se pudo confirmar tu huella o rostro. Intenta de nuevo.');
      return;
    }
    if (_isOffer) {
      _finishOffer();
    } else {
      _toast('Inicio con huella o rostro activado.');
    }
  }

  Future<void> _decline() async {
    setState(() => _busy = true);
    await _controller.decline();
    _finishOffer();
  }

  void _startPin() {
    _pinController.clear();
    setState(() {
      _step = _Step.pinFirst;
      _firstPin = null;
      _pinError = null;
    });
  }

  Future<void> _onPinCompleted(String pin) async {
    if (_step == _Step.pinFirst) {
      if (_isPredictable(pin)) {
        _pinController.clear();
        setState(() => _pinError = 'Elige un PIN menos predecible.');
        return;
      }
      _pinController.clear();
      setState(() {
        _firstPin = pin;
        _pinError = null;
        _step = _Step.pinConfirm;
      });
      return;
    }

    if (pin != _firstPin) {
      _pinController.clear();
      setState(() {
        _firstPin = null;
        _pinError = 'Los PIN no coinciden. Vuelve a crearlo.';
        _step = _Step.pinFirst;
      });
      return;
    }
    setState(() => _busy = true);
    await _controller.setPin(pin);
    if (!mounted) return;
    if (_isOffer) {
      _finishOffer();
      return;
    }
    setState(() {
      _busy = false;
      _step = _Step.choose;
    });
    _toast('PIN guardado.');
  }

  /// Rechaza repeticiones (111111) y secuencias (123456, 654321).
  static bool _isPredictable(String pin) {
    final digits = pin.codeUnits.map((c) => c - 48).toList();
    bool steps(int delta) => [
      for (var i = 1; i < digits.length; i++) digits[i] - digits[i - 1],
    ].every((d) => d == delta);
    return steps(0) || steps(1) || steps(-1);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(quickUnlockControllerProvider);

    if (_step != _Step.choose) return _pinStep();

    return FormScaffold(
      title: _isOffer ? 'Entra más rápido la próxima vez' : 'Inicio rápido',
      subtitle: _isOffer
          ? 'Usa tu huella, tu rostro o un PIN en lugar de tu contraseña.'
          : 'Elige cómo desbloquear ARGOS en este teléfono.',
      onBack: _isOffer ? null : () => context.pop(),
      footer: _isOffer
          ? TertiaryButton(label: 'Ahora no', onPressed: _busy ? null : _decline)
          : null,
      children: [
        settings.when(
          loading: () => const Skeleton.card(),
          error: (_, _) => const ErrorState(
            message: 'No pudimos leer la configuración de este teléfono.',
          ),
          data: (s) => _isOffer ? _offerOptions(s) : _settingsOptions(s),
        ),
      ],
    );
  }

  Widget _offerOptions(QuickUnlockSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (settings.biometricAvailable) ...[
          Center(
            child: BiometricPrompt(
              isBusy: _busy,
              onPressed: _enableBiometric,
            ),
          ),
          const SizedBox(height: CustomDimensions.spacingLg),
        ],
        SecondaryButton(
          label: 'Crear un PIN de 6 dígitos',
          onPressed: _busy ? null : _startPin,
        ),
      ],
    );
  }

  Widget _settingsOptions(QuickUnlockSettings settings) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (settings.biometricAvailable)
            AppListTile(
              icon: CustomIcons.fingerprint,
              title: 'Huella o rostro',
              showChevron: false,
              trailing: AppToggle(
                value: settings.biometricEnabled,
                semanticLabel: 'Huella o rostro',
                onChanged: _busy
                    ? null
                    : (on) => on ? _enableBiometric() : _controller.disableBiometric(),
              ),
            ),
          AppListTile(
            icon: CustomIcons.pin,
            title: 'PIN de 6 dígitos',
            subtitle: settings.pinEnabled ? 'Activado' : 'Desactivado',
            showChevron: false,
            trailing: AppToggle(
              value: settings.pinEnabled,
              semanticLabel: 'PIN de 6 dígitos',
              onChanged: _busy
                  ? null
                  : (on) => on ? _startPin() : _controller.removePin(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinStep() {
    final confirming = _step == _Step.pinConfirm;
    return FormScaffold(
      title: confirming ? 'Repite el PIN' : 'Crea un PIN de 6 dígitos',
      subtitle: confirming
          ? 'Escríbelo otra vez para confirmarlo.'
          : 'Lo usarás para entrar sin contraseña en este teléfono.',
      onBack: _busy
          ? null
          : () => setState(() {
              _step = _Step.choose;
              _pinError = null;
            }),
      children: [
        PinField(
          key: ValueKey(_step),
          controller: _pinController,
          hasError: _pinError != null,
          enabled: !_busy,
          onCompleted: _onPinCompleted,
        ),
        if (_pinError != null) ...[
          const SizedBox(height: CustomDimensions.spacingMd),
          Text(
            _pinError!,
            textAlign: TextAlign.center,
            style: CustomTypography.bodySmall.copyWith(color: CustomColors.error),
          ),
        ],
      ],
    );
  }
}
