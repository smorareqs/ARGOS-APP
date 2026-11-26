import 'package:argos_app/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_service.g.dart';

/// Un punto GPS.
class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;
}

/// Por qué no se pudo leer la ubicación (mensaje listo para la persona).
class LocationException implements Exception {
  const LocationException(this.message, {this.openSettings = false});

  final String message;

  /// true: el permiso quedó negado para siempre; hay que ir a Ajustes.
  final bool openSettings;

  @override
  String toString() => message;
}

/// GPS para iniciar y cerrar tareas (fase02 §3: "Iniciar tarea: requiere
/// GPS"). En modo simulado, si el emulador no da ubicación, usa un punto fijo
/// para poder probar el flujo.
class LocationService {
  LocationService({required this.simulated});

  final bool simulated;

  static const _fallback = GeoPoint(14.5986, -90.5094);

  Future<GeoPoint> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (simulated) return _fallback;
        throw const LocationException('Activa la ubicación del teléfono para continuar.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (simulated) return _fallback;
        throw const LocationException(
          'ARGOS no tiene permiso de ubicación. Actívalo en Ajustes para iniciar y cerrar tareas.',
          openSettings: true,
        );
      }
      if (permission == LocationPermission.denied) {
        if (simulated) return _fallback;
        throw const LocationException('Necesitamos tu ubicación para registrar el inicio y el cierre.');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GeoPoint(pos.latitude, pos.longitude);
    } on LocationException {
      rethrow;
    } catch (_) {
      if (simulated) return _fallback;
      final last = await Geolocator.getLastKnownPosition().catchError((_) => null);
      if (last != null) return GeoPoint(last.latitude, last.longitude);
      throw const LocationException('No pudimos leer tu ubicación. Sal a un lugar abierto e intenta de nuevo.');
    }
  }

  Future<void> openSettings() => Geolocator.openAppSettings();
}

@Riverpod(keepAlive: true)
LocationService locationService(Ref ref) =>
    LocationService(simulated: ref.watch(appConfigProvider).useMock);
