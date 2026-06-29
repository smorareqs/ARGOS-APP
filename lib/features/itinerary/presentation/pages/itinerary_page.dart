import 'package:argos_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Itinerario — primera pantalla al ingresar. Vista diaria de tareas del
/// personal de campo. Contenido estático (aún sin backend); el saludo usa
/// el nombre del usuario en sesión.
/// Ref: ARGOS App · Frame 02 · Itinerario.
class ItineraryPage extends ConsumerStatefulWidget {
  const ItineraryPage({super.key});

  @override
  ConsumerState<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends ConsumerState<ItineraryPage> {
  int _tabIndex = 0;
  int _selectedDay = 1; // Lunes 16, según el diseño.

  static const _days = [
    WeekDay(weekday: 'D', day: '15', muted: true),
    WeekDay(weekday: 'L', day: '16', selected: true),
    WeekDay(weekday: 'M', day: '17'),
    WeekDay(weekday: 'M', day: '18'),
    WeekDay(weekday: 'J', day: '19'),
    WeekDay(weekday: 'V', day: '20'),
    WeekDay(weekday: 'S', day: '21', muted: true),
  ];

  static const _destinations = [
    NavDestination(icon: CustomIcons.itinerary, label: 'Itinerario'),
    NavDestination(icon: CustomIcons.activities, label: 'Actividades'),
    NavDestination(icon: CustomIcons.equipment, label: 'Equipo'),
    NavDestination(icon: CustomIcons.metrics, label: 'Métricas'),
  ];

  String _initialsOf(String? name) {
    if (name == null || name.trim().isEmpty) return 'MR';
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  String _firstNameOf(String? name) {
    if (name == null || name.trim().isEmpty) return 'María';
    return name.trim().split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final days = [
      for (var i = 0; i < _days.length; i++)
        WeekDay(
          weekday: _days[i].weekday,
          day: _days[i].day,
          muted: _days[i].muted,
          selected: i == _selectedDay,
        ),
    ];

    return Scaffold(
      backgroundColor: CustomColors.background,
      bottomNavigationBar: AppBottomNav(
        destinations: _destinations,
        currentIndex: _tabIndex,
        onSelect: (i) => setState(() => _tabIndex = i),
      ),
      body: Column(
        children: [
          ItineraryHeader(
            dateLabel: 'Lunes 16 de junio',
            greeting: 'Hola, ${_firstNameOf(user?.nombre)}',
            initials: _initialsOf(user?.nombre),
            onTapAvatar: () => _confirmLogout(context),
            summaries: const [
              HeaderSummary(value: '4', label: 'Limpiezas hoy'),
              HeaderSummary(value: '1', label: 'En progreso', highlight: true),
              HeaderSummary(value: '1', suffix: '/4', label: 'Finalizadas'),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: WeekStrip(
              days: days,
              onSelect: (i) => setState(() => _selectedDay = i),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
              children: [
                _agendaHeader(),
                const SizedBox(height: 12),
                ..._taskCards(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _agendaHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Agenda de hoy', style: CustomTypography.cardTitle),
          Text(
            'Ver semana',
            style: CustomTypography.verdana(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: CustomColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _taskCards() {
    const gap = SizedBox(height: 13);
    return [
      const TaskCard(
        title: 'Apto 304 · Marbella Bay',
        address: 'Av. del Mar 1820, Torre B',
        statusLabel: 'En progreso',
        statusVariant: StatusBadgeVariant.inProgress,
        accented: true,
        meta: [
          TaskMeta(icon: CustomIcons.time, label: '10:00 – 12:30'),
          TaskMeta(icon: CustomIcons.property, label: 'Salida completa'),
        ],
        checklistDone: 5,
        checklistTotal: 12,
      ),
      gap,
      const TaskCard(
        title: 'Apto 12A · Vista Verde',
        address: 'Calle Robles 47, Planta 1',
        statusLabel: 'Pendiente',
        statusVariant: StatusBadgeVariant.pending,
        meta: [
          TaskMeta(icon: CustomIcons.time, label: '13:00 – 14:30'),
          TaskMeta(icon: CustomIcons.property, label: 'Mantenimiento ligero'),
        ],
      ),
      gap,
      const TaskCard(
        title: 'Apto 7 · Casa Dunas',
        address: 'Paseo Litoral 9',
        statusLabel: 'Pendiente',
        statusVariant: StatusBadgeVariant.pending,
        meta: [TaskMeta(icon: CustomIcons.time, label: '15:30 – 17:00')],
        incident: 'Avería reportada: cámara de seguridad',
      ),
      gap,
      const TaskCard(
        title: 'Apto 201 · Sol Naciente',
        address: 'Av. Central 300',
        statusLabel: 'Finalizada',
        statusVariant: StatusBadgeVariant.operative,
        completed: true,
        completedNote: '08:00 – 09:20 · 12 fotos de evidencia',
      ),
    ];
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CustomColors.surface,
        title: Text('Cerrar sesión', style: CustomTypography.cardTitle),
        content: Text(
          '¿Deseas salir de tu cuenta?',
          style: CustomTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: CustomTypography.verdana(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: CustomColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Salir',
              style: CustomTypography.verdana(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: CustomColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}
