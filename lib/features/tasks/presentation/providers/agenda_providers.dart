import 'package:argos_app/features/tasks/data/repositories/tasks_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agenda_providers.g.dart';

/// Agenda de un día (sin hora). Se vuelve a pedir con `ref.refresh`.
@riverpod
Future<DayAgenda> dayAgenda(Ref ref, DateTime date) =>
    ref.watch(tasksRepositoryProvider).agenda(date);
