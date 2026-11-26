import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/core/outbox/outbox.dart';
import 'package:argos_app/core/outbox/outbox_providers.dart';
import 'package:argos_app/features/auth/models/session.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/itinerary/presentation/pages/itinerary_page.dart';
import 'package:argos_app/features/tasks/data/datasources/tasks_remote_datasource.dart';
import 'package:argos_app/features/tasks/data/mock/tasks_mock_routes.dart';
import 'package:design_system/design_system.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sesión fija: evita depender del backend en la prueba de la pantalla.
class _SignedIn extends SessionController {
  @override
  AuthState build() => const AuthSignedIn(
    Session(
      user: SessionUser(id: 'u-1', email: 'maria@argos.demo', fullName: 'María Ramos'),
      tenant: ActiveTenant(id: 't-1', name: 'Costa Limpia S.A.'),
      roleKey: 'cleaner',
      roleName: 'Colaborador de limpieza',
      permissions: {'tasks.execute'},
    ),
  );
}

/// Agenda simulada sin red real; [online] en false simula estar sin conexión.
class _FakeTasks extends TasksRemoteDataSource {
  _FakeTasks() : super(Dio());

  bool online = true;

  @override
  Future<List<Map<String, dynamic>>> forDate(DateTime date, {bool mine = true}) async {
    if (!online) {
      throw DioException.connectionError(
        requestOptions: RequestOptions(path: '/tasks'),
        reason: 'sin red',
      );
    }
    return [
      for (final t in mockAgenda(date, today: _today, userId: 'u-1'))
        Map<String, dynamic>.from(t),
    ];
  }
}

final _today = DateTime(2026, 10, 22); // jueves

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  late _FakeTasks tasks;
  late AppDatabase db;
  var openedProfile = false;

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(_SignedIn.new),
          tasksRemoteDataSourceProvider.overrideWithValue(tasks),
          appDatabaseProvider.overrideWithValue(db),
          outboxProvider.overrideWith((ref) => Outbox(db: db, send: (_, _, _) async => {})),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ItineraryPage(
              today: _today,
              onOpenProfile: () => openedProfile = true,
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  setUp(() {
    tasks = _FakeTasks();
    db = AppDatabase(NativeDatabase.memory());
    openedProfile = false;
    addTearDown(db.close);
  });

  testWidgets('Hoy muestra la sesión, la semana y las tareas del día', (tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await pumpPage(tester);

    expect(find.text('Hola, María'), findsOneWidget);
    expect(find.text('Jueves 22 de octubre'), findsOneWidget);

    // Semana de domingo 18 a sábado 24, con hoy seleccionado.
    final days = tester.widget<WeekStrip>(find.byType(WeekStrip)).days;
    expect(days.map((d) => d.day), ['18', '19', '20', '21', '22', '23', '24']);
    expect(days.map((d) => d.weekday).join(), 'DLMMJVS');
    expect(days.indexWhere((d) => d.selected), 4);

    final expected = mockAgenda(_today, today: _today, userId: 'u-1').length;
    expect(find.byType(TaskCard), findsNWidgets(expected));
    // La que está en progreso va primero y con acento.
    final first = tester.widget<TaskCard>(find.byType(TaskCard).first);
    expect(first.statusLabel, 'En progreso');
    expect(first.accented, isTrue);
    expect(find.text('Debió iniciar a las 11:00'), findsOneWidget);

    // Filtro "Retrasadas".
    await tester.scrollUntilVisible(
      find.textContaining('Retrasadas'),
      120,
      scrollable: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
      ),
    );
    await tester.ensureVisible(find.textContaining('Retrasadas'));
    await tester.pump();
    await tester.tap(find.textContaining('Retrasadas'));
    await settle(tester, frames: 4);
    expect(find.byType(TaskCard), findsOneWidget);

    await tester.tap(find.text('MR'));
    expect(openedProfile, isTrue);
    await unmount(tester);
  });

  testWidgets('el domingo no hay tareas', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('18'));
    await settle(tester);
    expect(find.text('Sin tareas este día'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('sin conexión muestra la copia guardada', (tester) async {
    await pumpPage(tester); // guarda la copia
    tasks.online = false;
    await tester.pumpWidget(const SizedBox());
    await pumpPage(tester);
    expect(find.byType(OfflineBar), findsOneWidget);
    expect(find.byType(TaskCard), findsWidgets);
    await unmount(tester);
  });

  testWidgets('sin conexión y sin copia muestra el error', (tester) async {
    tasks.online = false;
    await pumpPage(tester);
    expect(find.textContaining('sin datos guardados'), findsOneWidget);
    await unmount(tester);
  });
}

Future<void> settle(WidgetTester tester, {int frames = 20}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
  }
}
