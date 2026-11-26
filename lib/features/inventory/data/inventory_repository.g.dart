// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$inventoryRepositoryHash() =>
    r'7322cdc8b72d13a3f85a6c913a6c3d10dbafa70c';

/// See also [inventoryRepository].
@ProviderFor(inventoryRepository)
final inventoryRepositoryProvider = Provider<InventoryRepository>.internal(
  inventoryRepository,
  name: r'inventoryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$inventoryRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InventoryRepositoryRef = ProviderRef<InventoryRepository>;
String _$myInventoryHash() => r'f1057901d9aadf1878422420f74893ad0b292ccd';

/// Mi inventario con la hora de la copia si vino sin conexión.
///
/// Copied from [myInventory].
@ProviderFor(myInventory)
final myInventoryProvider =
    AutoDisposeFutureProvider<(MyInventory, DateTime?)>.internal(
      myInventory,
      name: r'myInventoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$myInventoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyInventoryRef = AutoDisposeFutureProviderRef<(MyInventory, DateTime?)>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
