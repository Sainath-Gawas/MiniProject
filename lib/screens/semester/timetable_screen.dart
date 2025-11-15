import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/timetable_model.dart';
import '/models/attendance_model.dart';
import '/services/firestore_service.dart';
import 'package:edutrack/utils/timetable_utils.dart';

class TimetableScreen extends StatefulWidget {
  final String semesterName;
  const TimetableScreen({Key? key, required this.semesterName})
    : super(key: key);

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _instructorController = TextEditingController();

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptPastClassesAttendance();
    });
  }

  // ------------------- AUTOMATIC ATTENDANCE PROMPT (Premium only) -------------------
  Future<void> _promptPastClassesAttendance() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if user is premium
    if (uid == 'guest_user') return;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final isPremium = userDoc.data()?['isPremium'] ?? userDoc.data()?['premium'] ?? false;
    
    if (!isPremium) return; // Only premium users get automatic popup

    // Fetch all timetable entries
    final allEntries = await _firestoreService.getTimetableOnce(
      uid,
      widget.semesterName,
    );

    // Fetch existing attendance to avoid duplicates
    final existingAttendance = await _firestoreService.getAttendanceOnce(
      uid,
      widget.semesterName,
    );

    final today = DateTime.now();

    // Filter only past classes that are not logged yet
    final pendingClasses = allEntries.where((entry) {
      final classDate = entry.getEndDateTime(forDate: today);
      final alreadyLogged = existingAttendance.any(
        (att) =>
            att.subject == entry.subject &&
            att.date.year == classDate.year &&
            att.date.month == classDate.month &&
            att.date.day == classDate.day,
      );
      return classDate.isBefore(today) && !alreadyLogged;
    }).toList();

    for (var entry in pendingClasses) {
      final classConducted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Class: ${entry.subject}'),
          content: const Text('Was this class conducted?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (classConducted != true) continue;

      final attended = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Class: ${entry.subject}'),
          content: const Text('Did you attend this class?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      final record = AttendanceRecord(
        id: null,
        date: entry.getEndDateTime(forDate: today),
        subject: entry.subject,
        status: attended == true
            ? AttendanceStatus.present
            : AttendanceStatus.absent,
      );

      await _firestoreService.addAttendanceRecord(
        uid,
        widget.semesterName,
        record,
      );

      // Update Subject model attendance counts
      await _firestoreService.updateSubjectAttendance(
        uid,
        widget.semesterName,
        entry.subject,
        classHappened: classConducted == true,
        attended: attended == true,
        wasCancelled: classConducted != true,
      );
    }
  }

  // ------------------- TIMETABLE ENTRY DIALOG -------------------
  void _openTimetableDialog({TimetableEntry? existingEntry}) {
    String? selectedDay = existingEntry?.day;
    _startTimeController.text = existingEntry?.startTime ?? '';
    _endTimeController.text = existingEntry?.endTime ?? '';
    _subjectController.text = existingEntry?.subject ?? '';
    _locationController.text = existingEntry?.location ?? '';
    _instructorController.text = existingEntry?.instructor ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> _pickTime(TextEditingController controller) async {
            final now = TimeOfDay.now();
            final initial =
                TimetableUtils.parseTimeOfDay(controller.text) ?? now;
            final picked = await showTimePicker(
              context: context,
              initialTime: initial,
            );
            if (picked != null) {
              controller.text = TimetableUtils.formatTimeOfDay(picked);
              setDialogState(() {});
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              existingEntry == null
                  ? "Add Timetable Entry"
                  : "Edit Timetable Entry",
              style: const TextStyle(
                color: Color(0xFF283593),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    decoration: const InputDecoration(
                      labelText: "Day",
                      border: OutlineInputBorder(),
                    ),
                    items: _days
                        .map(
                          (day) =>
                              DropdownMenuItem(value: day, child: Text(day)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => selectedDay = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _startTimeController,
                    readOnly: true,
                    onTap: () => _pickTime(_startTimeController),
                    decoration: const InputDecoration(
                      labelText: "Start Time",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _endTimeController,
                    readOnly: true,
                    onTap: () => _pickTime(_endTimeController),
                    decoration: const InputDecoration(
                      labelText: "End Time",
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: "Subject *",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: "Location (Optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _instructorController,
                    decoration: const InputDecoration(
                      labelText: "Instructor (Optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF283593),
                ),
                onPressed: () async {
                  final day = selectedDay ?? '';
                  final startTime = _startTimeController.text.trim();
                  final endTime = _endTimeController.text.trim();
                  final subject = _subjectController.text.trim();
                  final location = _locationController.text.trim().isEmpty
                      ? null
                      : _locationController.text.trim();
                  final instructor = _instructorController.text.trim().isEmpty
                      ? null
                      : _instructorController.text.trim();

                  if (day.isEmpty ||
                      startTime.isEmpty ||
                      endTime.isEmpty ||
                      subject.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all required fields'),
                      ),
                    );
                    return;
                  }

                  final entry = TimetableEntry(
                    id: existingEntry?.id,
                    day: day,
                    startTime: startTime,
                    endTime: endTime,
                    subject: subject,
                    location: location,
                    instructor: instructor,
                  );

                  if (existingEntry == null) {
                    await _firestoreService.addTimetableEntry(
                      uid,
                      widget.semesterName,
                      entry,
                    );
                  } else {
                    await _firestoreService.updateTimetableEntry(
                      uid,
                      widget.semesterName,
                      entry,
                    );
                  }

                  if (mounted) Navigator.pop(context);
                },
                child: Text(existingEntry == null ? "Add" : "Update"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteEntryConfirmation(TimetableEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Entry"),
        content: const Text(
          "Are you sure you want to delete this timetable entry?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _firestoreService.deleteTimetableEntry(
                uid,
                widget.semesterName,
                entry.id!,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableCard(TimetableEntry entry) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF283593),
          child: Text(
            entry.day.substring(0, 3).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text(
          entry.subject,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${entry.startTime} - ${entry.endTime}',
              style: const TextStyle(
                color: Color(0xFF616161),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (entry.location != null) ...[
              const SizedBox(height: 2),
              Text(
                '📍 ${entry.location}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            if (entry.instructor != null) ...[
              const SizedBox(height: 2),
              Text(
                '👤 ${entry.instructor}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _openTimetableDialog(existingEntry: entry);
            if (value == 'delete') _deleteEntryConfirmation(entry);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("Timetable"),
        backgroundColor: const Color(0xFF283593),
      ),
      body: StreamBuilder<List<TimetableEntry>>(
        stream: _firestoreService.getTimetable(uid, widget.semesterName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return const Center(
              child: Text(
                "No timetable entries yet.\nTap + to add one!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );

          final entries = snapshot.data!;
          final groupedByDay = <String, List<TimetableEntry>>{};
          for (var entry in entries)
            groupedByDay.putIfAbsent(entry.day, () => []).add(entry);

          final sortedDays = groupedByDay.keys.toList()
            ..sort((a, b) => _days.indexOf(a).compareTo(_days.indexOf(b)));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: sortedDays.expand((day) {
              final dayEntries = groupedByDay[day]!;
              dayEntries.sort(
                (a, b) => a.getStartDateTime().compareTo(b.getStartDateTime()),
              );

              return [
                ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF283593),
                    ),
                  ),
                  subtitle: Text(
                    '${dayEntries.length} class${dayEntries.length > 1 ? 'es' : ''}',
                  ),
                  children: dayEntries.map(_buildTimetableCard).toList(),
                ),
              ];
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF283593),
        child: const Icon(Icons.add),
        onPressed: () => _openTimetableDialog(),
      ),
    );
  }
}
