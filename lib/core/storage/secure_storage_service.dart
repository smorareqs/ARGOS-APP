import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_service.g.dart';

/// Almacenamiento seguro (Keychain / Keystore) de la sesión y del inicio
/// rápido. El token de acceso nunca se guarda aquí: vive solo en memoria.
class SecureStorageService {
  SecureStorageService(this._storage);

  static const _refreshTokenKey = 'refresh_token';
  static const _deviceIdKey = 'device_id';
  static const _pinHashKey = 'pin_hash';
  static const _pinFailuresKey = 'pin_failures';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _quickUnlockDeclinedKey = 'quick_unlock_declined';
  static const _lastTenantKey = 'last_tenant_id';
  static const _rememberTenantKey = 'remember_tenant';
  static const _lastSyncKey = 'fecha_ultimo_sync';
  static const _guestSessionKey = 'guest_session';

  /// Claves del login local anterior (MD5), eliminado en la fase 1.
  static const _legacyKeys = ['session_token', 'device_serial'];

  final FlutterSecureStorage _storage;

  // ── Sesión ─────────────────────────────────────────────
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  /// Identificador del dispositivo: se genera una vez y sobrevive al cierre
  /// de sesión para que el backend reconozca el equipo.
  Future<String?> readDeviceId() => _storage.read(key: _deviceIdKey);

  Future<void> writeDeviceId(String id) =>
      _storage.write(key: _deviceIdKey, value: id);

  // ── Inicio rápido ──────────────────────────────────────
  Future<String?> readPinHash() => _storage.read(key: _pinHashKey);

  Future<void> writePinHash(String hash) =>
      _storage.write(key: _pinHashKey, value: hash);

  Future<void> deletePinHash() => _storage.delete(key: _pinHashKey);

  Future<int> readPinFailures() async =>
      int.tryParse(await _storage.read(key: _pinFailuresKey) ?? '') ?? 0;

  Future<void> writePinFailures(int count) =>
      _storage.write(key: _pinFailuresKey, value: '$count');

  Future<bool> readBiometricEnabled() => _readBool(_biometricEnabledKey);

  Future<void> writeBiometricEnabled(bool enabled) =>
      _writeBool(_biometricEnabledKey, enabled);

  Future<bool> readQuickUnlockDeclined() => _readBool(_quickUnlockDeclinedKey);

  Future<void> writeQuickUnlockDeclined(bool declined) =>
      _writeBool(_quickUnlockDeclinedKey, declined);

  // ── Preferencia de empresa (A4) ────────────────────────
  Future<String?> readLastTenantId() => _storage.read(key: _lastTenantKey);

  Future<void> writeLastTenantId(String tenantId) =>
      _storage.write(key: _lastTenantKey, value: tenantId);

  Future<bool> readRememberTenant() => _readBool(_rememberTenantKey);

  Future<void> writeRememberTenant(bool remember) =>
      _writeBool(_rememberTenantKey, remember);

  // ── Sincronización ─────────────────────────────────────
  Future<String?> readLastSyncDate() => _storage.read(key: _lastSyncKey);

  Future<void> writeLastSyncDate(String isoDate) =>
      _storage.write(key: _lastSyncKey, value: isoDate);

  // ── Modo huésped (A9) ──────────────────────────────────
  /// Sesión del huésped (JSON con el token y su vencimiento). Dura hasta 24 h
  /// después de la salida y no se renueva: es independiente de la del personal.
  Future<String?> readGuestSession() => _storage.read(key: _guestSessionKey);

  Future<void> writeGuestSession(String json) =>
      _storage.write(key: _guestSessionKey, value: json);

  Future<void> deleteGuestSession() => _storage.delete(key: _guestSessionKey);

  /// Borra la sesión y el inicio rápido. Conserva el id del dispositivo y la
  /// preferencia de empresa, que no son datos de sesión.
  Future<void> clearSession() async {
    for (final key in [
      _refreshTokenKey,
      _pinHashKey,
      _pinFailuresKey,
      _biometricEnabledKey,
      _quickUnlockDeclinedKey,
      _lastSyncKey,
      ..._legacyKeys,
    ]) {
      await _storage.delete(key: key);
    }
  }

  Future<bool> _readBool(String key) async =>
      await _storage.read(key: key) == 'true';

  Future<void> _writeBool(String key, bool value) =>
      _storage.write(key: key, value: value ? 'true' : 'false');
}

@Riverpod(keepAlive: true)
SecureStorageService secureStorageService(Ref ref) {
  return SecureStorageService(const FlutterSecureStorage());
}
