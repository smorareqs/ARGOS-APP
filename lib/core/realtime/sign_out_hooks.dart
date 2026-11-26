import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_out_hooks.g.dart';

/// Lo que debe correr con el token todavía vigente antes de cerrar sesión
/// (p. ej. quitar el teléfono de los avisos push). Cada paso tiene 3 s; si
/// falla, se cierra sesión igual.
class SignOutHooks {
  final _hooks = <Future<void> Function()>[];

  void add(Future<void> Function() hook) => _hooks.add(hook);

  void remove(Future<void> Function() hook) => _hooks.remove(hook);

  Future<void> run() async {
    for (final hook in List.of(_hooks)) {
      try {
        await hook().timeout(const Duration(seconds: 3));
      } catch (_) {
        // Cerrar sesión no espera a la red.
      }
    }
  }
}

@Riverpod(keepAlive: true)
SignOutHooks signOutHooks(Ref ref) => SignOutHooks();
