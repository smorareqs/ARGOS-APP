import 'package:argos_app/features/guest/presentation/providers/guest_session.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A9 · Acceso de huésped. Con el enlace del correo (`argos://guest?token=`)
/// entra solo; si no, pide el código de la reserva y el correo.
class GuestLoginPage extends ConsumerStatefulWidget {
  const GuestLoginPage({super.key, this.token});

  final String? token;

  @override
  ConsumerState<GuestLoginPage> createState() => _GuestLoginPageState();
}

class _GuestLoginPageState extends ConsumerState<GuestLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = ref.read(guestSessionProvider);
    if (s is GuestNone) _error = s.message;
    final token = widget.token;
    if (token != null && token.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _signIn(token: token));
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _signIn({String? token}) async {
    if (_busy) return;
    if (token == null && !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref
        .read(guestSessionProvider.notifier)
        .signIn(token: token, code: token == null ? _code.text : null, email: token == null ? _email.text : null);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: CustomTypography.verdana(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 1),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final viaLink = widget.token != null && widget.token!.isNotEmpty;
    return Scaffold(
      backgroundColor: CustomColors.primary,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(28, 8, 28, MediaQuery.of(context).viewInsets.bottom + 32),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Volver',
                  icon: const Icon(CustomIcons.arrowBack, color: Colors.white),
                  onPressed: () => context.canPop() ? context.pop() : context.go('/login'),
                ),
              ),
              const SizedBox(height: 24),
              const Center(child: ArgosLogo(showWordmark: false, size: 64, color: Colors.white)),
              const SizedBox(height: 28),
              Text(
                'Bienvenido',
                textAlign: TextAlign.center,
                style: CustomTypography.garamond(fontSize: 34, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                viaLink
                    ? 'Estamos abriendo tu reserva…'
                    : 'Ingresa con el código de tu reserva. Lo encuentras en el correo de confirmación.',
                textAlign: TextAlign.center,
                style: CustomTypography.verdana(fontSize: 14, color: Colors.white.withValues(alpha: 0.7), height: 1.5),
              ),
              const SizedBox(height: 32),
              if (viaLink && _busy)
                const Center(child: CircularProgressIndicator(color: CustomColors.secondary))
              else ...[
                _label('Código de reserva'),
                DarkTextField(
                  controller: _code,
                  hintText: 'ABCD-1234',
                  prefixIcon: CustomIcons.key,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v ?? '').replaceAll(RegExp(r'[\s-]'), '').length < 6 ? 'Escribe el código del correo.' : null,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  onChanged: (v) {
                    final up = v.toUpperCase();
                    if (up != v) {
                      _code.value = _code.value.copyWith(
                        text: up,
                        selection: TextSelection.collapsed(offset: up.length),
                      );
                    }
                  },
                ),
                const SizedBox(height: 14),
                _label('Correo de la reserva'),
                DarkTextField(
                  controller: _email,
                  hintText: 'tu@correo.com',
                  prefixIcon: CustomIcons.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _signIn(),
                  autofillHints: const [AutofillHints.email],
                  validator: (v) => (v ?? '').contains('@') ? null : 'Escribe el correo con el que reservaste.',
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: CustomTypography.verdana(fontSize: 13, color: CustomColors.errorOnDark, height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              if (!(viaLink && _busy))
                PrimaryButton(
                  label: 'Entrar',
                  isLoading: _busy,
                  trailingIcon: CustomIcons.arrowForward,
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _signIn();
                  },
                ),
              const SizedBox(height: 18),
              Text(
                '¿No tienes código? Pídelo a la recepción o a quien te hizo la reserva.',
                textAlign: TextAlign.center,
                style: CustomTypography.verdana(fontSize: 12, color: Colors.white.withValues(alpha: 0.45), height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
