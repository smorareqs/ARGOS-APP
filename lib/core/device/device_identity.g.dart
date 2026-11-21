// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_identity.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deviceIdentityServiceHash() =>
    r'b1c0cc511e87f2b7af75e051cc3ef8452e7eecdc';

/// See also [deviceIdentityService].
@ProviderFor(deviceIdentityService)
final deviceIdentityServiceProvider = Provider<DeviceIdentityService>.internal(
  deviceIdentityService,
  name: r'deviceIdentityServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deviceIdentityServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeviceIdentityServiceRef = ProviderRef<DeviceIdentityService>;
String _$appVersionHash() => r'04a369f4b0c7d40b8b2421f5b49fe1e9195eb90a';

/// Versión de la app para el pie del login y "Acerca de" (p. ej. "1.0.0").
///
/// Copied from [appVersion].
@ProviderFor(appVersion)
final appVersionProvider = FutureProvider<String>.internal(
  appVersion,
  name: r'appVersionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appVersionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppVersionRef = FutureProviderRef<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
