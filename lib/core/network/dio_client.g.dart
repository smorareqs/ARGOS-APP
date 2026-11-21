// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$publicDioHash() => r'01a2e805e89cc20c83c5d5ad0b65f78d6a16140d';

/// Cliente sin token: login, refresh, recuperar contraseña e invitaciones.
///
/// Copied from [publicDio].
@ProviderFor(publicDio)
final publicDioProvider = Provider<Dio>.internal(
  publicDio,
  name: r'publicDioProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$publicDioHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PublicDioRef = ProviderRef<Dio>;
String _$dioClientHash() => r'8b417a95d92c1f0383090a4ed4a08b789efa755e';

/// Cliente autenticado: agrega el token de acceso y lo renueva ante un 401.
///
/// Copied from [dioClient].
@ProviderFor(dioClient)
final dioClientProvider = Provider<Dio>.internal(
  dioClient,
  name: r'dioClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dioClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DioClientRef = ProviderRef<Dio>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
