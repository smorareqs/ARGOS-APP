import 'package:argos_app/core/realtime/realtime_client.dart';
import 'package:argos_app/core/realtime/realtime_providers.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/notifications/data/notifications_repository.dart';
import 'package:argos_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:argos_app/features/notifications/presentation/providers/inbox_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/harness.dart';

Future<ProviderContainer> signedIn(Harness harness, String email) async {
  final container = harness.container();
  await booted(container);
  final session = container.read(sessionControllerProvider.notifier);
  await session.login(email, demoPassword);
  if (container.read(sessionControllerProvider) case AuthChoosingTenant(:final memberships)) {
    await session.chooseTenant(memberships.first.tenantId, remember: false);
  }
  session.finishQuickUnlockOffer();
  return container;
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('la bandeja se carga, recibe avisos al instante y se marca leída', () async {
    final harness = Harness();
    final container = await signedIn(harness, 'ana@argos.demo');
    container.read(realtimeClientProvider).connect();
    final sub = container.listen(inboxProvider, (_, _) {});
    addTearDown(sub.close);

    final first = await container.read(inboxProvider.future);
    expect(first.items, isNotEmpty);
    expect(first.unread, 2);
    expect(first.items.first.appRoute, startsWith('/tasks/'));

    // Llega un aviso por tiempo real: arriba y suma a los sin leer.
    mockRealtimeBus.add(
      RealtimeMessage('notification', {
        'id': 'ntf-live',
        'type': 'task_rescheduled',
        'title': 'Cambió tu tarea',
        'body': 'Ahora a las 13:30',
        'data': {'app_route': '/tasks/x'},
        'read_at': null,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    await settle();
    var state = container.read(inboxProvider).value!;
    expect(state.items.first.id, 'ntf-live');
    expect(state.unread, 3);
    expect(container.read(unreadNotificationsProvider), 3);

    // Repetido no se duplica.
    mockRealtimeBus.add(RealtimeMessage('notification', {'id': 'ntf-live', 'type': 'x', 'title': 'x', 'created_at': '2026-01-01T00:00:00Z'}));
    await settle();
    expect(container.read(inboxProvider).value!.unread, 3);

    final target = state.items.firstWhere((n) => n.unread && n.id != 'ntf-live');
    await container.read(inboxProvider.notifier).markRead(target.id);
    state = container.read(inboxProvider).value!;
    expect(state.unread, 2);

    // Leído en otro dispositivo (la web): llega por el canal.
    mockRealtimeBus.add(const RealtimeMessage('notification.read', {'all': true}));
    await settle();
    expect(container.read(inboxProvider).value!.unread, 0);

    // "Marcar todas" llega al servidor.
    mockRealtimeBus.add(
      RealtimeMessage('notification', {
        'id': 'ntf-live-2',
        'type': 'task_assigned',
        'title': 'Nueva tarea',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    await settle();
    expect(container.read(inboxProvider).value!.unread, 1);
    await container.read(inboxProvider.notifier).markAllRead();
    final (page, _) = await container.read(notificationsRepositoryProvider).list();
    expect(page.unread, 0);
  });

  test('preferencias: lo crítico no se apaga', () async {
    final harness = Harness();
    final container = await signedIn(harness, 'ana@argos.demo');
    final repo = container.read(notificationsRepositoryProvider);
    final prefs = await repo.preferences();
    final changed = [
      for (final p in prefs) p.copyWith(push: false, email: false),
    ];
    final saved = await repo.savePreferences(changed);
    expect(saved.firstWhere((p) => p.type == 'task_assigned').push, isTrue);
    expect(saved.firstWhere((p) => p.type == 'task_reminder').push, isFalse);
    expect(saved.firstWhere((p) => p.type == 'task_reminder').email, isFalse);
  });

  testWidgets('B16 y C4 se dibujan', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final harness = Harness();
    late ProviderContainer container;
    await tester.runAsync(() async {
      container = await signedIn(harness, 'sofia@argos.demo');
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MaterialApp(home: NotificationsPage())),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(settle);
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Alertas'), findsOneWidget);
    expect(find.text('Panel'), findsOneWidget);
    expect(find.text('Reconocer'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Marcar todas'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pump();
    expect(find.text('Marcar todas'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Limpieza de salida terminada'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pump();
    expect(find.byType(NotificationTile), findsWidgets);
    await tester.scrollUntilVisible(find.text('Marcar todas'), -300, scrollable: find.byType(Scrollable).first);
    await tester.pump();

    await tester.tap(find.text('Marcar todas'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(settle);
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Estás al día'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
