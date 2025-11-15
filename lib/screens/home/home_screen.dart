import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../semester/semester_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_reminder_service.dart';
import '../attendance/attendance_notification_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> firestoreSemesters = [];
  List<String> guestSemesters = [];

  bool get isGuest => currentUser?.isAnonymous ?? false;
  String userName = "Guest User";

  @override
  void initState() {
    super.initState();
    if (isGuest) return;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['name'] ?? "User";
        });
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('semesters')
          .get();

      setState(() {
        firestoreSemesters = snapshot.docs.map((e) => e.id).toList();
      });

      // Check for pending attendance after data is loaded
      // Add a small delay to ensure UI is ready
      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _checkPendingAttendance();
          }
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  Future<void> _addSemester() async {
    final semNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Semester"),
        content: TextField(
          controller: semNameController,
          decoration: const InputDecoration(hintText: "Enter semester name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final name = semNameController.text.trim();
              if (name.isEmpty) return;

              if (isGuest) {
                setState(() => guestSemesters.add(name));
              } else {
                await _firestore
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('semesters')
                    .doc(name)
                    .set({'createdAt': Timestamp.now()});
                await _loadUserData();
              }
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPendingAttendance() async {
    if (isGuest || !mounted || firestoreSemesters.isEmpty) return;

    final reminderService = AttendanceReminderService();
    final handler = AttendanceNotificationHandler();

    // Check each semester for pending classes
    for (var semester in firestoreSemesters) {
      if (!mounted) break; // Check if still mounted

      final pendingClasses = await reminderService.getPendingAttendanceClasses(
        semester,
      );

      if (pendingClasses.isNotEmpty && mounted) {
        // Show dialog for first pending class
        final firstClass = pendingClasses.first;
        await handler.handleNotificationResponse(
          context: context,
          semester: semester,
          subject: firstClass.subject,
          time: firstClass.startTime,
        );
        // After handling one, wait a bit and check for more
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          _checkPendingAttendance(); // Recursively check for more
        }
        break; // Only process one semester at a time
      }
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final semesters = isGuest ? guestSemesters : firestoreSemesters;

    return Scaffold(
      appBar: AppBar(
        title: Text("Hello, $userName 👋"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF283593), Color(0xFF00B0FF)],
                ),
              ),
              child: Text(
                "Student",
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
            ),
            ...semesters.map(
              (sem) => ListTile(
                title: Text(sem),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SemesterDashboardScreen(semesterName: sem),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("Add Semester"),
              onTap: _addSemester,
            ),
          ],
        ),
      ),
      body: semesters.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school, size: 80, color: Colors.grey),
                    const SizedBox(height: 20),
                    Text(
                      "No semesters found",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _addSemester,
                      child: const Text("Add your first semester"),
                    ),
                    if (isGuest)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Sign up to save your progress permanently",
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  "Your Semesters",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                ...semesters.map(
                  (sem) => Card(
                    child: ListTile(
                      title: Text(sem),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SemesterDashboardScreen(semesterName: sem),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
