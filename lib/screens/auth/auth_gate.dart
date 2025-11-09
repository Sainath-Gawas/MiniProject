import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edutrack/services/auth_service.dart';
import 'package:edutrack/screens/home/main_navigation_shell.dart';
import 'package:edutrack/screens/auth/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // Fetches user role data (Admin, VIP, User, Guest)
  Future<Map<String, dynamic>> _fetchUserRole(User user) async {
    if (user.isAnonymous) {
      return {'role': 'Guest', 'isVIP': false, 'isAdmin': false};
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // Default role if document is missing (should not happen after registration)
    if (!doc.exists) {
      return {'role': 'User', 'isVIP': false, 'isAdmin': false};
    }

    // Determine the highest active role
    bool isAdmin = doc.data()?['isAdmin'] ?? false;
    bool isVIP = doc.data()?['isVIP'] ?? false;
    String role = isAdmin ? 'Admin' : (isVIP ? 'VIP' : 'User');

    return {
      'role': role,
      'isVIP': isVIP,
      'isAdmin': isAdmin,
      'userDoc': doc.data(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;

          return FutureBuilder<Map<String, dynamic>>(
            future: _fetchUserRole(user),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.hasData) {
                // Route to the main shell upon successful role fetch
                return MainNavigationShell(
                  user: user,
                  userRoleData: roleSnapshot.data!,
                );
              }
              // Fallback to login if role fetching fails
              return const LoginScreen();
            },
          );
        } else {
          // If no user is logged in, show the LoginScreen
          return const LoginScreen();
        }
      },
    );
  }
}
