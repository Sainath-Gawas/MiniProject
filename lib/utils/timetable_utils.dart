import 'package:flutter/material.dart';

class TimetableUtils {
  // Parse string like "9:00 AM" to TimeOfDay
  static TimeOfDay? parseTimeOfDay(String time) {
    try {
      final format = time.trim().toUpperCase();
      final parts = format.split(RegExp(r'[: ]'));
      if (parts.length < 3) return null;
      int hour = int.parse(parts[0]);
      final int minute = int.parse(parts[1]);
      final String period = parts[2];
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  // Format TimeOfDay to "9:00 AM"
  static String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Convert string like "9:00 AM" to total minutes since 00:00
  static int timeToMinutes(String time) {
    final tod = parseTimeOfDay(time);
    if (tod == null) return 0;
    return tod.hour * 60 + tod.minute;
  }

  // Check if a class has ended based on startTime + duration
  static bool hasClassEnded(String startTime, int durationMinutes) {
    final tod = parseTimeOfDay(startTime);
    if (tod == null) return false;
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final endMinutes = tod.hour * 60 + tod.minute + durationMinutes;
    return nowMinutes >= endMinutes;
  }

  // Get DateTime for a class today based on startTime
  static DateTime getClassStartDateTime(String startTime) {
    final tod = parseTimeOfDay(startTime);
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      tod?.hour ?? 0,
      tod?.minute ?? 0,
    );
  }

  // Get DateTime for the end of a class today
  static DateTime getClassEndDateTime(String startTime, int durationMinutes) {
    final start = getClassStartDateTime(startTime);
    return start.add(Duration(minutes: durationMinutes));
  }

  // Validate HH:MM AM/PM format
  static bool isValidTimeFormat(String time) => parseTimeOfDay(time) != null;

  // Check start < end
  static bool isValidTimeRange(String start, String end) =>
      timeToMinutes(end) > timeToMinutes(start);
}
