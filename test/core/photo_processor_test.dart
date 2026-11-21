import 'dart:io';

import 'package:argos_app/core/media/photo_processor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('reduce a 1600 px, JPEG y marca de agua', () {
    final big = img.Image(width: 4000, height: 3000);
    img.fill(big, color: img.ColorRgb8(200, 190, 170));
    final out = processPhotoSync(
      img.encodeJpg(big),
      takenAt: DateTime(2026, 10, 22, 9, 42),
      propertyCode: 'LAU-01',
    );
    final decoded = img.decodeJpg(out)!;
    expect(decoded.width, 1600);
    expect(decoded.height, 1200);
    // La esquina inferior derecha lleva la banda teal de la marca.
    final p = decoded.getPixel(1600 - 20, 1200 - 18);
    expect(p.b, lessThan(170));
  });

  test('las fotos pequeñas no se agrandan', () {
    final small = img.Image(width: 800, height: 600);
    final out = processPhotoSync(img.encodePng(small), takenAt: DateTime(2026));
    expect(img.decodeJpg(out)!.width, 800);
  });

  test('texto de la marca de agua', () {
    final t = DateTime(2026, 3, 5, 7, 8);
    expect(watermarkText(t, 'LAU-01'), '05/03/2026 07:08 | LAU-01');
    expect(watermarkText(t, null), '05/03/2026 07:08');
    expect(watermarkText(t, 'Peñón'), '05/03/2026 07:08 | Pe??n');
  });

  test('muestra (archivo para revisión manual)', () {
    final out = processPhotoSync(
      File('assets/demo/room_before.jpg').readAsBytesSync(),
      takenAt: DateTime(2026, 10, 22, 9, 42),
      propertyCode: 'LAU-01',
    );
    final dir = Platform.environment['ARGOS_SAMPLE_DIR'];
    if (dir != null) File('$dir/watermark_sample.jpg').writeAsBytesSync(out);
  });
}
