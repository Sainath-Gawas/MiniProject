import '../utils/timetable_utils.dart';

class TimetableEntry {
  final String? id;
  final String day; // Monday, Tuesday, etc.
  final String startTime;
  final String endTime;
  final String subject;
  final String? location;
  final String? instructor;

  TimetableEntry({
    this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.location,
    this.instructor,
  });

  factory TimetableEntry.fromMap(String id, Map<String, dynamic> data) {
    return TimetableEntry(
      id: id,
      day: data['day'] ?? '',
      startTime: data['startTime'] ?? '',
      endTime: data['endTime'] ?? '',
      subject: data['subject'] ?? '',
      location: data['location'],
      instructor: data['instructor'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'subject': subject,
      'location': location,
      'instructor': instructor,
    };
  }

  /// Returns a DateTime object for the start time of the class today
  DateTime getStartDateTime({DateTime? forDate}) {
    final tod = TimetableUtils.parseTimeOfDay(startTime);
    final now = forDate ?? DateTime.now();
    if (tod == null) return now;
    return DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
  }

  /// Returns a DateTime object for the end time of the class today
  DateTime getEndDateTime({DateTime? forDate}) {
    final tod = TimetableUtils.parseTimeOfDay(endTime);
    final now = forDate ?? DateTime.now();
    if (tod == null) return now;
    return DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
  }

  /// Returns true if this class has already ended
  bool hasClassEnded({DateTime? forDate}) {
    return getEndDateTime(forDate: forDate).isBefore(DateTime.now());
  }

  /// Creates a copy with modified fields
  TimetableEntry copyWith({
    String? id,
    String? day,
    String? startTime,
    String? endTime,
    String? subject,
    String? location,
    String? instructor,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subject: subject ?? this.subject,
      location: location ?? this.location,
      instructor: instructor ?? this.instructor,
    );
  }
}
