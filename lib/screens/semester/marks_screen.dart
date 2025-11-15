import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '/models/subject_model.dart';
import '/models/exam_model.dart';
import '/models/gpa_scale_model.dart';
import '/services/firestore_service.dart';

class MarksScreen extends StatefulWidget {
  final String semesterName;
  const MarksScreen({Key? key, required this.semesterName}) : super(key: key);

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
  final GPAScale _gpaScale = GPAScale.defaultScale();

  // Exam dialog controllers
  final TextEditingController _examNameController = TextEditingController();
  final TextEditingController _examMaxMarksController = TextEditingController();
  final TextEditingController _examMarksObtainedController = TextEditingController();
  final TextEditingController _examNotesController = TextEditingController();
  DateTime? _selectedExamDate;
  ExamType? _selectedExamType;

  // Subject setup dialog controllers
  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _targetOverallController = TextEditingController(text: '80.0');
  final TextEditingController _numberOfITsController = TextEditingController(text: '3');
  final TextEditingController _bestITsController = TextEditingController(text: '2');
  final TextEditingController _maxMarksPerITController = TextEditingController(text: '20');
  final TextEditingController _maxMarksPerAssignmentController = TextEditingController(text: '10');
  final TextEditingController _maxInternalComponentController = TextEditingController(text: '30');
  final TextEditingController _maxSemesterEndController = TextEditingController(text: '45');

  void _openSubjectSetupDialog({Subject? subject}) {
    if (subject != null) {
      _subjectNameController.text = subject.name;
      _targetOverallController.text = subject.targetOverallPercentage.toString();
      _numberOfITsController.text = subject.numberOfITs.toString();
      _bestITsController.text = subject.bestITsToConsider.toString();
      _maxMarksPerITController.text = subject.maxMarksPerIT.toString();
      _maxMarksPerAssignmentController.text = subject.maxMarksPerAssignment.toString();
      _maxInternalComponentController.text = subject.maxInternalComponent.toString();
      _maxSemesterEndController.text = subject.maxSemesterEndExam.toString();
    } else {
      _subjectNameController.clear();
      _targetOverallController.text = '80.0';
      _numberOfITsController.text = '3';
      _bestITsController.text = '2';
      _maxMarksPerITController.text = '20';
      _maxMarksPerAssignmentController.text = '10';
      _maxInternalComponentController.text = '30';
      _maxSemesterEndController.text = '45';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          subject == null ? 'Setup Subject for Marks' : 'Edit Subject Configuration',
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
                controller: _subjectNameController,
                enabled: subject == null,
                decoration: const InputDecoration(
                  labelText: 'Subject Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetOverallController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target Overall Percentage *',
                  hintText: 'e.g., 80.0',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Internal Test (IT) Configuration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _numberOfITsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of IT Attempts (Y) *',
                  hintText: 'e.g., 3',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bestITsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Best ITs to Consider (X) *',
                  hintText: 'e.g., 2',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxMarksPerITController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Max Marks per IT *',
                  hintText: 'e.g., 20',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Assignment Configuration',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _maxMarksPerAssignmentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Max Marks per Assignment *',
                  hintText: 'e.g., 10',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Component Max Marks',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _maxInternalComponentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Max Internal Component *',
                  hintText: 'e.g., 30',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxSemesterEndController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Max Semester End Exam *',
                  hintText: 'e.g., 45',
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
              if (_subjectNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter subject name')),
                );
                return;
              }

              final targetOverall = double.tryParse(_targetOverallController.text.trim()) ?? 80.0;
              final numberOfITs = int.tryParse(_numberOfITsController.text.trim()) ?? 0;
              final bestITs = int.tryParse(_bestITsController.text.trim()) ?? 0;
              final maxMarksPerIT = double.tryParse(_maxMarksPerITController.text.trim()) ?? 0.0;
              final maxMarksPerAssignment = double.tryParse(_maxMarksPerAssignmentController.text.trim()) ?? 0.0;
              final maxInternalComponent = double.tryParse(_maxInternalComponentController.text.trim()) ?? 0.0;
              final maxSemesterEnd = double.tryParse(_maxSemesterEndController.text.trim()) ?? 0.0;

              if (bestITs > numberOfITs) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Best ITs cannot exceed number of ITs')),
                );
                return;
              }

              final updatedSubject = Subject(
                id: subject?.id,
                name: _subjectNameController.text.trim(),
                targetOverallPercentage: targetOverall,
                numberOfITs: numberOfITs,
                bestITsToConsider: bestITs,
                maxMarksPerIT: maxMarksPerIT,
                maxMarksPerAssignment: maxMarksPerAssignment,
                maxInternalComponent: maxInternalComponent,
                maxSemesterEndExam: maxSemesterEnd,
                targetAttendancePercentage: subject?.targetAttendancePercentage ?? 75.0,
                totalClassesConducted: subject?.totalClassesConducted ?? 0,
                classesAttended: subject?.classesAttended ?? 0,
                createdAt: subject?.createdAt ?? DateTime.now(),
                updatedAt: DateTime.now(),
              );

              await _firestoreService.saveSubject(uid, widget.semesterName, updatedSubject);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(subject == null ? 'Subject setup complete!' : 'Subject updated!')),
                );
              }
            },
            child: Text(subject == null ? 'Setup' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _openExamDialog({Exam? exam, required Subject subject}) {
    if (exam != null) {
      _examNameController.text = exam.name;
      _examMaxMarksController.text = exam.maxMarks.toString();
      _examMarksObtainedController.text = exam.marksObtained.toString();
      _examNotesController.text = exam.notes ?? '';
      _selectedExamDate = exam.date;
      _selectedExamType = exam.type;
    } else {
      _examNameController.clear();
      _examMaxMarksController.clear();
      _examMarksObtainedController.clear();
      _examNotesController.clear();
      _selectedExamDate = DateTime.now();
      _selectedExamType = ExamType.internal;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            exam == null ? "Add Exam/Assignment" : "Edit Exam/Assignment",
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
                  controller: _examNameController,
                  decoration: const InputDecoration(
                    labelText: "Exam Name *",
                    hintText: "e.g., IT1, Assignment 1, Semester End Exam",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ExamType>(
                  value: _selectedExamType,
                  decoration: const InputDecoration(
                    labelText: "Exam Type *",
                    border: OutlineInputBorder(),
                  ),
                  items: ExamType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getExamTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedExamType = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text("Date *"),
                  subtitle: Text(
                    _selectedExamDate != null
                        ? DateFormat('dd MMM yyyy').format(_selectedExamDate!)
                        : 'Select date',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedExamDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        _selectedExamDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _examMaxMarksController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Maximum Marks *",
                    hintText: "e.g., 20 for IT, 10 for Assignment",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _examMarksObtainedController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Marks Obtained *",
                    hintText: "Leave blank if not yet taken",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _examNotesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Notes (Optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF283593),
              ),
              onPressed: () async {
                if (_examNameController.text.trim().isEmpty ||
                    _examMaxMarksController.text.trim().isEmpty ||
                    _selectedExamDate == null ||
                    _selectedExamType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }

                final maxMarks = double.tryParse(_examMaxMarksController.text.trim());
                final marksObtained = double.tryParse(_examMarksObtainedController.text.trim()) ?? 0.0;

                if (maxMarks == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter valid maximum marks')),
                  );
                  return;
                }

                if (marksObtained > maxMarks) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marks obtained cannot exceed maximum marks')),
                  );
                  return;
                }

                final newExam = Exam(
                  id: exam?.id,
                  name: _examNameController.text.trim(),
                  type: _selectedExamType!,
                  maxMarks: maxMarks,
                  marksObtained: marksObtained,
                  date: _selectedExamDate!,
                  notes: _examNotesController.text.trim().isEmpty
                      ? null
                      : _examNotesController.text.trim(),
                );

                if (newExam.id == null) {
                  await _firestoreService.addExam(
                    uid,
                    widget.semesterName,
                    subject.id!,
                    newExam,
                  );
                } else {
                  await _firestoreService.updateExam(
                    uid,
                    widget.semesterName,
                    subject.id!,
                    newExam,
                  );
                }

                if (mounted) Navigator.pop(context);
              },
              child: Text(exam == null ? "Add" : "Update"),
            ),
          ],
        ),
      ),
    );
  }

  String _getExamTypeLabel(ExamType type) {
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

  Color _getExamTypeColor(ExamType type) {
    switch (type) {
      case ExamType.internal:
        return Colors.blue;
      case ExamType.semester:
        return Colors.purple;
      case ExamType.assignment:
        return Colors.orange;
      case ExamType.quiz:
        return Colors.green;
      case ExamType.other:
        return Colors.grey;
    }
  }

  void _deleteExamConfirmation(Exam exam, Subject subject) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Exam"),
        content: const Text("Are you sure you want to delete this exam record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _firestoreService.deleteExam(
                uid,
                widget.semesterName,
                subject.id!,
                exam.id!,
              );
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(Exam exam, Subject subject) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: _getExamTypeColor(exam.type),
          child: Text(
            exam.percentage.toStringAsFixed(0),
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          exam.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    exam.typeString,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: _getExamTypeColor(exam.type),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy').format(exam.date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${exam.marksObtained.toStringAsFixed(1)} / ${exam.maxMarks.toStringAsFixed(1)} (${exam.percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF616161),
              ),
            ),
            if (exam.notes != null) ...[
              const SizedBox(height: 4),
              Text(
                exam.notes!,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _openExamDialog(exam: exam, subject: subject);
            } else if (value == 'delete') {
              _deleteExamConfirmation(exam, subject);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  // Calculate overall marks and percentage using Subject model's calculation methods
  // This respects the "best X of Y ITs" configuration and proper scaling
  Map<String, dynamic> _calculateOverallMarksAndPercentage(Subject subject, List<Exam> exams) {
    // Filter exams that have marks entered (marksObtained > 0)
    final enteredExams = exams.where((e) => e.marksObtained > 0).toList();
    
    if (enteredExams.isEmpty) {
      return {
        'overallMarks': 0.0,
        'maxMarks': 0.0,
        'percentage': 0.0,
        'availableMarks': 0.0,
        'availableMaxMarks': 0.0,
        'availablePercentage': 0.0,
        'hasInternal': false,
        'hasSemester': false,
      };
    }
    
    // Use Subject model's calculation methods which implement:
    // - Best X of Y ITs selection
    // - CEIL rounding and capping
    // - Proper scaling to internal component
    // - Addition of semester exam marks
    
    final finalInternalScore = subject.calculateFinalInternalComponentScore(exams);
    final semesterEndScore = subject.calculateSemesterEndExamScore(exams);
    
    // Check which components are available
    final hasInternal = finalInternalScore > 0 || 
        exams.any((e) => (e.type.toString().split('.').last == 'internal' || 
                          e.type.toString().split('.').last == 'assignment') && 
                         e.marksObtained > 0);
    final hasSemester = semesterEndScore > 0;
    
    // Calculate overall marks (only add semester if available)
    final overallMarks = finalInternalScore + (hasSemester ? semesterEndScore : 0.0);
    
    // Max possible marks based on available components only
    final maxPossibleMarks = subject.maxInternalComponent + 
        (hasSemester ? subject.maxSemesterEndExam : 0.0);
    
    // Overall percentage based on all components (for display)
    final totalMaxMarks = subject.maxInternalComponent + subject.maxSemesterEndExam;
    final totalOverallMarks = finalInternalScore + semesterEndScore;
    final percentage = totalMaxMarks > 0 
        ? (totalOverallMarks / totalMaxMarks) * 100 
        : 0.0;
    
    // Available percentage (only considering available components)
    final availablePercentage = maxPossibleMarks > 0 
        ? (overallMarks / maxPossibleMarks) * 100 
        : 0.0;
    
    return {
      'overallMarks': totalOverallMarks,
      'maxMarks': totalMaxMarks,
      'percentage': percentage,
      'availableMarks': overallMarks,
      'availableMaxMarks': maxPossibleMarks,
      'availablePercentage': availablePercentage,
      'hasInternal': hasInternal,
      'hasSemester': hasSemester,
    };
  }

  Widget _buildCalculatedMarksCard(Subject subject, List<Exam> exams) {
    // Filter exams with marks entered
    final enteredExams = exams.where((e) => e.marksObtained > 0).toList();
    
    // Calculate overall marks and percentage using proper calculation logic
    final overallData = _calculateOverallMarksAndPercentage(subject, exams);
    final overallMarks = overallData['overallMarks']!;
    final maxMarks = overallData['maxMarks']!;
    final overallPercentage = overallData['percentage']!;
    final availableMarks = overallData['availableMarks']!;
    final availableMaxMarks = overallData['availableMaxMarks']!;
    final availablePercentage = overallData['availablePercentage']!;
    final hasInternal = overallData['hasInternal'] as bool;
    final hasSemester = overallData['hasSemester'] as bool;
    
    // Calculate other metrics (these use the complex calculation logic)
    final finalCappedITAvg = subject.calculateFinalCappedITAverage(exams);
    final rawAssignmentMarks = subject.calculateRawAssignmentMarks(exams);
    final finalInternalScore = subject.calculateFinalInternalComponentScore(exams);
    final semesterEndScore = subject.calculateSemesterEndExamScore(exams);
    
    // Calculate GPA based on overall percentage (only when all components available)
    final subjectGPA = hasInternal && hasSemester 
        ? _gpaScale.getGPA(overallPercentage) 
        : 0.0;
    
    // Status logic: Compare available percentage against target
    // Only show "Below Target" when we have actual marks and they're below target
    // Uses availablePercentage which only considers available components
    final hasEnteredMarks = enteredExams.isNotEmpty;
    
    // Determine if on track based on available components only
    // availablePercentage already handles the case of partial components
    final isOnTrack = !hasEnteredMarks || 
        availablePercentage >= subject.targetOverallPercentage;

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Calculated Marks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF283593),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: !hasEnteredMarks 
                        ? Colors.blue.shade100 
                        : (isOnTrack ? Colors.green.shade100 : Colors.red.shade100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    !hasEnteredMarks 
                        ? 'Enter Marks' 
                        : (isOnTrack ? 'On Track ✓' : 'Below Target'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: !hasEnteredMarks 
                          ? Colors.blue.shade700 
                          : (isOnTrack ? Colors.green.shade700 : Colors.red.shade700),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildMarksRow('Internal Tests Average', '${finalCappedITAvg.toStringAsFixed(1)} / ${subject.maxMarksPerIT.toStringAsFixed(1)}'),
            _buildMarksRow('Assignment Marks', '${rawAssignmentMarks.toStringAsFixed(1)} / ${subject.maxMarksPerAssignment.toStringAsFixed(1)}'),
            _buildMarksRow('Internal Component Score', '${finalInternalScore.toStringAsFixed(1)} / ${subject.maxInternalComponent.toStringAsFixed(1)}'),
            _buildMarksRow('Semester End Exam Score', '${semesterEndScore.toStringAsFixed(1)} / ${subject.maxSemesterEndExam.toStringAsFixed(1)}'),
            const Divider(),
            // Show overall marks obtained vs max possible marks
            if (hasEnteredMarks)
              _buildMarksRow(
                'Overall Subject Marks', 
                hasInternal && hasSemester
                    ? '${overallMarks.toStringAsFixed(1)} / ${maxMarks.toStringAsFixed(1)}'
                    : hasInternal
                        ? '${availableMarks.toStringAsFixed(1)} / ${availableMaxMarks.toStringAsFixed(1)} (Internal only)'
                        : '${availableMarks.toStringAsFixed(1)} / ${availableMaxMarks.toStringAsFixed(1)} (Semester only)',
                isBold: true,
              ),
            _buildMarksRow(
              'Overall Percentage', 
              hasEnteredMarks 
                ? hasInternal && hasSemester
                    ? '${overallPercentage.toStringAsFixed(2)}%'
                    : '${availablePercentage.toStringAsFixed(2)}% (${hasInternal ? "Internal" : "Semester"} only)'
                : 'Enter marks to see percentage',
              isBold: true, 
              color: hasEnteredMarks 
                ? (isOnTrack ? Colors.green : Colors.red)
                : Colors.grey,
            ),
            if (hasEnteredMarks && hasInternal && hasSemester)
              _buildMarksRow('Subject GPA', subjectGPA.toStringAsFixed(2), isBold: true, color: isOnTrack ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildMarksRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 15 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? const Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSection(Subject subject) {
    return StreamBuilder<List<Exam>>(
      stream: _firestoreService.getExams(uid, widget.semesterName, subject.id!),
      builder: (context, examsSnapshot) {
        final exams = examsSnapshot.data ?? [];
        
        // Check if subject is configured for marks
        final isConfigured = subject.maxMarksPerIT > 0 && 
                             subject.maxMarksPerAssignment > 0 && 
                             subject.maxInternalComponent > 0 && 
                             subject.maxSemesterEndExam > 0;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(
              subject.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF283593),
              ),
            ),
            subtitle: !isConfigured
                ? const Text('Tap to configure marks settings', style: TextStyle(color: Colors.orange))
                : exams.isEmpty
                    ? const Text('No exams added yet')
                    : Text(
                        '${exams.length} exam(s)',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Color(0xFF283593)),
                  onPressed: () => _openSubjectSetupDialog(subject: subject),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF283593)),
                  onPressed: () => _openExamDialog(subject: subject),
                ),
              ],
            ),
            children: [
              if (!isConfigured)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Subject not configured for marks tracking.\nPlease configure the marks settings first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _openSubjectSetupDialog(subject: subject),
                        icon: const Icon(Icons.settings),
                        label: const Text('Configure Marks Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF283593),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (exams.isNotEmpty) _buildCalculatedMarksCard(subject, exams),
                if (exams.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No exams yet. Tap + to add one!',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Individual Exams/Assignments',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        ...exams.map((exam) => _buildExamCard(exam, subject)).toList(),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("Marks"),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assessment, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text(
                    "No subjects found.\nAdd subjects in Timetable first!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: subjects.map((subject) => _buildSubjectSection(subject)).toList(),
          );
        },
      ),
    );
  }
}
