import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CustomColors define la paleta base', () {
    expect(CustomColors.primary, isNotNull);
    expect(CustomColors.background, isNotNull);
  });
}
