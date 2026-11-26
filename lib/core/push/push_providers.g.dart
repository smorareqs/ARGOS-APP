// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pushServiceHash() => r'4285fdaa36e292019e5a10a65ecf1b7dc34a7576';

/// See also [pushService].
@ProviderFor(pushService)
final pushServiceProvider = Provider<PushService>.internal(
  pushService,
  name: r'pushServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pushServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PushServiceRef = ProviderRef<PushService>;
String _$pushRunnerHash() => r'66bda945c7f11b2ed650dcd98f63a341433cc59a';

/// Registra el teléfono para push al entrar (y cuando FCM rota el token),
/// lo quita al cerrar sesión, y abre la pantalla del push que se tocó.
///
/// Copied from [pushRunner].
@ProviderFor(pushRunner)
final pushRunnerProvider = Provider<void>.internal(
  pushRunner,
  name: r'pushRunnerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pushRunnerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PushRunnerRef = ProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
