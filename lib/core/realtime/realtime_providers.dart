import 'dart:async';

import 'package:argos_app/core/config/app_config.dart';
import 'package:argos_app/core/network/access_token_source.dart';
import 'package:argos_app/core/network/connectivity_service.dart';
import 'package:argos_app/core/realtime/realtime_client.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'realtime_providers.g.dart';

@Riverpod(keepAlive: true)
RealtimeClient realtimeClient(Ref ref) {
  final config = ref.watch(appConfigProvider);
  final tokens = ref.watch(sessionTokensProvider);
  final RealtimeClient client = config.useMock
      ? MockRealtimeClient(mockRealtimeBus)
      : SocketRealtimeClient(
          url: realtimeUrl(config.apiBaseUrl),
          token: () => tokens.accessToken,
          renewToken: tokens.renewAccessToken,
        );
  ref.onDispose(client.dispose);
  return client;
}

/// Mensajes del canal (todas las features escuchan aquí).
@Riverpod(keepAlive: true)
Stream<RealtimeMessage> realtimeMessages(Ref ref) =>
    ref.watch(realtimeClientProvider).messages;

/// Conecta el canal mientras hay sesión en línea y la app está al frente;
/// lo cierra en segundo plano (ahí llegan los push).
@Riverpod(keepAlive: true)
void realtimeRunner(Ref ref) {
  final client = ref.watch(realtimeClientProvider);
  var foreground = true;

  void update() {
    final auth = ref.read(sessionControllerProvider);
    if (foreground && auth is AuthSignedIn && !auth.offline) {
      client.connect();
    } else {
      client.disconnect();
    }
  }

  ref.listen(sessionControllerProvider, (_, _) => update());
  final network = ref.watch(connectivityServiceProvider).watch().listen((up) {
    if (up) update();
  });
  final lifecycle = AppLifecycleListener(
    onResume: () {
      foreground = true;
      update();
    },
    onPause: () {
      foreground = false;
      update();
    },
  );
  ref.onDispose(() {
    network.cancel();
    lifecycle.dispose();
    client.disconnect();
  });
  update();
}
