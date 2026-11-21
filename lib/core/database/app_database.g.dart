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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionCacheTable sessionCache = $SessionCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [sessionCache];
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionCacheTableTableManager get sessionCache =>
      $$SessionCacheTableTableManager(_db, _db.sessionCache);
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
