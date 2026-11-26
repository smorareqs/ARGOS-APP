import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/hospitality/data/hospitality_repository.dart';
import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:argos_app/features/security/presentation/widgets/security_widgets.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _todayKey() => dayKey(DateTime.now());

Widget _loadingList() => ListView(
  padding: const EdgeInsets.all(16),
  children: [
    const Skeleton(width: double.infinity, height: 150, radius: CustomDimensions.radiusCard),
    for (var i = 0; i < 3; i++) ...[
      const SizedBox(height: 12),
      const Skeleton(width: double.infinity, height: 90, radius: CustomDimensions.radiusCard),
    ],
  ],
);

Widget _errorList(Object? error, Future<void> Function() retry) => ListView(
  padding: const EdgeInsets.all(16),
  physics: const AlwaysScrollableScrollPhysics(),
  children: [
    ErrorState(
      message: error is DioException ? 'Sin conexión. El tablero necesita internet.' : errorMessage(error ?? 'Error'),
      onRetry: retry,
    ),
  ],
);

class _Header extends StatelessWidget {
  const _Header({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null)
            Text(
              subtitle!.toUpperCase(),
              style: CustomTypography.label.copyWith(letterSpacing: 1.2, color: CustomColors.textMuted),
            ),
          Text(title, style: CustomTypography.pageTitle),
        ],
      ),
    );
  }
}

// ── D1 · Tablero ─────────────────────────────────────────

/// D1 · Tablero de seguridad: contadores del día, búsqueda por nombre o
/// placa y secciones de salidas, llegadas, hospedados, áreas y parqueos.
class SecurityBoardPage extends ConsumerStatefulWidget {
  const SecurityBoardPage({super.key});

  @override
  ConsumerState<SecurityBoardPage> createState() => _SecurityBoardPageState();
}

class _SecurityBoardPageState extends ConsumerState<SecurityBoardPage> {
  var _query = '';

  Future<void> _refresh() => ref.refresh(securityBoardProvider(_todayKey()).future).then((_) {}, onError: (_) {});

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(securityBoardProvider(_todayKey()));
    final board = async.valueOrNull;
    final auth = ref.watch(sessionControllerProvider);
    final firstName = auth is AuthSignedIn ? auth.session.user.fullName.split(' ').first : null;

    Widget body;
    if (board == null && async.isLoading) {
      body = _loadingList();
    } else if (board == null) {
      body = _errorList(async.error, _refresh);
    } else {
      body = _BoardView(board: board, query: _query, onQuery: (q) => setState(() => _query = q), onChanged: _refresh);
    }

    return Scaffold(
      backgroundColor: CustomColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(title: firstName == null ? 'Tablero' : 'Hola, $firstName', subtitle: shortDay(DateTime.now())),
            Expanded(
              child: RefreshIndicator(color: CustomColors.primary, onRefresh: _refresh, child: body),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardView extends ConsumerWidget {
  const _BoardView({required this.board, required this.query, required this.onQuery, required this.onChanged});

  final SecurityBoard board;
  final String query;
  final ValueChanged<String> onQuery;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = board;
    bool keep(BoardStay s) => s.matches(query);
    final departures = b.departures.where(keep).toList()..sort((x, y) => x.checkOutTime.compareTo(y.checkOutTime));
    final arrivals = b.arrivals.where(keep).toList()..sort((x, y) => x.checkInTime.compareTo(y.checkInTime));
    final inHouse = b.inHouse.where(keep).toList();
    final byBuilding = <String, List<BoardStay>>{};
    for (final s in inHouse) {
      (byBuilding[s.building.isEmpty ? 'Sin edificio' : s.building] ??= []).add(s);
    }
    final plates = b.plates
        .where(
          (p) =>
              query.isEmpty ||
              p.plate.toLowerCase().contains(query.toLowerCase().replaceAll(' ', '')) ||
              p.guestName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    final pending = b.alarms.where((a) => a.open).toList();
    SecurityAlarm? alarmOf(BoardStay s) =>
        b.alarms.where((a) => a.reservationId == s.reservationId && a.open).firstOrNull;
    final firing = pending.where((a) => a.status == AlarmStatus.fired).toList();
    final nothing = departures.isEmpty && arrivals.isEmpty && inHouse.isEmpty && plates.isEmpty;

    void open(BoardStay s) => showStaySheet(context, reservationId: s.reservationId, preview: s);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: CustomColors.primary,
            borderRadius: BorderRadius.circular(CustomDimensions.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HOY EN LAS PROPIEDADES',
                style: CustomTypography.verdana(
                  fontSize: 10.5,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  BoardCounter(value: b.departures.length, label: 'Salidas'),
                  BoardCounter(value: b.arrivals.length, label: 'Llegadas'),
                  BoardCounter(
                    value: b.inHouse.length + b.departures.where((s) => s.status == 'checked_in').length,
                    label: 'Hospedados',
                  ),
                  BoardCounter(value: pending.length, label: 'Alarmas', alert: true),
                ],
              ),
            ],
          ),
        ),
        if (firing.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final a in firing)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AlarmCard(
                alarm: a,
                onAttend: () async {
                  if (await showAttendSheet(context, ref, a)) {
                    if (context.mounted) showToast(context, 'Alarma atendida.');
                    await onChanged();
                  }
                },
              ),
            ),
        ],
        const SizedBox(height: 14),
        SearchField(hintText: 'Buscar por nombre, placa o propiedad', minLength: 1, onSearch: onQuery),
        if (nothing)
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: EmptyState(
              icon: query.isEmpty ? CustomIcons.security : CustomIcons.search,
              title: query.isEmpty ? 'Día tranquilo' : 'Sin resultados',
              message: query.isEmpty ? 'Hoy no hay llegadas, salidas ni huéspedes.' : 'Nadie coincide con "$query".',
            ),
          ),
        if (departures.isNotEmpty) ...[
          const SizedBox(height: 22),
          SectionHeader(title: 'Salidas hoy · ${departures.length}'),
          const SizedBox(height: 10),
          for (final s in departures)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StayCard(stay: s, time: s.checkOutTime, alarm: alarmOf(s), onTap: () => open(s)),
            ),
        ],
        if (arrivals.isNotEmpty) ...[
          const SizedBox(height: 22),
          SectionHeader(title: 'Llegadas hoy · ${arrivals.length}'),
          const SizedBox(height: 10),
          for (final s in arrivals)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StayCard(stay: s, time: s.checkInTime, onTap: () => open(s)),
            ),
        ],
        for (final entry in byBuilding.entries) ...[
          const SizedBox(height: 22),
          SectionHeader(title: 'Hospedados · ${entry.key} · ${entry.value.length}'),
          const SizedBox(height: 10),
          for (final s in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StayCard(
                stay: s,
                time: s.checkOutDate == dayKey(DateTime.now()) ? s.checkOutTime : '—',
                onTap: () => open(s),
              ),
            ),
        ],
        if (b.areaBookings.isNotEmpty && query.isEmpty) ...[
          const SizedBox(height: 22),
          SectionHeader(title: 'Áreas comunes hoy · ${b.areaBookings.length}'),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final bk in b.areaBookings)
                  AppListTile(
                    icon: CustomIcons.sharedAreas,
                    title: '${bk.start}–${bk.end} · ${bk.areaName}',
                    subtitle:
                        '${bk.guestName} · ${bk.propertyCode} · ${bk.people} ${bk.people == 1 ? 'persona' : 'personas'}',
                    showChevron: false,
                  ),
              ],
            ),
          ),
        ],
        if (plates.isNotEmpty) ...[
          const SizedBox(height: 22),
          SectionHeader(title: 'Parqueos ocupados · ${plates.length}'),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final p in plates)
                  AppListTile(
                    leading: PlateTag(p.plate),
                    title: 'Espacio ${p.spaceCode}',
                    subtitle: '${p.guestName} · ${p.propertyCode}${p.level.isEmpty ? '' : ' · ${p.level}'}',
                    showChevron: false,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── D2 · Alarmas ─────────────────────────────────────────

enum _AlarmFilter { pending, today, all }

/// D2 · Alarmas de salida: pendientes primero; atendidas tachadas.
class SecurityAlarmsPage extends ConsumerStatefulWidget {
  const SecurityAlarmsPage({super.key});

  @override
  ConsumerState<SecurityAlarmsPage> createState() => _SecurityAlarmsPageState();
}

class _SecurityAlarmsPageState extends ConsumerState<SecurityAlarmsPage> {
  var _filter = _AlarmFilter.pending;

  String get _key => _filter.name;

  Future<void> _refresh() => ref.refresh(securityAlarmsProvider(_key).future).then((_) {}, onError: (_) {});

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(securityAlarmsProvider(_key));
    final list = async.valueOrNull;

    Widget body;
    if (list == null && async.isLoading) {
      body = _loadingList();
    } else if (list == null) {
      body = _errorList(async.error, _refresh);
    } else {
      final sorted = [...list]
        ..sort((a, b) {
          if (a.open != b.open) return a.open ? -1 : 1;
          if (a.status != b.status && a.open) return a.status == AlarmStatus.fired ? -1 : 1;
          return a.open ? a.fireAt.compareTo(b.fireAt) : b.fireAt.compareTo(a.fireAt);
        });
      body = ListView(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          FilterChips<_AlarmFilter>(
            options: const [
              FilterOption(value: _AlarmFilter.pending, label: 'Pendientes'),
              FilterOption(value: _AlarmFilter.today, label: 'Hoy'),
              FilterOption(value: _AlarmFilter.all, label: 'Todas'),
            ],
            selected: {_filter},
            onChanged: (s) => setState(() => _filter = s.isEmpty ? _filter : s.first),
          ),
          const SizedBox(height: 14),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: EmptyState(
                icon: CustomIcons.alarm,
                title: 'Sin alarmas pendientes',
                message: 'Te avisamos 30 minutos antes de cada salida y a la hora exacta.',
              ),
            )
          else
            for (final a in sorted)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: AlarmCard(
                  alarm: a,
                  onOpen: () => showStaySheet(context, reservationId: a.reservationId),
                  onAttend: () async {
                    if (await showAttendSheet(context, ref, a)) {
                      if (context.mounted) showToast(context, 'Alarma atendida.');
                      await _refresh();
                    }
                  },
                ),
              ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: CustomColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(title: 'Alarmas', subtitle: 'Salidas de huéspedes'),
            Expanded(
              child: RefreshIndicator(color: CustomColors.primary, onRefresh: _refresh, child: body),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Áreas comunes (seguridad) ────────────────────────────

/// Reservas de áreas comunes del día, por área y hora (solo lectura).
class SecurityAreasPage extends ConsumerStatefulWidget {
  const SecurityAreasPage({super.key});

  @override
  ConsumerState<SecurityAreasPage> createState() => _SecurityAreasPageState();
}

class _SecurityAreasPageState extends ConsumerState<SecurityAreasPage> {
  var _day = DateTime.now();

  Future<void> _refresh() => ref.refresh(areaBookingsProvider(dayKey(_day)).future).then((_) {}, onError: (_) {});

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(areaBookingsProvider(dayKey(_day)));
    final areas = ref.watch(sharedAreasProvider).valueOrNull ?? const <SharedArea>[];
    final list = async.valueOrNull;
    final today = DateTime.now();
    final days = [for (var i = 0; i < 7; i++) DateTime(today.year, today.month, today.day + i)];

    Widget body;
    if (list == null && async.isLoading) {
      body = _loadingList();
    } else if (list == null) {
      body = _errorList(async.error, _refresh);
    } else {
      final byArea = <String, List<AreaBooking>>{};
      for (final b in list) {
        (byArea[b.areaName] ??= []).add(b);
      }
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = days[i];
                return SizedBox(
                  width: 48,
                  child: Row(
                    children: [
                      WeekDayChip(
                        weekday: ['L', 'M', 'M', 'J', 'V', 'S', 'D'][d.weekday - 1],
                        day: '${d.day}',
                        selected: dayKey(d) == dayKey(_day),
                        onTap: () => setState(() => _day = d),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: EmptyState(
                icon: CustomIcons.sharedAreas,
                title: 'Sin reservas',
                message: 'Nadie apartó áreas comunes ese día.',
              ),
            )
          else
            for (final entry in byArea.entries) ...[
              Row(
                children: [
                  AreaArtBoxSmall(
                    art: areas.where((a) => a.name == entry.key).firstOrNull?.photo ?? AreaArt.brightRoom,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(entry.key, style: CustomTypography.sectionTitle)),
                  Text(
                    '${entry.value.fold<int>(0, (s, b) => s + b.people)} personas',
                    style: CustomTypography.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final b in entry.value..sort((x, y) => x.start.compareTo(y.start)))
                      AppListTile(
                        leading: SizedBox(
                          width: 52,
                          child: Text(
                            b.start,
                            style: CustomTypography.mono.copyWith(fontSize: 15, color: CustomColors.primary),
                          ),
                        ),
                        title: b.guestName,
                        subtitle:
                            '${b.propertyCode} · ${b.people} ${b.people == 1 ? 'persona' : 'personas'} · hasta ${b.end}',
                        showChevron: false,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: CustomColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(title: 'Áreas comunes', subtitle: 'Reservas de huéspedes'),
            Expanded(
              child: RefreshIndicator(color: CustomColors.primary, onRefresh: _refresh, child: body),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icono pequeño de un área (como [AreaArt]).
class AreaArtBoxSmall extends StatelessWidget {
  const AreaArtBoxSmall({super.key, required this.art});

  final AreaArt art;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: art.color, borderRadius: BorderRadius.circular(9)),
      child: Icon(art.icon, color: Colors.white, size: 18),
    );
  }
}
