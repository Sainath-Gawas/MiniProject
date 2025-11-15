import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'notes_screen.dart';
import 'attendance_screen.dart';
import 'timetable_screen.dart';
import 'marks_screen.dart';
import '/models/subject_model.dart';
import '/models/exam_model.dart';
import '/models/timetable_model.dart';
import '/models/attendance_model.dart';
import '/models/gpa_scale_model.dart';
import '/services/firestore_service.dart';
import '../../screens/premium/upgrade_premium_screen.dart';
import '../../screens/sathi/sathi_chat_screen.dart';
import '../../widgets/premium_badge.dart';

class SemesterDashboardScreen extends StatefulWidget {
  final String semesterName;
  const SemesterDashboardScreen({Key? key, required this.semesterName})
    : super(key: key);

  @override
  State<SemesterDashboardScreen> createState() =>
      _SemesterDashboardScreenState();
}

class _SemesterDashboardScreenState extends State<SemesterDashboardScreen> {
  int _selectedIndex = 0;
  String _quote = "Loading inspirational quote...";
  String _author = "";
  bool _loadingQuote = true;

  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';

  Timer? _attendanceCheckTimer;
  final Set<String> _processedClasses =
      {}; // Track processed classes to prevent duplicates

  @override
  void initState() {
    super.initState();
    _fetchQuote();
    _startAttendanceCheck();
  }

  @override
  void dispose() {
    _attendanceCheckTimer?.cancel();
    super.dispose();
  }

  /// Start periodic check for classes that just ended
  void _startAttendanceCheck() {
    // Check every minute for classes that ended
    _attendanceCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkForEndedClasses();
    });

    // Also check immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        _checkForEndedClasses();
      });
    });
  }

  /// Check for classes that just ended and show attendance pop-up (Premium only)
  Future<void> _checkForEndedClasses() async {
    if (!mounted || uid == 'guest_user') return;

    // Check if user is premium
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final isPremium = userDoc.data()?['isPremium'] ?? userDoc.data()?['premium'] ?? false;
    
    if (!isPremium) return; // Only premium users get automatic popup

    try {
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

      // Get timetable entries for today
      final timetable = await _firestoreService.getTimetableOnce(
        uid,
        widget.semesterName,
      );
      final todayEntries = timetable.where((e) => e.day == currentDay).toList();

      if (todayEntries.isEmpty) return;

      // Get existing attendance for today
      final existingAttendance = await _firestoreService.getAttendanceOnce(
        uid,
        widget.semesterName,
      );
      final todayAttendance = existingAttendance.where((att) {
        return att.date.year == today.year &&
            att.date.month == today.month &&
            att.date.day == today.day;
      }).toList();

      final markedSubjects = todayAttendance.map((a) => a.subject).toSet();

      // Check each timetable entry
      for (var entry in todayEntries) {
        // Skip if already marked today
        if (markedSubjects.contains(entry.subject)) continue;

        // Create a unique key for this class today
        final classKey =
            '${entry.subject}_${today.year}_${today.month}_${today.day}';

        // Skip if already processed
        if (_processedClasses.contains(classKey)) continue;

        // Check if class just ended (within last 5 minutes)
        final endTime = entry.getEndDateTime(forDate: now);
        final minutesSinceEnd = now.difference(endTime).inMinutes;

        // Show pop-up if class ended 0-5 minutes ago
        // This gives a 5-minute window after class ends
        if (minutesSinceEnd >= 0 && minutesSinceEnd <= 5) {
          _processedClasses.add(classKey);
          _showAttendanceDialog(entry, endTime);
          break; // Only show one dialog at a time
        }
      }
    } catch (e) {
      print('Error checking for ended classes: $e');
    }
  }

  /// Show attendance dialog for a class
  Future<void> _showAttendanceDialog(
    TimetableEntry entry,
    DateTime classDate,
  ) async {
    if (!mounted) return;

    final attended = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Mark attendance for ${entry.subject}?',
          style: const TextStyle(
            color: Color(0xFF283593),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Class ended at ${entry.endTime}',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Absent'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF283593),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Present'),
          ),
        ],
      ),
    );

    if (attended == null) {
      // User dismissed, remove from processed so it can be shown again
      final today = DateTime.now();
      final classKey =
          '${entry.subject}_${today.year}_${today.month}_${today.day}';
      _processedClasses.remove(classKey);
      return;
    }

    // Create attendance record
    final record = AttendanceRecord(
      id: null,
      date: classDate,
      subject: entry.subject,
      status: attended ? AttendanceStatus.present : AttendanceStatus.absent,
    );

    // Save to Firestore
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
      classHappened: true,
      attended: attended,
      wasCancelled: false,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            attended
                ? 'Attendance marked: Present ✓'
                : 'Attendance marked: Absent',
          ),
          backgroundColor: attended ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _fetchQuote() async {
    setState(() => _loadingQuote = true);
    try {
      final response = await http
          .get(Uri.parse('https://type.fit/api/quotes'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final randomQuote = (data..shuffle()).first;
          final quoteText = randomQuote['text'] ?? "No quote available";
          String authorText = randomQuote['author'] ?? "Unknown";

          // Clean author name
          authorText = authorText.replaceAll(', type.fit', '').trim();
          if (authorText.isEmpty) authorText = "Unknown";

          if (!mounted) return;
          setState(() {
            _quote = quoteText;
            _author = authorText;
            _loadingQuote = false;
          });
        } else {
          _setFallbackQuote();
        }
      } else {
        _setFallbackQuote();
      }
    } catch (e) {
      print("Quote fetch error: $e");
      _setFallbackQuote();
    }
  }

  /// Set fallback quote when API fails
  void _setFallbackQuote() {
    if (!mounted) return;
    setState(() {
      _quote = "The only way to do great work is to love what you do.";
      _author = "Steve Jobs";
      _loadingQuote = false;
    });
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NotesScreen(semesterName: widget.semesterName),
        ),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              AttendanceScreen(semesterName: widget.semesterName),
        ),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MarksScreen(semesterName: widget.semesterName),
        ),
      );
    } else if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              TimetableScreen(semesterName: widget.semesterName),
        ),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  Widget _buildQuoteCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "💬 Quote of the Day",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF283593),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF00B0FF)),
                  onPressed: _fetchQuote,
                  tooltip: 'Refresh quote',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _loadingQuote
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _quote,
                        style: const TextStyle(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF212121),
                        ),
                      ),
                      if (_author.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "- $_author",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF616161),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(Subject subject) {
    final percentage = subject.currentAttendancePercentage;
    final present = subject.classesAttended;
    final absent = subject.classesMissed;
    final total = subject.totalClassesConducted;
    final isOnTrack = subject.isOnTrack;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isOnTrack
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= subject.targetAttendancePercentage
                    ? Colors.green
                    : (percentage >= subject.targetAttendancePercentage * 0.8
                          ? Colors.orange
                          : Colors.red),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', total.toString(), Colors.blue),
                _buildStatItem('Present', present.toString(), Colors.green),
                _buildStatItem('Absent', absent.toString(), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
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

  Widget _buildMarksBarChart(
    List<Subject> subjects,
    Map<String, List<Exam>> examsMap,
  ) {
    // Filter subjects that have marks data
    final subjectsWithMarks = subjects.where((subject) {
      final exams = examsMap[subject.id] ?? [];
      return exams.isNotEmpty;
    }).toList();

    if (subjectsWithMarks.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              "No marks data available yet.\nAdd exams in the Marks tab!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Prepare data for bar chart
    final List<BarChartGroupData> barGroups = [];
    final List<String> subjectNames = [];

    for (int i = 0; i < subjectsWithMarks.length; i++) {
      final subject = subjectsWithMarks[i];
      final exams = examsMap[subject.id] ?? [];

      // Calculate internal test average (best X of Y)
      final internalTests = exams
          .where((e) => e.type == ExamType.internal && e.marksObtained > 0)
          .toList();
      double internalAvg = 0.0;
      if (internalTests.isNotEmpty && subject.bestITsToConsider > 0) {
        internalTests.sort(
          (a, b) => b.marksObtained.compareTo(a.marksObtained),
        );
        final bestITs = internalTests.take(subject.bestITsToConsider).toList();
        final sum = bestITs.fold<double>(
          0.0,
          (prev, e) => prev + e.marksObtained,
        );
        internalAvg = (sum / bestITs.length).ceilToDouble();
        if (internalAvg > subject.maxMarksPerIT)
          internalAvg = subject.maxMarksPerIT;
      }

      // Get semester end exam marks
      final semesterExam = exams.firstWhere(
        (e) => e.type == ExamType.semester && e.marksObtained > 0,
        orElse: () => Exam(
          id: null,
          name: '',
          type: ExamType.semester,
          maxMarks: 0,
          marksObtained: 0,
          date: DateTime.now(),
        ),
      );
      final semesterMarks = semesterExam.marksObtained;

      // Normalize to percentage for better visualization
      final internalPercent = subject.maxMarksPerIT > 0
          ? (internalAvg / subject.maxMarksPerIT * 100)
          : 0.0;
      final semesterPercent = subject.maxSemesterEndExam > 0
          ? (semesterMarks / subject.maxSemesterEndExam * 100)
          : 0.0;

      subjectNames.add(
        subject.name.length > 10
            ? '${subject.name.substring(0, 10)}...'
            : subject.name,
      );

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: internalPercent,
              color: Colors.blue,
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: semesterPercent,
              color: Colors.purple,
              width: 12,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📊 Marks per Subject",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF283593),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Internal Tests', Colors.blue),
                const SizedBox(width: 16),
                _buildLegendItem('Semester End', Colors.purple),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.grey[850]!,
                      tooltipBorder: BorderSide(
                        color: Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < subjectNames.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                subjectNames[value.toInt()],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDashboardContent() {
    return StreamBuilder<List<Subject>>(
      stream: _firestoreService.getSubjects(uid, widget.semesterName),
      builder: (context, subjectsSnapshot) {
        if (subjectsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final subjects = subjectsSnapshot.data ?? [];

        if (subjects.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildQuoteCard(),
                const SizedBox(height: 20),
                const Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        "No subjects found.\nAdd subjects in Timetable or Attendance tab!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<bool>(
          stream: _firestoreService.getUserPremiumStatus(uid),
          builder: (context, premiumSnapshot) {
            final isPremium = premiumSnapshot.data ?? false;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuoteCard(),
                  const SizedBox(height: 20),
                  const Text(
                    "📊 Attendance Summary",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF283593),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...subjects
                      .map((subject) => _buildAttendanceCard(subject))
                      .toList(),
                  const SizedBox(height: 20),
                  // Marks chart - use a custom widget that handles multiple streams
                  _buildMarksChartSection(subjects),
                  if (!isPremium) ...[
                    const SizedBox(height: 20),
                    _buildPremiumCTACard(),
                  ],
                  if (isPremium) ...[
                    const SizedBox(height: 20),
                    _buildPremiumAnalyticsSection(subjects),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPremiumCTACard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF283593), Color(0xFF00B0FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Unlock full analytics with Student Sathi Premium",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Get access to:",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _buildFeatureItem("GPA trend across semesters"),
            _buildFeatureItem("Subject-wise marks analysis"),
            _buildFeatureItem("Internal vs external distribution charts"),
            _buildFeatureItem("Attendance heatmap"),
            _buildFeatureItem("Smooth animations & rich UI"),
            _buildFeatureItem("AI Assistant SATHI"),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UpgradePremiumScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF283593),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  "Upgrade",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAnalyticsSection(List<Subject> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "⭐ Premium Analytics",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF283593),
          ),
        ),
        const SizedBox(height: 12),
        _buildGPATrendCard(),
        const SizedBox(height: 16),
        _buildSubjectWiseAnalysisCard(subjects),
        const SizedBox(height: 16),
        _buildInternalExternalChart(subjects),
      ],
    );
  }

  Widget _buildGPATrendCard() {
    return StreamBuilder<List<Subject>>(
      stream: _firestoreService.getSubjects(uid, widget.semesterName),
      builder: (context, subjectsSnapshot) {
        if (!subjectsSnapshot.hasData || subjectsSnapshot.data!.isEmpty) {
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📈 GPA Trend",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF283593),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        "No data available. Add exams and marks to view analytics.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final subjects = subjectsSnapshot.data!;
        return _GPATrendChartWidget(
          subjects: subjects,
          firestoreService: _firestoreService,
          uid: uid,
          semesterName: widget.semesterName,
        );
      },
    );
  }

  Widget _buildSubjectWiseAnalysisCard(List<Subject> subjects) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📊 Subject-wise Marks Analysis",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF283593),
              ),
            ),
            const SizedBox(height: 16),
            _SubjectMarksChartWidget(
              subjects: subjects,
              firestoreService: _firestoreService,
              uid: uid,
              semesterName: widget.semesterName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInternalExternalChart(List<Subject> subjects) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "🥧 Attendance Distribution",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF283593),
              ),
            ),
            const SizedBox(height: 16),
            _AttendancePieChartWidget(
              subjects: subjects,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarksChartSection(List<Subject> subjects) {
    // Use a simpler approach: show chart with data as it becomes available
    // For subjects with no exams, they'll show 0
    return _MarksChartWidget(
      subjects: subjects,
      firestoreService: _firestoreService,
      uid: uid,
      semesterName: widget.semesterName,
      buildChart: _buildMarksBarChart,
    );
  }

  Widget _getBody() {
    return _buildDashboardContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.semesterName,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const PremiumBadge(),
          ],
        ),
        backgroundColor: const Color(0xFF283593),
      ),
      body: _getBody(),
      floatingActionButton: StreamBuilder<bool>(
        stream: _firestoreService.getUserPremiumStatus(uid),
        builder: (context, snapshot) {
          final isPremium = snapshot.data ?? false;
          if (!isPremium || uid == 'guest_user') return const SizedBox.shrink();
          
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SathiChatScreen()),
              );
            },
            backgroundColor: Colors.amber.shade600,
            icon: const Icon(Icons.smart_toy, color: Colors.white),
            label: const Text(
              'Chat with SATHI',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF283593),
        unselectedItemColor: const Color(0xFF616161),
        type: BottomNavigationBarType.fixed,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.note_alt), label: "Notes"),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: "Attendance",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Marks"),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: "Timetable",
          ),
        ],
      ),
    );
  }
}

// Helper widget to collect exams from multiple streams and display chart
class _MarksChartWidget extends StatefulWidget {
  final List<Subject> subjects;
  final FirestoreService firestoreService;
  final String uid;
  final String semesterName;
  final Widget Function(List<Subject>, Map<String, List<Exam>>) buildChart;

  const _MarksChartWidget({
    required this.subjects,
    required this.firestoreService,
    required this.uid,
    required this.semesterName,
    required this.buildChart,
  });

  @override
  State<_MarksChartWidget> createState() => _MarksChartWidgetState();
}

class _MarksChartWidgetState extends State<_MarksChartWidget> {
  final Map<String, List<Exam>> examsMap = {};

  @override
  Widget build(BuildContext context) {
    // Build stream builders for all subjects and collect data
    return Column(
      children: widget.subjects.map((subject) {
        return StreamBuilder<List<Exam>>(
          stream: widget.firestoreService.getExams(
            widget.uid,
            widget.semesterName,
            subject.id!,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              examsMap[subject.id!] = snapshot.data ?? [];
            }

            // Show chart only for the last subject (after all streams have at least attempted)
            if (subject == widget.subjects.last) {
              return widget.buildChart(widget.subjects, examsMap);
            }

            return const SizedBox.shrink();
          },
        );
      }).toList(),
    );
  }
}

// GPA Trend Chart Widget
class _GPATrendChartWidget extends StatefulWidget {
  final List<Subject> subjects;
  final FirestoreService firestoreService;
  final String uid;
  final String semesterName;

  const _GPATrendChartWidget({
    required this.subjects,
    required this.firestoreService,
    required this.uid,
    required this.semesterName,
  });

  @override
  State<_GPATrendChartWidget> createState() => _GPATrendChartWidgetState();
}

class _GPATrendChartWidgetState extends State<_GPATrendChartWidget> {
  final Map<String, List<Exam>> examsMap = {};
  final gpaScale = GPAScale.defaultScale();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "📈 Subject-wise GPA",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF283593),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: Column(
                children: widget.subjects.map((subject) {
                  return StreamBuilder<List<Exam>>(
                    stream: widget.firestoreService.getExams(
                      widget.uid,
                      widget.semesterName,
                      subject.id!,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        examsMap[subject.id!] = snapshot.data ?? [];
                      }
                      
                      final exams = examsMap[subject.id!] ?? [];
                      final percentage = subject.calculateOverallSubjectPercentage(exams);
                      final gpa = percentage > 0 ? gpaScale.getGPA(percentage) : 0.0;
                      
                      if (subject == widget.subjects.last) {
                        final hasData = examsMap.values.any((exams) => exams.isNotEmpty);
                        if (!hasData) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                "No data available. Add exams and marks to view analytics.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }
                        
                        final gpaData = widget.subjects.map((s) {
                          final sExams = examsMap[s.id!] ?? [];
                          final sPercentage = s.calculateOverallSubjectPercentage(sExams);
                          return {
                            'name': s.name.length > 10 ? '${s.name.substring(0, 10)}...' : s.name,
                            'gpa': sPercentage > 0 ? gpaScale.getGPA(sPercentage) : 0.0,
                          };
                        }).toList();
                        
                        return Expanded(
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 10,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= 0 && value.toInt() < gpaData.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            gpaData[value.toInt()]['name'] as String,
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                    reservedSize: 40,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      );
                                    },
                                    reservedSize: 30,
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: gpaData.asMap().entries.map((entry) {
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value['gpa'] as double,
                                      color: const Color(0xFF283593),
                                      width: 16,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Subject Marks Chart Widget
class _SubjectMarksChartWidget extends StatefulWidget {
  final List<Subject> subjects;
  final FirestoreService firestoreService;
  final String uid;
  final String semesterName;

  const _SubjectMarksChartWidget({
    required this.subjects,
    required this.firestoreService,
    required this.uid,
    required this.semesterName,
  });

  @override
  State<_SubjectMarksChartWidget> createState() => _SubjectMarksChartWidgetState();
}

class _SubjectMarksChartWidgetState extends State<_SubjectMarksChartWidget> {
  final Map<String, List<Exam>> examsMap = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.subjects.map((subject) {
        return StreamBuilder<List<Exam>>(
          stream: widget.firestoreService.getExams(
            widget.uid,
            widget.semesterName,
            subject.id!,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              examsMap[subject.id!] = snapshot.data ?? [];
            }
            
            if (subject == widget.subjects.last) {
              final hasData = examsMap.values.any((exams) => exams.isNotEmpty);
              if (!hasData) {
                return const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    "No data available. Add exams and marks to view analytics.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              
              return SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < widget.subjects.length) {
                              final subj = widget.subjects[value.toInt()];
                              final name = subj.name.length > 8 ? '${subj.name.substring(0, 8)}...' : subj.name;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  name,
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 40,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: widget.subjects.asMap().entries.map((entry) {
                      final exams = examsMap[entry.value.id!] ?? [];
                      final percentage = entry.value.calculateOverallSubjectPercentage(exams);
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: percentage,
                            color: const Color(0xFF283593),
                            width: 20,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        );
      }).toList(),
    );
  }
}

// Attendance Pie Chart Widget
class _AttendancePieChartWidget extends StatelessWidget {
  final List<Subject> subjects;

  const _AttendancePieChartWidget({required this.subjects});

  @override
  Widget build(BuildContext context) {
    int totalPresent = 0;
    int totalAbsent = 0;
    
    for (var subject in subjects) {
      totalPresent += subject.classesAttended;
      totalAbsent += subject.classesMissed;
    }
    
    final total = totalPresent + totalAbsent;
    
    if (total == 0) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "No data available. Add attendance records to view analytics.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }
    
    final presentPercent = (totalPresent / total * 100);
    final absentPercent = (totalAbsent / total * 100);
    
    return SizedBox(
      height: 250,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: presentPercent,
              title: '${presentPercent.toStringAsFixed(1)}%',
              color: Colors.green,
              radius: 80,
            ),
            PieChartSectionData(
              value: absentPercent,
              title: '${absentPercent.toStringAsFixed(1)}%',
              color: Colors.red,
              radius: 80,
            ),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
}
