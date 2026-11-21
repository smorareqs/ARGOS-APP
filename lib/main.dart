import 'package:argos_app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // EB Garamond viene empaquetada en el design system: nunca se descarga.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const ProviderScope(child: ArgosApp()));
}
