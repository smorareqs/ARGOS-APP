import 'dart:async';

import 'package:argos_app/features/tasks/data/repositories/tasks_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agenda_providers.g.dart';

/// Agenda de un día (sin hora): la propia o, con [mine] en false, la de
/// todo el equipo del supervisor. Se vuelve a pedir con `ref.refresh` y
/// sola cuando cambia una tarea.
@riverpod
Future<DayAgenda> dayAgenda(Ref ref, DateTime date, {bool mine = true}) {
  final repo = ref.watch(tasksRepositoryProvider);
  final sub = repo.changes.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return repo.agenda(date, mine: mine);
}
