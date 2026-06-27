import 'package:design_system/atoms/app_text_field.dart';
import 'package:design_system/atoms/primary_button.dart';
import 'package:design_system/molecules/labeled_field.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:flutter/material.dart';

/// Formulario de inicio de sesión ARGOS — organismo presentacional.
/// Compone [LabeledField] + [AppTextField] + [PrimaryButton].
/// El estado y la lógica viven en la *screen* que lo consume.
class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    this.isLoading = false,
    this.obscurePassword = true,
    this.onToggleObscure,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final bool isLoading;
  final bool obscurePassword;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: 'Correo electrónico',
          field: AppTextField(
            controller: emailController,
            hintText: 'admin@costalimpia.com',
            prefixIcon: CustomIcons.email,
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        const SizedBox(height: CustomDimensions.spacingMd),
        LabeledField(
          label: 'Contraseña',
          field: AppTextField(
            controller: passwordController,
            hintText: '••••••••',
            prefixIcon: CustomIcons.lock,
            obscureText: obscurePassword,
            suffixIcon: onToggleObscure == null
                ? null
                : IconButton(
                    icon: Icon(
                      obscurePassword
                          ? CustomIcons.visibility
                          : CustomIcons.visibilityOff,
                      size: 18,
                    ),
                    onPressed: onToggleObscure,
                  ),
          ),
        ),
        const SizedBox(height: CustomDimensions.spacingLg),
        PrimaryButton(
          label: 'Iniciar sesión',
          isLoading: isLoading,
          trailingIcon: CustomIcons.arrowForward,
          onPressed: onSubmit,
        ),
      ],
    );
  }
}
