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
  });

  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final Set<DateTime> availableDates;

  /// Inclusive booking-window bounds (clinic-local calendar days).
  final DateTime firstDay;
  final DateTime lastDay;

  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  bool _isAvailable(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return availableDates.contains(normalized);
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

    return TableCalendar<void>(
      firstDay: first,
      lastDay: last,
      focusedDay: safeFocused,
      selectedDayPredicate: (day) =>
          selectedDate != null && isSameDay(selectedDate, day),
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
          color: AppColors.primary,
          shape: BoxShape.circle,
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
