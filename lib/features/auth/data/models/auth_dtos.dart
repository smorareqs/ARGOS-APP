import 'package:argos_app/features/auth/models/account.dart';
import 'package:argos_app/features/auth/models/session.dart';

// Mapeo JSON ↔ entidades del contrato de fase01.md §3.7.1.

/// Par de tokens emitido por login, select-tenant y refresh.
class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    expiresIn: Duration(seconds: (json['expires_in'] as num?)?.toInt() ?? 900),
  );

  final String accessToken;
  final String refreshToken;
  final Duration expiresIn;
}

/// "Respuesta de sesión": tokens o, con varias empresas, token de selección.
class LoginResponse {
  const LoginResponse({
    required this.memberships,
    this.tokens,
    this.selectionToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final memberships = [
      for (final m in (json['memberships'] as List? ?? const []).whereType<Map>())
        membershipFromJson(Map<String, dynamic>.from(m)),
    ];
    if (json['status'] == 'select_tenant') {
      return LoginResponse(
        memberships: memberships,
        selectionToken: json['selection_token'] as String,
      );
    }
    return LoginResponse(
      memberships: memberships,
      tokens: TokenPair.fromJson(json),
    );
  }

  final List<Membership> memberships;
  final TokenPair? tokens;
  final String? selectionToken;
}

Membership membershipFromJson(Map<String, dynamic> json) => Membership(
  tenantId: json['tenant_id'] as String,
  tenantName: json['tenant_name'] as String,
  tenantLogoUrl: json['tenant_logo_url'] as String?,
  roleKey: json['role_key'] as String,
  roleName: json['role_name'] as String,
);

Map<String, dynamic> membershipToJson(Membership m) => {
  'tenant_id': m.tenantId,
  'tenant_name': m.tenantName,
  'tenant_logo_url': m.tenantLogoUrl,
  'role_key': m.roleKey,
  'role_name': m.roleName,
};

/// `GET /auth/me`.
Session sessionFromMeJson(Map<String, dynamic> json) {
  final user = Map<String, dynamic>.from(json['user'] as Map);
  final tenant = Map<String, dynamic>.from(json['tenant'] as Map);
  final role = Map<String, dynamic>.from(json['role'] as Map);
  final features = Map<String, dynamic>.from(tenant['features'] as Map? ?? const {});
  return Session(
    user: SessionUser(
      id: user['id'] as String,
      email: user['email'] as String,
      fullName: user['full_name'] as String,
      totpEnabled: user['totp_enabled'] as bool? ?? false,
    ),
    tenant: ActiveTenant(
      id: tenant['id'] as String,
      name: tenant['name'] as String,
      logoUrl: tenant['logo_url'] as String?,
      timezone: tenant['timezone'] as String? ?? 'America/Guatemala',
      currency: tenant['currency'] as String? ?? 'GTQ',
      features: {for (final e in features.entries) e.key: e.value == true},
      readOnly: tenant['read_only'] == true,
      billingStatus: tenant['billing_status'] as String? ?? 'active',
    ),
    roleKey: role['key'] as String,
    roleName: role['name'] as String,
    permissions: {
      for (final p in json['permissions'] as List? ?? const []) '$p',
    },
    memberships: [
      for (final m in (json['memberships'] as List? ?? const []).whereType<Map>())
        membershipFromJson(Map<String, dynamic>.from(m)),
    ],
  );
}

DeviceSession deviceSessionFromJson(Map<String, dynamic> json) => DeviceSession(
  id: json['id'] as String,
  platform: json['platform'] as String? ?? 'android',
  deviceName: json['device_name'] as String?,
  lastUsedAt: DateTime.parse(json['last_used_at'] as String).toLocal(),
  current: json['current'] as bool? ?? false,
);

InvitationInfo invitationFromJson(Map<String, dynamic> json) => InvitationInfo(
  tenantName: json['tenant_name'] as String,
  roleName: json['role_name'] as String,
  email: json['email'] as String,
  userExists: json['user_exists'] as bool? ?? false,
);
