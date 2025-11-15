import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/note_model.dart';
import '../models/timetable_model.dart';
import '../models/attendance_model.dart';
import '../models/subject_model.dart';
import '../models/exam_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ------------------- USER METHODS -------------------

  Future<void> createUserDoc(
    String uid,
    String email, {
    String? name,
    String? phone,
  }) async {
    if (_isGuest(uid)) return;

    await _db.collection('users').doc(uid).set({
      'email': email,
      'name': name ?? '',
      'phone': phone ?? '',
      'role': 'user',
      'premium': false,
      'isPremium': false,
      'uiMode': 'light',
      'semesters': [],
      'semester': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AppUser?> getUser(String uid) async {
    if (_isGuest(uid)) return null;

    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists ? AppUser.fromMap(uid, doc.data()!) : null;
  }

  Future<List<AppUser>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs
        .map((doc) => AppUser.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> togglePremium(String uid, bool premium) async {
    if (_isGuest(uid)) return;

    await _db.collection('users').doc(uid).update({
      'premium': premium,
      'isPremium': premium,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> upgradeToPremium(String uid) async {
    if (_isGuest(uid)) return;

    await _db.collection('users').doc(uid).update({
      'premium': true,
      'isPremium': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUiMode(String uid, String uiMode) async {
    if (_isGuest(uid)) return;

    await _db.collection('users').doc(uid).update({
      'uiMode': uiMode,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<String> getUserUiMode(String uid) {
    if (_isGuest(uid)) {
      return Stream.value('light');
    }

    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['uiMode'] ?? 'light');
  }

  Stream<bool> getUserPremiumStatus(String uid) {
    if (_isGuest(uid)) {
      return Stream.value(false);
    }

    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['isPremium'] ?? doc.data()?['premium'] ?? false);
  }

  Future<void> updateNotificationSettings(String uid, bool enabled) async {
    if (_isGuest(uid)) return;

    await _db.collection('users').doc(uid).update({
      'attendanceNotificationsEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> getNotificationSettings(String uid) async {
    if (_isGuest(uid)) return false;

    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['attendanceNotificationsEnabled'] ?? true;
  }

  // ------------------- NOTES METHODS -------------------

  Stream<List<Note>> getNotes(String uid, String semester) {
    if (_isGuest(uid)) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('notes')
        .orderBy('datetime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Note.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> addNote(String uid, String semester, Note note) async {
    if (_isGuest(uid)) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('notes')
        .add(note.toMap());
  }

  Future<void> updateNote(String uid, String semester, Note note) async {
    if (_isGuest(uid) || note.id == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('notes')
        .doc(note.id)
        .update(note.toMap());
  }

  Future<void> deleteNote(String uid, String semester, String noteId) async {
    if (_isGuest(uid)) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('notes')
        .doc(noteId)
        .delete();
  }

  // ------------------- TIMETABLE METHODS -------------------

  Stream<List<TimetableEntry>> getTimetable(String uid, String semester) {
    if (_isGuest(uid)) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('timetable')
        .snapshots()
        .map((snapshot) {
          final entries = snapshot.docs
              .map((doc) => TimetableEntry.fromMap(doc.id, doc.data()))
              .toList();

          final dayOrder = [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ];

          entries.sort((a, b) {
            final dayCompare = dayOrder
                .indexOf(a.day)
                .compareTo(dayOrder.indexOf(b.day));
            if (dayCompare != 0) return dayCompare;
            return a.getStartDateTime().compareTo(b.getStartDateTime());
          });

          return entries;
        });
  }

  Future<List<TimetableEntry>> getTimetableOnce(
    String uid,
    String semester,
  ) async {
    if (_isGuest(uid)) return [];

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('timetable')
        .get();
    final entries = snapshot.docs
        .map((doc) => TimetableEntry.fromMap(doc.id, doc.data()))
        .toList();

    final dayOrder = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    entries.sort((a, b) {
      final dayCompare = dayOrder
          .indexOf(a.day)
          .compareTo(dayOrder.indexOf(b.day));
      if (dayCompare != 0) return dayCompare;
      return a.getStartDateTime().compareTo(b.getStartDateTime());
    });

    return entries;
  }

  Future<void> addTimetableEntry(
    String uid,
    String semester,
    TimetableEntry entry,
  ) async {
    if (_isGuest(uid)) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('timetable')
        .add(entry.toMap());
  }

  Future<void> updateTimetableEntry(
    String uid,
    String semester,
    TimetableEntry entry,
  ) async {
    if (_isGuest(uid) || entry.id == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('timetable')
        .doc(entry.id)
        .update(entry.toMap());
  }

  Future<void> deleteTimetableEntry(
    String uid,
    String semester,
    String entryId,
  ) async {
    if (_isGuest(uid)) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('timetable')
        .doc(entryId)
        .delete();
  }

  // ------------------- ATTENDANCE METHODS -------------------

  Stream<List<AttendanceRecord>> getAttendance(String uid, String semester) {
    if (_isGuest(uid)) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('attendance')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<List<AttendanceRecord>> getAttendanceOnce(
    String uid,
    String semester,
  ) async {
    if (_isGuest(uid)) return [];

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('attendance')
        .get();
    return snapshot.docs
        .map((doc) => AttendanceRecord.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> addAttendanceRecord(
    String uid,
    String semester,
    AttendanceRecord record,
  ) async {
    if (_isGuest(uid)) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('attendance')
        .add(record.toMap());
  }

  Future<void> updateAttendanceRecord(
    String uid,
    String semester,
    AttendanceRecord record,
  ) async {
    if (_isGuest(uid) || record.id == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('attendance')
        .doc(record.id)
        .update(record.toMap());
  }

  Future<void> deleteAttendanceRecord(
    String uid,
    String semester,
    String recordId,
  ) async {
    if (_isGuest(uid)) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('attendance')
        .doc(recordId)
        .delete();
  }

  Future<Map<String, dynamic>> getAttendanceStats(
    String uid,
    String semester,
    String subject,
  ) async {
    if (_isGuest(uid))
      return {
        'present': 0,
        'absent': 0,
        'late': 0,
        'total': 0,
        'percentage': 0.0,
      };

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('attendance')
        .where('subject', isEqualTo: subject)
        .get();

    int present = 0, absent = 0, late = 0;
    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] as String;
      if (status == 'present')
        present++;
      else if (status == 'absent')
        absent++;
      else if (status == 'late')
        late++;
    }

    final total = present + absent + late;
    final percentage = total > 0 ? (present / total * 100) : 0.0;

    return {
      'present': present,
      'absent': absent,
      'late': late,
      'total': total,
      'percentage': percentage,
    };
  }

  // ------------------- PENDING CLASSES -------------------

  /// Returns classes whose time is over but attendance not yet logged
  Future<List<TimetableEntry>> getPendingClasses(
    String uid,
    String semester,
  ) async {
    if (_isGuest(uid)) return [];

    final now = DateTime.now();
    final timetable = await getTimetableOnce(uid, semester);
    final attendance = await getAttendanceOnce(uid, semester);

    final loggedKeys = attendance.map((att) {
      final date = att.date;
      return '${att.subject}_${date.year}-${date.month}-${date.day}';
    }).toSet();

    return timetable.where((entry) {
      final entryEnd = entry.getEndDateTime(forDate: now);
      final key =
          '${entry.subject}_${entryEnd.year}-${entryEnd.month}-${entryEnd.day}';
      return entryEnd.isBefore(now) && !loggedKeys.contains(key);
    }).toList();
  }

  // ------------------- SUBJECT METHODS -------------------

  Stream<List<Subject>> getSubjects(String uid, String semester) {
    if (_isGuest(uid)) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('subjects')
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Subject.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<Subject?> getSubject(
    String uid,
    String semester,
    String subjectName,
  ) async {
    if (_isGuest(uid)) return null;

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('subjects')
        .where('name', isEqualTo: subjectName)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty)
      return Subject.fromMap(
        snapshot.docs.first.id,
        snapshot.docs.first.data(),
      );
    return null;
  }

  Future<void> saveSubject(String uid, String semester, Subject subject) async {
    if (_isGuest(uid)) return;

    final subjectData = subject.toMap();
    subjectData['updatedAt'] = FieldValue.serverTimestamp();
    if (subject.id == null) {
      subjectData['createdAt'] = FieldValue.serverTimestamp();
      await _db
          .collection('users')
          .doc(uid)
          .collection('semesters')
          .doc(semester)
          .collection('subjects')
          .add(subjectData);
    } else {
      await _db
          .collection('users')
          .doc(uid)
          .collection('semesters')
          .doc(semester)
          .collection('subjects')
          .doc(subject.id)
          .update(subjectData);
    }
  }

  Future<void> updateSubjectAttendance(
    String uid,
    String semester,
    String subjectName, {
    required bool classHappened,
    required bool attended,
    bool wasCancelled = false,
  }) async {
    if (_isGuest(uid)) return;

    final subject = await getSubject(uid, semester, subjectName);
    if (subject == null || wasCancelled) return;

    int newTotal = subject.totalClassesConducted + (classHappened ? 1 : 0);
    int newAttended =
        subject.classesAttended + (attended && classHappened ? 1 : 0);

    final updatedSubject = Subject(
      id: subject.id,
      name: subject.name,
      targetAttendancePercentage: subject.targetAttendancePercentage,
      totalClassesConducted: newTotal,
      classesAttended: newAttended,
      createdAt: subject.createdAt,
      updatedAt: DateTime.now(),
    );

    await saveSubject(uid, semester, updatedSubject);
  }

  // ------------------- EXAMS METHODS -------------------

  Stream<List<Exam>> getExams(String uid, String semester, String subjectId) {
    if (_isGuest(uid)) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('subjects')
        .doc(subjectId)
        .collection('exams')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Exam.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<List<Exam>> getExamsOnce(
    String uid,
    String semester,
    String subjectId,
  ) async {
    if (_isGuest(uid)) return [];

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('subjects')
        .doc(subjectId)
        .collection('exams')
        .get();

    return snapshot.docs
        .map((doc) => Exam.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> addExam(
    String uid,
    String semester,
    String subjectId,
    Exam exam,
  ) async {
    if (_isGuest(uid)) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('subjects')
        .doc(subjectId)
        .collection('exams')
        .add(exam.toMap());
  }

  Future<void> updateExam(
    String uid,
    String semester,
    String subjectId,
    Exam exam,
  ) async {
    if (_isGuest(uid) || exam.id == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('subjects')
        .doc(subjectId)
        .collection('exams')
        .doc(exam.id)
        .update(exam.toMap());
  }

  Future<void> deleteExam(
    String uid,
    String semester,
    String subjectId,
    String examId,
  ) async {
    if (_isGuest(uid)) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('semesters')
        .doc(semester)
        .collection('subjects')
        .doc(subjectId)
        .collection('exams')
        .doc(examId)
        .delete();
  }

  // ------------------- HELPER -------------------

  bool _isGuest(String uid) => uid.toLowerCase().startsWith('guest');
}
