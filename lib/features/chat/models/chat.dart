/// Chat (fase 6, B22–B23 y F8). Mismo contrato que la web (W-M1).
library;

DateTime _date(Object? v) => DateTime.tryParse('$v')?.toLocal() ?? DateTime.now();

class ChatParticipant {
  const ChatParticipant({required this.type, required this.id, required this.name, this.role});

  factory ChatParticipant.fromJson(Map<String, dynamic> j) => ChatParticipant(
    type: '${j['type'] ?? 'user'}',
    id: '${j['id'] ?? ''}',
    name: '${j['name'] ?? ''}',
    role: j['role'] as String?,
  );

  final String type;
  final String id;
  final String name;
  final String? role;

  bool get isGuest => type == 'guest';
}

class ChatReservation {
  const ChatReservation({
    required this.id,
    required this.code,
    required this.propertyCode,
    required this.propertyName,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.guestName,
  });

  factory ChatReservation.fromJson(Map<String, dynamic> j) => ChatReservation(
    id: '${j['id'] ?? ''}',
    code: '${j['code'] ?? ''}',
    propertyCode: '${j['property_code'] ?? ''}',
    propertyName: '${j['property_name'] ?? ''}',
    checkIn: DateTime.tryParse('${j['check_in_date']}') ?? DateTime.now(),
    checkOut: DateTime.tryParse('${j['check_out_date']}') ?? DateTime.now(),
    status: '${j['status'] ?? ''}',
    guestName: '${j['guest_name'] ?? ''}',
  );

  final String id;
  final String code;
  final String propertyCode;
  final String propertyName;
  final DateTime checkIn;
  final DateTime checkOut;
  final String status;
  final String guestName;
}

/// Estado local de un mensaje propio.
enum MessageState { sent, sending, failed }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderType,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    required this.mine,
    this.body,
    this.fileUrl,
    this.state = MessageState.sent,
    this.localFileId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: '${j['id'] ?? ''}',
    conversationId: '${j['conversation_id'] ?? ''}',
    senderType: '${j['sender_type'] ?? 'user'}',
    senderId: '${j['sender_id'] ?? ''}',
    senderName: '${j['sender_name'] ?? ''}',
    body: j['body'] as String?,
    fileUrl: j['file_url'] as String?,
    createdAt: _date(j['created_at']),
    mine: j['mine'] == true,
  );

  final String id;
  final String conversationId;
  final String senderType;
  final String senderId;
  final String senderName;
  final String? body;
  final String? fileUrl;
  final DateTime createdAt;
  final bool mine;
  final MessageState state;

  /// Foto por mandar (para reintentar).
  final String? localFileId;

  bool get isSystem => senderType == 'system';

  ChatMessage copyWith({MessageState? state, bool? mine}) => ChatMessage(
    id: id,
    conversationId: conversationId,
    senderType: senderType,
    senderId: senderId,
    senderName: senderName,
    body: body,
    fileUrl: fileUrl,
    createdAt: createdAt,
    mine: mine ?? this.mine,
    state: state ?? this.state,
    localFileId: localFileId,
  );

  /// Vista previa para la lista.
  String get preview => (body ?? '').trim().isNotEmpty ? body!.trim() : (fileUrl != null ? '📷 Foto' : '');
}

class Conversation {
  const Conversation({
    required this.id,
    required this.kind,
    required this.title,
    required this.participants,
    required this.unread,
    required this.isArchived,
    required this.muted,
    this.reservation,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
    id: '${j['id'] ?? ''}',
    kind: '${j['kind'] ?? 'internal'}',
    title: '${j['title'] ?? ''}',
    reservation: j['reservation'] is Map
        ? ChatReservation.fromJson(Map<String, dynamic>.from(j['reservation'] as Map))
        : null,
    participants: [
      for (final p in j['participants'] as List? ?? const [])
        if (p is Map) ChatParticipant.fromJson(Map<String, dynamic>.from(p)),
    ],
    lastMessage: j['last_message'] is Map
        ? ChatMessage.fromJson(Map<String, dynamic>.from(j['last_message'] as Map))
        : null,
    lastMessageAt: j['last_message_at'] == null ? null : _date(j['last_message_at']),
    unread: (j['unread'] as num?)?.toInt() ?? 0,
    isArchived: j['is_archived'] == true,
    muted: j['muted'] == true,
  );

  final String id;
  final String kind;
  final String title;
  final ChatReservation? reservation;
  final List<ChatParticipant> participants;
  final ChatMessage? lastMessage;
  final DateTime? lastMessageAt;
  final int unread;
  final bool isArchived;
  final bool muted;

  bool get isGuest => kind == 'guest';

  /// Grupo: más de dos personas del equipo o con nombre propio.
  bool get isGroup => !isGuest && participants.where((p) => !p.isGuest).length > 2;

  Conversation copyWith({int? unread, ChatMessage? lastMessage, DateTime? lastMessageAt, bool? muted}) => Conversation(
    id: id,
    kind: kind,
    title: title,
    reservation: reservation,
    participants: participants,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    unread: unread ?? this.unread,
    isArchived: isArchived,
    muted: muted ?? this.muted,
  );
}

class ChatPerson {
  const ChatPerson({required this.id, required this.name, this.role});

  factory ChatPerson.fromJson(Map<String, dynamic> j) =>
      ChatPerson(id: '${j['id'] ?? ''}', name: '${j['name'] ?? ''}', role: j['role'] as String?);

  final String id;
  final String name;
  final String? role;
}

/// Página de mensajes (antiguos primero).
class MessagePage {
  const MessagePage(this.items, this.nextCursor);

  final List<ChatMessage> items;
  final String? nextCursor;
}

/// F8: la conversación del huésped con la empresa.
class GuestChat {
  const GuestChat({
    required this.id,
    required this.title,
    required this.participants,
    required this.messages,
    required this.unread,
    required this.isArchived,
  });

  factory GuestChat.fromJson(Map<String, dynamic> j) => GuestChat(
    id: '${j['id'] ?? ''}',
    title: '${j['title'] ?? ''}',
    participants: [
      for (final p in j['participants'] as List? ?? const [])
        if (p is Map) ChatParticipant.fromJson(Map<String, dynamic>.from(p)),
    ],
    messages: [
      for (final m in j['messages'] as List? ?? const [])
        if (m is Map) ChatMessage.fromJson(Map<String, dynamic>.from(m)),
    ],
    unread: (j['unread'] as num?)?.toInt() ?? 0,
    isArchived: j['is_archived'] == true,
  );

  final String id;
  final String title;
  final List<ChatParticipant> participants;
  final List<ChatMessage> messages;
  final int unread;
  final bool isArchived;
}

/// F1: el código de la puerta.
class GuestLock {
  const GuestLock({
    required this.available,
    required this.hasLock,
    required this.message,
    this.code,
    this.deviceName,
    this.validFrom,
    this.validTo,
    this.showsAt,
  });

  factory GuestLock.fromJson(Map<String, dynamic> j) {
    DateTime? d(String k) => j[k] == null ? null : DateTime.tryParse('${j[k]}')?.toLocal();
    return GuestLock(
      available: j['available'] == true,
      hasLock: j['has_lock'] == true,
      message: '${j['message'] ?? ''}',
      code: j['code'] as String?,
      deviceName: j['device_name'] as String?,
      validFrom: d('valid_from'),
      validTo: d('valid_to'),
      showsAt: d('shows_at'),
    );
  }

  final bool available;
  final bool hasLock;
  final String message;
  final String? code;
  final String? deviceName;
  final DateTime? validFrom;
  final DateTime? validTo;
  final DateTime? showsAt;
}

const _months = ['ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.', 'jul.', 'ago.', 'sept.', 'oct.', 'nov.', 'dic.'];
const _weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

String chatTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "Hoy", "Ayer" o "lunes 18 de nov.".
String chatDayLabel(DateTime d, DateTime now) {
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  final base = '${_weekdays[d.weekday - 1]} ${d.day} de ${_months[d.month - 1]}';
  return d.year == now.year ? base : '$base ${d.year}';
}

/// Hora en la lista: hoy la hora, ayer "Ayer", esta semana el día, si no la fecha.
String chatListTime(DateTime d, DateTime now) {
  final day = DateTime(d.year, d.month, d.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return chatTime(d);
  if (diff == 1) return 'Ayer';
  if (diff < 7) {
    final w = _weekdays[d.weekday - 1];
    return '${w[0].toUpperCase()}${w.substring(1, 3)}';
  }
  return '${d.day} ${_months[d.month - 1]}';
}
