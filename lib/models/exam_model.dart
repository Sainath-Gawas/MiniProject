import 'package:cloud_firestore/cloud_firestore.dart';

enum ExamType {
  internal,
  semester,
  assignment,
  quiz,
  other,
}

class Exam {
  final String? id;
  final String name; // e.g., "Internal 1", "Mid-term", "Assignment 1"
  final ExamType type;
  final double maxMarks;
  final double marksObtained;
  final DateTime date;
  final String? notes; // Optional notes

  Exam({
    required this.id,
    required this.name,
    required this.type,
    required this.maxMarks,
    required this.marksObtained,
    required this.date,
    this.notes,
  });

  factory Exam.fromMap(String id, Map<String, dynamic> data) {
    ExamType examType;
    final typeString = data['type'] as String? ?? 'other';
    switch (typeString.toLowerCase()) {
      case 'internal':
        examType = ExamType.internal;
        break;
      case 'semester':
        examType = ExamType.semester;
        break;
      case 'assignment':
        examType = ExamType.assignment;
        break;
      case 'quiz':
        examType = ExamType.quiz;
        break;
      default:
        examType = ExamType.other;
        break;
    }

    return Exam(
      id: id,
      name: data['name'] ?? '',
      type: examType,
      maxMarks: (data['maxMarks'] ?? 0.0).toDouble(),
      marksObtained: (data['marksObtained'] ?? 0.0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.toString().split('.').last, // Store as 'internal', 'semester', etc.
      'maxMarks': maxMarks,
      'marksObtained': marksObtained,
      'date': date,
      'notes': notes,
    };
  }

  double get percentage {
    if (maxMarks == 0) return 0.0;
    return (marksObtained / maxMarks) * 100;
  }

  String get typeString {
    switch (type) {
      case ExamType.internal:
        return 'Internal Test';
      case ExamType.semester:
        return 'Semester End Exam';
      case ExamType.assignment:
        return 'Assignment';
      case ExamType.quiz:
        return 'Quiz';
      case ExamType.other:
        return 'Other';
    }
  }
}
