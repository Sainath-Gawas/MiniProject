import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/models/subject_model.dart';
import '/services/firestore_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String semesterName;
  const AttendanceScreen({Key? key, required this.semesterName})
    : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

  // ------------------- CREATE SUBJECT -------------------
  void _openCreateSubjectDialog() {
    final _nameCtrl = TextEditingController();
    final _targetCtrl = TextEditingController(text: '75.0');
    final _totalCtrl = TextEditingController(text: '0');
    final _attendedCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Create Subject',
          style: TextStyle(
            color: Color(0xFF283593),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Target % (e.g. 75.0)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _totalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial total classes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _attendedCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Initial attended classes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF283593),
            ),
            onPressed: () async {
              final name = _nameCtrl.text.trim();
              final target = double.tryParse(_targetCtrl.text.trim()) ?? 75.0;
              final total = int.tryParse(_totalCtrl.text.trim()) ?? 0;
              final attended = int.tryParse(_attendedCtrl.text.trim()) ?? 0;

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter subject name')),
                );
                return;
              }
              if (attended > total) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attended cannot exceed total')),
                );
                return;
              }

              final subject = Subject(
                id: null,
                name: name,
                targetAttendancePercentage: target,
                totalClassesConducted: total,
                classesAttended: attended,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await _firestoreService.saveSubject(
                uid,
                widget.semesterName,
                subject,
              );

              if (mounted) {
                Navigator.pop(context); // close after save
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subject created successfully')),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ------------------- EDIT SUBJECT -------------------
  void _openEditSubjectDialog(Subject subject) {
    final _targetCtrl = TextEditingController(
      text: subject.targetAttendancePercentage.toString(),
    );
    final _totalCtrl = TextEditingController(
      text: subject.totalClassesConducted.toString(),
    );
    final _attendedCtrl = TextEditingController(
      text: subject.classesAttended.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit ${subject.name}',
          style: const TextStyle(
            color: Color(0xFF283593),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Target %',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _totalCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total classes conducted',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _attendedCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Classes attended',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Use this to correct or set initial values for a subject.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF283593),
            ),
            onPressed: () async {
              final target =
                  double.tryParse(_targetCtrl.text.trim()) ??
                  subject.targetAttendancePercentage;
              final total =
                  int.tryParse(_totalCtrl.text.trim()) ??
                  subject.totalClassesConducted;
              final attended =
                  int.tryParse(_attendedCtrl.text.trim()) ??
                  subject.classesAttended;

              if (attended > total) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Attended cannot exceed total')),
                );
                return;
              }

              final updated = Subject(
                id: subject.id,
                name: subject.name,
                targetAttendancePercentage: target,
                totalClassesConducted: total,
                classesAttended: attended,
                createdAt: subject.createdAt,
                updatedAt: DateTime.now(),
              );

              await _firestoreService.saveSubject(
                uid,
                widget.semesterName,
                updated,
              );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subject updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ------------------- RECORD CLASS -------------------
  void _openRecordClassDialog(Subject subject) {
    showDialog(
      context: context,
      builder: (context) {
        bool attended = true;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(
              'Record Class - ${subject.name}',
              style: const TextStyle(
                color: Color(0xFF283593),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Did you attend this class?'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Present'),
                      selected: attended,
                      selectedColor: Colors.green.shade200,
                      onSelected: (v) => setState(() => attended = true),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Absent'),
                      selected: !attended,
                      selectedColor: Colors.red.shade200,
                      onSelected: (v) => setState(() => attended = false),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF283593),
                ),
                onPressed: () async {
                  await _firestoreService.updateSubjectAttendance(
                    uid,
                    widget.semesterName,
                    subject.name,
                    classHappened: true,
                    attended: attended,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          attended ? 'Marked Present' : 'Marked Absent',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Record'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------- BUILD SUBJECT CARD -------------------
  Widget _buildSubjectCard(Subject subject) {
    final percent = subject.currentAttendancePercentage;
    final target = subject.targetAttendancePercentage;
    final isOnTrack = subject.isOnTrack;
    final needMore = _calculateNeededClasses(subject);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(
                    subject.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF283593),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOnTrack
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOnTrack ? 'On Track ✓' : 'Below Target',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isOnTrack
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _openEditSubjectDialog(subject);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit Subject')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Attendance %
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Target',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${target.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF283593),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Current',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isOnTrack ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                percent >= target
                    ? Colors.green
                    : (percent >= target * 0.8 ? Colors.orange : Colors.red),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('Attended', subject.classesAttended, Colors.green),
                _statItem('Missed', subject.classesMissed, Colors.red),
                _statItem('Total', subject.totalClassesConducted, Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            if (!isOnTrack && subject.totalClassesConducted > 0)
              Text(
                needMore > 0
                    ? 'Need $needMore more attended classes (approx.) to reach target'
                    : 'Target reachable with upcoming classes',
                style: TextStyle(fontSize: 13, color: Colors.red.shade700),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openRecordClassDialog(subject),
                  icon: const Icon(Icons.how_to_reg),
                  label: const Text('Record Class'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF283593),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _openEditSubjectDialog(subject),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  int _calculateNeededClasses(Subject s) {
    final target = s.targetAttendancePercentage / 100;
    final a = s.classesAttended;
    final t = s.totalClassesConducted;

    if (t == 0 && a == 0) return 0;
    if (s.currentAttendancePercentage >= s.targetAttendancePercentage) return 0;

    final numerator = (target * t) - a;
    final denom = 1 - target;
    if (denom <= 0) return 0;
    final needed = (numerator / denom).ceil();
    return needed > 0 ? needed : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: const Color(0xFF283593),
      ),
      body: StreamBuilder<List<Subject>>(
        stream: _firestoreService.getSubjects(uid, widget.semesterName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjects = snapshot.data ?? [];

          if (subjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No subjects yet. Add subjects to start tracking attendance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _openCreateSubjectDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Subject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF283593),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            itemBuilder: (context, index) => _buildSubjectCard(subjects[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF283593),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
        onPressed: _openCreateSubjectDialog,
      ),
    );
  }
}
