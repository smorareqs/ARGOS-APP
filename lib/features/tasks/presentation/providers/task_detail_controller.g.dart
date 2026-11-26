// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$taskDetailControllerHash() =>
    r'1c44e00d9aa603efe2298c2df1095bb0650f1221';

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

abstract class _$TaskDetailController
    extends BuildlessAutoDisposeAsyncNotifier<TaskLoad> {
  late final String id;

  FutureOr<TaskLoad> build(String id);
}

/// Estado de una tarea abierta: se recarga sola cuando un cambio llega al
/// servidor, y cada acción la actualiza al instante (también sin red).
///
/// Copied from [TaskDetailController].
@ProviderFor(TaskDetailController)
const taskDetailControllerProvider = TaskDetailControllerFamily();

/// Estado de una tarea abierta: se recarga sola cuando un cambio llega al
/// servidor, y cada acción la actualiza al instante (también sin red).
///
/// Copied from [TaskDetailController].
class TaskDetailControllerFamily extends Family<AsyncValue<TaskLoad>> {
  /// Estado de una tarea abierta: se recarga sola cuando un cambio llega al
  /// servidor, y cada acción la actualiza al instante (también sin red).
  ///
  /// Copied from [TaskDetailController].
  const TaskDetailControllerFamily();

  /// Estado de una tarea abierta: se recarga sola cuando un cambio llega al
  /// servidor, y cada acción la actualiza al instante (también sin red).
  ///
  /// Copied from [TaskDetailController].
  TaskDetailControllerProvider call(String id) {
    return TaskDetailControllerProvider(id);
  }

  @override
  TaskDetailControllerProvider getProviderOverride(
    covariant TaskDetailControllerProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'taskDetailControllerProvider';
}

/// Estado de una tarea abierta: se recarga sola cuando un cambio llega al
/// servidor, y cada acción la actualiza al instante (también sin red).
///
/// Copied from [TaskDetailController].
class TaskDetailControllerProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<TaskDetailController, TaskLoad> {
  /// Estado de una tarea abierta: se recarga sola cuando un cambio llega al
  /// servidor, y cada acción la actualiza al instante (también sin red).
  ///
  /// Copied from [TaskDetailController].
  TaskDetailControllerProvider(String id)
    : this._internal(
        () => TaskDetailController()..id = id,
        from: taskDetailControllerProvider,
        name: r'taskDetailControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$taskDetailControllerHash,
        dependencies: TaskDetailControllerFamily._dependencies,
        allTransitiveDependencies:
            TaskDetailControllerFamily._allTransitiveDependencies,
        id: id,
      );

  TaskDetailControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  FutureOr<TaskLoad> runNotifierBuild(covariant TaskDetailController notifier) {
    return notifier.build(id);
  }

  @override
  Override overrideWith(TaskDetailController Function() create) {
    return ProviderOverride(
      origin: this,
      override: TaskDetailControllerProvider._internal(
        () => create()..id = id,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<TaskDetailController, TaskLoad>
  createElement() {
    return _TaskDetailControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TaskDetailControllerProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TaskDetailControllerRef on AutoDisposeAsyncNotifierProviderRef<TaskLoad> {
  /// The parameter `id` of this provider.
  String get id;
}

class _TaskDetailControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<TaskDetailController, TaskLoad>
    with TaskDetailControllerRef {
  _TaskDetailControllerProviderElement(super.provider);

  @override
  String get id => (origin as TaskDetailControllerProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
