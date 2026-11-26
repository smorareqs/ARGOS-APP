import 'package:argos_app/core/outbox/outbox_providers.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/tasks/data/repositories/tasks_repository.dart';
import 'package:argos_app/features/tasks/models/task_summary.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/harness.dart';

void main() {
  late Harness harness;
  late ProviderContainer container;

  setUp(() async {
    harness = Harness();
    container = harness.container();
    await booted(container);
    await container.read(sessionControllerProvider.notifier).login('ana@argos.demo', demoPassword);
    container.read(sessionControllerProvider.notifier).finishQuickUnlockOffer();
  });

  test('el checklist se marca sin conexión y se envía al volver la red', () async {
    final repo = container.read(tasksRepositoryProvider);
    final outbox = container.read(outboxProvider);
    final agenda = await repo.agenda(harness.clock.now());
    final running = agenda.tasks.firstWhere((t) => t.status == TaskStatus.inProgress);

    var task = (await repo.detail(running.id)).task;
    expect(task.canExecute, isTrue);
    final item = task.items.firstWhere((i) => !i.isDone && !i.needsPhotos);

    harness.backend.offline = true;
    task = await repo.setItem(task, item.id, isDone: true);
    expect(task.items.firstWhere((i) => i.id == item.id).isDone, isTrue);
    expect(await outbox.pendingFor(TasksRepository.entityKey(task.id)), hasLength(1));

    // Sin red: la copia guardada ya trae el cambio y la agenda la marca.
    final offline = await repo.detail(task.id);
    expect(offline.cachedAt, isNotNull);
    expect(offline.task.items.firstWhere((i) => i.id == item.id).isDone, isTrue);
    expect((await repo.agenda(harness.clock.now())).unsynced, contains(task.id));

    harness.backend.offline = false;
    await outbox.process();
    expect(await outbox.pendingFor(TasksRepository.entityKey(task.id)), isEmpty);
    final fresh = await repo.detail(task.id);
    expect(fresh.cachedAt, isNull);
    expect(fresh.task.items.firstWhere((i) => i.id == item.id).isDone, isTrue);
  });

  test('cerrar sin las fotos queda en error con el motivo del servidor', () async {
    final repo = container.read(tasksRepositoryProvider);
    final outbox = container.read(outboxProvider);
    final agenda = await repo.agenda(harness.clock.now());
    final running = agenda.tasks.firstWhere((t) => t.status == TaskStatus.inProgress);
    var task = (await repo.detail(running.id)).task;
    for (final i in task.items) {
      task = await repo.setItem(task, i.id, isDone: true);
    }
    task = await repo.complete(
      task,
      lat: 9.9,
      lng: -84.1,
      custody: [
        for (final c in task.custody)
          CustodyReturn(itemId: c.itemId, returned: 0, consumed: 0, kept: c.quantity),
      ],
    );
    // En el teléfono ya se ve terminada.
    expect(task.summary.status, TaskStatus.done);

    await outbox.process();
    final summary = await outbox.watchSummary().first;
    expect(summary.failed, 1);
    final rows = await outbox.watchAll().first;
    expect(rows.single.lastError, contains('fotos'));
    // El servidor la sigue teniendo en curso.
    expect((await repo.detail(task.id)).task.summary.status, TaskStatus.inProgress);
  });

  test('applyLocal descuenta los insumos de la custodia', () {
    final json = <String, dynamic>{
      'id': 't1',
      'status': 'in_progress',
      'items': <Object>[],
      'custody': [
        {'item_id': 'jab', 'name': 'Jabón', 'unit': 'unidad', 'quantity': 10, 'returnable': false},
      ],
      'consumption': <Object>[],
      'timeline': <Object>[],
    };
    final out = applyLocal(json, 'POST', '/tasks/t1/consumptions', {
      'items': [
        {'item_id': 'jab', 'quantity': 4},
      ],
    }, DateTime(2026, 10, 22, 10));
    expect((out['custody'] as List).single['quantity'], 6);
    expect((out['consumption'] as List).single['qty'], 4);
    expect((out['timeline'] as List).single['type'], 'consumption');
  });
}
