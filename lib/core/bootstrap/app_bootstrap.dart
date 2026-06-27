import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/core/utils/md5_hash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_bootstrap.g.dart';

@Riverpod(keepAlive: true)
Future<void> appBootstrap(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  final count = await db.select(db.usuarios).get();

  if (count.isEmpty) {
    await db.into(db.usuarios).insert(
          UsuariosCompanion.insert(
            codigo: 'admin',
            nombre: 'Administrador',
            passwordHash: hashMd5('admin123'),
          ),
        );
  }
}
