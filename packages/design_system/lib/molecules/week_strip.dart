import 'package:design_system/atoms/week_day_chip.dart';
import 'package:flutter/material.dart';

/// Un día dentro de la [WeekStrip].
class WeekDay {
  const WeekDay({
    required this.weekday,
    required this.day,
    this.selected = false,
    this.muted = false,
  });

  final String weekday;
  final String day;
  final bool selected;
  final bool muted;
}

/// Tira horizontal de días de la semana.
/// Ref: ARGOS App · tira de semana del Itinerario.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.days, this.onSelect});

  final List<WeekDay> days;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < days.length; i++) ...[
          WeekDayChip(
            weekday: days[i].weekday,
            day: days[i].day,
            selected: days[i].selected,
            muted: days[i].muted,
            onTap: onSelect == null ? null : () => onSelect!(i),
          ),
          if (i != days.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}
