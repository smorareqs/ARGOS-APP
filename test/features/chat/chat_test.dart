import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/features/auth/data/models/auth_dtos.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/chat/data/chat_repository.dart';
import 'package:argos_app/features/chat/models/chat.dart';
import 'package:argos_app/features/chat/presentation/pages/chat_list_page.dart';
import 'package:argos_app/features/chat/presentation/pages/chat_thread_page.dart';
import 'package:argos_app/features/guest/data/guest_repository.dart';
import 'package:argos_app/features/guest/presentation/pages/guest_home_page.dart';
import 'package:argos_app/features/guest/presentation/providers/guest_session.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/harness.dart';
import '../notifications/inbox_test.dart' show signedIn;

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 30));

Future<GuestState> _guestReady(ProviderContainer c) async {
  for (var i = 0; i < 50 && c.read(guestSessionProvider) is GuestLoading; i++) {
    await _settle();
  }
  return c.read(guestSessionProvider);
}

Future<ProviderContainer> _tomas(Harness harness) async {
  final c = harness.container();
  await _guestReady(c);
  expect(await c.read(guestSessionProvider.notifier).signIn(code: 'HUESPED-CST', email: 'tomas.reyes@correo.sv'), isNull);
  return c;
}

void _phone(WidgetTester tester, {double height = 1600}) {
  tester.view.physicalSize = Size(390, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Cierra la pantalla y deja que terminen los temporizadores (sondeo del hilo).
Future<void> _close(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('chat del equipo', () {
    test('Ana ve sus conversaciones con no leídos y no ve las de huéspedes', () async {
      final c = await signedIn(Harness(now: DateTime.now()), 'ana@argos.demo');
      final repo = c.read(chatRepositoryProvider);
      final list = await repo.conversations('internal');
      expect(list.map((x) => x.id), containsAll(['c-equipo', 'c-ana-luis']));
      final pair = list.firstWhere((x) => x.id == 'c-ana-luis');
      expect(pair.title, 'Luis Pérez');
      expect(pair.unread, 1);
      expect(pair.isGroup, isFalse);
      expect(list.firstWhere((x) => x.id == 'c-equipo').isGroup, isTrue);
      expect(await repo.conversations('guest'), isEmpty);
      await expectLater(
        repo.messages('c-tomas'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)),
      );

      await repo.read('c-ana-luis');
      expect((await repo.conversation('c-ana-luis')).unread, 0);
      // Crear un 1:1 que ya existe devuelve el mismo.
      expect((await repo.create(['u-luis'])).id, 'c-ana-luis');
      final group = await repo.create(['u-luis', 'u-marta'], title: 'Torre Olivo');
      expect(group.title, 'Torre Olivo');
      expect(group.participants, hasLength(3));
      expect((await repo.mute('c-equipo', true)).muted, isTrue);
      c.dispose();
    });

    test('el hilo envía al instante y queda "enviado" con la respuesta del servidor', () async {
      final c = await signedIn(Harness(now: DateTime.now()), 'ana@argos.demo');
      final sub = c.listen(chatThreadProvider('c-ana-luis'), (_, _) {});
      for (var i = 0; i < 20 && c.read(chatThreadProvider('c-ana-luis')).loading; i++) {
        await _settle();
      }
      final before = c.read(chatThreadProvider('c-ana-luis')).messages;
      expect(before, hasLength(3));
      expect(before.where((m) => m.mine).single.body, 'Todavía estoy, te espero.');

      final ctrl = c.read(chatThreadProvider('c-ana-luis').notifier);
      final sending = ctrl.send(body: '  Ya voy saliendo  ');
      final temp = c.read(chatThreadProvider('c-ana-luis')).messages.last;
      expect(temp.state, MessageState.sending);
      expect(temp.body, 'Ya voy saliendo');
      expect(await sending, isTrue);
      final after = c.read(chatThreadProvider('c-ana-luis')).messages;
      expect(after, hasLength(4));
      expect(after.last.state, MessageState.sent);
      expect(after.last.mine, isTrue);
      expect(after.last.id, isNot(startsWith('local-')));
      expect(await ctrl.send(body: '   '), isFalse);
      sub.close();
      c.dispose();
    });

    test('la supervisora ve el chat con el huésped y su reserva', () async {
      final c = await signedIn(Harness(now: DateTime.now()), 'sofia@argos.demo');
      final guests = await c.read(chatRepositoryProvider).conversations('guest');
      final tomas = guests.single;
      expect(tomas.title, 'Tomás Reyes');
      expect(tomas.reservation?.code, 'ARG-7K3P9Q');
      expect(tomas.unread, 1);
      expect(tomas.participants.where((p) => p.isGuest), hasLength(1));
      c.dispose();
    });
  });

  group('chat del huésped y código', () {
    test('Tomás escribe a la empresa y ve su código de puerta', () async {
      final harness = Harness(now: DateTime.now());
      final c = await _tomas(harness);
      final me = guestMeOf(c.read(guestSessionProvider))!;
      expect(me.chat && me.smartLocks, isTrue);
      final repo = c.read(guestRepositoryProvider);
      final chat = await repo.chat();
      expect(chat.messages.first.isSystem, isTrue);
      expect(chat.messages.where((m) => m.mine), isNotEmpty);
      final sent = await repo.sendChat('¿Hay estacionamiento para visitas?');
      expect(sent.mine, isTrue);
      expect((await repo.chat()).messages.last.body, '¿Hay estacionamiento para visitas?');

      final lock = await repo.lock();
      expect(lock.available && lock.hasLock, isTrue);
      expect(lock.code, '730519');
      c.dispose();
    });

    test('la huésped de Garrent no tiene chat ni cerradura', () async {
      final harness = Harness(now: DateTime.now());
      final c = harness.container();
      await _guestReady(c);
      await c.read(guestSessionProvider.notifier).signIn(code: 'HUESPED-GAR', email: 'ana.gomez@correo.sv');
      final me = guestMeOf(c.read(guestSessionProvider))!;
      expect(me.chat || me.smartLocks, isFalse);
      final lock = await c.read(guestRepositoryProvider).lock();
      expect(lock.hasLock, isFalse);
      c.dispose();
    });
  });

  group('pago vencido', () {
    test('lee read_only y billing_status de /auth/me', () {
      Map<String, dynamic> me({bool readOnly = false, String status = 'active'}) => {
        'user': {'id': 'u', 'email': 'a@b.c', 'full_name': 'A'},
        'tenant': {'id': 't', 'name': 'T', 'features': {}, 'read_only': readOnly, 'billing_status': status},
        'role': {'key': 'admin', 'name': 'Admin'},
        'permissions': ['tenant.billing'],
      };
      expect(sessionFromMeJson(me()).tenant.readOnly, isFalse);
      expect(sessionFromMeJson(me(readOnly: true, status: 'suspended')).tenant.readOnly, isTrue);
      expect(sessionFromMeJson(me(status: 'past_due')).tenant.pastDue, isTrue);
    });

    test('Garrent sale con pago vencido en el modo simulado', () async {
      final harness = Harness(now: DateTime.now());
      final c = harness.container();
      await booted(c);
      final session = c.read(sessionControllerProvider.notifier);
      await session.login('sofia@argos.demo', demoPassword);
      final choosing = c.read(sessionControllerProvider) as AuthChoosingTenant;
      final garrent = choosing.memberships.firstWhere((m) => m.tenantName == 'Garrent');
      await session.chooseTenant(garrent.tenantId, remember: false);
      session.finishQuickUnlockOffer();
      final s = c.read(sessionControllerProvider) as AuthSignedIn;
      expect(s.session.tenant.pastDue, isTrue);
      expect(s.session.tenant.readOnly, isFalse);
      c.dispose();
    });
  });

  group('pantallas', () {
    testWidgets('B22: lista con Equipo y Huéspedes para la supervisora', (tester) async {
      _phone(tester);
      final harness = Harness(now: DateTime.now());
      late ProviderContainer c;
      await tester.runAsync(() async => c = await signedIn(harness, 'sofia@argos.demo'));
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const MaterialApp(home: ChatListPage())));
      await tester.runAsync(() => _settle());
      await tester.pumpAndSettle();
      expect(find.text('Equipo'), findsOneWidget);
      expect(find.text('Huéspedes'), findsOneWidget);
      expect(find.text('Equipo Costa Limpia'), findsOneWidget);

      await tester.tap(find.text('Huéspedes'));
      await tester.runAsync(() => _settle());
      await tester.pumpAndSettle();
      expect(find.text('Tomás Reyes'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });

    testWidgets('B23: burbujas por día y enviar un mensaje', (tester) async {
      _phone(tester);
      final harness = Harness(now: DateTime.now());
      late ProviderContainer c;
      await tester.runAsync(() async => c = await signedIn(harness, 'ana@argos.demo'));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: ChatThreadPage(id: 'c-ana-luis')),
        ),
      );
      await tester.runAsync(() => _settle());
      await tester.pumpAndSettle();
      expect(find.text('Luis Pérez'), findsOneWidget);
      expect(find.byType(ChatBubble), findsNWidgets(3));
      expect(find.byType(ChatDayDivider), findsWidgets);

      await tester.enterText(find.byType(TextField), 'Perfecto, gracias');
      await tester.pump();
      await tester.tap(find.byIcon(CustomIcons.send));
      await tester.runAsync(() => _settle());
      await tester.pumpAndSettle();
      expect(find.text('Perfecto, gracias'), findsOneWidget);
      expect(find.byType(ChatBubble), findsNWidgets(4));
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });

    testWidgets('F8: el huésped escribe a la empresa (sin cámara)', (tester) async {
      _phone(tester);
      final harness = Harness(now: DateTime.now());
      late ProviderContainer c;
      await tester.runAsync(() async => c = await _tomas(harness));
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const MaterialApp(home: GuestChatPage())),
      );
      await tester.runAsync(() => _settle());
      await tester.pumpAndSettle();
      expect(find.text('Costa Limpia S.A.'), findsOneWidget);
      expect(find.textContaining('toallas extra'), findsOneWidget);
      expect(find.byIcon(CustomIcons.camera), findsNothing);
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });

    testWidgets('F1: código de la puerta y acceso al chat', (tester) async {
      tester.view.physicalSize = const Size(800, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final harness = Harness();
      late ProviderContainer c;
      await tester.runAsync(() async => c = await _tomas(harness));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(home: GuestHomePage(now: harness.clock.now())),
        ),
      );
      await tester.runAsync(() => _settle());
      await tester.pumpAndSettle();
      expect(find.text('Código · Puerta principal'), findsOneWidget);
      expect(find.text('7 3 0 5 1 9'), findsOneWidget);
      expect(find.text('Escribir a la empresa'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _close(tester, c);
    });
  });
}
