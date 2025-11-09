import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:edutrack/services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  final User user;
  final Map<String, dynamic> userRoleData;

  const HomeScreen({super.key, required this.user, required this.userRoleData});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final role = userRoleData['role'] as String;
    final isGuest = user.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: const Text("EduTrack Dashboard"),
        backgroundColor: primaryColor,
        // Profile/Logout moved to the Profile tab, but we'll keep a temporary logout here
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Welcome, ${isGuest ? 'Guest' : user.email}!",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                "Your Current Role: $role",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              // Guest Warning / VIP Upsell CTA
              if (role == 'Guest')
                const Card(
                  color: Colors.yellow,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Warning: Guest Mode is Read-Only. Data will not be saved. Sign up to save your progress.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (role == 'User')
                ElevatedButton(
                  onPressed: () {
                    // Navigate to VIP Upsell screen later
                  },
                  child: const Text("Upgrade to VIP for Premium Features"),
                ),
              const SizedBox(height: 40),
              // Feature Placeholder
              ElevatedButton.icon(
                onPressed: () {
                  // Next step: Navigate to Subject Setup Screen
                },
                icon: const Icon(Icons.add),
                label: const Text("Start: Set up Your First Subject"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
