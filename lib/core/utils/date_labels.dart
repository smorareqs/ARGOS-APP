/// Fechas en español según la distancia (ux-ui.md §3.7). Sin dependencias
/// de `intl` para no inicializar locales.
abstract final class DateLabels {
  static const _weekdays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// Inicial del día, p. ej. "L" (lunes) o "D" (domingo).
  static String weekdayInitial(DateTime date) =>
      ['L', 'M', 'M', 'J', 'V', 'S', 'D'][date.weekday - 1];

  /// "Miércoles 22 de octubre".
  static String longDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]} ${date.day} de ${_months[date.month - 1]}';

  /// "22 oct", o "22 oct 2025" si no es del año en curso.
  static String shortDate(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final label = '${date.day} ${_months[date.month - 1].substring(0, 3)}';
    return date.year == reference.year ? label : '$label ${date.year}';
  }

  /// "hace un momento", "hace 5 min", "hace 2 h", "ayer", "22 oct".
  static String relative(DateTime date, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(date);
    if (diff.inMinutes < 1) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    return shortDate(date, now: reference);
  }
}
