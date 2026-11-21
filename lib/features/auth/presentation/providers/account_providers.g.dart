// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$invitationInfoHash() => r'830d06e2477cad854921cefe8f95fda831b36332';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// A8 · Datos de la invitación.
///
/// Copied from [invitationInfo].
@ProviderFor(invitationInfo)
const invitationInfoProvider = InvitationInfoFamily();

/// A8 · Datos de la invitación.
///
/// Copied from [invitationInfo].
class InvitationInfoFamily extends Family<AsyncValue<InvitationInfo>> {
  /// A8 · Datos de la invitación.
  ///
  /// Copied from [invitationInfo].
  const InvitationInfoFamily();

  /// A8 · Datos de la invitación.
  ///
  /// Copied from [invitationInfo].
  InvitationInfoProvider call(String token) {
    return InvitationInfoProvider(token);
  }

  @override
  InvitationInfoProvider getProviderOverride(
    covariant InvitationInfoProvider provider,
  ) {
    return call(provider.token);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'invitationInfoProvider';
}

/// A8 · Datos de la invitación.
///
/// Copied from [invitationInfo].
class InvitationInfoProvider extends AutoDisposeFutureProvider<InvitationInfo> {
  /// A8 · Datos de la invitación.
  ///
  /// Copied from [invitationInfo].
  InvitationInfoProvider(String token)
    : this._internal(
        (ref) => invitationInfo(ref as InvitationInfoRef, token),
        from: invitationInfoProvider,
        name: r'invitationInfoProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$invitationInfoHash,
        dependencies: InvitationInfoFamily._dependencies,
        allTransitiveDependencies:
            InvitationInfoFamily._allTransitiveDependencies,
        token: token,
      );

  InvitationInfoProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.token,
  }) : super.internal();

  final String token;

  @override
  Override overrideWith(
    FutureOr<InvitationInfo> Function(InvitationInfoRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: InvitationInfoProvider._internal(
        (ref) => create(ref as InvitationInfoRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        token: token,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<InvitationInfo> createElement() {
    return _InvitationInfoProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is InvitationInfoProvider && other.token == token;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, token.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin InvitationInfoRef on AutoDisposeFutureProviderRef<InvitationInfo> {
  /// The parameter `token` of this provider.
  String get token;
}

class _InvitationInfoProviderElement
    extends AutoDisposeFutureProviderElement<InvitationInfo>
    with InvitationInfoRef {
  _InvitationInfoProviderElement(super.provider);

  @override
  String get token => (origin as InvitationInfoProvider).token;
}

String _$activeSessionsHash() => r'cfcffa757ad99166752d8dde43bfb2d873693f67';

/// B18 · Sesiones activas.
///
/// Copied from [ActiveSessions].
@ProviderFor(ActiveSessions)
final activeSessionsProvider =
    AutoDisposeAsyncNotifierProvider<
      ActiveSessions,
      List<DeviceSession>
    >.internal(
      ActiveSessions.new,
      name: r'activeSessionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$activeSessionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ActiveSessions = AutoDisposeAsyncNotifier<List<DeviceSession>>;
String _$passwordActionsHash() => r'c8272fc0ce8004cc3568a74c7e216636df10e45d';

/// A7 y "Cambiar contraseña".
///
/// Copied from [PasswordActions].
@ProviderFor(PasswordActions)
final passwordActionsProvider =
    AutoDisposeNotifierProvider<PasswordActions, void>.internal(
      PasswordActions.new,
      name: r'passwordActionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$passwordActionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PasswordActions = AutoDisposeNotifier<void>;
String _$quickUnlockControllerHash() =>
    r'eaa7e47d00cf695d2b640401bd8078972c9f4adc';

/// A5 · Configuración del inicio rápido y sus acciones.
///
/// Copied from [QuickUnlockController].
@ProviderFor(QuickUnlockController)
final quickUnlockControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      QuickUnlockController,
      QuickUnlockSettings
    >.internal(
      QuickUnlockController.new,
      name: r'quickUnlockControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$quickUnlockControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$QuickUnlockController = AutoDisposeAsyncNotifier<QuickUnlockSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
