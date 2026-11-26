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
export 'tokens/custom_motion.dart';
export 'tokens/custom_shadows.dart';
export 'tokens/custom_typography.dart';

// ── Atoms ──────────────────────────────────────────────
export 'atoms/app_checkbox.dart';
export 'atoms/app_chip.dart';
export 'atoms/app_icon_button.dart';
export 'atoms/app_text_field.dart';
export 'atoms/app_toggle.dart';
export 'atoms/argos_logo.dart';
export 'atoms/avatar.dart';
export 'atoms/danger_button.dart';
export 'atoms/dark_text_field.dart';
export 'atoms/digit_code_field.dart';
export 'atoms/nav_tab_item.dart';
export 'atoms/number_stepper.dart';
export 'atoms/offline_bar.dart';
export 'atoms/photo_thumb.dart';
export 'atoms/primary_button.dart';
export 'atoms/progress_bar.dart';
export 'atoms/secondary_button.dart';
export 'atoms/skeleton.dart';
export 'atoms/status_badge.dart';
export 'atoms/summary_chip.dart';
export 'atoms/tertiary_button.dart';
export 'atoms/week_day_chip.dart';

// ── Molecules ──────────────────────────────────────────
export 'molecules/app_bottom_nav.dart';
export 'molecules/app_card.dart';
export 'molecules/app_list_tile.dart';
export 'molecules/before_after_pair.dart';
export 'molecules/checklist_item_row.dart';
export 'molecules/empty_state.dart';
export 'molecules/error_state.dart';
export 'molecules/filter_chips.dart';
export 'molecules/itinerary_header.dart';
export 'molecules/labeled_field.dart';
export 'molecules/notification_tile.dart';
export 'molecules/photo_grid.dart';
export 'molecules/quantity_row.dart';
export 'molecules/search_field.dart';
export 'molecules/section_header.dart';
export 'molecules/task_card.dart';
export 'molecules/timeline_item.dart';
export 'molecules/urgency_selector.dart';
export 'molecules/week_strip.dart';

// ── Organisms ──────────────────────────────────────────
export 'organisms/biometric_prompt.dart';
export 'organisms/login_form.dart';
export 'organisms/login_panel.dart';
export 'organisms/tenant_picker.dart';

// ── Templates ──────────────────────────────────────────
export 'templates/argos_scaffold.dart';
export 'templates/confirm_sheet.dart';
export 'templates/detail_scaffold.dart';
export 'templates/form_scaffold.dart';
export 'templates/sheet_scaffold.dart';
export 'templates/tab_scaffold.dart';
