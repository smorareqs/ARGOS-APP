import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/hospitality/data/hospitality_repository.dart';
import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:argos_app/features/hospitality/models/reservation.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lo que falta antes del check-in, con una salida clara.
class CheckInBlockersSheet extends StatelessWidget {
  const CheckInBlockersSheet({super.key, required this.blockers});

  final List<String> blockers;

  @override
  Widget build(BuildContext context) {
    return SheetScaffold(
      title: 'Aún no se puede hacer el check-in',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final b in blockers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(CustomIcons.pending, size: 20, color: CustomColors.warning),
                  const SizedBox(width: 10),
                  Expanded(child: Text(b, style: CustomTypography.body)),
                ],
              ),
            ),
          const SizedBox(height: 10),
          PrimaryButton(label: 'Entendido', onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}

// ── C9 · Depósito ────────────────────────────────────────

enum DepositMode { received, returned, retained }

Future<bool> showDepositSheet(
  BuildContext context, {
  required ReservationDetail detail,
  required DepositMode mode,
}) async =>
    await showArgosSheet<bool>(
      context,
      builder: (_) => _DepositSheet(detail: detail, mode: mode),
    ) ??
    false;

class _DepositSheet extends ConsumerStatefulWidget {
  const _DepositSheet({required this.detail, required this.mode});

  final ReservationDetail detail;
  final DepositMode mode;

  @override
  ConsumerState<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends ConsumerState<_DepositSheet> {
  late final _amount = TextEditingController(text: _default());
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  var _method = 'cash';
  var _busy = false;
  String? _error;

  String _default() {
    final d = widget.detail.deposit;
    final v = switch (widget.mode) {
      DepositMode.received => d.amount ?? widget.detail.reservation.depositAmount ?? 0,
      DepositMode.returned => (d.balance - d.charges).clamp(0, d.balance),
      DepositMode.retained => d.charges > 0 ? d.charges.clamp(0, d.balance) : d.balance,
    };
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.replaceAll(',', '.').trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Escribe un monto mayor que cero.');
      return;
    }
    if (widget.mode == DepositMode.retained && _notes.text.trim().length < 3) {
      setState(() => _error = 'Escribe el motivo de la retención.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(hospitalityRepositoryProvider)
          .depositTx(
            widget.detail.reservation.id,
            type: widget.mode.name,
            amount: amount,
            method: _method,
            reference: _reference.text,
            notes: _notes.text,
          );
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      showToast(context, switch (widget.mode) {
        DepositMode.received => 'Depósito registrado.',
        DepositMode.returned => 'Devolución registrada.',
        DepositMode.retained => 'Retención registrada.',
      });
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = errorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail.deposit;
    final cur = widget.detail.reservation.currency;
    return SheetScaffold(
      title: switch (widget.mode) {
        DepositMode.received => 'Registrar depósito',
        DepositMode.returned => 'Devolver depósito',
        DepositMode.retained => 'Retener depósito',
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.mode != DepositMode.received)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'En garantía: ${money(d.balance, cur)}${d.charges > 0 ? ' · hallazgos con cargo: ${money(d.charges, cur)}' : ''}',
                style: CustomTypography.body,
              ),
            ),
          LabeledField(
            label: 'Monto ($cur)',
            field: AppTextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: CustomIcons.deposit,
            ),
          ),
          const SizedBox(height: 14),
          Text('MÉTODO', style: CustomTypography.label.copyWith(color: CustomColors.textSecondary)),
          const SizedBox(height: 8),
          FilterChips<String>(
            padding: EdgeInsets.zero,
            options: [
              for (final m in const ['cash', 'transfer', 'card', 'other'])
                FilterOption(value: m, label: DepositTx.methodLabel(m)),
            ],
            selected: {_method},
            onChanged: (s) => setState(() => _method = s.isEmpty ? _method : s.first),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Referencia (opcional)',
            field: AppTextField(controller: _reference, hintText: 'Número de transferencia o voucher'),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: widget.mode == DepositMode.retained ? 'Motivo' : 'Nota (opcional)',
            field: AppTextField(
              controller: _notes,
              maxLines: 2,
              hintText: widget.mode == DepositMode.retained ? 'Por qué se retiene' : null,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: CustomTypography.bodySmall.copyWith(color: CustomColors.error)),
          ],
          const SizedBox(height: 18),
          widget.mode == DepositMode.retained
              ? DangerButton(label: 'Retener', isLoading: _busy, onPressed: _save)
              : PrimaryButton(
                  label: widget.mode == DepositMode.received ? 'Registrar depósito' : 'Registrar devolución',
                  isLoading: _busy,
                  onPressed: _save,
                ),
        ],
      ),
    );
  }
}

// ── C7 · Registro de huésped ─────────────────────────────

Future<bool> showGuestSheet(BuildContext context, {required ReservationDetail detail, StayGuest? guest}) async =>
    await showArgosSheet<bool>(
      context,
      builder: (_) => _GuestSheet(detail: detail, guest: guest),
    ) ??
    false;

class _GuestSheet extends ConsumerStatefulWidget {
  const _GuestSheet({required this.detail, this.guest});

  final ReservationDetail detail;
  final StayGuest? guest;

  @override
  ConsumerState<_GuestSheet> createState() => _GuestSheetState();
}

class _GuestSheetState extends ConsumerState<_GuestSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.guest?.fullName);
  late final _email = TextEditingController(text: widget.guest?.email);
  late final _phone = TextEditingController(text: widget.guest?.phone);
  late final _number = TextEditingController(text: widget.guest?.documentNumber);
  late final _nationality = TextEditingController(text: widget.guest?.nationality);
  late var _type = widget.guest?.documentType ?? 'dpi';
  StayGuest? _existing;
  var _busy = false;
  String? _error;

  bool get _editing => widget.guest != null;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _number, _nationality]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _lookup() async {
    if (_editing || _number.text.trim().length < 4) return;
    try {
      final hit = await ref.read(hospitalityRepositoryProvider).findByDocument(_number.text);
      if (mounted) setState(() => _existing = hit);
    } on Object {
      // Buscar es una ayuda: si falla, se registra como nuevo.
    }
  }

  void _useExisting(StayGuest g) {
    setState(() {
      _name.text = g.fullName;
      _email.text = g.email ?? '';
      _phone.text = g.phone ?? '';
      _type = g.documentType ?? _type;
      _nationality.text = g.nationality ?? '';
    });
  }

  Map<String, dynamic> _fields() => {
    'full_name': _name.text.trim(),
    'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
    'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
    'document_type': _number.text.trim().isEmpty ? null : _type,
    'document_number': _number.text.trim().isEmpty ? null : _number.text.trim().toUpperCase(),
    'nationality': _type == 'passport' && _nationality.text.trim().length == 2
        ? _nationality.text.trim().toUpperCase()
        : null,
  };

  Future<void> _save({bool photos = false}) async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = ref.read(hospitalityRepositoryProvider);
    final r = widget.detail.reservation;
    try {
      String guestId;
      if (_editing) {
        guestId = widget.guest!.id;
        await repo.updateGuest(guestId, _fields());
      } else {
        final existing = _existing;
        final before = {for (final g in widget.detail.guests) g.id};
        final updated = existing != null
            ? await repo.addGuest(r.id, guestId: existing.id, primary: widget.detail.guests.isEmpty)
            : await repo.addGuest(
                r.id,
                guest: {
                  for (final e in _fields().entries)
                    if (e.value != null) e.key: e.value,
                },
                primary: widget.detail.guests.isEmpty,
              );
        guestId = updated.guests.where((g) => !before.contains(g.id)).firstOrNull?.id ?? existing?.id ?? '';
        if (existing != null) await repo.updateGuest(guestId, _fields());
      }
      HapticFeedback.selectionClick();
      if (!mounted) return;
      final router = GoRouter.of(context);
      Navigator.of(context).pop(true);
      if (photos && guestId.isNotEmpty) {
        await router.push(
          '/guests/$guestId/document?name=${Uri.encodeComponent(_name.text.trim())}&property=${Uri.encodeComponent(r.propertyCode)}',
        );
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = errorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.guest;
    final needsPhotos = g == null || g.missing.contains('id_front') || g.missing.contains('id_back');
    final ex = _existing;
    return SheetScaffold(
      title: _editing ? 'Registro de ${g!.fullName.split(' ').first}' : 'Agregar huésped',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FilterChips<String>(
              padding: EdgeInsets.zero,
              options: const [
                FilterOption(value: 'dpi', label: 'DPI'),
                FilterOption(value: 'passport', label: 'Pasaporte'),
              ],
              selected: {_type},
              onChanged: (s) => setState(() => _type = s.isEmpty ? _type : s.first),
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: _type == 'dpi' ? 'Número de DPI' : 'Número de pasaporte',
              field: Focus(
                onFocusChange: (has) {
                  if (!has) _lookup();
                },
                child: AppTextField(
                  controller: _number,
                  hintText: _type == 'dpi' ? '0000 00000 0000' : 'X0000000',
                  prefixIcon: CustomIcons.document,
                ),
              ),
            ),
            if (ex != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: AppChip(
                  label:
                      'Ya registrado: ${ex.fullName}${ex.lastStay == null ? '' : ' · ${shortStay(ex.lastStay!)}'} · usar',
                  onTap: () => _useExisting(ex),
                ),
              ),
            ],
            const SizedBox(height: 12),
            LabeledField(
              label: 'Nombre completo',
              field: AppTextField(
                controller: _name,
                hintText: 'Como aparece en el documento',
                validator: (v) => (v ?? '').trim().length < 2 ? 'Escribe el nombre.' : null,
              ),
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Correo',
              field: AppTextField(
                controller: _email,
                hintText: 'para enviarle el acceso',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v ?? '').trim().isEmpty || (v ?? '').contains('@') ? null : 'Revisa el correo.',
              ),
            ),
            const SizedBox(height: 12),
            LabeledField(
              label: 'Teléfono (opcional)',
              field: AppTextField(controller: _phone, keyboardType: TextInputType.phone),
            ),
            if (_type == 'passport') ...[
              const SizedBox(height: 12),
              LabeledField(
                label: 'Nacionalidad (2 letras)',
                field: AppTextField(
                  controller: _nationality,
                  hintText: 'MX, US, ES…',
                  validator: (v) =>
                      (v ?? '').trim().isEmpty || (v ?? '').trim().length == 2 ? null : 'Usa el código de 2 letras.',
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: CustomTypography.bodySmall.copyWith(color: CustomColors.error)),
            ],
            const SizedBox(height: 18),
            if (needsPhotos && widget.detail.reservation.hasCheckin) ...[
              PrimaryButton(
                label: 'Guardar y fotografiar documento',
                trailingIcon: CustomIcons.camera,
                isLoading: _busy,
                onPressed: () => _save(photos: true),
              ),
              const SizedBox(height: 8),
              TertiaryButton(label: 'Solo guardar', onPressed: _busy ? null : _save),
            ] else
              PrimaryButton(label: 'Guardar', isLoading: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

/// "2026-03-03" → "3 mar".
String shortStay(String day) {
  final parts = shortDay(parseDay(day)).split(' ');
  return '${parts[1]} ${parts[2]}';
}

// ── Parqueo ──────────────────────────────────────────────

Future<bool> showParkingSheet(BuildContext context, {required ReservationDetail detail}) async =>
    await showArgosSheet<bool>(context, builder: (_) => _ParkingSheet(detail: detail)) ?? false;

class _ParkingSheet extends ConsumerStatefulWidget {
  const _ParkingSheet({required this.detail});

  final ReservationDetail detail;

  @override
  ConsumerState<_ParkingSheet> createState() => _ParkingSheetState();
}

class _ParkingSheetState extends ConsumerState<_ParkingSheet> {
  final _plate = TextEditingController();
  final _car = TextEditingController();
  List<(String, String, String)>? _spaces;
  Set<String> _taken = {};
  String? _space;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(hospitalityRepositoryProvider);
    final r = widget.detail.reservation;
    try {
      final spaces = await repo.spaces();
      final used = await repo.assignments(r.checkInDate, r.checkOutDate);
      if (!mounted) return;
      setState(() {
        _spaces = spaces;
        _taken = {
          for (final a in used)
            if (a.from.compareTo(_key(r.checkOutDate)) < 0 && a.to.compareTo(_key(r.checkInDate)) > 0) a.spaceCode,
        };
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = errorMessage(e));
    }
  }

  static String _key(DateTime d) => dayKey(d);

  @override
  void dispose() {
    _plate.dispose();
    _car.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_space == null) {
      setState(() => _error = 'Elige un espacio.');
      return;
    }
    if (!RegExp(r'^[A-Z0-9-]{5,10}$').hasMatch(_plate.text.trim().toUpperCase().replaceAll(' ', ''))) {
      setState(() => _error = 'Revisa la placa: letras, números y guion (p. ej. P123-456).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(hospitalityRepositoryProvider)
          .assignParking(
            spaceId: _space!,
            reservationCode: widget.detail.reservation.code,
            plate: _plate.text.replaceAll(' ', ''),
            description: _car.text,
          );
      if (!mounted) return;
      showToast(context, 'Parqueo asignado.');
      Navigator.of(context).pop(true);
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = errorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spaces = _spaces;
    return SheetScaffold(
      title: 'Asignar parqueo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ESPACIO', style: CustomTypography.label.copyWith(color: CustomColors.textSecondary)),
          const SizedBox(height: 8),
          if (spaces == null && _error == null)
            const Skeleton(width: double.infinity, height: 44, radius: 12)
          else if (spaces != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, code, level) in spaces)
                  _SpaceChip(
                    code: code,
                    level: level,
                    taken: _taken.contains(code),
                    selected: _space == id,
                    onTap: _taken.contains(code) ? null : () => setState(() => _space = id),
                  ),
              ],
            ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Placa',
            field: AppTextField(controller: _plate, hintText: 'P123-456', prefixIcon: CustomIcons.car),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Vehículo (opcional)',
            field: AppTextField(controller: _car, hintText: 'Marca, modelo y color'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: CustomTypography.bodySmall.copyWith(color: CustomColors.error)),
          ],
          const SizedBox(height: 18),
          PrimaryButton(label: 'Asignar', isLoading: _busy, onPressed: _save),
        ],
      ),
    );
  }
}

class _SpaceChip extends StatelessWidget {
  const _SpaceChip({required this.code, required this.level, required this.taken, required this.selected, this.onTap});

  final String code;
  final String level;
  final bool taken;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: !taken,
      label: 'Espacio $code${taken ? ', ocupado' : ''}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? CustomColors.primary : (taken ? CustomColors.neutralSoft : CustomColors.surface),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? CustomColors.primary : CustomColors.borderField),
          ),
          child: Column(
            children: [
              Text(
                code,
                style: CustomTypography.mono.copyWith(
                  fontSize: 14,
                  color: selected ? Colors.white : (taken ? CustomColors.disabled : CustomColors.primary),
                  decoration: taken ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                taken ? 'Ocupado' : level,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CustomTypography.label.copyWith(
                  fontSize: 9.5,
                  color: selected ? Colors.white70 : CustomColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
