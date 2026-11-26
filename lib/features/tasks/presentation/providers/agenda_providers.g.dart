// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agenda_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dayAgendaHash() => r'93b313803cee323701ff75a5f665b23802aa8891';

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

/// Agenda de un día (sin hora): la propia o, con [mine] en false, la de
/// todo el equipo del supervisor. Se vuelve a pedir con `ref.refresh` y
/// sola cuando cambia una tarea.
///
/// Copied from [dayAgenda].
@ProviderFor(dayAgenda)
const dayAgendaProvider = DayAgendaFamily();

/// Agenda de un día (sin hora): la propia o, con [mine] en false, la de
/// todo el equipo del supervisor. Se vuelve a pedir con `ref.refresh` y
/// sola cuando cambia una tarea.
///
/// Copied from [dayAgenda].
class DayAgendaFamily extends Family<AsyncValue<DayAgenda>> {
  /// Agenda de un día (sin hora): la propia o, con [mine] en false, la de
  /// todo el equipo del supervisor. Se vuelve a pedir con `ref.refresh` y
  /// sola cuando cambia una tarea.
  ///
  /// Copied from [dayAgenda].
  const DayAgendaFamily();

  /// Agenda de un día (sin hora): la propia o, con [mine] en false, la de
  /// todo el equipo del supervisor. Se vuelve a pedir con `ref.refresh` y
  /// sola cuando cambia una tarea.
  ///
  /// Copied from [dayAgenda].
  DayAgendaProvider call(DateTime date, {bool mine = true}) {
    return DayAgendaProvider(date, mine: mine);
  }

  @override
  DayAgendaProvider getProviderOverride(covariant DayAgendaProvider provider) {
    return call(provider.date, mine: provider.mine);
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

/// Agenda de un día (sin hora): la propia o, con [mine] en false, la de
/// todo el equipo del supervisor. Se vuelve a pedir con `ref.refresh` y
/// sola cuando cambia una tarea.
///
/// Copied from [dayAgenda].
class DayAgendaProvider extends AutoDisposeFutureProvider<DayAgenda> {
  /// Agenda de un día (sin hora): la propia o, con [mine] en false, la de
  /// todo el equipo del supervisor. Se vuelve a pedir con `ref.refresh` y
  /// sola cuando cambia una tarea.
  ///
  /// Copied from [dayAgenda].
  DayAgendaProvider(DateTime date, {bool mine = true})
    : this._internal(
        (ref) => dayAgenda(ref as DayAgendaRef, date, mine: mine),
        from: dayAgendaProvider,
        name: r'dayAgendaProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$dayAgendaHash,
        dependencies: DayAgendaFamily._dependencies,
        allTransitiveDependencies: DayAgendaFamily._allTransitiveDependencies,
        date: date,
        mine: mine,
      );

  DayAgendaProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
    required this.mine,
  }) : super.internal();

  final DateTime date;
  final bool mine;

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
        mine: mine,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<DayAgenda> createElement() {
    return _DayAgendaProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DayAgendaProvider &&
        other.date == date &&
        other.mine == mine;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);
    hash = _SystemHash.combine(hash, mine.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DayAgendaRef on AutoDisposeFutureProviderRef<DayAgenda> {
  /// The parameter `date` of this provider.
  DateTime get date;

  /// The parameter `mine` of this provider.
  bool get mine;
}

class _DayAgendaProviderElement
    extends AutoDisposeFutureProviderElement<DayAgenda>
    with DayAgendaRef {
  _DayAgendaProviderElement(super.provider);

  @override
  DateTime get date => (origin as DayAgendaProvider).date;
  @override
  bool get mine => (origin as DayAgendaProvider).mine;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
