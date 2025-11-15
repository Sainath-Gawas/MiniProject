import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../semester/semester_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/attendance_reminder_service.dart';
import '../attendance/attendance_notification_handler.dart';
import '../settings/settings_screen.dart';
import '../premium/upgrade_premium_screen.dart';
import '../sathi/sathi_chat_screen.dart';
import '../../widgets/premium_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

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

    // Check if user is premium (automatic popup is premium-only)
    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    final isPremium = userDoc.data()?['isPremium'] ?? userDoc.data()?['premium'] ?? false;
    
    if (!isPremium) return; // Only premium users get automatic popup

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
        title: Row(
          children: [
            Expanded(
              child: Text(
                "Hello, $userName 👋",
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const PremiumBadge(),
          ],
        ),
        actions: [
          if (!isGuest)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
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
            if (!isGuest) ...[
              const Divider(),
              StreamBuilder<bool>(
                stream: _firestoreService.getUserPremiumStatus(currentUser!.uid),
                builder: (context, snapshot) {
                  final isPremium = snapshot.data ?? false;
                  if (!isPremium) {
                    return ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber),
                      title: const Text("Upgrade to Premium"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UpgradePremiumScreen(),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              StreamBuilder<bool>(
                stream: _firestoreService.getUserPremiumStatus(currentUser!.uid),
                builder: (context, premiumSnapshot) {
                  final isPremium = premiumSnapshot.data ?? false;
                  return ListTile(
                    leading: Icon(
                      Icons.smart_toy,
                      color: isPremium ? Colors.amber : Colors.grey,
                    ),
                    title: Text(
                      isPremium ? "SATHI Assistant" : "SATHI Assistant (Premium)",
                      style: TextStyle(
                        color: isPremium ? null : Colors.grey,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (isPremium) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SathiChatScreen()),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Premium Feature'),
                            content: const Text(
                              'SATHI Assistant is a premium feature.\nContact admin to upgrade your plan.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("Settings"),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
            if (isGuest) ...[
              const Divider(),
              Card(
                color: Colors.amber.shade50,
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Sign up to save your data permanently",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your data will be lost if you don't sign up. Create an account to keep your progress safe.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF283593),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Sign Up Now"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                        child: Card(
                          color: Colors.amber.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Sign up to save your data permanently",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Your data will be lost if you don't sign up. Create an account to keep your progress safe.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF283593),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text("Sign Up Now"),
                                  ),
                                ),
                              ],
                            ),
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
      floatingActionButton: StreamBuilder<bool>(
        stream: _firestoreService.getUserPremiumStatus(currentUser?.uid ?? 'guest_user'),
        builder: (context, snapshot) {
          final isPremium = snapshot.data ?? false;
          if (!isPremium || isGuest) return const SizedBox.shrink();
          
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
    );
  }
}
