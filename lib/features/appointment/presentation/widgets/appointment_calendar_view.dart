import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';

class AppointmentCalendarView extends StatelessWidget {
  const AppointmentCalendarView({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.availableDates,
    required this.firstDay,
    required this.lastDay,
    required this.onMonthChanged,
    required this.onDateSelected,
    this.sessionDates = const {},
  });

  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final Set<DateTime> availableDates;

  /// Dates that already have a saved session (shown with a lighter highlight).
  final Set<DateTime> sessionDates;

  /// Inclusive booking-window bounds (clinic-local calendar days).
  final DateTime firstDay;
  final DateTime lastDay;

  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  bool _isAvailable(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return availableDates.contains(normalized) || _isSessionDay(day);
  }

  bool _isSessionDay(DateTime day) {
    for (final d in sessionDates) {
      if (isSameDay(d, day)) return true;
    }
    return false;
  }

  bool _isActiveDay(DateTime day) =>
      selectedDate != null && isSameDay(selectedDate, day);

  Widget _dayCell({
    required DateTime day,
    required Color background,
    required Color foreground,
    FontWeight weight = FontWeight.w800,
  }) {
    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: foreground,
          fontWeight: weight,
          fontSize: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final first = DateTime(firstDay.year, firstDay.month, firstDay.day);
    final last = DateTime(lastDay.year, lastDay.month, lastDay.day);

    // table_calendar requires focusedDay within [firstDay, lastDay].
    // Prefer the 1st of the focused month when it falls inside the window.
    var safeFocused = DateTime(focusedMonth.year, focusedMonth.month, 1);
    if (safeFocused.isBefore(first)) safeFocused = first;
    if (safeFocused.isAfter(last)) safeFocused = last;

    // Light fill for saved sessions; deeper fill for the currently tapped day.
    const sessionFill = AppColors.brandMutedSurface;
    const sessionFg = AppColors.brandPrimaryDark;
    const activeFill = AppColors.primaryDark;
    const activeFg = AppColors.textOnPrimary;

    return TableCalendar<void>(
      firstDay: first,
      lastDay: last,
      focusedDay: safeFocused,
      selectedDayPredicate: _isActiveDay,
      calendarFormat: CalendarFormat.month,
      availableGestures: AvailableGestures.horizontalSwipe,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: activeFill,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: activeFg,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
        defaultTextStyle: const TextStyle(
          color: AppColors.forest,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
        weekendTextStyle: const TextStyle(
          color: AppColors.forest,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
        disabledTextStyle: TextStyle(
          color: AppColors.textDisabled.withValues(alpha: 0.55),
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        outsideDaysVisible: false,
      ),
      calendarBuilders: CalendarBuilders(
        // Saved session dates that are not the active tap.
        defaultBuilder: (context, day, focused) {
          if (!_isSessionDay(day) || _isActiveDay(day)) return null;
          return _dayCell(
            day: day,
            background: sessionFill,
            foreground: sessionFg,
          );
        },
        todayBuilder: (context, day, focused) {
          if (_isActiveDay(day)) {
            return _dayCell(
              day: day,
              background: activeFill,
              foreground: activeFg,
            );
          }
          if (_isSessionDay(day)) {
            return _dayCell(
              day: day,
              background: sessionFill,
              foreground: sessionFg,
            );
          }
          return null;
        },
        selectedBuilder: (context, day, focused) {
          return _dayCell(
            day: day,
            background: activeFill,
            foreground: activeFg,
          );
        },
      ),
      enabledDayPredicate: _isAvailable,
      onPageChanged: (focusedDay) {
        final month = DateTime(focusedDay.year, focusedDay.month);
        final minMonth = DateTime(first.year, first.month);
        final maxMonth = DateTime(last.year, last.month);
        if (month.isBefore(minMonth) || month.isAfter(maxMonth)) return;
        onMonthChanged(month);
      },
      onDaySelected: (selected, focused) {
        if (_isAvailable(selected)) {
          onDateSelected(selected);
        }
      },
    );
  }
}
