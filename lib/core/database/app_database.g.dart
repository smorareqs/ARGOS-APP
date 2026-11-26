// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SessionCacheTable extends SessionCache
    with TableInfo<$SessionCacheTable, SessionCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totpEnabledMeta = const VerificationMeta(
    'totpEnabled',
  );
  @override
  late final GeneratedColumn<bool> totpEnabled = GeneratedColumn<bool>(
    'totp_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("totp_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tenantIdMeta = const VerificationMeta(
    'tenantId',
  );
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
    'tenant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantNameMeta = const VerificationMeta(
    'tenantName',
  );
  @override
  late final GeneratedColumn<String> tenantName = GeneratedColumn<String>(
    'tenant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenantLogoUrlMeta = const VerificationMeta(
    'tenantLogoUrl',
  );
  @override
  late final GeneratedColumn<String> tenantLogoUrl = GeneratedColumn<String>(
    'tenant_logo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleKeyMeta = const VerificationMeta(
    'roleKey',
  );
  @override
  late final GeneratedColumn<String> roleKey = GeneratedColumn<String>(
    'role_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleNameMeta = const VerificationMeta(
    'roleName',
  );
  @override
  late final GeneratedColumn<String> roleName = GeneratedColumn<String>(
    'role_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _permissionsJsonMeta = const VerificationMeta(
    'permissionsJson',
  );
  @override
  late final GeneratedColumn<String> permissionsJson = GeneratedColumn<String>(
    'permissions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _featuresJsonMeta = const VerificationMeta(
    'featuresJson',
  );
  @override
  late final GeneratedColumn<String> featuresJson = GeneratedColumn<String>(
    'features_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _membershipsJsonMeta = const VerificationMeta(
    'membershipsJson',
  );
  @override
  late final GeneratedColumn<String> membershipsJson = GeneratedColumn<String>(
    'memberships_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    email,
    fullName,
    totpEnabled,
    tenantId,
    tenantName,
    tenantLogoUrl,
    timezone,
    currency,
    roleKey,
    roleName,
    permissionsJson,
    featuresJson,
    membershipsJson,
    savedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('totp_enabled')) {
      context.handle(
        _totpEnabledMeta,
        totpEnabled.isAcceptableOrUnknown(
          data['totp_enabled']!,
          _totpEnabledMeta,
        ),
      );
    }
    if (data.containsKey('tenant_id')) {
      context.handle(
        _tenantIdMeta,
        tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('tenant_name')) {
      context.handle(
        _tenantNameMeta,
        tenantName.isAcceptableOrUnknown(data['tenant_name']!, _tenantNameMeta),
      );
    } else if (isInserting) {
      context.missing(_tenantNameMeta);
    }
    if (data.containsKey('tenant_logo_url')) {
      context.handle(
        _tenantLogoUrlMeta,
        tenantLogoUrl.isAcceptableOrUnknown(
          data['tenant_logo_url']!,
          _tenantLogoUrlMeta,
        ),
      );
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('role_key')) {
      context.handle(
        _roleKeyMeta,
        roleKey.isAcceptableOrUnknown(data['role_key']!, _roleKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_roleKeyMeta);
    }
    if (data.containsKey('role_name')) {
      context.handle(
        _roleNameMeta,
        roleName.isAcceptableOrUnknown(data['role_name']!, _roleNameMeta),
      );
    } else if (isInserting) {
      context.missing(_roleNameMeta);
    }
    if (data.containsKey('permissions_json')) {
      context.handle(
        _permissionsJsonMeta,
        permissionsJson.isAcceptableOrUnknown(
          data['permissions_json']!,
          _permissionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_permissionsJsonMeta);
    }
    if (data.containsKey('features_json')) {
      context.handle(
        _featuresJsonMeta,
        featuresJson.isAcceptableOrUnknown(
          data['features_json']!,
          _featuresJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_featuresJsonMeta);
    }
    if (data.containsKey('memberships_json')) {
      context.handle(
        _membershipsJsonMeta,
        membershipsJson.isAcceptableOrUnknown(
          data['memberships_json']!,
          _membershipsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_membershipsJsonMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      totpEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}totp_enabled'],
      )!,
      tenantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_id'],
      )!,
      tenantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_name'],
      )!,
      tenantLogoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tenant_logo_url'],
      ),
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      roleKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_key'],
      )!,
      roleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role_name'],
      )!,
      permissionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}permissions_json'],
      )!,
      featuresJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}features_json'],
      )!,
      membershipsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}memberships_json'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $SessionCacheTable createAlias(String alias) {
    return $SessionCacheTable(attachedDatabase, alias);
  }
}

class SessionCacheRow extends DataClass implements Insertable<SessionCacheRow> {
  /// Siempre 1: hay como máximo una sesión en el dispositivo.
  final int id;
  final String userId;
  final String email;
  final String fullName;
  final bool totpEnabled;
  final String tenantId;
  final String tenantName;
  final String? tenantLogoUrl;
  final String timezone;
  final String currency;
  final String roleKey;
  final String roleName;

  /// Lista JSON de permisos.
  final String permissionsJson;

  /// Mapa JSON de banderas del tenant.
  final String featuresJson;

  /// Lista JSON de membresías activas (para "Cambiar de empresa").
  final String membershipsJson;
  final DateTime savedAt;
  const SessionCacheRow({
    required this.id,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.totpEnabled,
    required this.tenantId,
    required this.tenantName,
    this.tenantLogoUrl,
    required this.timezone,
    required this.currency,
    required this.roleKey,
    required this.roleName,
    required this.permissionsJson,
    required this.featuresJson,
    required this.membershipsJson,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['email'] = Variable<String>(email);
    map['full_name'] = Variable<String>(fullName);
    map['totp_enabled'] = Variable<bool>(totpEnabled);
    map['tenant_id'] = Variable<String>(tenantId);
    map['tenant_name'] = Variable<String>(tenantName);
    if (!nullToAbsent || tenantLogoUrl != null) {
      map['tenant_logo_url'] = Variable<String>(tenantLogoUrl);
    }
    map['timezone'] = Variable<String>(timezone);
    map['currency'] = Variable<String>(currency);
    map['role_key'] = Variable<String>(roleKey);
    map['role_name'] = Variable<String>(roleName);
    map['permissions_json'] = Variable<String>(permissionsJson);
    map['features_json'] = Variable<String>(featuresJson);
    map['memberships_json'] = Variable<String>(membershipsJson);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SessionCacheCompanion toCompanion(bool nullToAbsent) {
    return SessionCacheCompanion(
      id: Value(id),
      userId: Value(userId),
      email: Value(email),
      fullName: Value(fullName),
      totpEnabled: Value(totpEnabled),
      tenantId: Value(tenantId),
      tenantName: Value(tenantName),
      tenantLogoUrl: tenantLogoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(tenantLogoUrl),
      timezone: Value(timezone),
      currency: Value(currency),
      roleKey: Value(roleKey),
      roleName: Value(roleName),
      permissionsJson: Value(permissionsJson),
      featuresJson: Value(featuresJson),
      membershipsJson: Value(membershipsJson),
      savedAt: Value(savedAt),
    );
  }

  factory SessionCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionCacheRow(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      email: serializer.fromJson<String>(json['email']),
      fullName: serializer.fromJson<String>(json['fullName']),
      totpEnabled: serializer.fromJson<bool>(json['totpEnabled']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      tenantName: serializer.fromJson<String>(json['tenantName']),
      tenantLogoUrl: serializer.fromJson<String?>(json['tenantLogoUrl']),
      timezone: serializer.fromJson<String>(json['timezone']),
      currency: serializer.fromJson<String>(json['currency']),
      roleKey: serializer.fromJson<String>(json['roleKey']),
      roleName: serializer.fromJson<String>(json['roleName']),
      permissionsJson: serializer.fromJson<String>(json['permissionsJson']),
      featuresJson: serializer.fromJson<String>(json['featuresJson']),
      membershipsJson: serializer.fromJson<String>(json['membershipsJson']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'email': serializer.toJson<String>(email),
      'fullName': serializer.toJson<String>(fullName),
      'totpEnabled': serializer.toJson<bool>(totpEnabled),
      'tenantId': serializer.toJson<String>(tenantId),
      'tenantName': serializer.toJson<String>(tenantName),
      'tenantLogoUrl': serializer.toJson<String?>(tenantLogoUrl),
      'timezone': serializer.toJson<String>(timezone),
      'currency': serializer.toJson<String>(currency),
      'roleKey': serializer.toJson<String>(roleKey),
      'roleName': serializer.toJson<String>(roleName),
      'permissionsJson': serializer.toJson<String>(permissionsJson),
      'featuresJson': serializer.toJson<String>(featuresJson),
      'membershipsJson': serializer.toJson<String>(membershipsJson),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SessionCacheRow copyWith({
    int? id,
    String? userId,
    String? email,
    String? fullName,
    bool? totpEnabled,
    String? tenantId,
    String? tenantName,
    Value<String?> tenantLogoUrl = const Value.absent(),
    String? timezone,
    String? currency,
    String? roleKey,
    String? roleName,
    String? permissionsJson,
    String? featuresJson,
    String? membershipsJson,
    DateTime? savedAt,
  }) => SessionCacheRow(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    email: email ?? this.email,
    fullName: fullName ?? this.fullName,
    totpEnabled: totpEnabled ?? this.totpEnabled,
    tenantId: tenantId ?? this.tenantId,
    tenantName: tenantName ?? this.tenantName,
    tenantLogoUrl: tenantLogoUrl.present
        ? tenantLogoUrl.value
        : this.tenantLogoUrl,
    timezone: timezone ?? this.timezone,
    currency: currency ?? this.currency,
    roleKey: roleKey ?? this.roleKey,
    roleName: roleName ?? this.roleName,
    permissionsJson: permissionsJson ?? this.permissionsJson,
    featuresJson: featuresJson ?? this.featuresJson,
    membershipsJson: membershipsJson ?? this.membershipsJson,
    savedAt: savedAt ?? this.savedAt,
  );
  SessionCacheRow copyWithCompanion(SessionCacheCompanion data) {
    return SessionCacheRow(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      email: data.email.present ? data.email.value : this.email,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      totpEnabled: data.totpEnabled.present
          ? data.totpEnabled.value
          : this.totpEnabled,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      tenantName: data.tenantName.present
          ? data.tenantName.value
          : this.tenantName,
      tenantLogoUrl: data.tenantLogoUrl.present
          ? data.tenantLogoUrl.value
          : this.tenantLogoUrl,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      currency: data.currency.present ? data.currency.value : this.currency,
      roleKey: data.roleKey.present ? data.roleKey.value : this.roleKey,
      roleName: data.roleName.present ? data.roleName.value : this.roleName,
      permissionsJson: data.permissionsJson.present
          ? data.permissionsJson.value
          : this.permissionsJson,
      featuresJson: data.featuresJson.present
          ? data.featuresJson.value
          : this.featuresJson,
      membershipsJson: data.membershipsJson.present
          ? data.membershipsJson.value
          : this.membershipsJson,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionCacheRow(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('totpEnabled: $totpEnabled, ')
          ..write('tenantId: $tenantId, ')
          ..write('tenantName: $tenantName, ')
          ..write('tenantLogoUrl: $tenantLogoUrl, ')
          ..write('timezone: $timezone, ')
          ..write('currency: $currency, ')
          ..write('roleKey: $roleKey, ')
          ..write('roleName: $roleName, ')
          ..write('permissionsJson: $permissionsJson, ')
          ..write('featuresJson: $featuresJson, ')
          ..write('membershipsJson: $membershipsJson, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    email,
    fullName,
    totpEnabled,
    tenantId,
    tenantName,
    tenantLogoUrl,
    timezone,
    currency,
    roleKey,
    roleName,
    permissionsJson,
    featuresJson,
    membershipsJson,
    savedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionCacheRow &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.email == this.email &&
          other.fullName == this.fullName &&
          other.totpEnabled == this.totpEnabled &&
          other.tenantId == this.tenantId &&
          other.tenantName == this.tenantName &&
          other.tenantLogoUrl == this.tenantLogoUrl &&
          other.timezone == this.timezone &&
          other.currency == this.currency &&
          other.roleKey == this.roleKey &&
          other.roleName == this.roleName &&
          other.permissionsJson == this.permissionsJson &&
          other.featuresJson == this.featuresJson &&
          other.membershipsJson == this.membershipsJson &&
          other.savedAt == this.savedAt);
}

class SessionCacheCompanion extends UpdateCompanion<SessionCacheRow> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> email;
  final Value<String> fullName;
  final Value<bool> totpEnabled;
  final Value<String> tenantId;
  final Value<String> tenantName;
  final Value<String?> tenantLogoUrl;
  final Value<String> timezone;
  final Value<String> currency;
  final Value<String> roleKey;
  final Value<String> roleName;
  final Value<String> permissionsJson;
  final Value<String> featuresJson;
  final Value<String> membershipsJson;
  final Value<DateTime> savedAt;
  const SessionCacheCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.email = const Value.absent(),
    this.fullName = const Value.absent(),
    this.totpEnabled = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.tenantName = const Value.absent(),
    this.tenantLogoUrl = const Value.absent(),
    this.timezone = const Value.absent(),
    this.currency = const Value.absent(),
    this.roleKey = const Value.absent(),
    this.roleName = const Value.absent(),
    this.permissionsJson = const Value.absent(),
    this.featuresJson = const Value.absent(),
    this.membershipsJson = const Value.absent(),
    this.savedAt = const Value.absent(),
  });
  SessionCacheCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String email,
    required String fullName,
    this.totpEnabled = const Value.absent(),
    required String tenantId,
    required String tenantName,
    this.tenantLogoUrl = const Value.absent(),
    required String timezone,
    required String currency,
    required String roleKey,
    required String roleName,
    required String permissionsJson,
    required String featuresJson,
    required String membershipsJson,
    required DateTime savedAt,
  }) : userId = Value(userId),
       email = Value(email),
       fullName = Value(fullName),
       tenantId = Value(tenantId),
       tenantName = Value(tenantName),
       timezone = Value(timezone),
       currency = Value(currency),
       roleKey = Value(roleKey),
       roleName = Value(roleName),
       permissionsJson = Value(permissionsJson),
       featuresJson = Value(featuresJson),
       membershipsJson = Value(membershipsJson),
       savedAt = Value(savedAt);
  static Insertable<SessionCacheRow> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? email,
    Expression<String>? fullName,
    Expression<bool>? totpEnabled,
    Expression<String>? tenantId,
    Expression<String>? tenantName,
    Expression<String>? tenantLogoUrl,
    Expression<String>? timezone,
    Expression<String>? currency,
    Expression<String>? roleKey,
    Expression<String>? roleName,
    Expression<String>? permissionsJson,
    Expression<String>? featuresJson,
    Expression<String>? membershipsJson,
    Expression<DateTime>? savedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (email != null) 'email': email,
      if (fullName != null) 'full_name': fullName,
      if (totpEnabled != null) 'totp_enabled': totpEnabled,
      if (tenantId != null) 'tenant_id': tenantId,
      if (tenantName != null) 'tenant_name': tenantName,
      if (tenantLogoUrl != null) 'tenant_logo_url': tenantLogoUrl,
      if (timezone != null) 'timezone': timezone,
      if (currency != null) 'currency': currency,
      if (roleKey != null) 'role_key': roleKey,
      if (roleName != null) 'role_name': roleName,
      if (permissionsJson != null) 'permissions_json': permissionsJson,
      if (featuresJson != null) 'features_json': featuresJson,
      if (membershipsJson != null) 'memberships_json': membershipsJson,
      if (savedAt != null) 'saved_at': savedAt,
    });
  }

  SessionCacheCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? email,
    Value<String>? fullName,
    Value<bool>? totpEnabled,
    Value<String>? tenantId,
    Value<String>? tenantName,
    Value<String?>? tenantLogoUrl,
    Value<String>? timezone,
    Value<String>? currency,
    Value<String>? roleKey,
    Value<String>? roleName,
    Value<String>? permissionsJson,
    Value<String>? featuresJson,
    Value<String>? membershipsJson,
    Value<DateTime>? savedAt,
  }) {
    return SessionCacheCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      totpEnabled: totpEnabled ?? this.totpEnabled,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      tenantLogoUrl: tenantLogoUrl ?? this.tenantLogoUrl,
      timezone: timezone ?? this.timezone,
      currency: currency ?? this.currency,
      roleKey: roleKey ?? this.roleKey,
      roleName: roleName ?? this.roleName,
      permissionsJson: permissionsJson ?? this.permissionsJson,
      featuresJson: featuresJson ?? this.featuresJson,
      membershipsJson: membershipsJson ?? this.membershipsJson,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (totpEnabled.present) {
      map['totp_enabled'] = Variable<bool>(totpEnabled.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (tenantName.present) {
      map['tenant_name'] = Variable<String>(tenantName.value);
    }
    if (tenantLogoUrl.present) {
      map['tenant_logo_url'] = Variable<String>(tenantLogoUrl.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (roleKey.present) {
      map['role_key'] = Variable<String>(roleKey.value);
    }
    if (roleName.present) {
      map['role_name'] = Variable<String>(roleName.value);
    }
    if (permissionsJson.present) {
      map['permissions_json'] = Variable<String>(permissionsJson.value);
    }
    if (featuresJson.present) {
      map['features_json'] = Variable<String>(featuresJson.value);
    }
    if (membershipsJson.present) {
      map['memberships_json'] = Variable<String>(membershipsJson.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionCacheCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('totpEnabled: $totpEnabled, ')
          ..write('tenantId: $tenantId, ')
          ..write('tenantName: $tenantName, ')
          ..write('tenantLogoUrl: $tenantLogoUrl, ')
          ..write('timezone: $timezone, ')
          ..write('currency: $currency, ')
          ..write('roleKey: $roleKey, ')
          ..write('roleName: $roleName, ')
          ..write('permissionsJson: $permissionsJson, ')
          ..write('featuresJson: $featuresJson, ')
          ..write('membershipsJson: $membershipsJson, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }
}

class $PendingUploadsTable extends PendingUploads
    with TableInfo<$PendingUploadsTable, PendingUploadRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingUploadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moduleMeta = const VerificationMeta('module');
  @override
  late final GeneratedColumn<String> module = GeneratedColumn<String>(
    'module',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentTypeMeta = const VerificationMeta(
    'contentType',
  );
  @override
  late final GeneratedColumn<String> contentType = GeneratedColumn<String>(
    'content_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileIdMeta = const VerificationMeta('fileId');
  @override
  late final GeneratedColumn<String> fileId = GeneratedColumn<String>(
    'file_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uploadedAtMeta = const VerificationMeta(
    'uploadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> uploadedAt = GeneratedColumn<DateTime>(
    'uploaded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localPath,
    module,
    kind,
    entityType,
    entityId,
    contentType,
    sizeBytes,
    status,
    fileId,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
    uploadedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_uploads';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingUploadRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('module')) {
      context.handle(
        _moduleMeta,
        module.isAcceptableOrUnknown(data['module']!, _moduleMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('content_type')) {
      context.handle(
        _contentTypeMeta,
        contentType.isAcceptableOrUnknown(
          data['content_type']!,
          _contentTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeBytesMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('file_id')) {
      context.handle(
        _fileIdMeta,
        fileId.isAcceptableOrUnknown(data['file_id']!, _fileIdMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('uploaded_at')) {
      context.handle(
        _uploadedAtMeta,
        uploadedAt.isAcceptableOrUnknown(data['uploaded_at']!, _uploadedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingUploadRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingUploadRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      module: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      contentType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      fileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_id'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      uploadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}uploaded_at'],
      ),
    );
  }

  @override
  $PendingUploadsTable createAlias(String alias) {
    return $PendingUploadsTable(attachedDatabase, alias);
  }
}

class PendingUploadRow extends DataClass
    implements Insertable<PendingUploadRow> {
  /// UUID generado en el teléfono.
  final String id;

  /// Ruta del archivo local ya procesado.
  final String localPath;

  /// Módulo, tipo y entidad dueños del archivo (`files` en el backend).
  final String module;
  final String kind;
  final String entityType;
  final String entityId;
  final String contentType;
  final int sizeBytes;

  /// queued, uploading, done o error (ver `UploadStatus`).
  final String status;

  /// Id del registro `files` una vez pedido el presign.
  final String? fileId;
  final int attempts;

  /// Antes de esta hora no se reintenta (espera creciente).
  final DateTime? nextAttemptAt;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? uploadedAt;
  const PendingUploadRow({
    required this.id,
    required this.localPath,
    required this.module,
    required this.kind,
    required this.entityType,
    required this.entityId,
    required this.contentType,
    required this.sizeBytes,
    required this.status,
    this.fileId,
    required this.attempts,
    this.nextAttemptAt,
    this.lastError,
    required this.createdAt,
    this.uploadedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['local_path'] = Variable<String>(localPath);
    map['module'] = Variable<String>(module);
    map['kind'] = Variable<String>(kind);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['content_type'] = Variable<String>(contentType);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || fileId != null) {
      map['file_id'] = Variable<String>(fileId);
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || uploadedAt != null) {
      map['uploaded_at'] = Variable<DateTime>(uploadedAt);
    }
    return map;
  }

  PendingUploadsCompanion toCompanion(bool nullToAbsent) {
    return PendingUploadsCompanion(
      id: Value(id),
      localPath: Value(localPath),
      module: Value(module),
      kind: Value(kind),
      entityType: Value(entityType),
      entityId: Value(entityId),
      contentType: Value(contentType),
      sizeBytes: Value(sizeBytes),
      status: Value(status),
      fileId: fileId == null && nullToAbsent
          ? const Value.absent()
          : Value(fileId),
      attempts: Value(attempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      uploadedAt: uploadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadedAt),
    );
  }

  factory PendingUploadRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingUploadRow(
      id: serializer.fromJson<String>(json['id']),
      localPath: serializer.fromJson<String>(json['localPath']),
      module: serializer.fromJson<String>(json['module']),
      kind: serializer.fromJson<String>(json['kind']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      contentType: serializer.fromJson<String>(json['contentType']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      status: serializer.fromJson<String>(json['status']),
      fileId: serializer.fromJson<String?>(json['fileId']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      uploadedAt: serializer.fromJson<DateTime?>(json['uploadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'localPath': serializer.toJson<String>(localPath),
      'module': serializer.toJson<String>(module),
      'kind': serializer.toJson<String>(kind),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'contentType': serializer.toJson<String>(contentType),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'status': serializer.toJson<String>(status),
      'fileId': serializer.toJson<String?>(fileId),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'uploadedAt': serializer.toJson<DateTime?>(uploadedAt),
    };
  }

  PendingUploadRow copyWith({
    String? id,
    String? localPath,
    String? module,
    String? kind,
    String? entityType,
    String? entityId,
    String? contentType,
    int? sizeBytes,
    String? status,
    Value<String?> fileId = const Value.absent(),
    int? attempts,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> uploadedAt = const Value.absent(),
  }) => PendingUploadRow(
    id: id ?? this.id,
    localPath: localPath ?? this.localPath,
    module: module ?? this.module,
    kind: kind ?? this.kind,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    contentType: contentType ?? this.contentType,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    status: status ?? this.status,
    fileId: fileId.present ? fileId.value : this.fileId,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    uploadedAt: uploadedAt.present ? uploadedAt.value : this.uploadedAt,
  );
  PendingUploadRow copyWithCompanion(PendingUploadsCompanion data) {
    return PendingUploadRow(
      id: data.id.present ? data.id.value : this.id,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      module: data.module.present ? data.module.value : this.module,
      kind: data.kind.present ? data.kind.value : this.kind,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      contentType: data.contentType.present
          ? data.contentType.value
          : this.contentType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      status: data.status.present ? data.status.value : this.status,
      fileId: data.fileId.present ? data.fileId.value : this.fileId,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      uploadedAt: data.uploadedAt.present
          ? data.uploadedAt.value
          : this.uploadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingUploadRow(')
          ..write('id: $id, ')
          ..write('localPath: $localPath, ')
          ..write('module: $module, ')
          ..write('kind: $kind, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('contentType: $contentType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('status: $status, ')
          ..write('fileId: $fileId, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('uploadedAt: $uploadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localPath,
    module,
    kind,
    entityType,
    entityId,
    contentType,
    sizeBytes,
    status,
    fileId,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
    uploadedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingUploadRow &&
          other.id == this.id &&
          other.localPath == this.localPath &&
          other.module == this.module &&
          other.kind == this.kind &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.contentType == this.contentType &&
          other.sizeBytes == this.sizeBytes &&
          other.status == this.status &&
          other.fileId == this.fileId &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.uploadedAt == this.uploadedAt);
}

class PendingUploadsCompanion extends UpdateCompanion<PendingUploadRow> {
  final Value<String> id;
  final Value<String> localPath;
  final Value<String> module;
  final Value<String> kind;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> contentType;
  final Value<int> sizeBytes;
  final Value<String> status;
  final Value<String?> fileId;
  final Value<int> attempts;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime?> uploadedAt;
  final Value<int> rowid;
  const PendingUploadsCompanion({
    this.id = const Value.absent(),
    this.localPath = const Value.absent(),
    this.module = const Value.absent(),
    this.kind = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.contentType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.fileId = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.uploadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingUploadsCompanion.insert({
    required String id,
    required String localPath,
    required String module,
    required String kind,
    required String entityType,
    required String entityId,
    required String contentType,
    required int sizeBytes,
    required String status,
    this.fileId = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    this.uploadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       localPath = Value(localPath),
       module = Value(module),
       kind = Value(kind),
       entityType = Value(entityType),
       entityId = Value(entityId),
       contentType = Value(contentType),
       sizeBytes = Value(sizeBytes),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<PendingUploadRow> custom({
    Expression<String>? id,
    Expression<String>? localPath,
    Expression<String>? module,
    Expression<String>? kind,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? contentType,
    Expression<int>? sizeBytes,
    Expression<String>? status,
    Expression<String>? fileId,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? uploadedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localPath != null) 'local_path': localPath,
      if (module != null) 'module': module,
      if (kind != null) 'kind': kind,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (contentType != null) 'content_type': contentType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (status != null) 'status': status,
      if (fileId != null) 'file_id': fileId,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (uploadedAt != null) 'uploaded_at': uploadedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingUploadsCompanion copyWith({
    Value<String>? id,
    Value<String>? localPath,
    Value<String>? module,
    Value<String>? kind,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? contentType,
    Value<int>? sizeBytes,
    Value<String>? status,
    Value<String?>? fileId,
    Value<int>? attempts,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime?>? uploadedAt,
    Value<int>? rowid,
  }) {
    return PendingUploadsCompanion(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      module: module ?? this.module,
      kind: kind ?? this.kind,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      contentType: contentType ?? this.contentType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      status: status ?? this.status,
      fileId: fileId ?? this.fileId,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (module.present) {
      map['module'] = Variable<String>(module.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (contentType.present) {
      map['content_type'] = Variable<String>(contentType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (fileId.present) {
      map['file_id'] = Variable<String>(fileId.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (uploadedAt.present) {
      map['uploaded_at'] = Variable<DateTime>(uploadedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingUploadsCompanion(')
          ..write('id: $id, ')
          ..write('localPath: $localPath, ')
          ..write('module: $module, ')
          ..write('kind: $kind, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('contentType: $contentType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('status: $status, ')
          ..write('fileId: $fileId, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('uploadedAt: $uploadedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApiCacheTable extends ApiCache
    with TableInfo<$ApiCacheTable, ApiCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, body, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApiCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  ApiCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiCacheRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $ApiCacheTable createAlias(String alias) {
    return $ApiCacheTable(attachedDatabase, alias);
  }
}

class ApiCacheRow extends DataClass implements Insertable<ApiCacheRow> {
  /// Clave de la lectura, p. ej. `tasks:2026-10-22`.
  final String key;
  final String body;
  final DateTime savedAt;
  const ApiCacheRow({
    required this.key,
    required this.body,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['body'] = Variable<String>(body);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  ApiCacheCompanion toCompanion(bool nullToAbsent) {
    return ApiCacheCompanion(
      key: Value(key),
      body: Value(body),
      savedAt: Value(savedAt),
    );
  }

  factory ApiCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiCacheRow(
      key: serializer.fromJson<String>(json['key']),
      body: serializer.fromJson<String>(json['body']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'body': serializer.toJson<String>(body),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  ApiCacheRow copyWith({String? key, String? body, DateTime? savedAt}) =>
      ApiCacheRow(
        key: key ?? this.key,
        body: body ?? this.body,
        savedAt: savedAt ?? this.savedAt,
      );
  ApiCacheRow copyWithCompanion(ApiCacheCompanion data) {
    return ApiCacheRow(
      key: data.key.present ? data.key.value : this.key,
      body: data.body.present ? data.body.value : this.body,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiCacheRow(')
          ..write('key: $key, ')
          ..write('body: $body, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, body, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiCacheRow &&
          other.key == this.key &&
          other.body == this.body &&
          other.savedAt == this.savedAt);
}

class ApiCacheCompanion extends UpdateCompanion<ApiCacheRow> {
  final Value<String> key;
  final Value<String> body;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const ApiCacheCompanion({
    this.key = const Value.absent(),
    this.body = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApiCacheCompanion.insert({
    required String key,
    required String body,
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       body = Value(body),
       savedAt = Value(savedAt);
  static Insertable<ApiCacheRow> custom({
    Expression<String>? key,
    Expression<String>? body,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (body != null) 'body': body,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApiCacheCompanion copyWith({
    Value<String>? key,
    Value<String>? body,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return ApiCacheCompanion(
      key: key ?? this.key,
      body: body ?? this.body,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiCacheCompanion(')
          ..write('key: $key, ')
          ..write('body: $body, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingActionsTable extends PendingActions
    with TableInfo<$PendingActionsTable, PendingActionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityKeyMeta = const VerificationMeta(
    'entityKey',
  );
  @override
  late final GeneratedColumn<String> entityKey = GeneratedColumn<String>(
    'entity_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _waitUploadsMeta = const VerificationMeta(
    'waitUploads',
  );
  @override
  late final GeneratedColumn<bool> waitUploads = GeneratedColumn<bool>(
    'wait_uploads',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("wait_uploads" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    method,
    path,
    body,
    entityKey,
    label,
    waitUploads,
    status,
    attempts,
    lastError,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_actions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingActionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('entity_key')) {
      context.handle(
        _entityKeyMeta,
        entityKey.isAcceptableOrUnknown(data['entity_key']!, _entityKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_entityKeyMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('wait_uploads')) {
      context.handle(
        _waitUploadsMeta,
        waitUploads.isAcceptableOrUnknown(
          data['wait_uploads']!,
          _waitUploadsMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingActionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingActionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      ),
      entityKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_key'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      waitUploads: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}wait_uploads'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingActionsTable createAlias(String alias) {
    return $PendingActionsTable(attachedDatabase, alias);
  }
}

class PendingActionRow extends DataClass
    implements Insertable<PendingActionRow> {
  final int id;

  /// Método y ruta de la API, p. ej. `PATCH /tasks/…/checklist/…`.
  final String method;
  final String path;

  /// Cuerpo JSON (null = sin cuerpo).
  final String? body;

  /// Entidad afectada (`task:<id>`) para mostrar "pendiente de enviar".
  final String entityKey;

  /// Texto corto para la pantalla de sincronización.
  final String label;

  /// Espera a que no queden fotos por subir (el cierre las necesita).
  final bool waitUploads;

  /// queued o error (el servidor lo rechazó; ver lastError).
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  const PendingActionRow({
    required this.id,
    required this.method,
    required this.path,
    this.body,
    required this.entityKey,
    required this.label,
    required this.waitUploads,
    required this.status,
    required this.attempts,
    this.lastError,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['method'] = Variable<String>(method);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || body != null) {
      map['body'] = Variable<String>(body);
    }
    map['entity_key'] = Variable<String>(entityKey);
    map['label'] = Variable<String>(label);
    map['wait_uploads'] = Variable<bool>(waitUploads);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingActionsCompanion toCompanion(bool nullToAbsent) {
    return PendingActionsCompanion(
      id: Value(id),
      method: Value(method),
      path: Value(path),
      body: body == null && nullToAbsent ? const Value.absent() : Value(body),
      entityKey: Value(entityKey),
      label: Value(label),
      waitUploads: Value(waitUploads),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
    );
  }

  factory PendingActionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingActionRow(
      id: serializer.fromJson<int>(json['id']),
      method: serializer.fromJson<String>(json['method']),
      path: serializer.fromJson<String>(json['path']),
      body: serializer.fromJson<String?>(json['body']),
      entityKey: serializer.fromJson<String>(json['entityKey']),
      label: serializer.fromJson<String>(json['label']),
      waitUploads: serializer.fromJson<bool>(json['waitUploads']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'method': serializer.toJson<String>(method),
      'path': serializer.toJson<String>(path),
      'body': serializer.toJson<String?>(body),
      'entityKey': serializer.toJson<String>(entityKey),
      'label': serializer.toJson<String>(label),
      'waitUploads': serializer.toJson<bool>(waitUploads),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingActionRow copyWith({
    int? id,
    String? method,
    String? path,
    Value<String?> body = const Value.absent(),
    String? entityKey,
    String? label,
    bool? waitUploads,
    String? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
  }) => PendingActionRow(
    id: id ?? this.id,
    method: method ?? this.method,
    path: path ?? this.path,
    body: body.present ? body.value : this.body,
    entityKey: entityKey ?? this.entityKey,
    label: label ?? this.label,
    waitUploads: waitUploads ?? this.waitUploads,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingActionRow copyWithCompanion(PendingActionsCompanion data) {
    return PendingActionRow(
      id: data.id.present ? data.id.value : this.id,
      method: data.method.present ? data.method.value : this.method,
      path: data.path.present ? data.path.value : this.path,
      body: data.body.present ? data.body.value : this.body,
      entityKey: data.entityKey.present ? data.entityKey.value : this.entityKey,
      label: data.label.present ? data.label.value : this.label,
      waitUploads: data.waitUploads.present
          ? data.waitUploads.value
          : this.waitUploads,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingActionRow(')
          ..write('id: $id, ')
          ..write('method: $method, ')
          ..write('path: $path, ')
          ..write('body: $body, ')
          ..write('entityKey: $entityKey, ')
          ..write('label: $label, ')
          ..write('waitUploads: $waitUploads, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    method,
    path,
    body,
    entityKey,
    label,
    waitUploads,
    status,
    attempts,
    lastError,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingActionRow &&
          other.id == this.id &&
          other.method == this.method &&
          other.path == this.path &&
          other.body == this.body &&
          other.entityKey == this.entityKey &&
          other.label == this.label &&
          other.waitUploads == this.waitUploads &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt);
}

class PendingActionsCompanion extends UpdateCompanion<PendingActionRow> {
  final Value<int> id;
  final Value<String> method;
  final Value<String> path;
  final Value<String?> body;
  final Value<String> entityKey;
  final Value<String> label;
  final Value<bool> waitUploads;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  const PendingActionsCompanion({
    this.id = const Value.absent(),
    this.method = const Value.absent(),
    this.path = const Value.absent(),
    this.body = const Value.absent(),
    this.entityKey = const Value.absent(),
    this.label = const Value.absent(),
    this.waitUploads = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingActionsCompanion.insert({
    this.id = const Value.absent(),
    required String method,
    required String path,
    this.body = const Value.absent(),
    required String entityKey,
    required String label,
    this.waitUploads = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
  }) : method = Value(method),
       path = Value(path),
       entityKey = Value(entityKey),
       label = Value(label),
       createdAt = Value(createdAt);
  static Insertable<PendingActionRow> custom({
    Expression<int>? id,
    Expression<String>? method,
    Expression<String>? path,
    Expression<String>? body,
    Expression<String>? entityKey,
    Expression<String>? label,
    Expression<bool>? waitUploads,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (method != null) 'method': method,
      if (path != null) 'path': path,
      if (body != null) 'body': body,
      if (entityKey != null) 'entity_key': entityKey,
      if (label != null) 'label': label,
      if (waitUploads != null) 'wait_uploads': waitUploads,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingActionsCompanion copyWith({
    Value<int>? id,
    Value<String>? method,
    Value<String>? path,
    Value<String?>? body,
    Value<String>? entityKey,
    Value<String>? label,
    Value<bool>? waitUploads,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
  }) {
    return PendingActionsCompanion(
      id: id ?? this.id,
      method: method ?? this.method,
      path: path ?? this.path,
      body: body ?? this.body,
      entityKey: entityKey ?? this.entityKey,
      label: label ?? this.label,
      waitUploads: waitUploads ?? this.waitUploads,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (entityKey.present) {
      map['entity_key'] = Variable<String>(entityKey.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (waitUploads.present) {
      map['wait_uploads'] = Variable<bool>(waitUploads.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingActionsCompanion(')
          ..write('id: $id, ')
          ..write('method: $method, ')
          ..write('path: $path, ')
          ..write('body: $body, ')
          ..write('entityKey: $entityKey, ')
          ..write('label: $label, ')
          ..write('waitUploads: $waitUploads, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionCacheTable sessionCache = $SessionCacheTable(this);
  late final $PendingUploadsTable pendingUploads = $PendingUploadsTable(this);
  late final $ApiCacheTable apiCache = $ApiCacheTable(this);
  late final $PendingActionsTable pendingActions = $PendingActionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessionCache,
    pendingUploads,
    apiCache,
    pendingActions,
  ];
}

typedef $$SessionCacheTableCreateCompanionBuilder =
    SessionCacheCompanion Function({
      Value<int> id,
      required String userId,
      required String email,
      required String fullName,
      Value<bool> totpEnabled,
      required String tenantId,
      required String tenantName,
      Value<String?> tenantLogoUrl,
      required String timezone,
      required String currency,
      required String roleKey,
      required String roleName,
      required String permissionsJson,
      required String featuresJson,
      required String membershipsJson,
      required DateTime savedAt,
    });
typedef $$SessionCacheTableUpdateCompanionBuilder =
    SessionCacheCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> email,
      Value<String> fullName,
      Value<bool> totpEnabled,
      Value<String> tenantId,
      Value<String> tenantName,
      Value<String?> tenantLogoUrl,
      Value<String> timezone,
      Value<String> currency,
      Value<String> roleKey,
      Value<String> roleName,
      Value<String> permissionsJson,
      Value<String> featuresJson,
      Value<String> membershipsJson,
      Value<DateTime> savedAt,
    });

class $$SessionCacheTableFilterComposer
    extends Composer<_$AppDatabase, $SessionCacheTable> {
  $$SessionCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get totpEnabled => $composableBuilder(
    column: $table.totpEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantName => $composableBuilder(
    column: $table.tenantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tenantLogoUrl => $composableBuilder(
    column: $table.tenantLogoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleKey => $composableBuilder(
    column: $table.roleKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roleName => $composableBuilder(
    column: $table.roleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get permissionsJson => $composableBuilder(
    column: $table.permissionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get featuresJson => $composableBuilder(
    column: $table.featuresJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get membershipsJson => $composableBuilder(
    column: $table.membershipsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionCacheTable> {
  $$SessionCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get totpEnabled => $composableBuilder(
    column: $table.totpEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantId => $composableBuilder(
    column: $table.tenantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantName => $composableBuilder(
    column: $table.tenantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tenantLogoUrl => $composableBuilder(
    column: $table.tenantLogoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleKey => $composableBuilder(
    column: $table.roleKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roleName => $composableBuilder(
    column: $table.roleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get permissionsJson => $composableBuilder(
    column: $table.permissionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get featuresJson => $composableBuilder(
    column: $table.featuresJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get membershipsJson => $composableBuilder(
    column: $table.membershipsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionCacheTable> {
  $$SessionCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<bool> get totpEnabled => $composableBuilder(
    column: $table.totpEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get tenantName => $composableBuilder(
    column: $table.tenantName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tenantLogoUrl => $composableBuilder(
    column: $table.tenantLogoUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get roleKey =>
      $composableBuilder(column: $table.roleKey, builder: (column) => column);

  GeneratedColumn<String> get roleName =>
      $composableBuilder(column: $table.roleName, builder: (column) => column);

  GeneratedColumn<String> get permissionsJson => $composableBuilder(
    column: $table.permissionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get featuresJson => $composableBuilder(
    column: $table.featuresJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get membershipsJson => $composableBuilder(
    column: $table.membershipsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SessionCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionCacheTable,
          SessionCacheRow,
          $$SessionCacheTableFilterComposer,
          $$SessionCacheTableOrderingComposer,
          $$SessionCacheTableAnnotationComposer,
          $$SessionCacheTableCreateCompanionBuilder,
          $$SessionCacheTableUpdateCompanionBuilder,
          (
            SessionCacheRow,
            BaseReferences<_$AppDatabase, $SessionCacheTable, SessionCacheRow>,
          ),
          SessionCacheRow,
          PrefetchHooks Function()
        > {
  $$SessionCacheTableTableManager(_$AppDatabase db, $SessionCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<bool> totpEnabled = const Value.absent(),
                Value<String> tenantId = const Value.absent(),
                Value<String> tenantName = const Value.absent(),
                Value<String?> tenantLogoUrl = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> roleKey = const Value.absent(),
                Value<String> roleName = const Value.absent(),
                Value<String> permissionsJson = const Value.absent(),
                Value<String> featuresJson = const Value.absent(),
                Value<String> membershipsJson = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
              }) => SessionCacheCompanion(
                id: id,
                userId: userId,
                email: email,
                fullName: fullName,
                totpEnabled: totpEnabled,
                tenantId: tenantId,
                tenantName: tenantName,
                tenantLogoUrl: tenantLogoUrl,
                timezone: timezone,
                currency: currency,
                roleKey: roleKey,
                roleName: roleName,
                permissionsJson: permissionsJson,
                featuresJson: featuresJson,
                membershipsJson: membershipsJson,
                savedAt: savedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String email,
                required String fullName,
                Value<bool> totpEnabled = const Value.absent(),
                required String tenantId,
                required String tenantName,
                Value<String?> tenantLogoUrl = const Value.absent(),
                required String timezone,
                required String currency,
                required String roleKey,
                required String roleName,
                required String permissionsJson,
                required String featuresJson,
                required String membershipsJson,
                required DateTime savedAt,
              }) => SessionCacheCompanion.insert(
                id: id,
                userId: userId,
                email: email,
                fullName: fullName,
                totpEnabled: totpEnabled,
                tenantId: tenantId,
                tenantName: tenantName,
                tenantLogoUrl: tenantLogoUrl,
                timezone: timezone,
                currency: currency,
                roleKey: roleKey,
                roleName: roleName,
                permissionsJson: permissionsJson,
                featuresJson: featuresJson,
                membershipsJson: membershipsJson,
                savedAt: savedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionCacheTable,
      SessionCacheRow,
      $$SessionCacheTableFilterComposer,
      $$SessionCacheTableOrderingComposer,
      $$SessionCacheTableAnnotationComposer,
      $$SessionCacheTableCreateCompanionBuilder,
      $$SessionCacheTableUpdateCompanionBuilder,
      (
        SessionCacheRow,
        BaseReferences<_$AppDatabase, $SessionCacheTable, SessionCacheRow>,
      ),
      SessionCacheRow,
      PrefetchHooks Function()
    >;
typedef $$PendingUploadsTableCreateCompanionBuilder =
    PendingUploadsCompanion Function({
      required String id,
      required String localPath,
      required String module,
      required String kind,
      required String entityType,
      required String entityId,
      required String contentType,
      required int sizeBytes,
      required String status,
      Value<String?> fileId,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      required DateTime createdAt,
      Value<DateTime?> uploadedAt,
      Value<int> rowid,
    });
typedef $$PendingUploadsTableUpdateCompanionBuilder =
    PendingUploadsCompanion Function({
      Value<String> id,
      Value<String> localPath,
      Value<String> module,
      Value<String> kind,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> contentType,
      Value<int> sizeBytes,
      Value<String> status,
      Value<String?> fileId,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime?> uploadedAt,
      Value<int> rowid,
    });

class $$PendingUploadsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get uploadedAt => $composableBuilder(
    column: $table.uploadedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingUploadsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get module => $composableBuilder(
    column: $table.module,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileId => $composableBuilder(
    column: $table.fileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get uploadedAt => $composableBuilder(
    column: $table.uploadedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingUploadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get module =>
      $composableBuilder(column: $table.module, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get contentType => $composableBuilder(
    column: $table.contentType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get fileId =>
      $composableBuilder(column: $table.fileId, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get uploadedAt => $composableBuilder(
    column: $table.uploadedAt,
    builder: (column) => column,
  );
}

class $$PendingUploadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingUploadsTable,
          PendingUploadRow,
          $$PendingUploadsTableFilterComposer,
          $$PendingUploadsTableOrderingComposer,
          $$PendingUploadsTableAnnotationComposer,
          $$PendingUploadsTableCreateCompanionBuilder,
          $$PendingUploadsTableUpdateCompanionBuilder,
          (
            PendingUploadRow,
            BaseReferences<
              _$AppDatabase,
              $PendingUploadsTable,
              PendingUploadRow
            >,
          ),
          PendingUploadRow,
          PrefetchHooks Function()
        > {
  $$PendingUploadsTableTableManager(
    _$AppDatabase db,
    $PendingUploadsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingUploadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingUploadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingUploadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String> module = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> contentType = const Value.absent(),
                Value<int> sizeBytes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> fileId = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> uploadedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingUploadsCompanion(
                id: id,
                localPath: localPath,
                module: module,
                kind: kind,
                entityType: entityType,
                entityId: entityId,
                contentType: contentType,
                sizeBytes: sizeBytes,
                status: status,
                fileId: fileId,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                uploadedAt: uploadedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String localPath,
                required String module,
                required String kind,
                required String entityType,
                required String entityId,
                required String contentType,
                required int sizeBytes,
                required String status,
                Value<String?> fileId = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> uploadedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingUploadsCompanion.insert(
                id: id,
                localPath: localPath,
                module: module,
                kind: kind,
                entityType: entityType,
                entityId: entityId,
                contentType: contentType,
                sizeBytes: sizeBytes,
                status: status,
                fileId: fileId,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                uploadedAt: uploadedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingUploadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingUploadsTable,
      PendingUploadRow,
      $$PendingUploadsTableFilterComposer,
      $$PendingUploadsTableOrderingComposer,
      $$PendingUploadsTableAnnotationComposer,
      $$PendingUploadsTableCreateCompanionBuilder,
      $$PendingUploadsTableUpdateCompanionBuilder,
      (
        PendingUploadRow,
        BaseReferences<_$AppDatabase, $PendingUploadsTable, PendingUploadRow>,
      ),
      PendingUploadRow,
      PrefetchHooks Function()
    >;
typedef $$ApiCacheTableCreateCompanionBuilder =
    ApiCacheCompanion Function({
      required String key,
      required String body,
      required DateTime savedAt,
      Value<int> rowid,
    });
typedef $$ApiCacheTableUpdateCompanionBuilder =
    ApiCacheCompanion Function({
      Value<String> key,
      Value<String> body,
      Value<DateTime> savedAt,
      Value<int> rowid,
    });

class $$ApiCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ApiCacheTable> {
  $$ApiCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ApiCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiCacheTable> {
  $$ApiCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ApiCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiCacheTable> {
  $$ApiCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$ApiCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApiCacheTable,
          ApiCacheRow,
          $$ApiCacheTableFilterComposer,
          $$ApiCacheTableOrderingComposer,
          $$ApiCacheTableAnnotationComposer,
          $$ApiCacheTableCreateCompanionBuilder,
          $$ApiCacheTableUpdateCompanionBuilder,
          (
            ApiCacheRow,
            BaseReferences<_$AppDatabase, $ApiCacheTable, ApiCacheRow>,
          ),
          ApiCacheRow,
          PrefetchHooks Function()
        > {
  $$ApiCacheTableTableManager(_$AppDatabase db, $ApiCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApiCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiCacheCompanion(
                key: key,
                body: body,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String body,
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => ApiCacheCompanion.insert(
                key: key,
                body: body,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ApiCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApiCacheTable,
      ApiCacheRow,
      $$ApiCacheTableFilterComposer,
      $$ApiCacheTableOrderingComposer,
      $$ApiCacheTableAnnotationComposer,
      $$ApiCacheTableCreateCompanionBuilder,
      $$ApiCacheTableUpdateCompanionBuilder,
      (ApiCacheRow, BaseReferences<_$AppDatabase, $ApiCacheTable, ApiCacheRow>),
      ApiCacheRow,
      PrefetchHooks Function()
    >;
typedef $$PendingActionsTableCreateCompanionBuilder =
    PendingActionsCompanion Function({
      Value<int> id,
      required String method,
      required String path,
      Value<String?> body,
      required String entityKey,
      required String label,
      Value<bool> waitUploads,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      required DateTime createdAt,
    });
typedef $$PendingActionsTableUpdateCompanionBuilder =
    PendingActionsCompanion Function({
      Value<int> id,
      Value<String> method,
      Value<String> path,
      Value<String?> body,
      Value<String> entityKey,
      Value<String> label,
      Value<bool> waitUploads,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime> createdAt,
    });

class $$PendingActionsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingActionsTable> {
  $$PendingActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityKey => $composableBuilder(
    column: $table.entityKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get waitUploads => $composableBuilder(
    column: $table.waitUploads,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingActionsTable> {
  $$PendingActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityKey => $composableBuilder(
    column: $table.entityKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get waitUploads => $composableBuilder(
    column: $table.waitUploads,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingActionsTable> {
  $$PendingActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get entityKey =>
      $composableBuilder(column: $table.entityKey, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<bool> get waitUploads => $composableBuilder(
    column: $table.waitUploads,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingActionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingActionsTable,
          PendingActionRow,
          $$PendingActionsTableFilterComposer,
          $$PendingActionsTableOrderingComposer,
          $$PendingActionsTableAnnotationComposer,
          $$PendingActionsTableCreateCompanionBuilder,
          $$PendingActionsTableUpdateCompanionBuilder,
          (
            PendingActionRow,
            BaseReferences<
              _$AppDatabase,
              $PendingActionsTable,
              PendingActionRow
            >,
          ),
          PendingActionRow,
          PrefetchHooks Function()
        > {
  $$PendingActionsTableTableManager(
    _$AppDatabase db,
    $PendingActionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String?> body = const Value.absent(),
                Value<String> entityKey = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<bool> waitUploads = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PendingActionsCompanion(
                id: id,
                method: method,
                path: path,
                body: body,
                entityKey: entityKey,
                label: label,
                waitUploads: waitUploads,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String method,
                required String path,
                Value<String?> body = const Value.absent(),
                required String entityKey,
                required String label,
                Value<bool> waitUploads = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
              }) => PendingActionsCompanion.insert(
                id: id,
                method: method,
                path: path,
                body: body,
                entityKey: entityKey,
                label: label,
                waitUploads: waitUploads,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingActionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingActionsTable,
      PendingActionRow,
      $$PendingActionsTableFilterComposer,
      $$PendingActionsTableOrderingComposer,
      $$PendingActionsTableAnnotationComposer,
      $$PendingActionsTableCreateCompanionBuilder,
      $$PendingActionsTableUpdateCompanionBuilder,
      (
        PendingActionRow,
        BaseReferences<_$AppDatabase, $PendingActionsTable, PendingActionRow>,
      ),
      PendingActionRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionCacheTableTableManager get sessionCache =>
      $$SessionCacheTableTableManager(_db, _db.sessionCache);
  $$PendingUploadsTableTableManager get pendingUploads =>
      $$PendingUploadsTableTableManager(_db, _db.pendingUploads);
  $$ApiCacheTableTableManager get apiCache =>
      $$ApiCacheTableTableManager(_db, _db.apiCache);
  $$PendingActionsTableTableManager get pendingActions =>
      $$PendingActionsTableTableManager(_db, _db.pendingActions);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

/// See also [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = Provider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = ProviderRef<AppDatabase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
