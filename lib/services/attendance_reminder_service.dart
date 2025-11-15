import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timetable_model.dart';

/// Service to check for pending attendance classes
/// Shows reminders when app opens for classes that ended recently
class AttendanceReminderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

  /// Get classes that need attendance marked
  /// Checks for classes that ended 10-15 minutes ago and haven't been marked today
  Future<List<TimetableEntry>> getPendingAttendanceClasses(
    String semester,
  ) async {
    if (uid == 'guest_user') return [];

    try {
      // Get today's date in IST (assuming IST for India)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Get current day name
      final dayNames = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final currentDay = dayNames[now.weekday - 1];

      // Get current time
      final currentHour = now.hour;
      final currentMinute = now.minute;
      final currentTimeMinutes = currentHour * 60 + currentMinute;

      // Get timetable entries for today
      final timetableSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('semesters')
          .doc(semester)
          .collection('timetable')
          .where('day', isEqualTo: currentDay)
          .get();

      if (timetableSnapshot.docs.isEmpty) return [];

      final pendingClasses = <TimetableEntry>[];

      // Get today's attendance records
      final attendanceSnapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('semesters')
          .doc(semester)
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where(
            'date',
            isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))),
          )
          .get();

      final markedSubjectsToday = attendanceSnapshot.docs
          .map((doc) => doc.data()['subject'] as String)
          .toSet();

      // Check each timetable entry
      for (var doc in timetableSnapshot.docs) {
        final entry = TimetableEntry.fromMap(doc.id, doc.data());

        // Parse end time
        final endTimeParts = entry.endTime.split(':');
        if (endTimeParts.length != 2) continue;

        final endHour = int.tryParse(endTimeParts[0]);
        final endMinute = int.tryParse(endTimeParts[1]);
        if (endHour == null || endMinute == null) continue;

        final endTimeMinutes = endHour * 60 + endMinute;

        // Check if class ended 10-15 minutes ago (with some buffer)
        // We'll check if it ended between 10-30 minutes ago to catch reminders
        final minutesSinceEnd = currentTimeMinutes - endTimeMinutes;

        // If class ended 10-30 minutes ago and hasn't been marked today
        // This gives a window for the reminder (10-15 min ideal, but up to 30 min to catch missed ones)
        if (minutesSinceEnd >= 10 &&
            minutesSinceEnd <= 30 &&
            !markedSubjectsToday.contains(entry.subject)) {
          pendingClasses.add(entry);
        }
      }

      return pendingClasses;
    } catch (e) {
      print('Error getting pending attendance: $e');
      return [];
    }
  }

  /// Check if a class was already marked today
  Future<bool> isClassMarkedToday(String semester, String subject) async {
    if (uid == 'guest_user') return false;

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('semesters')
          .doc(semester)
          .collection('attendance')
          .where('subject', isEqualTo: subject)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where(
            'date',
            isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))),
          )
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
