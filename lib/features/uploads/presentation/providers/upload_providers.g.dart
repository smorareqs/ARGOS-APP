// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$uploadStorageDirHash() => r'0ef17fb1cc4a80029d6df477f9e893ae40a2442d';

/// Carpeta donde se guardan las fotos mientras esperan subir.
///
/// Copied from [uploadStorageDir].
@ProviderFor(uploadStorageDir)
final uploadStorageDirProvider =
    Provider<Future<Directory> Function()>.internal(
      uploadStorageDir,
      name: r'uploadStorageDirProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$uploadStorageDirHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UploadStorageDirRef = ProviderRef<Future<Directory> Function()>;
String _$uploadQueueHash() => r'fe7aac98ae3831f028d09e70f8e0a950aab05f1a';

/// See also [uploadQueue].
@ProviderFor(uploadQueue)
final uploadQueueProvider = Provider<UploadQueue>.internal(
  uploadQueue,
  name: r'uploadQueueProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$uploadQueueHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UploadQueueRef = ProviderRef<UploadQueue>;
String _$uploadQueueRunnerHash() => r'b44af8728d44f7968683d496145c7f7ddc25ae72';

/// Mantiene la cola en marcha mientras la app está abierta: sube al entrar,
/// al volver la conexión y al regresar a la app. Solo con sesión en línea,
/// porque la subida necesita el token.
///
/// Copied from [uploadQueueRunner].
@ProviderFor(uploadQueueRunner)
final uploadQueueRunnerProvider = Provider<void>.internal(
  uploadQueueRunner,
  name: r'uploadQueueRunnerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$uploadQueueRunnerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UploadQueueRunnerRef = ProviderRef<void>;
String _$entityUploadsHash() => r'a2ae39d27408e7c4acece1c4c3e5aac1046489a7';

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

/// Fotos en cola de una entidad, con su estado y progreso.
///
/// Copied from [entityUploads].
@ProviderFor(entityUploads)
const entityUploadsProvider = EntityUploadsFamily();

/// Fotos en cola de una entidad, con su estado y progreso.
///
/// Copied from [entityUploads].
class EntityUploadsFamily extends Family<AsyncValue<List<PendingUpload>>> {
  /// Fotos en cola de una entidad, con su estado y progreso.
  ///
  /// Copied from [entityUploads].
  const EntityUploadsFamily();

  /// Fotos en cola de una entidad, con su estado y progreso.
  ///
  /// Copied from [entityUploads].
  EntityUploadsProvider call(String entityType, String entityId) {
    return EntityUploadsProvider(entityType, entityId);
  }

  @override
  EntityUploadsProvider getProviderOverride(
    covariant EntityUploadsProvider provider,
  ) {
    return call(provider.entityType, provider.entityId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'entityUploadsProvider';
}

/// Fotos en cola de una entidad, con su estado y progreso.
///
/// Copied from [entityUploads].
class EntityUploadsProvider
    extends AutoDisposeStreamProvider<List<PendingUpload>> {
  /// Fotos en cola de una entidad, con su estado y progreso.
  ///
  /// Copied from [entityUploads].
  EntityUploadsProvider(String entityType, String entityId)
    : this._internal(
        (ref) => entityUploads(ref as EntityUploadsRef, entityType, entityId),
        from: entityUploadsProvider,
        name: r'entityUploadsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$entityUploadsHash,
        dependencies: EntityUploadsFamily._dependencies,
        allTransitiveDependencies:
            EntityUploadsFamily._allTransitiveDependencies,
        entityType: entityType,
        entityId: entityId,
      );

  EntityUploadsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.entityType,
    required this.entityId,
  }) : super.internal();

  final String entityType;
  final String entityId;

  @override
  Override overrideWith(
    Stream<List<PendingUpload>> Function(EntityUploadsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EntityUploadsProvider._internal(
        (ref) => create(ref as EntityUploadsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        entityType: entityType,
        entityId: entityId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<PendingUpload>> createElement() {
    return _EntityUploadsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EntityUploadsProvider &&
        other.entityType == entityType &&
        other.entityId == entityId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, entityType.hashCode);
    hash = _SystemHash.combine(hash, entityId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EntityUploadsRef on AutoDisposeStreamProviderRef<List<PendingUpload>> {
  /// The parameter `entityType` of this provider.
  String get entityType;

  /// The parameter `entityId` of this provider.
  String get entityId;
}

class _EntityUploadsProviderElement
    extends AutoDisposeStreamProviderElement<List<PendingUpload>>
    with EntityUploadsRef {
  _EntityUploadsProviderElement(super.provider);

  @override
  String get entityType => (origin as EntityUploadsProvider).entityType;
  @override
  String get entityId => (origin as EntityUploadsProvider).entityId;
}

String _$uploadSummaryHash() => r'b5c4602131be44228cc3f6052a7487d52d169c5a';

/// Conteo global de la cola.
///
/// Copied from [uploadSummary].
@ProviderFor(uploadSummary)
final uploadSummaryProvider = AutoDisposeStreamProvider<UploadSummary>.internal(
  uploadSummary,
  name: r'uploadSummaryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$uploadSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UploadSummaryRef = AutoDisposeStreamProviderRef<UploadSummary>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
