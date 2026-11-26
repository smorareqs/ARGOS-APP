import 'dart:async';

import 'package:argos_app/core/realtime/realtime_client.dart';
import 'package:argos_app/core/realtime/realtime_providers.dart';
import 'package:argos_app/features/auth/presentation/providers/auth_state.dart';
import 'package:argos_app/features/auth/presentation/providers/session_controller.dart';
import 'package:argos_app/features/notifications/data/notifications_repository.dart';
import 'package:argos_app/features/notifications/models/app_notification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'inbox_controller.g.dart';

/// La bandeja en memoria: lo cargado, los sin leer y la hora de la copia si
/// vino sin conexión.
class InboxState {
  const InboxState({
    this.items = const [],
    this.unread = 0,
    this.nextCursor,
    this.cachedAt,
    this.loadingMore = false,
  });

  final List<AppNotification> items;
  final int unread;
  final String? nextCursor;
  final DateTime? cachedAt;
  final bool loadingMore;

  InboxState copyWith({
    List<AppNotification>? items,
    int? unread,
    String? Function()? nextCursor,
    bool? loadingMore,
  }) => InboxState(
    items: items ?? this.items,
    unread: unread ?? this.unread,
    nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
    cachedAt: cachedAt,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

/// Bandeja (B16): se carga con la sesión y se actualiza sola por tiempo real
/// (`notification`, `notification.read`).
@Riverpod(keepAlive: true)
class Inbox extends _$Inbox {
  final _arrivals = StreamController<AppNotification>.broadcast();

  /// Avisos nuevos mientras la app está abierta (para el aviso en pantalla).
  Stream<AppNotification> get arrivals => _arrivals.stream;

  NotificationsRepository get _repo => ref.read(notificationsRepositoryProvider);

  @override
  Future<InboxState> build() async {
    final auth = ref.watch(sessionControllerProvider);
    if (auth is! AuthSignedIn) return const InboxState();
    final userId = auth.session.user.id;
    final tenantId = auth.session.tenant.id;
    // Volver la red recarga (la sesión pasa de offline a en línea).
    ref.listen(realtimeMessagesProvider, (_, next) {
      final msg = next.valueOrNull;
      if (msg != null) _onMessage(msg);
    });
    final (page, cachedAt) = await _repo.list();
    // Si la sesión cambió mientras cargaba, esta respuesta ya no sirve.
    final now = ref.read(sessionControllerProvider);
    if (now is AuthSignedIn && (now.session.user.id != userId || now.session.tenant.id != tenantId)) {
      return const InboxState();
    }
    return InboxState(
      items: page.items,
      unread: page.unread,
      nextCursor: page.nextCursor,
      cachedAt: cachedAt,
    );
  }

  void _onMessage(RealtimeMessage msg) {
    final current = state.valueOrNull;
    if (current == null) return;
    switch (msg.type) {
      case 'notification':
        final data = msg.data;
        if (data == null) {
          unawaited(refresh());
          return;
        }
        final n = AppNotification.fromJson(data);
        if (current.items.any((i) => i.id == n.id)) return;
        state = AsyncData(current.copyWith(items: [n, ...current.items], unread: current.unread + 1));
        _arrivals.add(n);
      case 'notification.read':
        final data = msg.data ?? const {};
        if (data['all'] == true) {
          _applyAllRead(current);
        } else if (data['id'] != null) {
          _applyRead(current, '${data['id']}');
        }
      case 'hello':
        // Reconectó: pudo haberse perdido algo mientras no había socket.
        unawaited(refresh());
    }
  }

  Future<void> refresh() async {
    try {
      final (page, cachedAt) = await _repo.list();
      state = AsyncData(
        InboxState(items: page.items, unread: page.unread, nextCursor: page.nextCursor, cachedAt: cachedAt),
      );
    } catch (e, st) {
      if (state.valueOrNull == null) state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.nextCursor == null || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final (page, _) = await _repo.list(cursor: current.nextCursor);
      final known = current.items.map((i) => i.id).toSet();
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items.where((i) => !known.contains(i.id))],
          nextCursor: () => page.nextCursor,
          loadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  /// Marca leído al instante; si el servidor falla, lo deshace.
  Future<void> markRead(String id) async {
    final current = state.valueOrNull;
    if (current == null || !current.items.any((i) => i.id == id && i.unread)) return;
    _applyRead(current, id);
    try {
      await _repo.markRead(id);
    } catch (_) {
      state = AsyncData(current);
    }
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null || current.unread == 0) return;
    _applyAllRead(current);
    try {
      await _repo.markAllRead();
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }

  void _applyRead(InboxState current, String id) {
    final target = current.items.where((i) => i.id == id && i.unread);
    if (target.isEmpty) return;
    final now = DateTime.now();
    state = AsyncData(
      current.copyWith(
        items: [for (final i in current.items) i.id == id ? i.read(now) : i],
        unread: (current.unread - 1).clamp(0, 1 << 30),
      ),
    );
  }

  void _applyAllRead(InboxState current) {
    final now = DateTime.now();
    state = AsyncData(
      current.copyWith(items: [for (final i in current.items) i.read(now)], unread: 0),
    );
  }
}

/// Sin leer (insignia de la pestaña Alertas).
@riverpod
int unreadNotifications(Ref ref) => ref.watch(inboxProvider).valueOrNull?.unread ?? 0;
