import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
  bool get isGuest => uid == 'guest_user' || uid.toLowerCase().startsWith('guest');

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: const Color(0xFF283593),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Please sign up to access settings',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF283593),
      ),
      body: StreamBuilder<String>(
        stream: _firestoreService.getUserUiMode(uid),
        builder: (context, snapshot) {
          final currentUiMode = snapshot.data ?? 'light';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'UI Theme',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF283593),
                ),
              ),
              const SizedBox(height: 16),
              _buildThemeOption('Light', 'light', currentUiMode, Icons.light_mode),
              const SizedBox(height: 8),
              _buildThemeOption('Focus Mode', 'focus', currentUiMode, Icons.center_focus_strong),
              const SizedBox(height: 8),
              _buildThemeOption('Live Theme', 'live', currentUiMode, Icons.wb_sunny),
              const SizedBox(height: 8),
              _buildThemeOption('Gradient Theme', 'gradient', currentUiMode, Icons.gradient),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(
    String title,
    String mode,
    String currentMode,
    IconData icon,
  ) {
    final isSelected = currentMode == mode;

    return Card(
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF283593) : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? const Color(0xFF283593) : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF283593) : Colors.black87,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF283593))
            : null,
        onTap: () async {
          await _firestoreService.updateUiMode(uid, mode);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Theme changed to $title'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
      ),
    );
  }
}


