import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/tasks/data/repositories/tasks_repository.dart';
import 'package:argos_app/features/tasks/models/task_summary.dart';
import 'package:argos_app/features/tasks/presentation/pages/task_close_page.dart';
import 'package:argos_app/features/tasks/presentation/pages/task_detail_page.dart';
import 'package:argos_app/features/tasks/presentation/pages/task_execution_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/harness.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('detalle, ejecución y cierre de la tarea en curso se dibujan', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final harness = Harness();
    final container = harness.container();
    late TaskSummary running;
    await tester.runAsync(() async {
      await booted(container);
      await container.read(sessionControllerProvider.notifier).login('ana@argos.demo', demoPassword);
      container.read(sessionControllerProvider.notifier).finishQuickUnlockOffer();
      final agenda = await container.read(tasksRepositoryProvider).agenda(harness.clock.now());
      running = agenda.tasks.firstWhere((t) => t.status == TaskStatus.inProgress);
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

    await show(TaskDetailPage(taskId: running.id, preview: running));
    expect(find.text(running.property.name), findsWidgets);
    expect(find.text('Continuar'), findsOneWidget);

    await show(TaskExecutionPage(taskId: running.id));
    expect(find.byType(ChecklistItemRow), findsWidgets);
    expect(find.text('Cerrar limpieza'), findsOneWidget);

    await show(TaskClosePage(taskId: running.id));
    expect(find.text('Antes de cerrar'), findsOneWidget);
    expect(find.text('Custodia conciliada'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Tu custodia'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pump();
    expect(find.byType(QuantityRow), findsWidgets);
    expect(find.textContaining('Faltan'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
