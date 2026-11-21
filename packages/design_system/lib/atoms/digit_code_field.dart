import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// PIN de inicio rápido — 6 dígitos ocultos con puntos.
/// Ref: ux-ui.md §2.6 (PinField) · A5 y A6.
class PinField extends StatelessWidget {
  const PinField({
    super.key,
    this.controller,
    this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.onDark = false,
    this.autofocus = true,
    this.enabled = true,
    this.semanticLabel = 'PIN de 6 dígitos',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final bool onDark;
  final bool autofocus;
  final bool enabled;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return DigitCodeField(
      length: 6,
      obscure: true,
      controller: controller,
      onCompleted: onCompleted,
      onChanged: onChanged,
      hasError: hasError,
      onDark: onDark,
      autofocus: autofocus,
      enabled: enabled,
      semanticLabel: semanticLabel,
    );
  }
}

/// Código de verificación (TOTP) — 6 dígitos visibles con avance automático
/// y autocompletado del sistema.
/// Ref: ux-ui.md §2.6 (OtpField) · A3.
class OtpField extends StatelessWidget {
  const OtpField({
    super.key,
    this.controller,
    this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.autofocus = true,
    this.enabled = true,
    this.semanticLabel = 'Código de verificación de 6 dígitos',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final bool autofocus;
  final bool enabled;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return DigitCodeField(
      length: 6,
      obscure: false,
      controller: controller,
      onCompleted: onCompleted,
      onChanged: onChanged,
      hasError: hasError,
      autofocus: autofocus,
      enabled: enabled,
      semanticLabel: semanticLabel,
      autofillHints: const [AutofillHints.oneTimeCode],
    );
  }
}

/// Base de [PinField] y [OtpField]: un campo de texto invisible que recibe el
/// teclado numérico y una fila de casillas que muestran cada dígito.
class DigitCodeField extends StatefulWidget {
  const DigitCodeField({
    super.key,
    required this.length,
    required this.obscure,
    this.controller,
    this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.onDark = false,
    this.autofocus = true,
    this.enabled = true,
    this.semanticLabel,
    this.autofillHints,
  });

  final int length;
  final bool obscure;
  final TextEditingController? controller;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final bool onDark;
  final bool autofocus;
  final bool enabled;
  final String? semanticLabel;
  final Iterable<String>? autofillHints;

  @override
  State<DigitCodeField> createState() => _DigitCodeFieldState();
}

class _DigitCodeFieldState extends State<DigitCodeField> {
  TextEditingController? _ownController;
  final _focusNode = FocusNode();

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(DigitCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onTextChanged);
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _ownController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _onTextChanged() {
    setState(() {});
    final value = _controller.text;
    widget.onChanged?.call(value);
    if (value.length == widget.length) widget.onCompleted?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.text;
    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.length; i++) ...[
                if (i > 0) const SizedBox(width: CustomDimensions.spacingSm),
                _box(
                  char: i < value.length ? value[i] : null,
                  current: _focusNode.hasFocus && i == value.length,
                ),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                autofillHints: widget.autofillHints,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box({required String? char, required bool current}) {
    final dark = widget.onDark;
    final Color borderColor;
    if (widget.hasError) {
      borderColor = dark ? CustomColors.errorBorderOnDark : CustomColors.error;
    } else if (current || char != null) {
      borderColor = CustomColors.secondary;
    } else {
      borderColor = dark
          ? Colors.white.withValues(alpha: 0.16)
          : CustomColors.borderField;
    }
    final textColor = dark ? Colors.white : CustomColors.primary;

    return Container(
      width: 44,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.07) : CustomColors.surface,
        borderRadius: BorderRadius.circular(CustomDimensions.radiusField),
        border: Border.all(color: borderColor, width: current ? 1.6 : 1),
      ),
      child: char == null
          ? null
          : widget.obscure
          ? Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: textColor, shape: BoxShape.circle),
            )
          : Text(
              char,
              style: CustomTypography.garamond(fontSize: 26, color: textColor),
            ),
    );
  }
}
