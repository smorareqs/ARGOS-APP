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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Símbolo — anillo blanco con halo dorado + punto dorado.
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.85),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: CustomColors.secondary.withValues(alpha: 0.10),
                  spreadRadius: 8,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CustomColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Text(
              'ARGOS',
              style: CustomTypography.garamond(fontSize: 52, color: Colors.white)
                  .copyWith(letterSpacing: 11),
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
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              validator: userValidator,
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
