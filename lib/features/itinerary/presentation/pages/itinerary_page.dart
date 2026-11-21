import 'package:argos_app/core/utils/date_labels.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// B1 · Hoy — pestaña inicial del colaborador. En la fase 1 muestra la
/// cabecera con los datos reales de la sesión y la semana en curso; la
/// agenda (tareas, asistencia, resumen) llega con la fase 2.
/// Ref: ARGOS App · Frame 02 · Itinerario.
class ItineraryPage extends ConsumerStatefulWidget {
  const ItineraryPage({super.key, this.onOpenProfile, this.today});

  /// Al tocar el avatar.
  final VoidCallback? onOpenProfile;

  /// Fecha de referencia (por defecto, hoy). Útil en pruebas.
  final DateTime? today;

  @override
  ConsumerState<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends ConsumerState<ItineraryPage> {
  late final DateTime _today = widget.today ?? DateTime.now();
  late int _selectedDay = _today.weekday % 7; // la semana empieza en domingo

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider);
    final user = state is AuthSignedIn ? state.session.user : null;

    final sunday = DateTime(_today.year, _today.month, _today.day - _today.weekday % 7);
    final days = [
      for (var i = 0; i < 7; i++)
        _weekDay(sunday.add(Duration(days: i)), selected: i == _selectedDay),
    ];

    return Column(
      children: [
        ItineraryHeader(
          dateLabel: DateLabels.longDate(_today),
          greeting: user == null ? 'Hola' : 'Hola, ${user.firstName}',
          initials: user == null ? '' : Avatar.initialsOf(user.fullName),
          hasNotification: false,
          onTapAvatar: widget.onOpenProfile,
          summaries: const [],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: WeekStrip(
            days: days,
            onSelect: (i) => setState(() => _selectedDay = i),
          ),
        ),
        const Expanded(
          child: SingleChildScrollView(
            child: EmptyState(
              icon: CustomIcons.today,
              title: 'Tu agenda aparecerá aquí',
              message:
                  'Cuando te asignen limpiezas o mantenimientos los verás en esta '
                  'pantalla, también sin conexión.',
            ),
          ),
        ),
      ],
    );
  }

  static WeekDay _weekDay(DateTime date, {required bool selected}) => WeekDay(
    weekday: DateLabels.weekdayInitial(date),
    day: '${date.day}',
    muted: date.weekday == DateTime.saturday || date.weekday == DateTime.sunday,
    selected: selected,
  );
}
