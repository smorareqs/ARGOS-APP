import 'dart:async';
import 'dart:convert';

import 'package:argos_app/core/push/push_providers.dart';
import 'package:argos_app/core/storage/secure_storage_service.dart';
import 'package:argos_app/core/utils/toast.dart';
import 'package:argos_app/features/chat/models/chat.dart';
import 'package:argos_app/features/guest/data/guest_repository.dart';
import 'package:argos_app/features/guest/models/guest.dart';
import 'package:argos_app/features/hospitality/models/hospitality.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado del modo huésped. Es aparte de la sesión del personal: un teléfono
/// puede tener las dos, pero el router da prioridad a la del personal.
sealed class GuestState {
  const GuestState();
}

class GuestLoading extends GuestState {
  const GuestLoading();
}

class GuestNone extends GuestState {
  const GuestNone([this.message]);

  /// Por qué terminó (vencida, revocada), para mostrarlo en A9.
  final String? message;
}

class GuestActive extends GuestState {
  const GuestActive(this.session);
  final GuestSession session;
}

class GuestSessionController extends Notifier<GuestState> {
  @override
  GuestState build() {
    ref.read(guestTokenProvider).onExpired = () {
      if (state is GuestActive) unawaited(signOut('Tu acceso terminó. Pide un código nuevo a la recepción.'));
    };
    unawaited(_restore());
    return const GuestLoading();
  }

  SecureStorageService get _storage => ref.read(secureStorageServiceProvider);

  Future<void> _restore() async {
    try {
      final raw = await _storage.readGuestSession();
      if (raw == null) {
        state = const GuestNone();
        return;
      }
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final session = GuestSession(
        token: '${j['token']}',
        me: GuestMe.fromJson(Map<String, dynamic>.from(j['me'] as Map)),
      );
      if (session.expired(DateTime.now())) {
        await _storage.deleteGuestSession();
        state = const GuestNone('Tu estancia terminó. ¡Gracias por tu visita!');
        return;
      }
      _activate(session);
    } on Object {
      state = const GuestNone();
    }
  }

  void _activate(GuestSession session) {
    ref.read(guestTokenProvider).value = session.token;
    state = GuestActive(session);
    unawaited(_registerPush());
  }

  /// Entra con el token del enlace o con código y correo. Devuelve el error en
  /// palabras o null si entró.
  Future<String?> signIn({String? token, String? code, String? email}) async {
    try {
      final session = await ref.read(guestRepositoryProvider).signIn(token: token, code: code, email: email);
      await _storage.writeGuestSession(jsonEncode({'token': session.token, 'me': session.me.toJson()}));
      _activate(session);
      return null;
    } on Object catch (e) {
      return errorMessage(e);
    }
  }

  Future<void> signOut([String? message]) async {
    ref.read(guestTokenProvider).value = null;
    await _storage.deleteGuestSession();
    state = GuestNone(message);
  }

  Future<void> _registerPush() async {
    try {
      final token = await ref.read(pushServiceProvider).start();
      if (token != null) await ref.read(guestRepositoryProvider).registerDevice(token);
    } on Object {
      // Sin push la app funciona igual.
    }
  }
}

final guestSessionProvider = NotifierProvider<GuestSessionController, GuestState>(GuestSessionController.new);

GuestMe? guestMeOf(GuestState s) => s is GuestActive ? s.session.me : null;

// ── Datos del huésped ─────────────────────────────────────

final guestStayProvider = FutureProvider.autoDispose<GuestStay>(
  (ref) => ref.watch(guestRepositoryProvider).reservation(),
);

final guestAreasProvider = FutureProvider.autoDispose<({List<SharedArea> areas, List<AreaBooking> bookings})>(
  (ref) => ref.watch(guestRepositoryProvider).areas(),
);

final guestParkingProvider = FutureProvider.autoDispose<List<ParkingSpot>>(
  (ref) => ref.watch(guestRepositoryProvider).parking(),
);

final guestSlotsProvider = FutureProvider.autoDispose.family<List<AreaSlot>, (String, String)>(
  (ref, key) => ref.watch(guestRepositoryProvider).availability(key.$1, parseDay(key.$2)),
);

/// F8: datos de la conversación con la empresa (título y si está archivada).
final guestChatInfoProvider = FutureProvider.autoDispose<GuestChat>((ref) => ref.watch(guestRepositoryProvider).chat());

/// F1: el código de la puerta (se vuelve a pedir cada 10 min mientras se ve).
final guestLockProvider = FutureProvider.autoDispose<GuestLock>((ref) {
  final timer = Timer(const Duration(minutes: 10), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return ref.watch(guestRepositoryProvider).lock();
});
