import 'dart:async';

import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/core/network/dio_client.dart';
import 'package:argos_app/core/realtime/realtime_providers.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/chat/models/chat.dart';
import 'package:argos_app/features/guest/data/guest_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Chat del personal (B22–B23): `/chat/*`. El tiempo real llega por el socket
/// (`chat.message`); sin socket la conversación abierta consulta cada 20 s.
class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  Future<List<Conversation>> conversations(String kind) async => [
    for (final it in _list(
      _map(await _call(() => _dio.get<dynamic>('/chat/conversations', queryParameters: {'kind': kind})))['items'],
    ))
      Conversation.fromJson(it),
  ];

  Future<Conversation> conversation(String id) async =>
      Conversation.fromJson(_map(await _call(() => _dio.get<dynamic>('/chat/conversations/$id'))));

  Future<MessagePage> messages(String id, {String? before, int limit = 50}) async {
    final m = _map(
      await _call(
        () => _dio.get<dynamic>(
          '/chat/conversations/$id/messages',
          queryParameters: {'limit': limit, if (before != null) 'before': before},
        ),
      ),
    );
    return MessagePage([for (final it in _list(m['items'])) ChatMessage.fromJson(it)], m['next_cursor'] as String?);
  }

  Future<ChatMessage> send(String id, {String? body, String? fileId}) async => ChatMessage.fromJson(
    _map(
      await _call(
        () => _dio.post<dynamic>(
          '/chat/conversations/$id/messages',
          data: {
            if (body != null && body.trim().isNotEmpty) 'body': body.trim(),
            if (fileId != null) 'file_id': fileId,
          },
        ),
      ),
    ),
  );

  Future<void> read(String id) => _call(() => _dio.post<dynamic>('/chat/conversations/$id/read'));

  Future<Conversation> mute(String id, bool muted) async => Conversation.fromJson(
    _map(await _call(() => _dio.post<dynamic>('/chat/conversations/$id/mute', data: {'muted': muted}))),
  );

  Future<Conversation> create(List<String> userIds, {String? title}) async => Conversation.fromJson(
    _map(
      await _call(
        () => _dio.post<dynamic>(
          '/chat/conversations',
          data: {
            'kind': 'internal',
            'user_ids': userIds,
            if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
          },
        ),
      ),
    ),
  );

  Future<List<ChatPerson>> people() async => [
    for (final it in _list(await _call(() => _dio.get<dynamic>('/chat/people')))) ChatPerson.fromJson(it),
  ];

  static Map<String, dynamic> _map(Object? d) => d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};

  static List<Map<String, dynamic>> _list(Object? d) => [
    for (final it in d is List ? d : const [])
      if (it is Map) Map<String, dynamic>.from(it),
  ];

  static Future<Object?> _call(Future<Response<dynamic>> Function() fn) async {
    try {
      return (await fn()).data;
    } on DioException catch (e) {
      final api = ApiException.fromDio(e);
      if (api != null) throw api;
      rethrow;
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository(ref.watch(dioClientProvider)));

/// Qué chats ve la sesión.
({bool internal, bool guest}) chatAccess(Ref ref) {
  final s = ref.watch(sessionControllerProvider);
  if (s is! AuthSignedIn) return (internal: false, guest: false);
  return (
    internal: s.session.can('chat.internal'),
    guest: s.session.can('chat.guest') && s.session.tenant.hasFeature('guest_chat'),
  );
}

void _refreshOnChat(Ref ref) {
  ref.listen(realtimeMessagesProvider, (_, next) {
    final msg = next.valueOrNull;
    if (msg?.type == 'chat.message') ref.invalidateSelf();
  });
}

/// B22: conversaciones de un tipo (`internal` o `guest`).
final conversationsProvider = FutureProvider.autoDispose.family<List<Conversation>, String>((ref, kind) {
  _refreshOnChat(ref);
  return ref.watch(chatRepositoryProvider).conversations(kind);
});

/// No leídos de todo el chat (para el acceso en Perfil y Más).
final chatUnreadProvider = FutureProvider.autoDispose<int>((ref) async {
  final access = chatAccess(ref);
  var n = 0;
  try {
    if (access.internal) {
      n += (await ref.watch(conversationsProvider('internal').future)).fold<int>(0, (a, c) => a + c.unread);
    }
    if (access.guest) {
      n += (await ref.watch(conversationsProvider('guest').future)).fold<int>(0, (a, c) => a + c.unread);
    }
  } catch (_) {
    return 0;
  }
  return n;
});

final chatPeopleProvider = FutureProvider.autoDispose<List<ChatPerson>>(
  (ref) => ref.watch(chatRepositoryProvider).people(),
);

// ── Hilo (B23 y F8) ─────────────────────────────────────────

/// De dónde salen los mensajes de un hilo: una conversación del personal o
/// el chat del huésped.
abstract interface class ThreadSource {
  Future<MessagePage> latest();
  Future<MessagePage> older(String cursor);
  Future<ChatMessage> send({String? body, String? fileId});
  Future<void> read();
}

class _StaffSource implements ThreadSource {
  _StaffSource(this._repo, this._id);

  final ChatRepository _repo;
  final String _id;

  @override
  Future<MessagePage> latest() => _repo.messages(_id);
  @override
  Future<MessagePage> older(String cursor) => _repo.messages(_id, before: cursor);
  @override
  Future<ChatMessage> send({String? body, String? fileId}) => _repo.send(_id, body: body, fileId: fileId);
  @override
  Future<void> read() => _repo.read(_id);
}

class _GuestSource implements ThreadSource {
  _GuestSource(this._repo);

  final GuestRepository _repo;

  @override
  Future<MessagePage> latest() async => MessagePage((await _repo.chat()).messages, null);
  @override
  Future<MessagePage> older(String cursor) async => const MessagePage([], null);
  @override
  Future<ChatMessage> send({String? body, String? fileId}) => _repo.sendChat(body ?? '');
  @override
  Future<void> read() => _repo.readChat();
}

/// `guest` = el chat del huésped; cualquier otro valor es el id de la conversación.
const guestThread = 'guest';

class ChatThreadState {
  const ChatThreadState({
    this.messages = const [],
    this.loading = true,
    this.error,
    this.nextCursor,
    this.loadingOlder = false,
  });

  final List<ChatMessage> messages;
  final bool loading;
  final Object? error;
  final String? nextCursor;
  final bool loadingOlder;

  ChatThreadState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    Object? error,
    bool clearError = false,
    String? nextCursor,
    bool clearCursor = false,
    bool? loadingOlder,
  }) => ChatThreadState(
    messages: messages ?? this.messages,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
    nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
    loadingOlder: loadingOlder ?? this.loadingOlder,
  );
}

class ChatThreadController extends AutoDisposeFamilyNotifier<ChatThreadState, String> {
  late ThreadSource _source;
  Timer? _poll;
  var _seq = 0;

  @override
  ChatThreadState build(String id) {
    _source = id == guestThread
        ? _GuestSource(ref.watch(guestRepositoryProvider))
        : _StaffSource(ref.watch(chatRepositoryProvider), id);
    if (id != guestThread) {
      ref.listen(realtimeMessagesProvider, (_, next) {
        final msg = next.valueOrNull;
        if (msg?.type != 'chat.message' || msg?.data == null) return;
        final m = ChatMessage.fromJson(msg!.data!);
        if (m.conversationId != id) return;
        final s = ref.read(sessionControllerProvider);
        final me = s is AuthSignedIn ? s.session.user.id : null;
        _merge([
          m.copyWith(mine: m.mine || (me != null && m.senderType == 'user' && m.senderId == me)),
        ], markRead: true);
      });
    }
    _poll = Timer.periodic(Duration(seconds: id == guestThread ? 10 : 20), (_) => refresh(quiet: true));
    ref.onDispose(() => _poll?.cancel());
    Future.microtask(refresh);
    return const ChatThreadState();
  }

  Future<void> refresh({bool quiet = false}) async {
    if (!quiet) state = state.copyWith(loading: state.messages.isEmpty, clearError: true);
    try {
      final page = await _source.latest();
      final hadAny = state.messages.isNotEmpty;
      _merge(page.items, markRead: true);
      state = state.copyWith(
        loading: false,
        clearError: true,
        nextCursor: hadAny ? state.nextCursor : page.nextCursor,
        clearCursor: !hadAny && page.nextCursor == null,
      );
    } catch (e) {
      if (!quiet || state.messages.isEmpty) state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> loadOlder() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingOlder) return;
    state = state.copyWith(loadingOlder: true);
    try {
      final page = await _source.older(cursor);
      final known = {for (final m in state.messages) m.id};
      state = state.copyWith(
        messages: [...page.items.where((m) => !known.contains(m.id)), ...state.messages],
        nextCursor: page.nextCursor,
        clearCursor: page.nextCursor == null,
        loadingOlder: false,
      );
    } catch (_) {
      state = state.copyWith(loadingOlder: false);
    }
  }

  /// Junta mensajes del servidor con los que ya hay (sin repetir) y en orden.
  void _merge(List<ChatMessage> incoming, {bool markRead = false}) {
    if (incoming.isEmpty) return;
    final byId = {for (final m in state.messages) m.id: m};
    var fresh = false;
    for (final m in incoming) {
      final known = byId[m.id];
      if (known == null) fresh = true;
      byId[m.id] = known != null && known.mine && !m.mine ? m.copyWith(mine: true) : m;
    }
    final list = byId.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    state = state.copyWith(messages: list);
    if (fresh && markRead) unawaited(_source.read().catchError((_) {}));
  }

  /// Envía con burbuja inmediata ("enviando") que se cambia por la del servidor.
  Future<bool> send({String? body, String? fileId, String? previewUrl}) async {
    final text = body?.trim();
    if ((text == null || text.isEmpty) && fileId == null) return false;
    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
    final temp = ChatMessage(
      id: tempId,
      conversationId: arg,
      senderType: arg == guestThread ? 'guest' : 'user',
      senderId: '',
      senderName: '',
      body: text,
      fileUrl: previewUrl,
      createdAt: DateTime.now(),
      mine: true,
      state: MessageState.sending,
      localFileId: fileId,
    );
    state = state.copyWith(messages: [...state.messages, temp]);
    return _deliver(temp);
  }

  Future<bool> retry(ChatMessage m) async {
    state = state.copyWith(
      messages: [for (final x in state.messages) x.id == m.id ? x.copyWith(state: MessageState.sending) : x],
    );
    return _deliver(m);
  }

  Future<bool> _deliver(ChatMessage temp) async {
    try {
      final saved = await _source.send(body: temp.body, fileId: temp.localFileId);
      final rest = state.messages.where((x) => x.id != temp.id && x.id != saved.id).toList();
      final list = [...rest, saved.copyWith(mine: true)]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state = state.copyWith(messages: list);
      return true;
    } catch (e) {
      state = state.copyWith(
        messages: [for (final x in state.messages) x.id == temp.id ? x.copyWith(state: MessageState.failed) : x],
      );
      return false;
    }
  }
}

final chatThreadProvider = NotifierProvider.autoDispose.family<ChatThreadController, ChatThreadState, String>(
  ChatThreadController.new,
);

/// B23: cabecera de una conversación (título, reserva, silenciada, archivada).
final conversationProvider = FutureProvider.autoDispose.family<Conversation, String>(
  (ref, id) => ref.watch(chatRepositoryProvider).conversation(id),
);
