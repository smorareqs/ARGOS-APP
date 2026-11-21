import 'dart:convert';

import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/features/auth/data/models/auth_dtos.dart';
import 'package:argos_app/features/auth/models/session.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_local_datasource.g.dart';

/// Caché local de la sesión (tabla `session_cache`, una sola fila).
class SessionLocalDataSource {
  SessionLocalDataSource(this._db);

  final AppDatabase _db;

  static const _rowId = 1;

  Future<CachedSession?> read() async {
    final row = await (_db.select(
      _db.sessionCache,
    )..where((t) => t.id.equals(_rowId))).getSingleOrNull();
    return row == null ? null : CachedSession(_toSession(row), row.savedAt);
  }

  Future<void> save(Session session) {
    return _db
        .into(_db.sessionCache)
        .insertOnConflictUpdate(
          SessionCacheCompanion.insert(
            id: const Value(_rowId),
            userId: session.user.id,
            email: session.user.email,
            fullName: session.user.fullName,
            totpEnabled: Value(session.user.totpEnabled),
            tenantId: session.tenant.id,
            tenantName: session.tenant.name,
            tenantLogoUrl: Value(session.tenant.logoUrl),
            timezone: session.tenant.timezone,
            currency: session.tenant.currency,
            roleKey: session.roleKey,
            roleName: session.roleName,
            permissionsJson: jsonEncode(session.permissions.toList()),
            featuresJson: jsonEncode(session.tenant.features),
            membershipsJson: jsonEncode(
              session.memberships.map(membershipToJson).toList(),
            ),
            savedAt: DateTime.now(),
          ),
        );
  }

  Future<void> clear() => _db.delete(_db.sessionCache).go();

  static Session _toSession(SessionCacheRow row) {
    final features = Map<String, dynamic>.from(
      jsonDecode(row.featuresJson) as Map,
    );
    return Session(
      user: SessionUser(
        id: row.userId,
        email: row.email,
        fullName: row.fullName,
        totpEnabled: row.totpEnabled,
      ),
      tenant: ActiveTenant(
        id: row.tenantId,
        name: row.tenantName,
        logoUrl: row.tenantLogoUrl,
        timezone: row.timezone,
        currency: row.currency,
        features: {for (final e in features.entries) e.key: e.value == true},
      ),
      roleKey: row.roleKey,
      roleName: row.roleName,
      permissions: {
        for (final p in jsonDecode(row.permissionsJson) as List) '$p',
      },
      memberships: [
        for (final m in (jsonDecode(row.membershipsJson) as List).whereType<Map>())
          membershipFromJson(Map<String, dynamic>.from(m)),
      ],
    );
  }
}

@Riverpod(keepAlive: true)
SessionLocalDataSource sessionLocalDataSource(Ref ref) {
  return SessionLocalDataSource(ref.watch(appDatabaseProvider));
}
