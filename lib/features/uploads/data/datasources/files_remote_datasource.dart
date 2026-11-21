import 'dart:io';

import 'package:argos_app/core/config/app_config.dart';
import 'package:argos_app/core/network/api_exception.dart';
import 'package:argos_app/core/network/dio_client.dart';
import 'package:argos_app/core/network/mock/mock_routes.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'files_remote_datasource.g.dart';

/// Destino prefirmado para subir un archivo directo al almacenamiento.
class PresignedUpload {
  const PresignedUpload({
    required this.fileId,
    required this.url,
    required this.method,
    this.fields = const {},
    this.headers = const {},
  });

  /// `{file_id, url | upload_url, method?, fields?, headers?}`. Si trae
  /// `fields` es un POST prefirmado de S3 (formulario multipart, fase01
  /// §3.8); si no, un PUT con el archivo como cuerpo.
  factory PresignedUpload.fromJson(Map<String, dynamic> json) {
    final fields = <String, String>{
      for (final e in (json['fields'] as Map? ?? const {}).entries)
        '${e.key}': '${e.value}',
    };
    return PresignedUpload(
      fileId: '${json['file_id'] ?? json['id']}',
      url: '${json['upload_url'] ?? json['url']}',
      method:
          (json['method'] as String?)?.toUpperCase() ??
          (fields.isEmpty ? 'PUT' : 'POST'),
      fields: fields,
      headers: <String, String>{
        for (final e in (json['headers'] as Map? ?? const {}).entries)
          '${e.key}': '${e.value}',
      },
    );
  }

  final String fileId;
  final String url;
  final String method;
  final Map<String, String> fields;
  final Map<String, String> headers;
}

/// Servicio de archivos (fase01 §3.8): presign → subida directa → confirm.
class FilesRemoteDataSource {
  FilesRemoteDataSource({required Dio api, required Dio storage})
    : _api = api,
      _storage = storage;

  /// API de ARGOS, con token.
  final Dio _api;

  /// Sin token ni URL base: habla con el almacenamiento (S3).
  final Dio _storage;

  Future<PresignedUpload> presign({
    required String module,
    required String kind,
    required String entityType,
    required String entityId,
    required String contentType,
    required int size,
  }) => _send(
    () => _api.post<dynamic>(
      '/files/presign-upload',
      data: {
        'module': module,
        'kind': kind,
        'entity_type': entityType,
        'entity_id': entityId,
        'content_type': contentType,
        'size': size,
      },
    ),
    (data) => PresignedUpload.fromJson(Map<String, dynamic>.from(data as Map)),
  );

  Future<void> upload(
    PresignedUpload target,
    File file, {
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    final length = await file.length();
    void progress(int sent, int total) {
      final t = total > 0 ? total : length;
      if (t > 0) onProgress?.call((sent / t).clamp(0.0, 1.0));
    }

    await _send(() {
      if (target.method == 'POST') {
        return _storage.post<dynamic>(
          target.url,
          data: FormData.fromMap({
            ...target.fields,
            'Content-Type': contentType,
            'file': MultipartFile.fromFileSync(file.path),
          }),
          options: Options(headers: target.headers),
          onSendProgress: progress,
        );
      }
      return _storage.put<dynamic>(
        target.url,
        data: file.openRead(),
        options: Options(
          headers: {
            Headers.contentTypeHeader: contentType,
            Headers.contentLengthHeader: length,
            ...target.headers,
          },
        ),
        onSendProgress: progress,
      );
    }, (_) {});
  }

  Future<void> confirm(String fileId) => _send(
    () => _api.post<dynamic>('/files/${Uri.encodeComponent(fileId)}/confirm'),
    (_) {},
  );

  Future<T> _send<T>(
    Future<Response<dynamic>> Function() request,
    T Function(dynamic data) parse,
  ) async {
    try {
      final response = await request();
      return parse(response.data);
    } on DioException catch (e) {
      final api = ApiException.fromDio(e);
      if (api != null) throw api;
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
FilesRemoteDataSource filesRemoteDataSource(Ref ref) {
  final storage = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(minutes: 2),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.plain,
    ),
  );
  if (ref.watch(appConfigProvider).useMock) {
    storage.httpClientAdapter = ref.watch(mockBackendProvider);
  }
  return FilesRemoteDataSource(api: ref.watch(dioClientProvider), storage: storage);
}
