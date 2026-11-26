// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realtime_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$realtimeClientHash() => r'f087d4a957455f30a1c99189a3428e129a41ee03';

/// See also [realtimeClient].
@ProviderFor(realtimeClient)
final realtimeClientProvider = Provider<RealtimeClient>.internal(
  realtimeClient,
  name: r'realtimeClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$realtimeClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RealtimeClientRef = ProviderRef<RealtimeClient>;
String _$realtimeMessagesHash() => r'f885b24ecdec173b9b5dd0a2004a28b4b1e06aa4';

/// Mensajes del canal (todas las features escuchan aquí).
///
/// Copied from [realtimeMessages].
@ProviderFor(realtimeMessages)
final realtimeMessagesProvider = StreamProvider<RealtimeMessage>.internal(
  realtimeMessages,
  name: r'realtimeMessagesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$realtimeMessagesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RealtimeMessagesRef = StreamProviderRef<RealtimeMessage>;
String _$realtimeRunnerHash() => r'1431984c0d0137a035d5a4dffe79b2b9c7559f7a';

/// Conecta el canal mientras hay sesión en línea y la app está al frente;
/// lo cierra en segundo plano (ahí llegan los push).
///
/// Copied from [realtimeRunner].
@ProviderFor(realtimeRunner)
final realtimeRunnerProvider = Provider<void>.internal(
  realtimeRunner,
  name: r'realtimeRunnerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$realtimeRunnerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RealtimeRunnerRef = ProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
