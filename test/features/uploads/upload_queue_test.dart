import 'dart:io';
import 'dart:typed_data';

import 'package:argos_app/core/database/app_database.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/uploads/data/mock/files_mock_routes.dart';
import 'package:argos_app/features/uploads/data/repositories/upload_queue.dart';
import 'package:argos_app/features/uploads/models/pending_upload.dart';
import 'package:argos_app/features/uploads/presentation/providers/upload_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/harness.dart';

void main() {
  late Harness harness;
  late ProviderContainer container;
  late Directory dir;

  setUp(() async {
    harness = Harness();
    registerFilesMockRoutes(harness.backend);
    dir = await Directory.systemTemp.createTemp('argos_uploads');
    addTearDown(() => dir.delete(recursive: true));
    container = ProviderContainer(
      overrides: [
        ...harness.overrides,
        uploadStorageDirProvider.overrideWithValue(() async => dir),
      ],
    );
    addTearDown(container.dispose);
    await booted(container);
    await container
        .read(sessionControllerProvider.notifier)
        .login('ana@argos.demo', demoPassword);
    container.read(sessionControllerProvider.notifier).finishQuickUnlockOffer();
    expect(container.read(sessionControllerProvider), isA<AuthSignedIn>());
  });

  Future<List<PendingUpload>> uploads(UploadQueue queue) =>
      queue.watchEntity('task_checklist_item', 'item-1').first;

  Future<String> enqueue(UploadQueue queue) => queue.enqueue(
    bytes: Uint8List.fromList(List.filled(1024, 7)),
    module: 'cleaning',
    kind: 'checklist_photo',
    entityType: 'task_checklist_item',
    entityId: 'item-1',
  );

  test('sube la foto: presign, subida y confirm', () async {
    final queue = container.read(uploadQueueProvider);
    final id = await enqueue(queue);
    await queue.process();

    final rows = await uploads(queue);
    expect(rows.single.id, id);
    expect(rows.single.status, UploadStatus.done);
    expect(rows.single.fileId, isNotNull);
    expect(File(rows.single.localPath).existsSync(), isTrue);
    expect(harness.backend.requests, containsAllInOrder([
      'POST /files/presign-upload',
      startsWith('PUT /upload/'),
      startsWith('POST /files/'),
    ]));
  });

  test('sin conexión queda con error y se recupera al reintentar', () async {
    final queue = container.read(uploadQueueProvider);
    harness.backend.offline = true;
    final id = await enqueue(queue);
    await queue.process();

    var row = (await uploads(queue)).single;
    expect(row.status, UploadStatus.error);
    expect(row.attempts, 1);

    harness.backend.offline = false;
    await queue.retry(id);
    await queue.process();
    row = (await uploads(queue)).single;
    expect(row.status, UploadStatus.done);
  });

  test('el resumen cuenta lo pendiente', () async {
    final queue = container.read(uploadQueueProvider);
    queue.canUpload = () => false;
    await enqueue(queue);
    await enqueue(queue);
    final summary = await queue.watchSummary().first;
    expect(summary.pending, 2);
    expect(summary.failed, 0);
  });

  test('al arrancar, lo que quedó subiendo vuelve a la cola', () async {
    final queue = container.read(uploadQueueProvider);
    queue.canUpload = () => false;
    final id = await enqueue(queue);
    final db = container.read(appDatabaseProvider);
    await (db.update(db.pendingUploads)..where((t) => t.id.equals(id)))
        .write(const PendingUploadsCompanion(status: Value('uploading')));
    await queue.recover();
    expect((await uploads(queue)).single.status, UploadStatus.queued);
  });

  test('espera creciente entre reintentos', () {
    expect(UploadQueue.backoffFor(1), const Duration(seconds: 15));
    expect(UploadQueue.backoffFor(2), const Duration(seconds: 30));
    expect(UploadQueue.backoffFor(3), const Duration(minutes: 1));
    expect(UploadQueue.backoffFor(20), const Duration(minutes: 30));
  });
}
