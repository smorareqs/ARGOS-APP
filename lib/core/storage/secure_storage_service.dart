import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_service.g.dart';

class SecureStorageService {
  SecureStorageService(this._storage);

  static const _sessionTokenKey = 'session_token';
  static const _deviceSerialKey = 'device_serial';
  static const _lastSyncKey = 'fecha_ultimo_sync';

  final FlutterSecureStorage _storage;

  Future<String?> readSessionToken() => _storage.read(key: _sessionTokenKey);

  Future<void> writeSessionToken(String token) =>
      _storage.write(key: _sessionTokenKey, value: token);

  Future<void> deleteSessionToken() => _storage.delete(key: _sessionTokenKey);

  Future<String?> readDeviceSerial() => _storage.read(key: _deviceSerialKey);

  Future<void> writeDeviceSerial(String serial) =>
      _storage.write(key: _deviceSerialKey, value: serial);

  Future<String?> readLastSyncDate() => _storage.read(key: _lastSyncKey);

  Future<void> writeLastSyncDate(String isoDate) =>
      _storage.write(key: _lastSyncKey, value: isoDate);

  Future<void> clearAll() => _storage.deleteAll();
}

@Riverpod(keepAlive: true)
SecureStorageService secureStorageService(Ref ref) {
  return SecureStorageService(const FlutterSecureStorage());
}
