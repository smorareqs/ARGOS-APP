// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alerts_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$alertsRepositoryHash() => r'44168759d7dba2640b1ba3d95da9dce9b3e5baac';

/// See also [alertsRepository].
@ProviderFor(alertsRepository)
final alertsRepositoryProvider = Provider<AlertsRepository>.internal(
  alertsRepository,
  name: r'alertsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$alertsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AlertsRepositoryRef = ProviderRef<AlertsRepository>;
String _$alertsPanelHash() => r'8232c28d580a185a5eb869a1957d659da9dc21ad';

/// See also [alertsPanel].
@ProviderFor(alertsPanel)
final alertsPanelProvider =
    AutoDisposeFutureProvider<(AlertsSummary, List<OpsAlert>)>.internal(
      alertsPanel,
      name: r'alertsPanelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$alertsPanelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AlertsPanelRef =
    AutoDisposeFutureProviderRef<(AlertsSummary, List<OpsAlert>)>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
