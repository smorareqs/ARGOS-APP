import 'dart:async';

import 'package:argos_app/core/config/app_config.dart';
import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/core/network/connectivity_service.dart';
import 'package:argos_app/core/network/mock/mock_backend.dart';
import 'package:argos_app/core/network/mock/mock_routes.dart';
import 'package:argos_app/features/chat/data/mock/chat_mock_routes.dart';
import 'package:argos_app/features/auth/data/datasources/biometric_datasource.dart';
import 'package:argos_app/features/auth/data/mock/auth_mock_routes.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/hospitality/data/mock/hospitality_mock_routes.dart';
import 'package:argos_app/features/hr/data/mock/hr_mock_routes.dart';
import 'package:argos_app/features/notifications/data/mock/notifications_mock_routes.dart';
import 'package:argos_app/features/tasks/data/mock/tasks_mock_routes.dart';
import 'package:argos_app/features/tickets/data/mock/tickets_mock_routes.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reloj controlable para el backend simulado (vencimiento de tokens).
class TestClock {
  TestClock(this.current);

  DateTime current;

  DateTime now() => current;

  void advance(Duration duration) => current = current.add(duration);
}

class FakeBiometrics implements BiometricDataSource {
  FakeBiometrics({this.available = false, this.succeeds = true});

  bool available;
  bool succeeds;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return available && succeeds;
  }
}

class FakeConnectivity implements ConnectivityService {
  FakeConnectivity({this.online = true});

  bool online;
  final _changes = StreamController<bool>.broadcast();

  void set(bool value) {
    online = value;
    _changes.add(value);
  }

  @override
  Future<bool> hasConnection() async => online;

  @override
  Stream<bool> watch() => _changes.stream;
}

/// La app real (repositorios, Dio, interceptor, Drift en memoria) contra el
/// backend simulado, con biometría y red controlables.
class Harness {
  Harness({
    Map<String, String> storage = const {},
    bool biometricAvailable = false,
    bool online = true,
    DateTime? now,
  }) : clock = TestClock(now ?? DateTime(2026, 10, 22, 9)),
       backend = MockBackend(latency: Duration.zero),
       biometrics = FakeBiometrics(available: biometricAvailable),
       connectivity = FakeConnectivity(online: online) {
    FlutterSecureStorage.setMockInitialValues(Map.of(storage));
    registerAuthMockRoutes(backend, clock: clock.now);
    registerTasksMockRoutes(backend, clock: clock.now);
    registerNotificationsMockRoutes(backend, clock: clock.now, liveDemo: false);
    registerTicketsMockRoutes(backend, clock: clock.now);
    registerHospitalityMockRoutes(backend, clock: clock.now);
    registerHrMockRoutes(backend, clock: clock.now);
    registerChatMockRoutes(backend, clock: clock.now, liveDemo: false);
  }

  final TestClock clock;
  final MockBackend backend;
  final FakeBiometrics biometrics;
  final FakeConnectivity connectivity;

  List<Override> get overrides => [
    appConfigProvider.overrideWithValue(
      const AppConfig(apiBaseUrl: 'http://argos.test/api/v1', useMock: true),
    ),
    mockBackendProvider.overrideWithValue(backend),
    appDatabaseProvider.overrideWith((ref) {
      final db = AppDatabase(NativeDatabase.memory());
      ref.onDispose(db.close);
      return db;
    }),
    biometricDataSourceProvider.overrideWithValue(biometrics),
    connectivityServiceProvider.overrideWithValue(connectivity),
  ];

  ProviderContainer container() {
    final c = ProviderContainer(overrides: overrides);
    addTearDown(c.dispose);
    return c;
  }
}

/// Espera a que el estado de la sesión cumpla [predicate].
Future<AuthState> waitForState(
  ProviderContainer container,
  bool Function(AuthState state) predicate, {
  Duration timeout = const Duration(seconds: 5),
}) {
  final current = container.read(sessionControllerProvider);
  if (predicate(current)) return Future.value(current);
  final completer = Completer<AuthState>();
  final sub = container.listen<AuthState>(sessionControllerProvider, (_, next) {
    if (predicate(next) && !completer.isCompleted) completer.complete(next);
  });
  return completer.future.timeout(timeout).whenComplete(sub.close);
}

/// Espera a que termine el arranque (A1).
Future<AuthState> booted(ProviderContainer container) =>
    waitForState(container, (s) => s is! AuthBooting);

const demoPassword = mockDemoPassword;
