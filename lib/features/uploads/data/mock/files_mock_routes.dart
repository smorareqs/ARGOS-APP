import 'package:argos_app/core/network/mock/mock_backend.dart';
import 'package:uuid/uuid.dart';

/// Host ficticio del almacenamiento simulado.
const mockStorageHost = 'mock-storage.argos.local';

/// Rutas simuladas del servicio de archivos (fase01 §3.8): presign, subida
/// directa al "almacenamiento" y confirm. La subida tarda un poco para que
/// se vea el estado "subiendo" en las miniaturas.
void registerFilesMockRoutes(MockBackend backend) {
  final pending = <String>{};
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
      pending.add(id);
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
      if (!pending.contains(id)) {
        return MockResponse.problem(403, 'URL prefirmada vencida.');
      }
      return const MockResponse(200);
    })
    ..on('POST', '/files/{id}/confirm', (req) {
      final id = req.pathParams['id']!;
      if (!pending.remove(id) && !ready.contains(id)) {
        return MockResponse.problem(404, 'Archivo no encontrado.');
      }
      ready.add(id);
      return MockResponse.json({'id': id, 'status': 'ready'});
    });
}
