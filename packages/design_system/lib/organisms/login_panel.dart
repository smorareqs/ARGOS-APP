import 'package:design_system/atoms/argos_logo.dart';
import 'package:design_system/atoms/dark_text_field.dart';
import 'package:design_system/atoms/primary_button.dart';
import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Pantalla de inicio de sesión ARGOS — fondo teal con bloque de marca,
/// formulario en vidrio translúcido y CTA dorado.
/// Organismo presentacional: el estado y la autenticación viven en la *screen*.
/// Ref: ARGOS App · Frame 01 · Inicio de sesión.
class LoginPanel extends StatelessWidget {
  const LoginPanel({
    super.key,
    required this.userController,
    required this.passwordController,
    required this.onSubmit,
    this.userLabel = 'Correo o usuario',
    this.userHint = 'usuario',
    this.isLoading = false,
    this.obscurePassword = true,
    this.onToggleObscure,
    this.onForgotPassword,
    this.userValidator,
    this.passwordValidator,
    this.footer = 'ARGOS · v1.0',
    this.userKeyboardType = TextInputType.text,
    this.userAutofillHints,
    this.errorText,
  });

  final TextEditingController userController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;

  final String userLabel;
  final String userHint;
  final bool isLoading;
  final bool obscurePassword;
  final VoidCallback? onToggleObscure;
  final VoidCallback? onForgotPassword;
  final String? Function(String?)? userValidator;
  final String? Function(String?)? passwordValidator;
  final String footer;
  final TextInputType userKeyboardType;
  final Iterable<String>? userAutofillHints;

  /// Error del envío (p. ej. credenciales incorrectas), bajo el formulario.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: CustomColors.primary,
      child: Stack(
        children: [
          // Glow dorado superior-derecha.
          Positioned(
            top: -120,
            right: -120,
            child: _glow(380, CustomColors.secondary.withValues(alpha: 0.22)),
          ),
          // Glow blanco inferior-izquierda.
          Positioned(
            bottom: -160,
            left: -120,
            child: _glow(360, Colors.white.withValues(alpha: 0.05)),
          ),
          Column(
            children: [
              Expanded(child: _brandBlock()),
              _form(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 0.7],
          ),
        ),
      ),
    );
  }

  Widget _brandBlock() {
    // Con el teclado abierto queda poco alto: la marca se achica en vez de
    // desbordarse.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Símbolo — la casa con greca, en blanco sobre el teal.
              const ArgosLogo(
                showWordmark: false,
                size: 78,
                color: Colors.white,
              ),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Text(
                  'ARGOS',
                  style: CustomTypography.garamond(
                    fontSize: 52,
                    color: Colors.white,
                  ).copyWith(letterSpacing: 11),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'LIMPIEZA & MANTENIMIENTO',
                style: CustomTypography.verdana(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.55),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        28,
        0,
        28,
        MediaQuery.of(context).viewInsets.bottom + 56,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            label: userLabel,
            child: DarkTextField(
              controller: userController,
              hintText: userHint,
              prefixIcon: CustomIcons.email,
              keyboardType: userKeyboardType,
              textInputAction: TextInputAction.next,
              validator: userValidator,
              autofillHints: userAutofillHints,
            ),
          ),
          const SizedBox(height: 14),
          _field(
            label: 'Contraseña',
            child: DarkTextField(
              controller: passwordController,
              hintText: '••••••',
              prefixIcon: CustomIcons.lock,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit(),
              validator: passwordValidator,
              autofillHints: const [AutofillHints.password],
              suffixIcon: onToggleObscure == null
                  ? null
                  : GestureDetector(
                      onTap: onToggleObscure,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            'VER',
                            style: CustomTypography.verdana(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.5),
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onForgotPassword,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Text(
                  '¿Olvidaste tu contraseña?',
                  style: CustomTypography.verdana(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Text(
                errorText!,
                textAlign: TextAlign.center,
                style: CustomTypography.verdana(
                  fontSize: 13,
                  color: CustomColors.errorOnDark,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Iniciar sesión',
            isLoading: isLoading,
            trailingIcon: CustomIcons.arrowForward,
            onPressed: onSubmit,
          ),
          const SizedBox(height: 14),
          Text(
            footer,
            textAlign: TextAlign.center,
            style: CustomTypography.verdana(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.32),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: CustomTypography.verdana(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 1,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
