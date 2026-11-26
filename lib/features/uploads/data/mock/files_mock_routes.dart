import 'package:argos_app/core/network/mock/mock_backend.dart';
import 'package:uuid/uuid.dart';

/// Host ficticio del almacenamiento simulado.
const mockStorageHost = 'mock-storage.argos.local';

/// Archivo ya confirmado en el almacenamiento simulado.
class MockStoredFile {
  const MockStoredFile(this.entityType, this.entityId, this.kind);

  final String entityType;
  final String entityId;
  final String kind;
}

/// Archivos confirmados por id, para que las demás rutas simuladas (p. ej.
/// las fotos del checklist) los vean como el backend real.
final mockStoredFiles = <String, MockStoredFile>{};

/// Rutas simuladas del servicio de archivos (fase01 §3.8): presign, subida
/// directa al "almacenamiento" y confirm. La subida tarda un poco para que
/// se vea el estado "subiendo" en las miniaturas.
void registerFilesMockRoutes(MockBackend backend) {
  final pending = <String, MockStoredFile>{};
  final ready = <String>{};

  backend
    ..on('POST', '/files/presign-upload', (req) {
      if (req.bearerToken == null) {
        return MockResponse.problem(401, 'Sesión no válida.');
      }
      final body = req.json;
      final size = body['size'];
      if (size is! int || size <= 0 || size > 10 * 1024 * 1024) {
        return MockResponse.problem(422, 'El archivo supera los 10 MB.');
      }
      final id = const Uuid().v4();
      pending[id] = MockStoredFile(
        '${body['entity_type'] ?? ''}',
        '${body['entity_id'] ?? ''}',
        '${body['kind'] ?? ''}',
      );
      return MockResponse.json({
        'file_id': id,
        'upload_url': 'https://$mockStorageHost/upload/$id',
        'method': 'PUT',
        'headers': {'Content-Type': body['content_type']},
        'expires_in': 900,
      });
    })
    ..on('PUT', '/upload/{id}', (req) async {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      final id = req.pathParams['id']!;
      if (!pending.containsKey(id)) {
        return MockResponse.problem(403, 'URL prefirmada vencida.');
      }
      return const MockResponse(200);
    })
    ..on('POST', '/files/{id}/confirm', (req) {
      final id = req.pathParams['id']!;
      final file = pending.remove(id);
      if (file == null && !ready.contains(id)) {
        return MockResponse.problem(404, 'Archivo no encontrado.');
      }
      if (file != null) mockStoredFiles[id] = file;
      ready.add(id);
      return MockResponse.json({'id': id, 'status': 'ready'});
    });
}
