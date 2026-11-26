// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$outboxHash() => r'dfe190717d781d321ddeaeab122c011ae3eab69e';

/// See also [outbox].
@ProviderFor(outbox)
final outboxProvider = Provider<Outbox>.internal(
  outbox,
  name: r'outboxProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$outboxHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OutboxRef = ProviderRef<Outbox>;
String _$outboxRunnerHash() => r'bd4ab1052882380d63fa24a67bfbcec3c3bd1920';

/// Mantiene la cola de cambios en marcha mientras la app está abierta:
/// envía al entrar, al volver la conexión, al regresar a la app y cuando
/// terminan de subir las fotos (el cierre las espera).
///
/// Copied from [outboxRunner].
@ProviderFor(outboxRunner)
final outboxRunnerProvider = Provider<void>.internal(
  outboxRunner,
  name: r'outboxRunnerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$outboxRunnerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OutboxRunnerRef = ProviderRef<void>;
String _$outboxSummaryHash() => r'8f26df2b63fd8108c7e787eec2d4f231c95e98d6';

/// Conteo global de la cola de cambios.
///
/// Copied from [outboxSummary].
@ProviderFor(outboxSummary)
final outboxSummaryProvider = AutoDisposeStreamProvider<OutboxSummary>.internal(
  outboxSummary,
  name: r'outboxSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$outboxSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OutboxSummaryRef = AutoDisposeStreamProviderRef<OutboxSummary>;
String _$entityActionsHash() => r'89f051efb049eabbe3c3f24e70d68bfebc119af9';

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

/// Cambios sin enviar de una entidad (`task:<id>`).
///
/// Copied from [entityActions].
@ProviderFor(entityActions)
const entityActionsProvider = EntityActionsFamily();

/// Cambios sin enviar de una entidad (`task:<id>`).
///
/// Copied from [entityActions].
class EntityActionsFamily extends Family<AsyncValue<List<PendingActionRow>>> {
  /// Cambios sin enviar de una entidad (`task:<id>`).
  ///
  /// Copied from [entityActions].
  const EntityActionsFamily();

  /// Cambios sin enviar de una entidad (`task:<id>`).
  ///
  /// Copied from [entityActions].
  EntityActionsProvider call(String entityKey) {
    return EntityActionsProvider(entityKey);
  }

  @override
  EntityActionsProvider getProviderOverride(
    covariant EntityActionsProvider provider,
  ) {
    return call(provider.entityKey);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'entityActionsProvider';
}

/// Cambios sin enviar de una entidad (`task:<id>`).
///
/// Copied from [entityActions].
class EntityActionsProvider
    extends AutoDisposeStreamProvider<List<PendingActionRow>> {
  /// Cambios sin enviar de una entidad (`task:<id>`).
  ///
  /// Copied from [entityActions].
  EntityActionsProvider(String entityKey)
    : this._internal(
        (ref) => entityActions(ref as EntityActionsRef, entityKey),
        from: entityActionsProvider,
        name: r'entityActionsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$entityActionsHash,
        dependencies: EntityActionsFamily._dependencies,
        allTransitiveDependencies:
            EntityActionsFamily._allTransitiveDependencies,
        entityKey: entityKey,
      );

  EntityActionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.entityKey,
  }) : super.internal();

  final String entityKey;

  @override
  Override overrideWith(
    Stream<List<PendingActionRow>> Function(EntityActionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EntityActionsProvider._internal(
        (ref) => create(ref as EntityActionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        entityKey: entityKey,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<PendingActionRow>> createElement() {
    return _EntityActionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EntityActionsProvider && other.entityKey == entityKey;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, entityKey.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EntityActionsRef on AutoDisposeStreamProviderRef<List<PendingActionRow>> {
  /// The parameter `entityKey` of this provider.
  String get entityKey;
}

class _EntityActionsProviderElement
    extends AutoDisposeStreamProviderElement<List<PendingActionRow>>
    with EntityActionsRef {
  _EntityActionsProviderElement(super.provider);

  @override
  String get entityKey => (origin as EntityActionsProvider).entityKey;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
