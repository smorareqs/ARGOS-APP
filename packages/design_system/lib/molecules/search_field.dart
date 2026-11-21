import 'dart:async';

import 'package:design_system/atoms/app_icon_button.dart';
import 'package:design_system/tokens/custom_colors.dart';
import 'package:design_system/tokens/custom_dimensions.dart';
import 'package:design_system/tokens/custom_icons.dart';
import 'package:design_system/tokens/custom_typography.dart';
import 'package:flutter/material.dart';

/// Campo de búsqueda ARGOS — lupa, texto y botón para limpiar. Avisa con
/// retardo de 300 ms y solo a partir de 2 caracteres (o al quedar vacío).
/// Ref: ux-ui.md §2.6 (SearchField) y §3.2.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.onSearch,
    this.controller,
    this.hintText = 'Buscar',
    this.debounce = const Duration(milliseconds: 300),
    this.minLength = 2,
    this.autofocus = false,
  });

  /// Recibe el texto ya recortado; '' cuando se limpia.
  final ValueChanged<String> onSearch;
  final TextEditingController? controller;
  final String hintText;
  final Duration debounce;
  final int minLength;
  final bool autofocus;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  Timer? _timer;
  String _lastSent = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_onChanged);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {}); // muestra u oculta el botón de limpiar
    _timer?.cancel();
    final query = _controller.text.trim();
    if (query.isNotEmpty && query.length < widget.minLength) return;
    _timer = Timer(widget.debounce, () => _emit(query));
  }

  void _emit(String query) {
    if (query == _lastSent) return;
    _lastSent = query;
    widget.onSearch(query);
  }

  void _clear() {
    _controller.clear();
    _timer?.cancel();
    _emit('');
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(CustomDimensions.radiusField),
      borderSide: const BorderSide(color: CustomColors.borderField),
    );
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onSubmitted: (value) {
        _timer?.cancel();
        _emit(value.trim());
      },
      style: CustomTypography.body.copyWith(color: CustomColors.textPrimary),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: CustomTypography.body.copyWith(
          color: CustomColors.textMuted,
        ),
        filled: true,
        fillColor: CustomColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        prefixIcon: const Icon(
          CustomIcons.search,
          color: CustomColors.tealMuted,
          size: 22,
        ),
        suffixIcon: _controller.text.isEmpty
            ? null
            : AppIconButton(
                icon: CustomIcons.clear,
                semanticLabel: 'Limpiar búsqueda',
                color: CustomColors.textMuted,
                size: 20,
                onPressed: _clear,
              ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: CustomColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
