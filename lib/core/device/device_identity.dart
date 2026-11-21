import 'package:argos_app/core/storage/secure_storage_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'device_identity.g.dart';

/// Identidad del dispositivo que se envía al iniciar sesión: el backend liga
/// cada refresh token a ella y la muestra en "Sesiones activas".
class DeviceIdentity {
  const DeviceIdentity({
    required this.id,
    required this.platform,
    this.name,
  });

  final String id;

  /// `android`, `ios` o `web`.
  final String platform;

  /// Nombre legible, p. ej. "Samsung SM-A245M" o "iPhone de Ana".
  final String? name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'platform': platform};
}

class DeviceIdentityService {
  DeviceIdentityService(this._storage, this._deviceInfo);

  final SecureStorageService _storage;
  final DeviceInfoPlugin _deviceInfo;
  DeviceIdentity? _cached;

  Future<DeviceIdentity> current() async {
    final cached = _cached;
    if (cached != null) return cached;

    var id = await _storage.readDeviceId();
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await _storage.writeDeviceId(id);
    }
    return _cached = DeviceIdentity(
      id: id,
      platform: _platform(),
      name: await _deviceName(),
    );
  }

  String _platform() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  Future<String?> _deviceName() async {
    try {
      if (kIsWeb) return null;
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await _deviceInfo.androidInfo;
          final brand = info.manufacturer.isEmpty
              ? ''
              : '${info.manufacturer[0].toUpperCase()}${info.manufacturer.substring(1)} ';
          return '$brand${info.model}'.trim();
        case TargetPlatform.iOS:
          return (await _deviceInfo.iosInfo).name;
        default:
          return null;
      }
    } catch (_) {
      // Sin el plugin (pruebas, escritorio) el nombre es opcional.
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
DeviceIdentityService deviceIdentityService(Ref ref) {
  return DeviceIdentityService(
    ref.watch(secureStorageServiceProvider),
    DeviceInfoPlugin(),
  );
}

/// Versión de la app para el pie del login y "Acerca de" (p. ej. "1.0.0").
@Riverpod(keepAlive: true)
Future<String> appVersion(Ref ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  } catch (_) {
    return '';
  }
}
