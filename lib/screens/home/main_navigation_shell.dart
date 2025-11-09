import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import all screens that will be part of the bottom navigation
import 'package:edutrack/screens/home/home_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final User user;
  final Map<String, dynamic> userRoleData; // Data fetched by AuthGate

  const MainNavigationShell({
    super.key,
    required this.user,
    required this.userRoleData,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  // List of screens for the Bottom Navigation Bar
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize screens, passing user and role data
    _screens = [
      HomeScreen(user: widget.user, userRoleData: widget.userRoleData),
      const Center(child: Text("Subjects Screen Placeholder")),
      const Center(child: Text("Timetable Screen Placeholder")),
      const Center(child: Text("Notes Screen Placeholder")),
      const Center(child: Text("Profile Screen Placeholder")),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The accent color is used here for the selected item indicator
    final accentColor = Theme.of(context).colorScheme.secondary;

    // Check if the user is a Guest for role-based UI adjustments
    final isGuest = widget.user.isAnonymous;

    return Scaffold(
      body: _screens[_selectedIndex],

      // The Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Use fixed type for five items
        backgroundColor: Colors.white,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.grey[600],
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Subjects'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Timetable',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
