import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Avisos push del teléfono (FCM). Sin configuración de Firebase (modo
/// simulado, pruebas o falta `ARGOS_FIREBASE_*`) no hace nada.
abstract interface class PushService {
  /// Pide permiso y devuelve el token del teléfono, o null si no hay push.
  Future<String?> start();

  /// Token nuevo (FCM lo rota de vez en cuando).
  Stream<String> get tokenRefresh;

  /// `data` del push que la persona tocó (abre `app_route`).
  Stream<Map<String, String>> get opened;

  /// El push con el que se abrió la app desde cerrada, si lo hubo.
  Future<Map<String, String>?> initialOpen();

  String get platform;
}

class NoopPushService implements PushService {
  const NoopPushService();

  @override
  Future<String?> start() async => null;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, String>> get opened => const Stream.empty();

  @override
  Future<Map<String, String>?> initialOpen() async => null;

  @override
  String get platform => 'android';
}

/// Configuración de Firebase por `--dart-define` (no se guarda en el repo):
/// `ARGOS_FIREBASE_API_KEY`, `ARGOS_FIREBASE_APP_ID`,
/// `ARGOS_FIREBASE_SENDER_ID` y `ARGOS_FIREBASE_PROJECT_ID`.
class FirebaseConfig {
  static const apiKey = String.fromEnvironment('ARGOS_FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('ARGOS_FIREBASE_APP_ID');
  static const senderId = String.fromEnvironment('ARGOS_FIREBASE_SENDER_ID');
  static const projectId = String.fromEnvironment('ARGOS_FIREBASE_PROJECT_ID');

  static bool get configured =>
      apiKey.isNotEmpty && appId.isNotEmpty && senderId.isNotEmpty && projectId.isNotEmpty;

  static FirebaseOptions get options => const FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: senderId,
    projectId: projectId,
  );
}

class FirebasePushService implements PushService {
  Future<bool>? _ready;

  Future<bool> _init() => _ready ??= () async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: FirebaseConfig.options);
      }
      return true;
    } catch (_) {
      return false;
    }
  }();

  @override
  Future<String?> start() async {
    if (!await _init()) return null;
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return null;
    // En primer plano la bandeja se actualiza por tiempo real; el sistema
    // no muestra el aviso dos veces.
    await messaging.setForegroundNotificationPresentationOptions(alert: false, badge: true);
    try {
      // El token de registro clásico: el backend lo manda en `message.token`
      // de FCM HTTP v1. register()/onRegistered devuelven otro id (FID).
      // ignore: deprecated_member_use
      return await messaging.getToken();
    } catch (_) {
      return null; // sin Google Play Services o sin red
    }
  }

  @override
  Stream<String> get tokenRefresh async* {
    if (!await _init()) return;
    // ignore: deprecated_member_use
    yield* FirebaseMessaging.instance.onTokenRefresh;
  }

  @override
  Stream<Map<String, String>> get opened async* {
    if (!await _init()) return;
    yield* FirebaseMessaging.onMessageOpenedApp.map(_data);
  }

  @override
  Future<Map<String, String>?> initialOpen() async {
    if (!await _init()) return null;
    final message = await FirebaseMessaging.instance.getInitialMessage();
    return message == null ? null : _data(message);
  }

  static Map<String, String> _data(RemoteMessage m) => {
    for (final e in m.data.entries) e.key: '${e.value}',
  };

  @override
  String get platform => Platform.isIOS ? 'ios' : 'android';
}
