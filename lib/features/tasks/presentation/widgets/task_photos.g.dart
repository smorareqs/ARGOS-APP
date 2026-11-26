// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_photos.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fileUrlHash() => r'6ec3644515ff2eef330bcf023acbcf0f525a8cee';

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

/// URL de descarga de un archivo ya subido (vence en 5 min; se guarda 4).
///
/// Copied from [fileUrl].
@ProviderFor(fileUrl)
const fileUrlProvider = FileUrlFamily();

/// URL de descarga de un archivo ya subido (vence en 5 min; se guarda 4).
///
/// Copied from [fileUrl].
class FileUrlFamily extends Family<AsyncValue<String>> {
  /// URL de descarga de un archivo ya subido (vence en 5 min; se guarda 4).
  ///
  /// Copied from [fileUrl].
  const FileUrlFamily();

  /// URL de descarga de un archivo ya subido (vence en 5 min; se guarda 4).
  ///
  /// Copied from [fileUrl].
  FileUrlProvider call(String fileId) {
    return FileUrlProvider(fileId);
  }

  @override
  FileUrlProvider getProviderOverride(covariant FileUrlProvider provider) {
    return call(provider.fileId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'fileUrlProvider';
}

/// URL de descarga de un archivo ya subido (vence en 5 min; se guarda 4).
///
/// Copied from [fileUrl].
class FileUrlProvider extends AutoDisposeFutureProvider<String> {
  /// URL de descarga de un archivo ya subido (vence en 5 min; se guarda 4).
  ///
  /// Copied from [fileUrl].
  FileUrlProvider(String fileId)
    : this._internal(
        (ref) => fileUrl(ref as FileUrlRef, fileId),
        from: fileUrlProvider,
        name: r'fileUrlProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$fileUrlHash,
        dependencies: FileUrlFamily._dependencies,
        allTransitiveDependencies: FileUrlFamily._allTransitiveDependencies,
        fileId: fileId,
      );

  FileUrlProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.fileId,
  }) : super.internal();

  final String fileId;

  @override
  Override overrideWith(FutureOr<String> Function(FileUrlRef provider) create) {
    return ProviderOverride(
      origin: this,
      override: FileUrlProvider._internal(
        (ref) => create(ref as FileUrlRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        fileId: fileId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<String> createElement() {
    return _FileUrlProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FileUrlProvider && other.fileId == fileId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, fileId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FileUrlRef on AutoDisposeFutureProviderRef<String> {
  /// The parameter `fileId` of this provider.
  String get fileId;
}

class _FileUrlProviderElement extends AutoDisposeFutureProviderElement<String>
    with FileUrlRef {
  _FileUrlProviderElement(super.provider);

  @override
  String get fileId => (origin as FileUrlProvider).fileId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
