// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tickets_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$ticketsRepositoryHash() => r'b052771fa68fdd25bc9616698fff5eb23c9d5851';

/// See also [ticketsRepository].
@ProviderFor(ticketsRepository)
final ticketsRepositoryProvider = Provider<TicketsRepository>.internal(
  ticketsRepository,
  name: r'ticketsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$ticketsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TicketsRepositoryRef = ProviderRef<TicketsRepository>;
String _$ticketListHash() => r'a9f65d2c859abaa74c901d9d01245926b5873007';

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

/// See also [ticketList].
@ProviderFor(ticketList)
const ticketListProvider = TicketListFamily();

/// See also [ticketList].
class TicketListFamily extends Family<AsyncValue<List<Ticket>>> {
  /// See also [ticketList].
  const TicketListFamily();

  /// See also [ticketList].
  TicketListProvider call({required bool mine, String? status}) {
    return TicketListProvider(mine: mine, status: status);
  }

  @override
  TicketListProvider getProviderOverride(
    covariant TicketListProvider provider,
  ) {
    return call(mine: provider.mine, status: provider.status);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'ticketListProvider';
}

/// See also [ticketList].
class TicketListProvider extends AutoDisposeFutureProvider<List<Ticket>> {
  /// See also [ticketList].
  TicketListProvider({required bool mine, String? status})
    : this._internal(
        (ref) => ticketList(ref as TicketListRef, mine: mine, status: status),
        from: ticketListProvider,
        name: r'ticketListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$ticketListHash,
        dependencies: TicketListFamily._dependencies,
        allTransitiveDependencies: TicketListFamily._allTransitiveDependencies,
        mine: mine,
        status: status,
      );

  TicketListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.mine,
    required this.status,
  }) : super.internal();

  final bool mine;
  final String? status;

  @override
  Override overrideWith(
    FutureOr<List<Ticket>> Function(TicketListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TicketListProvider._internal(
        (ref) => create(ref as TicketListRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        mine: mine,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Ticket>> createElement() {
    return _TicketListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TicketListProvider &&
        other.mine == mine &&
        other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, mine.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TicketListRef on AutoDisposeFutureProviderRef<List<Ticket>> {
  /// The parameter `mine` of this provider.
  bool get mine;

  /// The parameter `status` of this provider.
  String? get status;
}

class _TicketListProviderElement
    extends AutoDisposeFutureProviderElement<List<Ticket>>
    with TicketListRef {
  _TicketListProviderElement(super.provider);

  @override
  bool get mine => (origin as TicketListProvider).mine;
  @override
  String? get status => (origin as TicketListProvider).status;
}

String _$ticketDetailHash() => r'e498b782f3bf40189e1a1d81a6f2f811ca71d9f9';

/// See also [ticketDetail].
@ProviderFor(ticketDetail)
const ticketDetailProvider = TicketDetailFamily();

/// See also [ticketDetail].
class TicketDetailFamily extends Family<AsyncValue<TicketDetail>> {
  /// See also [ticketDetail].
  const TicketDetailFamily();

  /// See also [ticketDetail].
  TicketDetailProvider call(String id) {
    return TicketDetailProvider(id);
  }

  @override
  TicketDetailProvider getProviderOverride(
    covariant TicketDetailProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'ticketDetailProvider';
}

/// See also [ticketDetail].
class TicketDetailProvider extends AutoDisposeFutureProvider<TicketDetail> {
  /// See also [ticketDetail].
  TicketDetailProvider(String id)
    : this._internal(
        (ref) => ticketDetail(ref as TicketDetailRef, id),
        from: ticketDetailProvider,
        name: r'ticketDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$ticketDetailHash,
        dependencies: TicketDetailFamily._dependencies,
        allTransitiveDependencies:
            TicketDetailFamily._allTransitiveDependencies,
        id: id,
      );

  TicketDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<TicketDetail> Function(TicketDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TicketDetailProvider._internal(
        (ref) => create(ref as TicketDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<TicketDetail> createElement() {
    return _TicketDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TicketDetailProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TicketDetailRef on AutoDisposeFutureProviderRef<TicketDetail> {
  /// The parameter `id` of this provider.
  String get id;
}

class _TicketDetailProviderElement
    extends AutoDisposeFutureProviderElement<TicketDetail>
    with TicketDetailRef {
  _TicketDetailProviderElement(super.provider);

  @override
  String get id => (origin as TicketDetailProvider).id;
}

String _$reportablePropertiesHash() =>
    r'e99d70343718cd35041ea0a038a22c845659bff4';

/// See also [reportableProperties].
@ProviderFor(reportableProperties)
final reportablePropertiesProvider =
    AutoDisposeFutureProvider<List<PropertyOption>>.internal(
      reportableProperties,
      name: r'reportablePropertiesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$reportablePropertiesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReportablePropertiesRef =
    AutoDisposeFutureProviderRef<List<PropertyOption>>;
String _$propertyAssetsHash() => r'0bd8bfd29f469d1b9a00f0811a00b8f799687b7c';

/// See also [propertyAssets].
@ProviderFor(propertyAssets)
const propertyAssetsProvider = PropertyAssetsFamily();

/// See also [propertyAssets].
class PropertyAssetsFamily extends Family<AsyncValue<List<AssetOption>>> {
  /// See also [propertyAssets].
  const PropertyAssetsFamily();

  /// See also [propertyAssets].
  PropertyAssetsProvider call(String propertyId) {
    return PropertyAssetsProvider(propertyId);
  }

  @override
  PropertyAssetsProvider getProviderOverride(
    covariant PropertyAssetsProvider provider,
  ) {
    return call(provider.propertyId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'propertyAssetsProvider';
}

/// See also [propertyAssets].
class PropertyAssetsProvider
    extends AutoDisposeFutureProvider<List<AssetOption>> {
  /// See also [propertyAssets].
  PropertyAssetsProvider(String propertyId)
    : this._internal(
        (ref) => propertyAssets(ref as PropertyAssetsRef, propertyId),
        from: propertyAssetsProvider,
        name: r'propertyAssetsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$propertyAssetsHash,
        dependencies: PropertyAssetsFamily._dependencies,
        allTransitiveDependencies:
            PropertyAssetsFamily._allTransitiveDependencies,
        propertyId: propertyId,
      );

  PropertyAssetsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.propertyId,
  }) : super.internal();

  final String propertyId;

  @override
  Override overrideWith(
    FutureOr<List<AssetOption>> Function(PropertyAssetsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PropertyAssetsProvider._internal(
        (ref) => create(ref as PropertyAssetsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        propertyId: propertyId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<AssetOption>> createElement() {
    return _PropertyAssetsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PropertyAssetsProvider && other.propertyId == propertyId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, propertyId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PropertyAssetsRef on AutoDisposeFutureProviderRef<List<AssetOption>> {
  /// The parameter `propertyId` of this provider.
  String get propertyId;
}

class _PropertyAssetsProviderElement
    extends AutoDisposeFutureProviderElement<List<AssetOption>>
    with PropertyAssetsRef {
  _PropertyAssetsProviderElement(super.provider);

  @override
  String get propertyId => (origin as PropertyAssetsProvider).propertyId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
