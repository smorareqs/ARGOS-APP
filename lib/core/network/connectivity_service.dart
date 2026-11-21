import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

/// Estado de la red del dispositivo. Solo indica si hay una interfaz
/// conectada; si el servidor responde o no lo dice la propia petición.
class ConnectivityService {
  ConnectivityService(this._connectivity);

  final Connectivity _connectivity;

  Future<bool> hasConnection() async {
    try {
      return _isOnline(await _connectivity.checkConnectivity());
    } catch (_) {
      // Si el plugin falla se asume conexión: la petición dirá la verdad.
      return true;
    }
  }

  /// Emite cada cambio de conexión (sin repetidos).
  Stream<bool> watch() =>
      _connectivity.onConnectivityChanged.map(_isOnline).distinct();

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}

@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) {
  return ConnectivityService(Connectivity());
}
