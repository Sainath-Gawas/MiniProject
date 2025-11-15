import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, late }

class AttendanceRecord {
  final String? id;
  final DateTime date;
  final String subject;
  final AttendanceStatus status;
  final String? notes;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.subject,
    required this.status,
    this.notes,
  });

  factory AttendanceRecord.fromMap(String id, Map<String, dynamic> data) {
    AttendanceStatus status;
    final statusString = data['status'] as String? ?? 'absent';
    switch (statusString.toLowerCase()) {
      case 'present':
        status = AttendanceStatus.present;
        break;
      case 'late':
        status = AttendanceStatus.late;
        break;
      case 'absent':
      default:
        status = AttendanceStatus.absent;
        break;
    }

    return AttendanceRecord(
      id: id,
      date: (data['date'] as Timestamp).toDate(),
      subject: data['subject'] ?? '',
      status: status,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'subject': subject,
      'status': status.toString().split('.').last,
      'notes': notes,
    };
  }

  String get statusString {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
    }
  }
}
