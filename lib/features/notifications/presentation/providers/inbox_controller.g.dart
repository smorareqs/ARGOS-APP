// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$unreadNotificationsHash() =>
    r'32daddd52193646fc04aaaf5312de4c68badcb9a';

/// Sin leer (insignia de la pestaña Alertas).
///
/// Copied from [unreadNotifications].
@ProviderFor(unreadNotifications)
final unreadNotificationsProvider = AutoDisposeProvider<int>.internal(
  unreadNotifications,
  name: r'unreadNotificationsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadNotificationsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadNotificationsRef = AutoDisposeProviderRef<int>;
String _$inboxHash() => r'72a9492f87394e8cbb8f3dd694915874665f0313';

/// Bandeja (B16): se carga con la sesión y se actualiza sola por tiempo real
/// (`notification`, `notification.read`).
///
/// Copied from [Inbox].
@ProviderFor(Inbox)
final inboxProvider = AsyncNotifierProvider<Inbox, InboxState>.internal(
  Inbox.new,
  name: r'inboxProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inboxHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Inbox = AsyncNotifier<InboxState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
