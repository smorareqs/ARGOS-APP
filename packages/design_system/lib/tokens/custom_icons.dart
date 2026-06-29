import 'package:flutter/material.dart';

/// Catálogo de iconos ARGOS (Material rounded).
abstract final class CustomIcons {
  static const IconData login = Icons.login_rounded;
  static const IconData home = Icons.home_rounded;
  static const IconData sync = Icons.sync_rounded;
  static const IconData logout = Icons.logout_rounded;
  static const IconData visibility = Icons.visibility_rounded;
  static const IconData visibilityOff = Icons.visibility_off_rounded;

  static const IconData email = Icons.mail_outline_rounded;
  static const IconData lock = Icons.lock_outline_rounded;
  static const IconData arrowForward = Icons.arrow_forward_rounded;
  static const IconData person = Icons.person_outline_rounded;
  static const IconData search = Icons.search_rounded;

  // ── Navegación inferior (Itinerario) ───────────────────
  static const IconData itinerary = Icons.calendar_today_rounded;
  static const IconData activities = Icons.checklist_rounded;
  static const IconData equipment = Icons.inventory_2_outlined;
  static const IconData metrics = Icons.bar_chart_rounded;

  // ── Tarjetas de tarea ──────────────────────────────────
  static const IconData notifications = Icons.notifications_none_rounded;
  static const IconData time = Icons.schedule_rounded;
  static const IconData property = Icons.home_outlined;
  static const IconData incident = Icons.warning_amber_rounded;
  static const IconData done = Icons.check_rounded;
}
