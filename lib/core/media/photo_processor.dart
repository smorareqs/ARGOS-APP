import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Lado mayor máximo de una foto subida (ux-ui.md §3.4).
const photoMaxSide = 1600;

/// Calidad JPEG de las fotos subidas (ux-ui.md §3.4).
const photoJpegQuality = 80;

/// Prepara una foto de la cámara para subirla: corrige la orientación,
/// reduce a [photoMaxSide] px de lado mayor, agrega la marca de agua con
/// fecha, hora y código de propiedad en la esquina inferior y la codifica en
/// JPEG [photoJpegQuality]. Corre en otro isolate para no trabar la UI.
Future<Uint8List> processPhoto(
  Uint8List original, {
  required DateTime takenAt,
  String? propertyCode,
}) {
  return Isolate.run(
    () => processPhotoSync(
      original,
      takenAt: takenAt,
      propertyCode: propertyCode,
    ),
  );
}

/// Versión síncrona de [processPhoto] (para pruebas).
Uint8List processPhotoSync(
  Uint8List original, {
  required DateTime takenAt,
  String? propertyCode,
}) {
  final decoded = img.decodeImage(original);
  if (decoded == null) {
    throw const FormatException('No se pudo leer la foto.');
  }
  var image = img.bakeOrientation(decoded);

  final longest = math.max(image.width, image.height);
  if (longest > photoMaxSide) {
    image = image.width >= image.height
        ? img.copyResize(
            image,
            width: photoMaxSide,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: photoMaxSide,
            interpolation: img.Interpolation.average,
          );
  }

  _stamp(image, watermarkText(takenAt, propertyCode));
  return img.encodeJpg(image, quality: photoJpegQuality);
}

/// Texto de la marca de agua: "22/10/2026 09:42 | LAU-01". Solo ASCII
/// porque las fuentes de mapa de bits del paquete `image` no traen más.
String watermarkText(DateTime takenAt, String? propertyCode) {
  String two(int n) => n.toString().padLeft(2, '0');
  final date =
      '${two(takenAt.day)}/${two(takenAt.month)}/${takenAt.year} '
      '${two(takenAt.hour)}:${two(takenAt.minute)}';
  final code = propertyCode?.trim();
  return code == null || code.isEmpty ? date : '$date | ${_ascii(code)}';
}

String _ascii(String s) => String.fromCharCodes(
  s.runes.map((r) => r >= 32 && r < 127 ? r : 63 /* ? */),
);

void _stamp(img.Image image, String text) {
  final font = image.width >= 1000 ? img.arial24 : img.arial14;
  final textWidth = text.codeUnits.fold<int>(
    0,
    (sum, c) => sum + (font.characters[c]?.xAdvance ?? font.base ~/ 2),
  );
  final padX = font.base ~/ 2;
  final padY = font.base ~/ 3;
  final margin = font.base ~/ 2;

  final x2 = image.width - margin;
  final y2 = image.height - margin;
  final x1 = math.max(0, x2 - textWidth - padX * 2);
  final y1 = math.max(0, y2 - font.lineHeight - padY * 2);

  // Banda teal ARGOS semitransparente para que el texto se lea en cualquier
  // foto sin tapar la evidencia.
  img.fillRect(
    image,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    color: img.ColorRgba8(0, 56, 65, 150),
    radius: padY,
  );
  img.drawString(
    image,
    text,
    font: font,
    x: x1 + padX,
    y: y1 + padY,
    color: img.ColorRgb8(255, 255, 255),
  );
}
