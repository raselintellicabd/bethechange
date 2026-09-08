import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';

class AppointmentCalendarView extends StatelessWidget {
  const AppointmentCalendarView({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.availableDates,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final Set<DateTime> availableDates;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  bool _isAvailable(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return availableDates.contains(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar<void>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2035, 12, 31),
      focusedDay: focusedMonth,
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
        disabledTextStyle: const TextStyle(color: AppColors.textDisabled),
        outsideDaysVisible: false,
      ),
      enabledDayPredicate: _isAvailable,
      onPageChanged: onMonthChanged,
      onDaySelected: (selected, focused) {
        if (_isAvailable(selected)) {
          onDateSelected(selected);
        }
      },
    );
  }
}
