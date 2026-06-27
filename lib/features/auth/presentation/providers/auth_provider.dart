import 'package:argos_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:argos_app/features/auth/models/usuario_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  Future<UsuarioEntity?> build() async {
    final result = await ref.read(authRepositoryProvider).getCurrentUser();
    return result.fold((_) => null, (user) => user);
  }

  Future<void> login(String codigo, String password) async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).login(
          codigo: codigo,
          password: password,
        );
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (user) => AsyncData(user),
    );
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    final result = await ref.read(authRepositoryProvider).logout();
    state = result.fold(
      (failure) => AsyncError(failure, StackTrace.current),
      (_) => const AsyncData(null),
    );
  }
}

@riverpod
Future<bool> isAuthenticated(Ref ref) async {  final result = await ref.watch(authRepositoryProvider).isAuthenticated();
  return result.fold((_) => false, (value) => value);
}
