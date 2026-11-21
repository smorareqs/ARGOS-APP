// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agenda_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dayAgendaHash() => r'797979eb0379886596ea33c25f7babdc02dd52ee';

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

/// Agenda de un día (sin hora). Se vuelve a pedir con `ref.refresh`.
///
/// Copied from [dayAgenda].
@ProviderFor(dayAgenda)
const dayAgendaProvider = DayAgendaFamily();

/// Agenda de un día (sin hora). Se vuelve a pedir con `ref.refresh`.
///
/// Copied from [dayAgenda].
class DayAgendaFamily extends Family<AsyncValue<DayAgenda>> {
  /// Agenda de un día (sin hora). Se vuelve a pedir con `ref.refresh`.
  ///
  /// Copied from [dayAgenda].
  const DayAgendaFamily();

  /// Agenda de un día (sin hora). Se vuelve a pedir con `ref.refresh`.
  ///
  /// Copied from [dayAgenda].
  DayAgendaProvider call(DateTime date) {
    return DayAgendaProvider(date);
  }

  @override
  DayAgendaProvider getProviderOverride(covariant DayAgendaProvider provider) {
    return call(provider.date);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'dayAgendaProvider';
}

/// Agenda de un día (sin hora). Se vuelve a pedir con `ref.refresh`.
///
/// Copied from [dayAgenda].
class DayAgendaProvider extends AutoDisposeFutureProvider<DayAgenda> {
  /// Agenda de un día (sin hora). Se vuelve a pedir con `ref.refresh`.
  ///
  /// Copied from [dayAgenda].
  DayAgendaProvider(DateTime date)
    : this._internal(
        (ref) => dayAgenda(ref as DayAgendaRef, date),
        from: dayAgendaProvider,
        name: r'dayAgendaProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$dayAgendaHash,
        dependencies: DayAgendaFamily._dependencies,
        allTransitiveDependencies: DayAgendaFamily._allTransitiveDependencies,
        date: date,
      );

  DayAgendaProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  Override overrideWith(
    FutureOr<DayAgenda> Function(DayAgendaRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: DayAgendaProvider._internal(
        (ref) => create(ref as DayAgendaRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<DayAgenda> createElement() {
    return _DayAgendaProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DayAgendaProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DayAgendaRef on AutoDisposeFutureProviderRef<DayAgenda> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _DayAgendaProviderElement
    extends AutoDisposeFutureProviderElement<DayAgenda>
    with DayAgendaRef {
  _DayAgendaProviderElement(super.provider);

  @override
  DateTime get date => (origin as DayAgendaProvider).date;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
