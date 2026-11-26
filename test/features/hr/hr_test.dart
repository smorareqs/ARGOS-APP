import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/features/hr/data/hr_repository.dart';
import 'package:argos_app/features/hr/models/hr.dart';
import 'package:argos_app/features/hr/presentation/pages/attendance_page.dart';
import 'package:argos_app/features/hr/presentation/pages/disciplinary_page.dart';
import 'package:argos_app/features/hr/presentation/pages/metrics_pages.dart';
import 'package:argos_app/features/hr/presentation/pages/payslips_page.dart';
import 'package:argos_app/features/shell/models/shell_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/harness.dart';
import '../notifications/inbox_test.dart' show signedIn;

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

String _month(DateTime d) => monthKey(d);

/// Pantalla de teléfono (390 px) alta, para ver toda la lista y los desbordes.
void _phone(WidgetTester tester, {double height = 2600}) {
  tester.view.physicalSize = Size(390, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<ProviderContainer> _pump(WidgetTester tester, String email, Widget page) async {
  final harness = Harness(now: DateTime.now());
  late ProviderContainer c;
  await tester.runAsync(() async => c = await signedIn(harness, email));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(home: page),
    ),
  );
  await tester.runAsync(() => _settle());
  await tester.pumpAndSettle();
  return c;
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('asistencia', () {
    test('marca entrada y salida con GPS; no deja marcar dos veces', () async {
      final harness = Harness(now: DateTime.now());
      final c = await signedIn(harness, 'ana@argos.demo');
      final repo = c.read(hrRepositoryProvider);
      final month = await repo.myAttendance(_month(DateTime.now()));
      expect(month.open, isNull);
      expect(month.schedule, hasLength(5));

      await expectLater(
        repo.clock(entering: true, lat: 0, lng: 0),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 422)),
      );
      final inRec = await repo.clock(entering: true, lat: 14.6, lng: -90.5);
      expect(inRec.open, isTrue);
      await expectLater(
        repo.clock(entering: true, lat: 14.6, lng: -90.5),
        throwsA(isA<ApiException>().having((e) => e.detail, 'detail', contains('Ya marcaste'))),
      );
      expect((await repo.myAttendance(_month(DateTime.now()))).open?.id, inRec.id);
      final out = await repo.clock(entering: false, lat: 14.6, lng: -90.5);
      expect(out.open, isFalse);
      expect(out.workedMinutes, 0);
      await expectLater(
        repo.clock(entering: false, lat: 14.6, lng: -90.5),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
      );
    });

    test('el propietario no tiene ficha de colaborador', () async {
      final c = await signedIn(Harness(now: DateTime.now()), 'propietario@argos.demo');
      await expectLater(
        c.read(hrRepositoryProvider).myAttendance(_month(DateTime.now())),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 422)),
      );
    });

    testWidgets('B15 muestra el botón, el resumen y el historial', (tester) async {
      _phone(tester);
      await _pump(tester, 'ana@argos.demo', const AttendancePage());
      expect(find.text('Marcar entrada'), findsWidgets);
      expect(find.text('Aún no marcas tu entrada'), findsOneWidget);
      expect(find.text('Horas del mes'), findsOneWidget);
      expect(find.textContaining('HISTORIAL'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('boletas y disciplina', () {
    test('mis boletas traen devengos y descuentos', () async {
      final c = await signedIn(Harness(now: DateTime.now()), 'ana@argos.demo');
      final list = await c.read(hrRepositoryProvider).payslips();
      expect(list, hasLength(4));
      final s = list.first;
      expect(s.lines.first.$1, 'Salario base');
      expect(s.deductions.first.$1, 'IGSS laboral');
      expect((s.gross - s.totalDeductions - s.net).abs(), lessThan(0.01));
      expect(s.basis, contains('limpiezas'));
      expect(quetzales(3836.63), 'Q3,836.63');
    });

    test('dar acuse de una acción disciplinaria una sola vez', () async {
      final c = await signedIn(Harness(now: DateTime.now()), 'ana@argos.demo');
      final repo = c.read(hrRepositoryProvider);
      final list = await repo.disciplinary();
      final pending = list.firstWhere((a) => a.pending);
      expect(pending.typeLabel, 'Llamada de atención');
      final done = await repo.acknowledge(pending.id, 'Entendido');
      expect(done.pending, isFalse);
      expect(done.note, 'Entendido');
      await expectLater(repo.acknowledge(pending.id, null), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 422)));
    });

    testWidgets('B20 y B21 se pintan a 390 px', (tester) async {
      _phone(tester);
      await _pump(tester, 'ana@argos.demo', const PayslipsPage());
      expect(find.text('ÚLTIMA BOLETA'), findsOneWidget);
      expect(find.text('Recibes'), findsOneWidget);
      await tester.tap(find.text('Ver detalle'));
      await tester.pumpAndSettle();
      expect(find.text('Líquido a recibir'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pump(tester, 'ana@argos.demo', const DisciplinaryPage());
      expect(find.textContaining('1 acción por leer'), findsOneWidget);
      await _pump(tester, 'ana@argos.demo', const DisciplinaryDetailPage(id: 'disc-1'));
      expect(find.text('Confirmo que la recibí'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('métricas', () {
    test('mis métricas: tendencia, puesto en mi rol y metas', () async {
      final c = await signedIn(Harness(now: DateTime.now()), 'ana@argos.demo');
      final m = await c.read(hrRepositoryProvider).myMetrics('month');
      expect(m.me.rank, 1);
      expect(m.me.rankOf, 4);
      expect(m.goals, hasLength(2));
      expect(m.perDay, isNotEmpty);
      final late = m.goals.firstWhere((g) => g.lowerIsBetter);
      expect(late.label, contains('máximo'));
    });

    test('el equipo se ordena por rol y el reporte trae propiedades', () async {
      final c = await signedIn(Harness(now: DateTime.now()), 'sofia@argos.demo');
      final repo = c.read(hrRepositoryProvider);
      final team = await repo.team('week');
      expect(team.roles.map((r) => r.$1), ['cleaner', 'maintenance']);
      expect(team.people.where((p) => p.roleKey == 'maintenance').single.rank, 1);
      final report = await repo.report(_month(DateTime.now()));
      expect(report.properties, isNotEmpty);
      expect(report.occupancy, inInclusiveRange(0, 100));
      // Quién marcó hoy (C1).
      final today = await repo.day(DateTime.now().toIso8601String().substring(0, 10));
      expect(today.map((r) => r.userId), contains('u-marta'));
    });

    testWidgets('B19, equipo y E3 se pintan a 390 px', (tester) async {
      _phone(tester);
      await _pump(tester, 'ana@argos.demo', const MyMetricsPage());
      expect(find.text('Limpiezas'), findsOneWidget);
      expect(find.text('¡Vas en primer lugar!'), findsOneWidget);
      expect(find.text('Limpiezas del mes'), findsOneWidget);
      await tester.tap(find.text('Mes'));
      await tester.runAsync(() => _settle());
      await tester.pumpAndSettle();
      expect(find.text('ESTE MES'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pump(tester, 'sofia@argos.demo', const TeamMetricsPage());
      expect(find.text('Marta Díaz'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pump(tester, 'propietario@argos.demo', const ReportsPage());
      expect(find.text('Ocupación'), findsOneWidget);
      expect(find.textContaining('POR PROPIEDAD'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    test('el propietario tiene su pestaña de reportes', () {
      final tabs = tabsFor(roleKey: 'owner', permissions: const {'metrics.all'}, features: const {});
      expect(tabs, contains(ShellTab.reports));
    });
  });
}
