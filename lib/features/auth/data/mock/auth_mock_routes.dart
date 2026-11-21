import 'dart:convert';
import 'dart:math';

import 'package:argos_app/core/network/mock/mock_backend.dart';

/// Contraseña de todos los usuarios de demostración.
const mockDemoPassword = 'argos123';

/// Código TOTP válido para `admin@argos.demo`.
const mockDemoTotp = '123456';

/// Rutas simuladas de autenticación (fase01.md §3.7.1), para trabajar con
/// `--dart-define=ARGOS_MOCK=true` mientras el backend no las tenga.
///
/// Usuarios (contraseña `argos123`):
///
/// | Correo                   | Rol                         | Para probar            |
/// | ------------------------ | --------------------------- | ---------------------- |
/// | `ana@argos.demo`         | cleaner                     | flujo básico           |
/// | `luis@argos.demo`        | maintenance                 | pestañas de mantenim.  |
/// | `sofia@argos.demo`       | supervisor + admin (2 emp.) | elegir empresa (A4)    |
/// | `admin@argos.demo`       | admin con 2FA (`123456`)    | código TOTP (A3)       |
/// | `seguridad@argos.demo`   | security                    | pestañas de seguridad  |
/// | `propietario@argos.demo` | owner                       | pestañas de propietario|
///
/// Invitaciones: `argos://invite?token=demo-nuevo` (cuenta nueva) y
/// `argos://invite?token=demo-existente` (Ana se une a Garrent).
///
/// Cinco contraseñas incorrectas seguidas para un correo devuelven 429.
/// Los tokens describen su propio contenido, así que la sesión sobrevive a
/// reiniciar la app aunque el backend simulado viva en memoria.
void registerAuthMockRoutes(MockBackend backend, {DateTime Function()? clock}) {
  final api = _MockAuthApi(clock ?? DateTime.now);
  backend
    ..on('POST', '/auth/login', api.login)
    ..on('POST', '/auth/select-tenant', api.selectTenant)
    ..on('POST', '/auth/refresh', api.refresh)
    ..on('POST', '/auth/logout', api.logout)
    ..on('GET', '/auth/me', api.me)
    ..on('GET', '/auth/sessions', api.sessions)
    ..on('DELETE', '/auth/sessions/{id}', api.revokeSession)
    ..on('DELETE', '/auth/sessions', api.revokeOtherSessions)
    ..on('POST', '/auth/password/forgot', api.forgotPassword)
    ..on('POST', '/auth/password/change', api.changePassword)
    ..on('GET', '/auth/invitations/{token}', api.invitation)
    ..on('POST', '/auth/invitations/accept', api.acceptInvitation);
}

class _Tenant {
  const _Tenant(this.id, this.name, this.features);

  final String id;
  final String name;
  final Map<String, bool> features;
}

class _User {
  _User(this.id, this.email, this.fullName, this.roles, {this.totp = false});

  final String id;
  final String email;
  final String fullName;

  /// tenantId → clave de rol.
  final Map<String, String> roles;
  final bool totp;
}

class _Invitation {
  const _Invitation(this.tenantId, this.roleKey, this.email);

  final String tenantId;
  final String roleKey;
  final String email;
}

class _DeviceSession {
  _DeviceSession({
    required this.id,
    required this.email,
    required this.platform,
    required this.lastUsedAt,
    this.deviceName,
  });

  final String id;
  final String email;
  final String platform;
  final String? deviceName;
  DateTime lastUsedAt;
}

const _costa = _Tenant('7c1d0f2e-0001-4a51-9a0e-6a3f1c000001', 'Costa Limpia S.A.', {
  'reservations': true,
  'parking': true,
  'shared_areas': true,
  'guest_chat': true,
  'payroll': true,
});

const _garrent = _Tenant('7c1d0f2e-0002-4a51-9a0e-6a3f1c000002', 'Garrent', {
  'reservations': true,
  'parking': false,
  'shared_areas': false,
  'guest_chat': false,
  'payroll': true,
});

const _roleNames = {
  'admin': 'Administrador',
  'supervisor': 'Supervisor',
  'cleaner': 'Colaborador de limpieza',
  'maintenance': 'Colaborador de mantenimiento',
  'security': 'Seguridad',
  'owner': 'Propietario',
};

/// Matriz de permisos por defecto (PRD 3.4).
const _rolePermissions = <String, List<String>>{
  'admin': [
    'tenant.settings', 'tenant.billing', 'users.read', 'users.manage',
    'roles.manage', 'properties.read', 'properties.manage',
    'properties.access_info', 'tasks.read', 'tasks.manage', 'tasks.assign',
    'tasks.execute', 'tasks.validate', 'inventory.read', 'inventory.manage',
    'inventory.checkout', 'inventory.reconcile', 'maintenance.read',
    'maintenance.report', 'maintenance.manage', 'maintenance.assign',
    'maintenance.execute', 'reservations.read', 'reservations.manage',
    'reservations.checkin', 'guests.read', 'guests.manage', 'guests.documents',
    'deposits.read', 'deposits.manage', 'parking.read', 'parking.manage',
    'shared_areas.manage', 'shared_areas.book', 'shared_areas.read',
    'security.dashboard', 'hr.attendance.own', 'hr.attendance.manage',
    'hr.payroll.manage', 'hr.payroll.export', 'hr.disciplinary.manage',
    'metrics.own', 'metrics.team', 'metrics.all', 'alerts.read',
    'alerts.manage', 'chat.internal', 'chat.guest', 'audit.read',
    'reports.export',
  ],
  'supervisor': [
    'users.read', 'properties.read', 'properties.access_info', 'tasks.read',
    'tasks.manage', 'tasks.assign', 'tasks.execute', 'tasks.validate',
    'inventory.read', 'inventory.manage', 'inventory.checkout',
    'inventory.reconcile', 'maintenance.read', 'maintenance.report',
    'maintenance.manage', 'maintenance.assign', 'maintenance.execute',
    'reservations.read', 'reservations.manage', 'reservations.checkin',
    'guests.read', 'deposits.read', 'parking.read', 'parking.manage',
    'shared_areas.read', 'shared_areas.book', 'security.dashboard',
    'hr.attendance.own', 'hr.disciplinary.own', 'metrics.own', 'metrics.team',
    'alerts.read', 'alerts.manage', 'chat.internal', 'chat.guest',
    'audit.read', 'reports.export',
  ],
  'cleaner': [
    'properties.read', 'properties.access_info', 'tasks.read', 'tasks.execute',
    'inventory.read', 'inventory.checkout', 'maintenance.read',
    'maintenance.report', 'hr.attendance.own', 'hr.disciplinary.own',
    'metrics.own', 'chat.internal',
  ],
  'maintenance': [
    'properties.read', 'properties.access_info', 'tasks.read', 'tasks.execute',
    'inventory.read', 'inventory.checkout', 'maintenance.read',
    'maintenance.report', 'maintenance.execute', 'hr.attendance.own',
    'hr.disciplinary.own', 'metrics.own', 'alerts.read', 'chat.internal',
  ],
  'security': [
    'properties.read', 'properties.access_info', 'maintenance.report',
    'reservations.read', 'guests.read', 'parking.read', 'shared_areas.read',
    'security.dashboard', 'hr.attendance.own', 'hr.disciplinary.own',
    'metrics.own', 'alerts.read', 'chat.internal',
  ],
  'owner': [
    'properties.read', 'tasks.read', 'maintenance.read', 'maintenance.report',
    'reservations.read', 'deposits.read', 'metrics.all', 'reports.export',
  ],
};

class _MockAuthApi {
  _MockAuthApi(this._now);

  final DateTime Function() _now;
  final _random = Random();

  static const _accessTtl = Duration(minutes: 15);
  static const _selectionTtl = Duration(minutes: 5);
  static const _maxFailedLogins = 5;

  final _tenants = {for (final t in [_costa, _garrent]) t.id: t};

  final _users = {
    for (final u in [
      _User('u-ana', 'ana@argos.demo', 'Ana López', {_costa.id: 'cleaner'}),
      _User('u-luis', 'luis@argos.demo', 'Luis Pérez', {_costa.id: 'maintenance'}),
      _User('u-sofia', 'sofia@argos.demo', 'Sofía Méndez', {
        _costa.id: 'supervisor',
        _garrent.id: 'admin',
      }),
      _User('u-carlos', 'admin@argos.demo', 'Carlos Rivas', {
        _costa.id: 'admin',
      }, totp: true),
      _User('u-jorge', 'seguridad@argos.demo', 'Jorge Castillo', {
        _costa.id: 'security',
      }),
      _User('u-elena', 'propietario@argos.demo', 'Elena Ruiz', {
        _costa.id: 'owner',
      }),
    ])
      u.email: u,
  };

  final _invitations = {
    'demo-nuevo': _Invitation(_costa.id, 'cleaner', 'nuevo@argos.demo'),
    'demo-existente': _Invitation(_garrent.id, 'cleaner', 'ana@argos.demo'),
  };

  final _failedLogins = <String, int>{};
  final _revokedSessions = <String>{};
  final _sessions = <String, _DeviceSession>{};

  // ── Endpoints ──────────────────────────────────────────

  MockResponse login(MockRequest request) {
    final body = request.json;
    final email = '${body['email'] ?? ''}'.trim().toLowerCase();
    final password = '${body['password'] ?? ''}';
    final totp = body['totp_code'] as String?;

    if ((_failedLogins[email] ?? 0) >= _maxFailedLogins) {
      return MockResponse.problem(
        429,
        'Demasiados intentos fallidos. Espera 15 minutos e intenta de nuevo.',
        headers: {'retry-after': '900'},
      );
    }
    final user = _users[email];
    if (user == null || password != mockDemoPassword) {
      _failedLogins[email] = (_failedLogins[email] ?? 0) + 1;
      return MockResponse.problem(401, 'Correo o contraseña incorrectos.');
    }
    if (user.totp) {
      if (totp == null) {
        return MockResponse.problem(
          428,
          'Ingresa el código de tu app de autenticación.',
        );
      }
      if (totp != mockDemoTotp) {
        return MockResponse.problem(401, 'El código de verificación no es correcto.');
      }
    }
    _failedLogins.remove(email);

    if (user.roles.length > 1) {
      return MockResponse.json({
        'status': 'select_tenant',
        'selection_token': _encode('st', {
          'sub': user.email,
          'exp': _epoch(_now().add(_selectionTtl)),
        }),
        'memberships': _memberships(user),
      });
    }
    return MockResponse.json(
      _openSession(user, user.roles.keys.first, _device(body)),
    );
  }

  MockResponse selectTenant(MockRequest request) {
    final body = request.json;
    final tenantId = '${body['tenant_id'] ?? ''}';

    final selection = _decode('st', body['selection_token'] as String?);
    if (selection != null) {
      final user = _users[selection['sub']];
      if (user == null || _expired(selection)) {
        return MockResponse.problem(401, 'La selección venció. Inicia sesión de nuevo.');
      }
      if (!user.roles.containsKey(tenantId)) {
        return MockResponse.problem(404, 'No perteneces a esa empresa.');
      }
      return MockResponse.json(_openSession(user, tenantId, _device(body)));
    }

    final refresh = _decode('rt', body['refresh_token'] as String?);
    final user = refresh == null ? null : _users[refresh['sub']];
    if (refresh == null || user == null || _revokedSessions.contains(refresh['sid'])) {
      return MockResponse.problem(401, 'Tu sesión fue cerrada. Ingresa de nuevo.');
    }
    if (!user.roles.containsKey(tenantId)) {
      return MockResponse.problem(404, 'No perteneces a esa empresa.');
    }
    return MockResponse.json({
      'status': 'authenticated',
      ..._tokens(user, tenantId, refresh['sid'] as String),
      'memberships': _memberships(user),
    });
  }

  MockResponse refresh(MockRequest request) {
    final claims = _decode('rt', request.json['refresh_token'] as String?);
    final user = claims == null ? null : _users[claims['sub']];
    final sid = claims?['sid'] as String?;
    if (claims == null || user == null || sid == null || _revokedSessions.contains(sid)) {
      return MockResponse.problem(401, 'Tu sesión fue cerrada. Ingresa de nuevo.');
    }
    final tenantId = claims['tid'] as String;
    if (!user.roles.containsKey(tenantId)) {
      return MockResponse.problem(401, 'Ya no tienes acceso a esta empresa.');
    }
    _sessions[sid]?.lastUsedAt = _now();
    return MockResponse.json(_tokens(user, tenantId, sid));
  }

  MockResponse logout(MockRequest request) {
    final claims = _decode('rt', request.json['refresh_token'] as String?);
    final sid = claims?['sid'];
    if (sid is String) _revokedSessions.add(sid);
    return MockResponse.noContent();
  }

  MockResponse me(MockRequest request) {
    final auth = _authenticate(request);
    if (auth == null) return _invalidToken();
    final (user, tenantId, _) = auth;
    final tenant = _tenants[tenantId]!;
    final roleKey = user.roles[tenantId]!;
    return MockResponse.json({
      'user': {
        'id': user.id,
        'email': user.email,
        'full_name': user.fullName,
        'totp_enabled': user.totp,
      },
      'tenant': {
        'id': tenant.id,
        'name': tenant.name,
        'logo_url': null,
        'timezone': 'America/Guatemala',
        'currency': 'GTQ',
        'features': tenant.features,
      },
      'role': {'key': roleKey, 'name': _roleNames[roleKey]},
      'permissions': _rolePermissions[roleKey],
      'memberships': _memberships(user),
    });
  }

  MockResponse sessions(MockRequest request) {
    final auth = _authenticate(request);
    if (auth == null) return _invalidToken();
    final (user, _, sid) = auth;
    final now = _now();
    _sessions.putIfAbsent(
      sid,
      () => _DeviceSession(
        id: sid,
        email: user.email,
        platform: 'android',
        lastUsedAt: now,
      ),
    );
    // Dos dispositivos más para poder probar la revocación.
    for (final demo in [
      _DeviceSession(
        id: 'demo-ios-${user.id}',
        email: user.email,
        platform: 'ios',
        deviceName: 'iPhone de ${user.fullName.split(' ').first}',
        lastUsedAt: now.subtract(const Duration(hours: 2)),
      ),
      _DeviceSession(
        id: 'demo-web-${user.id}',
        email: user.email,
        platform: 'web',
        deviceName: 'Chrome · Windows',
        lastUsedAt: now.subtract(const Duration(days: 3)),
      ),
    ]) {
      _sessions.putIfAbsent(demo.id, () => demo);
    }

    final list = _sessions.values
        .where((s) => s.email == user.email && !_revokedSessions.contains(s.id))
        .toList()
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return MockResponse.json([
      for (final s in list)
        {
          'id': s.id,
          'device_name': s.deviceName,
          'platform': s.platform,
          'last_used_at': s.lastUsedAt.toUtc().toIso8601String(),
          'created_at': s.lastUsedAt.toUtc().toIso8601String(),
          'current': s.id == sid,
        },
    ]);
  }

  MockResponse revokeSession(MockRequest request) {
    final auth = _authenticate(request);
    if (auth == null) return _invalidToken();
    final (user, _, _) = auth;
    final id = request.pathParams['id'];
    final target = _sessions[id];
    if (target == null || target.email != user.email) {
      return MockResponse.problem(404, 'Esa sesión no existe.');
    }
    _revokedSessions.add(target.id);
    return MockResponse.noContent();
  }

  MockResponse revokeOtherSessions(MockRequest request) {
    final auth = _authenticate(request);
    if (auth == null) return _invalidToken();
    final (user, _, sid) = auth;
    for (final s in _sessions.values) {
      if (s.email == user.email && s.id != sid) _revokedSessions.add(s.id);
    }
    return MockResponse.noContent();
  }

  MockResponse forgotPassword(MockRequest request) => const MockResponse(202);

  MockResponse changePassword(MockRequest request) {
    final auth = _authenticate(request);
    if (auth == null) return _invalidToken();
    final body = request.json;
    if (body['current_password'] != mockDemoPassword) {
      return MockResponse.problem(422, 'La contraseña actual no es correcta.');
    }
    if ('${body['new_password'] ?? ''}'.length < 8) {
      return MockResponse.problem(
        422,
        'La nueva contraseña debe tener al menos 8 caracteres.',
      );
    }
    return MockResponse.noContent();
  }

  MockResponse invitation(MockRequest request) {
    final invitation = _invitations[request.pathParams['token']];
    if (invitation == null) {
      return MockResponse.problem(404, 'La invitación venció o ya se usó.');
    }
    return MockResponse.json({
      'tenant_name': _tenants[invitation.tenantId]!.name,
      'role_name': _roleNames[invitation.roleKey],
      'email': invitation.email,
      'user_exists': _users.containsKey(invitation.email),
    });
  }

  MockResponse acceptInvitation(MockRequest request) {
    final body = request.json;
    final token = '${body['token'] ?? ''}';
    final invitation = _invitations[token];
    if (invitation == null) {
      return MockResponse.problem(404, 'La invitación venció o ya se usó.');
    }
    final password = '${body['password'] ?? ''}';
    var user = _users[invitation.email];
    if (user != null) {
      if (password != mockDemoPassword) {
        return MockResponse.problem(401, 'Correo o contraseña incorrectos.');
      }
    } else {
      final fullName = '${body['full_name'] ?? ''}'.trim();
      if (fullName.isEmpty || password.length < 8) {
        return MockResponse.problem(
          422,
          'Escribe tu nombre y una contraseña de al menos 8 caracteres.',
        );
      }
      user = _User('u-${_randomId()}', invitation.email, fullName, {});
      _users[user.email] = user;
    }
    user.roles[invitation.tenantId] = invitation.roleKey;
    _invitations.remove(token);
    return MockResponse.json(_openSession(user, invitation.tenantId, _device(body)));
  }

  // ── Internos ───────────────────────────────────────────

  Map<String, Object?> _openSession(
    _User user,
    String tenantId,
    Map<String, dynamic> device,
  ) {
    final sid = 's-${_randomId()}';
    _sessions[sid] = _DeviceSession(
      id: sid,
      email: user.email,
      platform: '${device['platform'] ?? 'android'}',
      deviceName: device['name'] as String?,
      lastUsedAt: _now(),
    );
    return {
      'status': 'authenticated',
      ..._tokens(user, tenantId, sid),
      'memberships': _memberships(user),
    };
  }

  Map<String, Object?> _tokens(_User user, String tenantId, String sid) => {
    'access_token': _encode('at', {
      'sub': user.email,
      'tid': tenantId,
      'sid': sid,
      'exp': _epoch(_now().add(_accessTtl)),
    }),
    'refresh_token': _encode('rt', {
      'sub': user.email,
      'tid': tenantId,
      'sid': sid,
      'n': _randomId(),
    }),
    'expires_in': _accessTtl.inSeconds,
  };

  List<Map<String, Object?>> _memberships(_User user) => [
    for (final entry in user.roles.entries)
      {
        'tenant_id': entry.key,
        'tenant_name': _tenants[entry.key]!.name,
        'tenant_logo_url': null,
        'role_key': entry.value,
        'role_name': _roleNames[entry.value],
      },
  ];

  /// (usuario, tenant, sesión) del token de acceso, o null si no es válido.
  (_User, String, String)? _authenticate(MockRequest request) {
    final claims = _decode('at', request.bearerToken);
    if (claims == null || _expired(claims)) return null;
    final user = _users[claims['sub']];
    final tenantId = claims['tid'] as String?;
    final sid = claims['sid'] as String?;
    if (user == null || tenantId == null || sid == null) return null;
    if (_revokedSessions.contains(sid) || !user.roles.containsKey(tenantId)) {
      return null;
    }
    return (user, tenantId, sid);
  }

  MockResponse _invalidToken() =>
      MockResponse.problem(401, 'Token inválido o expirado.');

  Map<String, dynamic> _device(Map<String, dynamic> body) =>
      body['device'] is Map ? Map<String, dynamic>.from(body['device'] as Map) : const {};

  bool _expired(Map<String, dynamic> claims) {
    final exp = claims['exp'];
    return exp is! int || exp < _epoch(_now());
  }

  static int _epoch(DateTime time) => time.millisecondsSinceEpoch ~/ 1000;

  String _randomId() =>
      List.generate(12, (_) => _random.nextInt(16).toRadixString(16)).join();

  static String _encode(String kind, Map<String, Object?> claims) {
    final payload = base64Url.encode(utf8.encode(jsonEncode(claims)));
    return 'mock-$kind.${payload.replaceAll('=', '')}';
  }

  static Map<String, dynamic>? _decode(String kind, String? token) {
    final prefix = 'mock-$kind.';
    if (token == null || !token.startsWith(prefix)) return null;
    try {
      final payload = base64Url.normalize(token.substring(prefix.length));
      return Map<String, dynamic>.from(
        jsonDecode(utf8.decode(base64Url.decode(payload))) as Map,
      );
    } catch (_) {
      return null;
    }
  }
}
