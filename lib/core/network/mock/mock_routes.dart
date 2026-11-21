import 'package:argos_app/core/network/mock/mock_backend.dart';
import 'package:argos_app/features/auth/data/mock/auth_mock_routes.dart';
import 'package:argos_app/features/tasks/data/mock/tasks_mock_routes.dart';
import 'package:argos_app/features/uploads/data/mock/files_mock_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mock_routes.g.dart';

/// Backend simulado con las rutas de todas las features.
///
/// Archivo compartido: cada feature agrega una sola línea `register...`
/// (ver reparto.md §2); nunca se reordena.
@Riverpod(keepAlive: true)
MockBackend mockBackend(Ref ref) {
  final backend = MockBackend();
  registerAuthMockRoutes(backend);
  registerFilesMockRoutes(backend);
  registerTasksMockRoutes(backend);
  return backend;
}
