import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

/// Handler for interactive attendance notifications
/// This should be called when user taps on notification or responds to it
class AttendanceNotificationHandler {
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

  /// Show interactive dialog for marking attendance
  Future<void> handleNotificationResponse({
    required BuildContext context,
    required String semester,
    required String subject,
    required String time,
  }) async {
    // First question: Did the class happen?
    final classHappened = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Class Reminder'),
        content: Text('Did your $subject class at $time happen today?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // No, cancelled
            child: const Text('No, it was cancelled'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Yes, happened
            child: const Text('Yes, it happened'),
          ),
        ],
      ),
    );

    if (classHappened == null) return; // User dismissed

    if (!classHappened) {
      // Class was cancelled - don't create any attendance record
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Class marked as cancelled - no attendance recorded'),
          ),
        );
      }
      return;
    }

    // Second question: Did you attend?
    final attended = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Mark Attendance'),
        content: Text('Did you attend $subject class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Absent
            child: const Text('No, I was absent'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Present
            child: const Text('Yes, I attended'),
          ),
        ],
      ),
    );

    if (attended == null) return; // User dismissed

    // Update Subject model directly (this will trigger real-time update in attendance screen)
    await _firestoreService.updateSubjectAttendance(
      uid,
      semester,
      subject,
      classHappened: true,
      attended: attended,
      wasCancelled: false,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            attended
                ? 'Attendance marked - You attended ✓'
                : 'Attendance marked - You were absent ✗',
          ),
        ),
      );
    }
  }
}
