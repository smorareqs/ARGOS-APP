import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/notifications/data/notifications_repository.dart';
import 'package:argos_app/features/notifications/models/app_notification.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Perfil › Notificaciones: push y correo por tipo de aviso. Los críticos
/// (tareas asignadas, alarmas de check-out) no se pueden apagar. La bandeja
/// recibe todo siempre.
class NotificationPreferencesPage extends ConsumerStatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  ConsumerState<NotificationPreferencesPage> createState() => _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState extends ConsumerState<NotificationPreferencesPage> {
  List<NotificationPreference>? _items;
  Object? _error;
  var _dirty = false;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await ref.read(notificationsRepositoryProvider).preferences();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _set(int i, {bool? push, bool? email}) => setState(() {
    _items![i] = _items![i].copyWith(push: push, email: email);
    _dirty = true;
  });

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final saved = await ref.read(notificationsRepositoryProvider).savePreferences(_items!);
      if (!mounted) return;
      setState(() {
        _items = saved;
        _dirty = false;
      });
      showToast(context, 'Preferencias guardadas.');
    } catch (e) {
      if (mounted) showToast(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return FormScaffold(
      title: 'Notificaciones',
      subtitle: 'Elige qué te llega al teléfono y al correo. En la bandeja de la app siempre ves todo.',
      onBack: () => context.pop(),
      footer: items == null
          ? null
          : PrimaryButton(
              label: 'Guardar',
              isLoading: _saving,
              onPressed: _dirty && !_saving ? _save : null,
            ),
      children: [
        if (items == null && _error == null)
          for (var i = 0; i < 6; i++) ...[
            const Skeleton(width: double.infinity, height: 52, radius: CustomDimensions.radiusField),
            const SizedBox(height: 8),
          ]
        else if (items == null)
          ErrorState(message: errorMessage(_error!), onRetry: _load)
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Expanded(child: SizedBox()),
                SizedBox(width: 64, child: Center(child: Text('Push', style: CustomTypography.label))),
                SizedBox(width: 64, child: Center(child: Text('Correo', style: CustomTypography.label))),
              ],
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, p) in items.indexed) ...[
                  if (i > 0) const Divider(height: 1, color: CustomColors.divider),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.label, style: CustomTypography.body.copyWith(fontSize: 13.5)),
                              if (p.critical)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text('Importante: no se puede apagar', style: CustomTypography.bodySmall),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 64,
                          child: Center(
                            child: AppToggle(
                              value: p.push,
                              semanticLabel: 'Push: ${p.label}',
                              onChanged: p.critical ? null : (v) => _set(i, push: v),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 64,
                          child: Center(
                            child: AppToggle(
                              value: p.email,
                              semanticLabel: 'Correo: ${p.label}',
                              onChanged: p.critical ? null : (v) => _set(i, email: v),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
