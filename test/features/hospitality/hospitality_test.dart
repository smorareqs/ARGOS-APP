import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/features/guest/data/guest_repository.dart';
import 'package:argos_app/features/guest/models/guest.dart';
import 'package:argos_app/features/guest/presentation/pages/guest_areas_page.dart';
import 'package:argos_app/features/guest/presentation/pages/guest_home_page.dart';
import 'package:argos_app/features/guest/presentation/providers/guest_session.dart';
import 'package:argos_app/features/hospitality/data/hospitality_repository.dart';
import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:argos_app/features/hospitality/models/reservation.dart';
import 'package:argos_app/features/reservations/presentation/pages/inspection_page.dart';
import 'package:argos_app/features/reservations/presentation/pages/reservation_detail_page.dart';
import 'package:argos_app/features/reservations/presentation/pages/reservations_page.dart';
import 'package:argos_app/features/security/presentation/pages/security_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/harness.dart';
import '../notifications/inbox_test.dart' show signedIn;

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

Future<GuestState> _guestReady(ProviderContainer c) async {
  for (var i = 0; i < 50 && c.read(guestSessionProvider) is GuestLoading; i++) {
    await _settle();
  }
  return c.read(guestSessionProvider);
}

/// Pantalla alta para que las listas construyan todas sus secciones.
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('modo huésped', () {
    test('entra con código y correo, ve su reserva y reserva un área', () async {
      final harness = Harness();
      final c = harness.container();
      expect(await _guestReady(c), isA<GuestNone>());
      final notifier = c.read(guestSessionProvider.notifier);

      expect(await notifier.signIn(code: 'HUESPED-CST', email: 'otro@correo.sv'), contains('no coinciden'));
      expect(await notifier.signIn(code: 'huesped cst', email: 'Tomas.Reyes@correo.sv '), isNull);
      final me = guestMeOf(c.read(guestSessionProvider))!;
      expect(me.firstName, 'Tomás');
      expect(me.parking && me.sharedAreas, isTrue);

      final repo = c.read(guestRepositoryProvider);
      final stay = await repo.reservation();
      expect(stay.code, 'ARG-7K3P9Q');
      expect(stay.phase(harness.clock.now()), StayPhase.during);
      expect(stay.parkingCount, 1);
      expect((await repo.parking()).single.plate, 'P123-456');

      final areas = await repo.areas();
      final pool = areas.areas.firstWhere((a) => a.name == 'Piscina');
      final tomorrow = DateTime(2026, 10, 23);
      final slots = await repo.availability(pool.id, tomorrow);
      expect(slots.first.start, '08:00');
      final booked = await repo.book(pool.id, tomorrow, '10:00', 3);
      expect(booked.areaName, 'Piscina');
      // Máximo 2 bloques por día en la piscina.
      await repo.book(pool.id, tomorrow, '11:00', 2);
      await expectLater(
        repo.book(pool.id, tomorrow, '12:00', 1),
        throwsA(isA<ApiException>().having((e) => e.detail, 'detail', contains('Ya tienes 2 bloques'))),
      );
      // Capacidad por personas.
      await expectLater(
        repo.book(areas.areas.firstWhere((a) => a.name == 'Rancho y asadores').id, tomorrow, '09:00', 11),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
      );
      await repo.cancel(booked.id);
      expect((await repo.bookings()).map((b) => b.id), isNot(contains(booked.id)));

      expect(await repo.report(title: 'No hay agua caliente', urgency: 'high'), greaterThan(0));
    });

    test('el enlace del correo entra solo y la sesión se restaura', () async {
      // El vencimiento se compara con la hora real del teléfono.
      final harness = Harness(now: DateTime.now());
      final c = harness.container();
      await _guestReady(c);
      expect(await c.read(guestSessionProvider.notifier).signIn(token: 'demo-huesped'), isNull);
      expect(c.read(guestSessionProvider), isA<GuestActive>());

      // Otro arranque con el mismo almacenamiento: sigue dentro.
      final again = harness.container();
      expect(await _guestReady(again), isA<GuestActive>());
    });

    testWidgets('F1 muestra fechas, instrucciones y accesos', (tester) async {
      _tall(tester);
      final harness = Harness();
      late ProviderContainer c;
      await tester.runAsync(() async {
        c = harness.container();
        await _guestReady(c);
        await c.read(guestSessionProvider.notifier).signIn(code: 'HUESPED-GAR', email: 'ana.gomez@correo.sv');
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(home: GuestHomePage(now: harness.clock.now())),
        ),
      );
      await tester.runAsync(() => _settle());
      await tester.pumpAndSettle();
      expect(find.text('Hola, Ana'), findsOneWidget);
      expect(find.textContaining('Te esperamos'), findsOneWidget);
      expect(find.text('INSTRUCCIONES DE ACCESO'), findsOneWidget);
      // Garrent no tiene parqueo ni áreas.
      expect(find.text('Mi parqueo'), findsNothing);
      expect(find.text('Reportar un problema'), findsOneWidget);
    });
  });

  group('seguridad', () {
    test('tablero del día y atender una alarma marca las dos de la salida', () async {
      final harness = Harness();
      final c = await signedIn(harness, 'seguridad@argos.demo');
      final repo = c.read(hospitalityRepositoryProvider);
      final board = await repo.board(harness.clock.now());
      expect(board.departures.map((s) => s.guestName), containsAll(['Marco Bianchi', 'Andrea Ortiz']));
      expect(board.arrivals.single.guestName, 'Lucía Hernández');
      expect(board.plates.map((p) => p.plate), contains('P789-012'));
      expect(board.departures.firstWhere((s) => s.guestName == 'Marco Bianchi').matches('p789'), isTrue);

      final pending = await repo.alarms('pending');
      final firing = pending.firstWhere((a) => a.status == AlarmStatus.fired);
      expect(firing.guestName, 'Marco Bianchi');
      await repo.attend(firing.id, 'Salió a tiempo');
      final after = await repo.alarms('pending');
      expect(after.where((a) => a.reservationId == firing.reservationId), isEmpty);
      final all = await repo.alarms('all');
      expect(all.where((a) => a.reservationId == firing.reservationId).every((a) => a.attendedByName == 'Jorge Castillo'), isTrue);

      // D3 sin documentos ni contacto.
      final detail = await repo.detail(firing.reservationId);
      expect(detail.guests.every((g) => g.email == null && g.documents.isEmpty), isTrue);
      expect(detail.deposit.available, isFalse);
    });

    testWidgets('D1 y D2 se pintan con los datos del día', (tester) async {
      _tall(tester);
      // Las pantallas piden el día real del teléfono.
      final harness = Harness(now: DateTime.now());
      late ProviderContainer c;
      await tester.runAsync(() async => c = await signedIn(harness, 'seguridad@argos.demo'));
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const MaterialApp(home: SecurityBoardPage())));
      await tester.runAsync(() => _settle());
      await tester.pumpAndSettle();
      expect(find.textContaining('SALIDAS HOY'), findsOneWidget);
      expect(find.text('Marcar atendida'), findsWidgets);

      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const MaterialApp(home: SecurityAlarmsPage())));
      await tester.runAsync(() => _settle());
      await tester.pumpAndSettle();
      expect(find.textContaining('Salida'), findsWidgets);
    });
  });

  group('supervisor', () {
    test('check-in con registro, documento y depósito; check-out e inspección', () async {
      final harness = Harness();
      final c = await signedIn(harness, 'sofia@argos.demo');
      final repo = c.read(hospitalityRepositoryProvider);
      final today = DateTime(2026, 10, 22);
      final list = await repo.reservations(today, DateTime(2026, 10, 23));
      final lucia = list.firstWhere((r) => r.displayName == 'Lucía Hernández');
      expect(lucia.arrivesOn(today), isTrue);

      var d = await repo.detail(lucia.id);
      expect(d.checkInBlockers(today), hasLength(2)); // huéspedes y depósito
      await expectLater(repo.checkIn(lucia.id), throwsA(isA<ApiException>()));

      // Completar el registro: correo y documento de Diego, fotos de los dos.
      final diego = d.guests.firstWhere((g) => g.fullName == 'Diego Hernández');
      await repo.updateGuest(diego.id, {'email': 'diego@correo.sv', 'document_type': 'passport', 'document_number': 'X5550001'});
      for (final g in d.guests) {
        await repo.attachDocument(g.id, 'id_front', 'f-${g.id}');
        await repo.attachDocument(g.id, 'id_back', 'b-${g.id}');
      }
      await repo.depositTx(lucia.id, type: 'received', amount: 200, method: 'transfer', reference: 'TRX-88');
      d = await repo.detail(lucia.id);
      expect(d.checkInBlockers(today), isEmpty);
      d = await repo.checkIn(lucia.id);
      expect(d.reservation.status, ReservationStatus.checkedIn);

      // Seguridad ya ve sus alarmas de salida.
      final alarms = await repo.alarms('all');
      expect(alarms.where((a) => a.reservationId == lucia.id), hasLength(2));

      d = await repo.checkOut(lucia.id);
      expect(d.reservation.status, ReservationStatus.checkedOut);
      expect(d.deposit.inspectionRequired, isTrue);
      d = await repo.createInspection(lucia.id, kind: 'post_departure', photoIds: ['p1']);
      d = await repo.addFinding(
        d.inspection('post_departure')!.id,
        area: 'Sala',
        description: 'Mancha en el sofá',
        severity: 'medium',
        cost: 40,
        charge: true,
        createTicket: true,
      );
      expect(d.deposit.charges, 40);
      expect(d.inspection('post_departure')!.findings.single.ticketNumber, isNotNull);
      final dep = await repo.depositTx(lucia.id, type: 'retained', amount: 40, method: 'cash', notes: 'Limpieza del sofá');
      expect(dep.balance, 160);
      final settled = await repo.depositTx(lucia.id, type: 'returned', amount: 160, method: 'transfer');
      expect(settled.status, 'retained_partial');
    });

    test('agregar huésped reutiliza el registrado por documento', () async {
      final harness = Harness();
      final c = await signedIn(harness, 'sofia@argos.demo');
      final repo = c.read(hospitalityRepositoryProvider);
      final hit = await repo.findByDocument('04839201-7');
      expect(hit?.fullName, 'Tomás Reyes');
      final d = await repo.addGuest('res-vega', guestId: hit!.id);
      expect(d.guests.map((g) => g.fullName), contains('Tomás Reyes'));
    });

    test('asignar parqueo choca con otra estancia en las mismas fechas', () async {
      final harness = Harness();
      final c = await signedIn(harness, 'sofia@argos.demo');
      final repo = c.read(hospitalityRepositoryProvider);
      final spaces = await repo.spaces();
      final e12 = spaces.firstWhere((s) => s.$2 == 'E-12');
      await expectLater(
        repo.assignParking(spaceId: e12.$1, reservationCode: 'ARG-4M8T2W', plate: 'p 111-222'),
        throwsA(isA<ApiException>().having((e) => e.detail, 'detail', contains('Ocupado por ARG-7K3P9Q'))),
      );
      final ok = await repo.assignParking(spaceId: spaces.firstWhere((s) => s.$2 == 'E-10').$1, reservationCode: 'ARG-4M8T2W', plate: 'P111-222');
      expect(ok.plate, 'P111-222');
    });

    testWidgets('C5 separa llegadas, salidas y hospedados', (tester) async {
      _tall(tester);
      final harness = Harness(now: DateTime.now());
      late ProviderContainer c;
      await tester.runAsync(() async => c = await signedIn(harness, 'sofia@argos.demo'));
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const MaterialApp(home: ReservationsPage())));
      await tester.runAsync(() => _settle());
      await tester.pumpAndSettle();
      expect(find.text('Reservas'), findsOneWidget);
      expect(find.byType(ReservationCard), findsWidgets);
      await tester.tap(find.textContaining('Salidas'));
      await tester.pumpAndSettle();
      expect(find.text('Marco Bianchi'), findsOneWidget);
    });
  });

  group('a 390 px', phoneLayouts);

  test('modelo: etiquetas de depósito y moneda', () {
    expect(depositLabel('received'), 'Depósito recibido');
    expect(money(150), r'$150');
    expect(money(12.5, 'GTQ'), 'Q12.50');
  });
}

/// Las pantallas de la fase 4 caben en un teléfono de 390 px sin desbordes.
void phoneLayouts() {
  Future<void> show(WidgetTester tester, ProviderContainer c, Widget page) async {
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(home: page)));
    await tester.runAsync(() => _settle());
    await tester.pumpAndSettle();
  }

  testWidgets('pantallas de seguridad y supervisor a 390 px', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = Harness(now: DateTime.now());
    late ProviderContainer security;
    late ProviderContainer sofia;
    await tester.runAsync(() async {
      security = await signedIn(harness, 'seguridad@argos.demo');
      sofia = await signedIn(harness, 'sofia@argos.demo');
    });
    await show(tester, security, const SecurityBoardPage());
    await show(tester, security, const SecurityAlarmsPage());
    await show(tester, security, const SecurityAreasPage());
    await show(tester, sofia, const ReservationsPage());
    for (final id in ['res-lucia', 'res-tomas', 'res-marco']) {
      await show(tester, sofia, ReservationDetailPage(reservationId: id));
    }
    await show(tester, sofia, const InspectionPage(reservationId: 'res-tomas', kind: 'post_departure'));
    // Deja cerrar las consultas de la cola de fotos antes de terminar.
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => _settle());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('pantallas del huésped a 390 px', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final harness = Harness(now: DateTime.now());
    late ProviderContainer c;
    await tester.runAsync(() async {
      c = harness.container();
      await _guestReady(c);
      await c.read(guestSessionProvider.notifier).signIn(code: 'HUESPED-CST', email: 'tomas.reyes@correo.sv');
    });
    await show(tester, c, const GuestHomePage());
    await show(tester, c, const GuestAreasPage());
    await show(tester, c, const GuestAreaPage(areaId: 'area-pool'));
    await show(tester, c, const GuestParkingPage());
    await show(tester, c, const GuestReportPage());
    await show(tester, c, const GuestHelpPage());
  });
}
