import 'package:argos_app/core/router/app_router.dart';
import 'package:argos_app/core/theme/app_theme.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ArgosApp extends ConsumerWidget {
  const ArgosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Cola de subida de fotos activa mientras la app está abierta.
    ref.watch(uploadQueueRunnerProvider);

    return MaterialApp.router(
      title: 'ARGOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
