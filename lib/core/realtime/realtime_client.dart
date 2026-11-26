import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// Mensaje del canal de tiempo real (`GET /ws`): `{type, data}`.
class RealtimeMessage {
  const RealtimeMessage(this.type, [this.data]);

  factory RealtimeMessage.fromJson(Map<String, dynamic> json) => RealtimeMessage(
    '${json['type'] ?? ''}',
    json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : null,
  );

  final String type;

  /// Puede faltar si el aviso no cabía en el canal: el cliente recarga.
  final Map<String, dynamic>? data;
}

/// Canal de avisos al instante (bandeja, chat). Se conecta con sesión en
/// línea y se reconecta solo con espera creciente.
abstract interface class RealtimeClient {
  Stream<RealtimeMessage> get messages;

  /// Abre (o mantiene) la conexión. Idempotente.
  void connect();

  void disconnect();

  void dispose();
}

/// WebSocket real contra `ws(s)://<api>/ws?token=…`.
class SocketRealtimeClient implements RealtimeClient {
  SocketRealtimeClient({
    required this.url,
    required this.token,
    required this.renewToken,
  });

  /// `ws://host:puerto/api/v1/ws`.
  final Uri url;
  final String? Function() token;
  final Future<String?> Function() renewToken;

  final _controller = StreamController<RealtimeMessage>.broadcast();
  WebSocket? _socket;
  Timer? _retry;
  var _wanted = false;
  var _connecting = false;
  var _attempts = 0;

  @override
  Stream<RealtimeMessage> get messages => _controller.stream;

  @override
  void connect() {
    _wanted = true;
    if (_socket != null || _connecting) return;
    unawaited(_open());
  }

  Future<void> _open() async {
    _connecting = true;
    _retry?.cancel();
    try {
      var access = token();
      if (access == null) {
        access = await renewToken();
        if (access == null) throw const SocketException('sin token');
      }
      final socket = await WebSocket.connect(
        url.replace(queryParameters: {'token': access}).toString(),
      ).timeout(const Duration(seconds: 15));
      socket.pingInterval = const Duration(seconds: 30);
      if (!_wanted) {
        await socket.close();
        return;
      }
      _socket = socket;
      _attempts = 0;
      socket.listen(
        (raw) {
          if (raw is! String) return;
          try {
            final json = jsonDecode(raw);
            if (json is Map) {
              _controller.add(RealtimeMessage.fromJson(Map<String, dynamic>.from(json)));
            }
          } catch (_) {}
        },
        onDone: _closed,
        onError: (Object _) => _closed(),
        cancelOnError: true,
      );
    } catch (_) {
      // 401: el token venció; el próximo intento lo renueva.
      if (_attempts > 0) await renewToken().catchError((Object _) => null);
      _schedule();
    } finally {
      _connecting = false;
    }
  }

  void _closed() {
    _socket = null;
    if (_wanted) _schedule();
  }

  void _schedule() {
    if (!_wanted) return;
    _attempts++;
    final seconds = math.min(30, math.pow(2, math.min(_attempts, 5)).toInt());
    _retry?.cancel();
    _retry = Timer(Duration(seconds: seconds), () {
      if (_wanted && _socket == null) unawaited(_open());
    });
  }

  @override
  void disconnect() {
    _wanted = false;
    _retry?.cancel();
    final socket = _socket;
    _socket = null;
    unawaited(socket?.close());
  }

  @override
  void dispose() {
    disconnect();
    unawaited(_controller.close());
  }
}

/// Canal en memoria para el modo simulado y las pruebas: las rutas
/// simuladas publican aquí lo que el backend mandaría por WebSocket.
class MockRealtimeClient implements RealtimeClient {
  MockRealtimeClient(this._bus);

  final StreamController<RealtimeMessage> _bus;
  var connected = false;

  @override
  Stream<RealtimeMessage> get messages =>
      _bus.stream.where((_) => connected);

  @override
  void connect() => connected = true;

  @override
  void disconnect() => connected = false;

  @override
  void dispose() => connected = false;
}

/// Bus del backend simulado.
final mockRealtimeBus = StreamController<RealtimeMessage>.broadcast();

/// `http://x/api/v1` → `ws://x/api/v1/ws`.
Uri realtimeUrl(String apiBaseUrl) {
  final base = Uri.parse(apiBaseUrl);
  final scheme = base.scheme == 'https' ? 'wss' : 'ws';
  final path = base.path.endsWith('/') ? '${base.path}ws' : '${base.path}/ws';
  return base.replace(scheme: scheme, path: path);
}
