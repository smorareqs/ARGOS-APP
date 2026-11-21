import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

/// Configuración de compilación, leída de `--dart-define`.
///
/// * `ARGOS_API_URL`: URL base de la API (por defecto el backend local visto
///   desde el emulador de Android).
/// * `ARGOS_MOCK=true`: usa el backend simulado en memoria en lugar de HTTP
///   (ver `core/network/mock/`). Es como se trabaja hasta que cada endpoint
///   esté en `main` del backend.
class AppConfig {
  const AppConfig({required this.apiBaseUrl, required this.useMock});

  factory AppConfig.fromEnvironment() => const AppConfig(
    apiBaseUrl: String.fromEnvironment(
      'ARGOS_API_URL',
      defaultValue: 'http://10.0.2.2:8000/api/v1',
    ),
    useMock: bool.fromEnvironment('ARGOS_MOCK'),
  );

  final String apiBaseUrl;
  final bool useMock;
}

@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => AppConfig.fromEnvironment();
