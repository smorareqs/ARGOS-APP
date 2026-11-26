import 'dart:async';

import 'package:argos_app/core/outbox/outbox_providers.dart';
import 'package:argos_app/core/push/push_providers.dart';
import 'package:argos_app/core/realtime/realtime_providers.dart';
import 'package:argos_app/core/router/app_links.dart';
import 'package:argos_app/core/router/app_router.dart';
import 'package:argos_app/core/theme/app_theme.dart';
import 'package:argos_app/features/notifications/models/app_notification.dart';
import 'package:argos_app/features/notifications/presentation/providers/inbox_controller.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Para mostrar avisos que llegan mientras la app está abierta.
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

class ArgosApp extends ConsumerStatefulWidget {
  const ArgosApp({super.key});

  @override
  ConsumerState<ArgosApp> createState() => _ArgosAppState();
}

class _ArgosAppState extends ConsumerState<ArgosApp> {
  StreamSubscription<AppNotification>? _arrivals;

  @override
  void initState() {
    super.initState();
    _arrivals = ref.read(inboxProvider.notifier).arrivals.listen(_show);
  }

  @override
  void dispose() {
    _arrivals?.cancel();
    super.dispose();
  }

  void _show(AppNotification n) {
    final route = n.appRoute;
    final messenger = appMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (n.body.isNotEmpty) Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          action: route == null || !isAppRouteAvailable(route)
              ? null
              : SnackBarAction(
                  label: 'Ver',
                  onPressed: () {
                    ref.read(inboxProvider.notifier).markRead(n.id);
                    ref.read(appRouterProvider).push(route == '/alerts' ? '/notifications' : route);
                  },
                ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    // Cola de subida de fotos activa mientras la app está abierta.
    ref.watch(uploadQueueRunnerProvider);
    // Cambios hechos sin conexión (checklist, inicio, cierre…).
    ref.watch(outboxRunnerProvider);
    // Avisos al instante (WebSocket) y push del teléfono.
    ref.watch(realtimeRunnerProvider);
    ref.watch(pushRunnerProvider);

    return MaterialApp.router(
      title: 'ARGOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scaffoldMessengerKey: appMessengerKey,
      routerConfig: router,
    );
  }
}
