import 'package:argos_app/core/network/mock/mock_backend.dart';
import 'package:argos_app/core/realtime/realtime_client.dart';
import 'package:argos_app/features/tasks/data/mock/tasks_mock_routes.dart';

/// Rutas simuladas de la fase 6: chat del equipo y con huéspedes
/// (`/chat/*`), chat del huésped (`/guest/chat*`) y código de la puerta
/// (`/guest/lock`).
///
/// Datos: el grupo "Equipo Costa Limpia", un 1:1 entre Ana y Luis, y la
/// conversación con Tomás Reyes (res-tomas), que tiene código de puerta.
/// La huésped de Garrent (res-ana) no tiene chat ni cerradura.
void registerChatMockRoutes(MockBackend backend, {DateTime Function()? clock, bool liveDemo = true}) {
  final api = _MockChat(clock ?? DateTime.now, liveDemo: liveDemo);
  backend
    ..on('GET', '/chat/conversations', api.auth(api.list))
    ..on('POST', '/chat/conversations', api.auth(api.create))
    ..on('GET', '/chat/people', api.auth(api.people))
    ..on('GET', '/chat/conversations/{conversation_id}', api.auth(api.get))
    ..on('GET', '/chat/conversations/{conversation_id}/messages', api.auth(api.messages))
    ..on('POST', '/chat/conversations/{conversation_id}/messages', api.auth(api.send))
    ..on('POST', '/chat/conversations/{conversation_id}/read', api.auth(api.read))
    ..on('POST', '/chat/conversations/{conversation_id}/mute', api.auth(api.mute))
    ..on('GET', '/guest/chat', api.guest(api.guestChat))
    ..on('POST', '/guest/chat/messages', api.guest(api.guestSend))
    ..on('POST', '/guest/chat/read', api.guest(api.guestRead))
    ..on('GET', '/guest/lock', api.guest(api.guestLock));
}

typedef _Who = (String, String, String);

const _staff = [
  ('u-ana', 'Ana López', 'cleaner'),
  ('u-luis', 'Luis Pérez', 'maintenance'),
  ('u-sofia', 'Sofía Méndez', 'supervisor'),
  ('u-carlos', 'Carlos Rivas', 'admin'),
  ('u-jorge', 'Jorge Castillo', 'security'),
  ('u-marta', 'Marta Díaz', 'cleaner'),
];

const _guestId = 'g-tomas';
const _guestName = 'Tomás Reyes';
const _guestStay = 'res-tomas';

class _Msg {
  _Msg(this.id, this.conv, this.senderType, this.senderId, this.senderName, this.at, {this.body, this.fileUrl});

  final String id;
  final String conv;
  final String senderType;
  final String senderId;
  final String senderName;
  final DateTime at;
  final String? body;
  final String? fileUrl;
}

class _Conv {
  _Conv(this.id, this.kind, this.title, this.members, {this.guest = false});

  final String id;
  final String kind;
  final String? title;
  final List<String> members;
  final bool guest;

  /// Las del huésped se archivan 24 h después de la salida.
  var archived = false;
  final lastRead = <String, DateTime>{};
  final muted = <String>{};
}

class _MockChat {
  _MockChat(this._now, {required this.liveDemo}) {
    final now = _now();
    DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));
    final team = _Conv('c-equipo', 'internal', 'Equipo Costa Limpia', [
      'u-ana',
      'u-luis',
      'u-sofia',
      'u-carlos',
      'u-jorge',
      'u-marta',
    ]);
    final pair = _Conv('c-ana-luis', 'internal', null, ['u-ana', 'u-luis']);
    final guest = _Conv('c-tomas', 'guest', _guestName, ['u-sofia', 'u-carlos'], guest: true);
    for (final c in [team, pair, guest]) {
      _convs[c.id] = c;
    }
    _msgs.addAll([
      _Msg(
        'm-1',
        'c-equipo',
        'user',
        'u-sofia',
        'Sofía Méndez',
        ago(26 * 60),
        body: 'Buenos días equipo. Hoy hay tres salidas y dos llegadas.',
      ),
      _Msg(
        'm-2',
        'c-equipo',
        'user',
        'u-luis',
        'Luis Pérez',
        ago(25 * 60 + 40),
        body: 'Voy primero a revisar el aire de Torre Olivo.',
      ),
      _Msg(
        'm-3',
        'c-equipo',
        'user',
        'u-sofia',
        'Sofía Méndez',
        ago(95),
        body: 'Recuerden subir las fotos de cada limpieza antes de las 3.',
      ),
      _Msg('m-4', 'c-equipo', 'user', 'u-marta', 'Marta Díaz', ago(40), body: 'Listo, ya terminé Casa Laurel.'),
      _Msg(
        'm-5',
        'c-ana-luis',
        'user',
        'u-luis',
        'Luis Pérez',
        ago(70),
        body: '¿Ya saliste del apartamento? Llego en 10 min a cambiar la chapa.',
      ),
      _Msg('m-6', 'c-ana-luis', 'user', 'u-ana', 'Ana López', ago(66), body: 'Todavía estoy, te espero.'),
      _Msg('m-7', 'c-ana-luis', 'user', 'u-luis', 'Luis Pérez', ago(12), body: 'Gracias. Dejé la llave en recepción.'),
      _Msg(
        'm-8',
        'c-tomas',
        'system',
        '',
        'Argos',
        ago(3 * 24 * 60),
        body: 'Hola $_guestName, aquí puedes escribirle al equipo durante tu estancia.',
      ),
      _Msg(
        'm-9',
        'c-tomas',
        'guest',
        _guestId,
        _guestName,
        ago(2 * 24 * 60 + 30),
        body: 'Hola, ¿podemos hacer el check-in un poco antes, a la 1?',
      ),
      _Msg(
        'm-10',
        'c-tomas',
        'user',
        'u-sofia',
        'Sofía Méndez',
        ago(2 * 24 * 60 + 10),
        body: '¡Claro! El apartamento estará listo a la 1. Bienvenidos.',
      ),
      _Msg(
        'm-11',
        'c-tomas',
        'guest',
        _guestId,
        _guestName,
        ago(30),
        body: '¿Nos pueden dejar toallas extra para la piscina?',
      ),
    ]);
    // Leído hasta antes de los últimos mensajes, para que haya no leídos.
    team.lastRead.addAll({for (final m in team.members) m: ago(100)});
    team.lastRead['u-sofia'] = now;
    pair.lastRead.addAll({'u-ana': ago(60), 'u-luis': now});
    guest.lastRead.addAll({'u-sofia': ago(60), 'u-carlos': ago(60), _guestId: now});
  }

  final DateTime Function() _now;
  final bool liveDemo;
  final _convs = <String, _Conv>{};
  final _msgs = <_Msg>[];
  var _seq = 100;

  MockHandler auth(MockResponse Function(MockRequest, _Who) fn) => (req) {
    final who = mockWho(req, _now());
    if (who == null) return MockResponse.problem(401, 'La sesión venció.');
    return fn(req, who);
  };

  /// Solo el huésped de Costa Limpia (res-tomas) tiene chat.
  MockHandler guest(MockResponse Function(MockRequest, String) fn) => (req) {
    final token = req.bearerToken ?? '';
    if (!token.startsWith('guest-')) {
      return MockResponse.problem(401, 'Tu acceso terminó. Pide un código nuevo a la recepción.');
    }
    return fn(req, token.substring(6));
  };

  String _name(String id) => _staff.firstWhere((p) => p.$1 == id, orElse: () => (id, id, '')).$2;

  String _role(String id) => _staff.firstWhere((p) => p.$1 == id, orElse: () => (id, id, '')).$3;

  List<_Msg> _of(String conv) => _msgs.where((m) => m.conv == conv).toList()..sort((a, b) => a.at.compareTo(b.at));

  Map<String, dynamic> _msgJson(_Msg m, String viewer) => {
    'id': m.id,
    'conversation_id': m.conv,
    'sender_type': m.senderType,
    'sender_id': m.senderId,
    'sender_name': m.senderName,
    'body': m.body,
    'file_url': m.fileUrl,
    'created_at': m.at.toUtc().toIso8601String(),
    'mine': m.senderId == viewer,
  };

  Map<String, dynamic>? _reservation(_Conv c) {
    if (!c.guest) return null;
    final now = _now();
    final p = mockPropertyOptions[1 % mockPropertyOptions.length];
    String d(int days) {
      final x = now.add(Duration(days: days));
      return '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    }

    return {
      'id': _guestStay,
      'code': 'ARG-7K3P9Q',
      'property_code': p.$2,
      'property_name': p.$3,
      'check_in_date': d(-2),
      'check_out_date': d(1),
      'status': 'checked_in',
      'guest_name': _guestName,
    };
  }

  Map<String, dynamic> _convJson(_Conv c, String viewer) {
    final msgs = _of(c.id);
    final last = msgs.isEmpty ? null : msgs.last;
    final read = c.lastRead[viewer];
    final title = c.title ?? c.members.where((m) => m != viewer).map(_name).join(', ');
    return {
      'id': c.id,
      'kind': c.kind,
      'title': title,
      'reservation': _reservation(c),
      'participants': [
        for (final m in c.members) {'type': 'user', 'id': m, 'name': _name(m), 'role': _role(m)},
        if (c.guest) {'type': 'guest', 'id': _guestId, 'name': _guestName},
      ],
      'last_message': last == null ? null : _msgJson(last, viewer),
      'last_message_at': last?.at.toUtc().toIso8601String(),
      'unread': msgs
          .where((m) => m.senderId != viewer && m.senderType != 'system' && (read == null || m.at.isAfter(read)))
          .length,
      'is_archived': c.archived,
      'muted': c.muted.contains(viewer),
    };
  }

  /// El personal con chat.guest ve todas las conversaciones de huéspedes.
  bool _sees(_Conv c, _Who who) =>
      c.members.contains(who.$1) || (c.guest && const {'supervisor', 'admin'}.contains(who.$3));

  _Conv? _find(MockRequest req, _Who who) {
    final c = _convs[req.pathParams['conversation_id']];
    return c != null && _sees(c, who) ? c : null;
  }

  MockResponse list(MockRequest req, _Who who) {
    final kind = req.query['kind'] ?? 'internal';
    final items = [
      for (final c in _convs.values)
        if (c.kind == kind && _sees(c, who)) _convJson(c, who.$1),
    ]..sort((a, b) => '${b['last_message_at']}'.compareTo('${a['last_message_at']}'));
    return MockResponse.json({'items': items, 'next_cursor': null});
  }

  MockResponse get(MockRequest req, _Who who) {
    final c = _find(req, who);
    return c == null
        ? MockResponse.problem(404, 'No encontramos la conversación.')
        : MockResponse.json(_convJson(c, who.$1));
  }

  MockResponse people(MockRequest req, _Who who) => MockResponse.json([
    for (final p in _staff)
      if (p.$1 != who.$1) {'id': p.$1, 'name': p.$2, 'role': p.$3},
  ]);

  MockResponse create(MockRequest req, _Who who) {
    final ids = [for (final id in req.json['user_ids'] as List? ?? const []) '$id'];
    if (ids.isEmpty) return MockResponse.problem(422, 'Elige al menos una persona.');
    final members = {who.$1, ...ids}.toList();
    final title = '${req.json['title'] ?? ''}'.trim();
    if (members.length == 2 && title.isEmpty) {
      for (final c in _convs.values) {
        if (!c.guest && c.title == null && c.members.toSet().containsAll(members) && c.members.length == 2) {
          return MockResponse.json(_convJson(c, who.$1));
        }
      }
    }
    final c = _Conv(
      'c-${_seq++}',
      'internal',
      title.isEmpty && members.length == 2 ? null : (title.isEmpty ? 'Grupo' : title),
      members,
    );
    c.lastRead[who.$1] = _now();
    _convs[c.id] = c;
    return MockResponse.json(_convJson(c, who.$1), status: 201);
  }

  MockResponse messages(MockRequest req, _Who who) {
    final c = _find(req, who);
    if (c == null) return MockResponse.problem(404, 'No encontramos la conversación.');
    final limit = int.tryParse(req.query['limit'] ?? '') ?? 50;
    var all = _of(c.id);
    final before = req.query['before'];
    if (before != null) {
      final i = all.indexWhere((m) => m.id == before);
      all = i < 0 ? const [] : all.sublist(0, i);
    }
    final page = all.length > limit ? all.sublist(all.length - limit) : all;
    return MockResponse.json({
      'items': [for (final m in page) _msgJson(m, who.$1)],
      'next_cursor': all.length > limit ? page.first.id : null,
    });
  }

  MockResponse send(MockRequest req, _Who who) {
    final c = _find(req, who);
    if (c == null) return MockResponse.problem(404, 'No encontramos la conversación.');
    if (c.archived) return MockResponse.problem(409, 'La conversación está archivada.');
    final body = '${req.json['body'] ?? ''}'.trim();
    final fileId = req.json['file_id'] as String?;
    if (body.isEmpty && fileId == null) return MockResponse.problem(422, 'Escribe un mensaje o adjunta una foto.');
    final m = _Msg(
      'm-${_seq++}',
      c.id,
      'user',
      who.$1,
      who.$2,
      _now(),
      body: body.isEmpty ? null : body,
      fileUrl: fileId == null ? null : 'https://picsum.photos/seed/$fileId/800/600',
    );
    _msgs.add(m);
    c.lastRead[who.$1] = m.at;
    if (!c.members.contains(who.$1)) c.members.add(who.$1);
    if (liveDemo) mockRealtimeBus.add(RealtimeMessage('chat.message', _msgJson(m, '')));
    return MockResponse.json(_msgJson(m, who.$1), status: 201);
  }

  MockResponse read(MockRequest req, _Who who) {
    final c = _find(req, who);
    if (c == null) return MockResponse.problem(404, 'No encontramos la conversación.');
    c.lastRead[who.$1] = _now();
    return MockResponse.noContent();
  }

  MockResponse mute(MockRequest req, _Who who) {
    final c = _find(req, who);
    if (c == null) return MockResponse.problem(404, 'No encontramos la conversación.');
    if (req.json['muted'] == true) {
      c.muted.add(who.$1);
    } else {
      c.muted.remove(who.$1);
    }
    return MockResponse.json(_convJson(c, who.$1));
  }

  // ── Huésped ──────────────────────────────────────────────

  MockResponse guestChat(MockRequest req, String stay) {
    if (stay != _guestStay) return MockResponse.problem(403, 'Esta empresa no tiene chat con huéspedes.');
    final c = _convs['c-tomas']!;
    final read = c.lastRead[_guestId];
    final msgs = _of(c.id);
    return MockResponse.json({
      'id': c.id,
      'title': 'Costa Limpia S.A.',
      'participants': [
        for (final m in c.members) {'type': 'user', 'id': m, 'name': _name(m), 'role': _role(m)},
      ],
      'messages': [for (final m in msgs) _msgJson(m, _guestId)],
      'unread': msgs.where((m) => m.senderId != _guestId && (read == null || m.at.isAfter(read))).length,
      'is_archived': c.archived,
    });
  }

  MockResponse guestSend(MockRequest req, String stay) {
    if (stay != _guestStay) return MockResponse.problem(403, 'Esta empresa no tiene chat con huéspedes.');
    final body = '${req.json['body'] ?? ''}'.trim();
    if (body.isEmpty) return MockResponse.problem(422, 'Escribe un mensaje.');
    final m = _Msg('m-${_seq++}', 'c-tomas', 'guest', _guestId, _guestName, _now(), body: body);
    _msgs.add(m);
    _convs['c-tomas']!.lastRead[_guestId] = m.at;
    if (liveDemo) {
      mockRealtimeBus.add(RealtimeMessage('chat.message', _msgJson(m, '')));
      // Respuesta automática para ver el chat en vivo en el modo simulado.
      Future<void>.delayed(const Duration(seconds: 4), () {
        _msgs.add(
          _Msg(
            'm-${_seq++}',
            'c-tomas',
            'user',
            'u-sofia',
            'Sofía Méndez',
            _now(),
            body: 'Recibido, $_guestName. Te ayudamos enseguida.',
          ),
        );
      });
    }
    return MockResponse.json(_msgJson(m, _guestId), status: 201);
  }

  MockResponse guestRead(MockRequest req, String stay) {
    _convs['c-tomas']?.lastRead[_guestId] = _now();
    return MockResponse.noContent();
  }

  MockResponse guestLock(MockRequest req, String stay) {
    if (stay != _guestStay) {
      return MockResponse.json({
        'available': false,
        'has_lock': false,
        'message': 'Esta propiedad no tiene cerradura inteligente.',
      });
    }
    final now = _now();
    final from = DateTime(now.year, now.month, now.day - 2, 15);
    final to = DateTime(now.year, now.month, now.day + 1, 13);
    return MockResponse.json({
      'available': true,
      'has_lock': true,
      'message': '',
      'code': '730519',
      'device_name': 'Puerta principal',
      'valid_from': from.toUtc().toIso8601String(),
      'valid_to': to.toUtc().toIso8601String(),
      'shows_at': from.subtract(const Duration(hours: 24)).toUtc().toIso8601String(),
    });
  }
}
