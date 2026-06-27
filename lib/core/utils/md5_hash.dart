import 'dart:convert';

import 'package:crypto/crypto.dart';

String hashMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}
