import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/notifications/data/notifications_repository.dart';
import 'package:argos_app/features/tickets/data/tickets_repository.dart';
import 'package:argos_app/features/tickets/models/ticket.dart';
import 'package:argos_app/features/tickets/presentation/pages/report_ticket_page.dart';
import 'package:argos_app/features/tickets/presentation/pages/ticket_detail_page.dart';
import 'package:argos_app/features/tickets/presentation/pages/tickets_page.dart';
import 'package:argos_app/features/tickets/presentation/widgets/ticket_card.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/harness.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> as(Harness harness, String email) async {
    final container = harness.container();
    await booted(container);
    await container.read(sessionControllerProvider.notifier).login(email, demoPassword);
    container.read(sessionControllerProvider.notifier).finishQuickUnlockOffer();
    return container;
  }

  test('reportar, iniciar y resolver; quien reportó recibe el aviso', () async {
    final harness = Harness();
    final ana = await as(harness, 'ana@argos.demo');
    final repo = ana.read(ticketsRepositoryProvider);
    final props = await repo.properties();
    final assets = await repo.assets(props.first.id);
    expect(assets, isNotEmpty);
    final created = await repo.create(
      propertyId: props.first.id,
      assetId: assets.first.id,
      title: 'Llave del lavamanos gotea',
      urgency: 'high',
    );
    expect(created.ticket.number, 44);
    expect(created.ticket.status, TicketStatus.open);
    expect(created.events.single.type, 'created');
    final mine = await repo.list();
    expect(mine.map((t) => t.id), contains(created.ticket.id));

    // Mantenimiento: sus asignadas, la más urgente primero.
    final luis = await as(harness, 'luis@argos.demo');
    final lrepo = luis.read(ticketsRepositoryProvider);
    final assigned = sortByUrgency(await lrepo.list(mine: true));
    expect(assigned.first.urgency, Urgency.critical);
    expect(assigned.every((t) => t.assigneeName == 'Luis Pérez'), isTrue);

    final started = await lrepo.start(created.ticket.id);
    expect(started.ticket.status, TicketStatus.inProgress);
    final resolved = await lrepo.resolve(created.ticket.id, resolution: 'Cambié el empaque.', cost: 45);
    expect(resolved.ticket.status, TicketStatus.resolved);
    expect(resolved.events.last.type, 'resolved');

    final (inbox, _) = await ana.read(notificationsRepositoryProvider).list();
    expect(inbox.items.first.type, 'ticket_resolved');
    expect(inbox.items.first.appRoute, '/tickets/${created.ticket.id}');
  });

  testWidgets('B12, B13 y B14 se dibujan', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final harness = Harness();
    late ProviderContainer container;
    await tester.runAsync(() async {
      container = await as(harness, 'luis@argos.demo');
    });

    Future<void> show(Widget page) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: MaterialApp(home: page)),
      );
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await show(const TicketsPage());
    expect(find.byType(TicketCard), findsNWidgets(2));
    expect(find.text('Aire acondicionado no enfría'), findsOneWidget);

    await show(const TicketDetailPage(ticketId: 'tk-42'));
    expect(find.text('Resolver'), findsOneWidget);
    expect(find.text('LO REPORTADO'), findsOneWidget);

    await show(const TicketDetailPage(ticketId: 'tk-41'));
    expect(find.text('Iniciar'), findsOneWidget);

    await show(const ReportTicketPage(propertyId: 'prop-lau-01', propertyLabel: 'LAU-01 · Casa Laurel'));
    expect(find.text('Reportar incidencia'), findsOneWidget);
    expect(find.text('LAU-01 · Casa Laurel'), findsOneWidget);
    expect(find.byType(UrgencySelector), findsOneWidget);
    expect(find.text('Qué está fallando (opcional)'.toUpperCase()), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
