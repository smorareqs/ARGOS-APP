// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$sessionControllerHash() => r'412dacc25ca9a573267b885d37fb974909c991c3';

/// Máquina de estados de la sesión (ux-ui.md F1). Las acciones que vienen de
/// un formulario devuelven el [AppFailure] para mostrarlo junto al campo, o
/// null si salieron bien; la navegación la decide el router según [state].
///
/// Copied from [SessionController].
@ProviderFor(SessionController)
final sessionControllerProvider =
    NotifierProvider<SessionController, AuthState>.internal(
      SessionController.new,
      name: r'sessionControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sessionControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SessionController = Notifier<AuthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
