/// ARGOS Design System.
///
/// Diseño atómico — cada capa se construye sobre la anterior y reutiliza
/// siempre la inferior:
///
///   tokens → atoms → molecules → organisms → templates → (screens en la app)
///
/// Ref: ARGOS Design System.dc.html.
library;

// ── Tokens ─────────────────────────────────────────────
export 'tokens/custom_colors.dart';
export 'tokens/custom_dimensions.dart';
export 'tokens/custom_icons.dart';
export 'tokens/custom_shadows.dart';
export 'tokens/custom_typography.dart';

// ── Atoms ──────────────────────────────────────────────
export 'atoms/app_chip.dart';
export 'atoms/app_text_field.dart';
export 'atoms/argos_logo.dart';
export 'atoms/primary_button.dart';
export 'atoms/secondary_button.dart';
export 'atoms/status_badge.dart';
export 'atoms/tertiary_button.dart';

// ── Molecules ──────────────────────────────────────────
export 'molecules/app_card.dart';
export 'molecules/labeled_field.dart';
export 'molecules/section_header.dart';

// ── Organisms ──────────────────────────────────────────
export 'organisms/login_form.dart';

// ── Templates ──────────────────────────────────────────
export 'templates/argos_scaffold.dart';
