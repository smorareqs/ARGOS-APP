/// Usuario autenticado.
class SessionUser {
  const SessionUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.totpEnabled = false,
  });

  final String id;
  final String email;
  final String fullName;
  final bool totpEnabled;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;
}

/// Empresa (tenant) activa en la sesión.
class ActiveTenant {
  const ActiveTenant({
    required this.id,
    required this.name,
    this.logoUrl,
    this.timezone = 'America/Guatemala',
    this.currency = 'GTQ',
    this.features = const {},
    this.readOnly = false,
    this.billingStatus = 'active',
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String timezone;
  final String currency;

  /// Banderas del tenant: `reservations`, `parking`, `shared_areas`…
  final Map<String, bool> features;

  bool hasFeature(String key) => features[key] ?? false;

  /// Pago vencido de más días: la empresa solo puede leer (402 al escribir).
  final bool readOnly;

  /// `trialing`, `active`, `past_due`, `suspended` o `cancelled`.
  final String billingStatus;

  bool get pastDue => billingStatus == 'past_due';
}

/// Membresía del usuario en una empresa, con su rol.
class Membership {
  const Membership({
    required this.tenantId,
    required this.tenantName,
    required this.roleKey,
    required this.roleName,
    this.tenantLogoUrl,
  });

  final String tenantId;
  final String tenantName;
  final String? tenantLogoUrl;
  final String roleKey;
  final String roleName;
}

/// Sesión completa: quién es el usuario, en qué empresa opera, con qué rol y
/// permisos. Es lo que decide qué pantallas existen (PRD 3).
class Session {
  const Session({
    required this.user,
    required this.tenant,
    required this.roleKey,
    required this.roleName,
    required this.permissions,
    this.memberships = const [],
  });

  final SessionUser user;
  final ActiveTenant tenant;
  final String roleKey;
  final String roleName;
  final Set<String> permissions;

  /// Membresías activas del usuario (incluida la actual).
  final List<Membership> memberships;

  bool can(String permission) => permissions.contains(permission);

  bool get hasOtherTenants => memberships.any((m) => m.tenantId != tenant.id);
}

/// Sesión leída de la caché local y cuándo se guardó.
class CachedSession {
  const CachedSession(this.session, this.savedAt);

  final Session session;
  final DateTime savedAt;
}
